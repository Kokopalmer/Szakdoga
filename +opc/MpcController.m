% File: +opc/MpcController.m
classdef MpcController < handle
    properties
        Model               % struct, benne: bootstat
        MoistureSetpoint = 1.0

        MV_config           % Tmin, Tmax
        SearchConfig        % line search paraméterek

        lastControl         % utolsó T [°C] (skálár)
        BaseInputVec        % 12×1 neural input (app.makeInput-ből)

        Debug = false        % debug log ki/bekapcsolása
    end

    methods
        function obj = MpcController(modelFile)
            % Neurális modellek betöltése (bootstat_only.mat)
            obj.Model = load(modelFile);  % struct, pl. Model.bootstat

            % Csak hőmérsékletet optimalizálunk
            obj.MV_config = struct( ...
                'Dryer_Temp_min', 15, ...   % alsó korlát
                'Dryer_Temp_max', 90  ...   % felső korlát
            );

            % Lineáris keresés beállításai
            obj.SearchConfig = struct( ...
                'BaseStep',   5.0, ...    % alap lépés [°C]
                'MaxStep',   15.0, ...    % max kezdő lépés [°C]
                'MinStep',    0.2, ...    % legkisebb lépés [°C]
                'MaxIter',   25,  ...     % max iteráció
                'Tolerance',  0.05 ...    % elfogadott nedvesség hiba
            );

            obj.lastControl  = NaN;    % később tölti fel az app
            obj.BaseInputVec = [];
        end

        function [T_opt, y_pred, exitflag, iterLog] = computeOptimal(obj, process_state, setpoint)
            % Külső API az app számára
            obj.MoistureSetpoint = setpoint;

            if isempty(obj.BaseInputVec)
                error('MpcController:BaseInputMissing', ...
                    'BaseInputVec üres – állítsd be app.makeInput(app) kimenetével.');
            end

            % Első hívásnál legyen lastControl = aktuális T
            if isnan(obj.lastControl)
                obj.lastControl = process_state.Dryer_Temp;
            end

            % 1D line search hőmérsékletre
            [T_opt, y_opt, exitflag, iterLog] = obj.lineSearchTemperature( ...
                obj.lastControl, setpoint);

            y_pred = y_opt;

            if exitflag >= 0
                obj.lastControl = T_opt;
            end

            if obj.Debug
                fprintf(['[MPC] Setpoint = %.3f | Predicted = %.3f | ' ...
                         'T_new = %.2f | T_prev = %.2f | exitflag = %d\n'], ...
                        obj.MoistureSetpoint, y_pred, ...
                        T_opt, obj.lastControl, exitflag);
            end
        end
    end

    methods (Access = private)
        function [T_opt, y_opt, exitflag, iterLog] = lineSearchTemperature(obj, T0, setpoint)
            cfg   = obj.SearchConfig;
            Tmin  = obj.MV_config.Dryer_Temp_min;
            Tmax  = obj.MV_config.Dryer_Temp_max;

            % Induló T a tartományon belül
            T = min(max(T0, Tmin), Tmax);

            % Kezdő pont kiértékelése
            input0 = obj.build_input_from_T(T);
            y0     = obj.predict_moisture(input0);
            err0   = y0 - setpoint;

            iterLog = struct('iter', 1, 'T', T, 'y', y0, 'err', err0, 'step', 0);

            if obj.Debug
                fprintf('[MPC-LS] it=%2d | T=%.2f | y=%.3f | err=%.3f | step=%.2f\n', ...
                    1, T, y0, err0, 0);
            end

            % Ha már elég jó
            if abs(err0) <= cfg.Tolerance
                T_opt    = T;
                y_opt    = y0;
                exitflag = 1;
                return;
            end

            % Dinamikus kezdő lépés a hiba nagysága alapján
            absErr0 = abs(err0);
            if absErr0 >= 2.0
                stepMag0 = cfg.MaxStep;              % nagyon messze → nagy lépés
            elseif absErr0 >= 1.0
                stepMag0 = min(cfg.MaxStep, 2*cfg.BaseStep);
            elseif absErr0 >= 0.5
                stepMag0 = cfg.BaseStep;
            else
                stepMag0 = max(cfg.BaseStep/2, cfg.MinStep*2);  % közel → finomabb
            end

            % Irány: err>0 → túl nedves → T-t emelni; err<0 → túl száraz → T-t csökkenteni
            if err0 > 0
                dir = +1;
            else
                dir = -1;
            end

            stepMag = stepMag0;
            step    = dir * stepMag;

            T_curr   = T;
            y_curr   = y0;
            err_curr = err0;

            iter = 1;

            while iter < cfg.MaxIter
                % Jelölt T
                T_cand = T_curr + step;
                T_cand = min(max(T_cand, Tmin), Tmax);

                if abs(T_cand - T_curr) < 1e-6
                    break;
                end

                input_cand = obj.build_input_from_T(T_cand);
                y_cand     = obj.predict_moisture(input_cand);
                err_cand   = y_cand - setpoint;

                iter = iter + 1;
                iterLog(iter) = struct( ...
                    'iter', iter, ...
                    'T',    T_cand, ...
                    'y',    y_cand, ...
                    'err',  err_cand, ...
                    'step', step);

                if obj.Debug
                    fprintf('[MPC-LS] it=%2d | T=%.2f | y=%.3f | err=%.3f | step=%.2f\n', ...
                        iter, T_cand, y_cand, err_cand, step);
                end

                % Elég jó?
                if abs(err_cand) <= cfg.Tolerance
                    T_curr   = T_cand;
                    y_curr   = y_cand;
                    err_curr = err_cand;
                    break;
                end

                % Előjelváltás → túlmentünk a célon
                if sign(err_cand) ~= sign(err_curr)
                    dir     = -dir;
                    stepMag = stepMag / 2;
                    step    = dir * stepMag;

                    T_curr   = T_cand;
                    y_curr   = y_cand;
                    err_curr = err_cand;

                else
                    % Nem váltott előjelet
                    if abs(err_cand) < abs(err_curr)
                        % Javulás → elfogadjuk
                        T_curr   = T_cand;
                        y_curr   = y_cand;
                        err_curr = err_cand;
                    else
                        % Rosszabb → felezzük a lépést, maradunk a helyünkön
                        stepMag = stepMag / 2;
                        step    = dir * stepMag;
                    end
                end

                if stepMag < cfg.MinStep
                    break;
                end
            end

            T_opt = T_curr;
            y_opt = y_curr;

            if abs(err_curr) <= cfg.Tolerance
                exitflag = 1;
            else
                exitflag = 0;
            end
        end

        function input_vec = build_input_from_T(obj, T)
            % BaseInputVec struktúrája (makeInput alapján):
            %  1: Szarito_T       (zóna1-3 átlag T)
            %  2: Szarito_V       (légáram)
            %  3: Mass_rate
            %  4: LS_ratio
            %  5: Screw_rotation
            %  6: Szarito_4zonaT  (4. zóna T)
            %  7..10: Extruder zónák T
            %  11: Mill_type
            %  12: Mill_sieve
            %
            % MPC-ben: 1-es ÉS 6-os elem EGYÜTT MOZOG → ugyanarra a T-re állítjuk.
            
            base = double(obj.BaseInputVec(:));  % 12×1
            base(1) = T;   % átlag szárító T (zónák 1–3)
            base(6) = T;   % 4. zóna T
            input_vec = base;
        end

        function y = predict_moisture(obj, input_vec)
            input_vec = double(input_vec(:));  % 12×1
            bs = obj.Model.bootstat;          % 500×4 cell
            nNets = size(bs, 1);
            preds = zeros(nNets, 1);

            for i = 1:nNets
                net = bs{i, 1};
                preds(i) = sim(net, input_vec);
            end

            y = mean(preds);
        end
    end
end
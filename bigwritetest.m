%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File: test_mpc_line_search.m  (offline szimuláció az új MPC-hez)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Offline teszt az új, dinamikus lépéses, csak-hőmérséklet MPCController-hez.

clear; clc; close all;

modelFile = 'bootstat_only.mat';

if ~isfile(modelFile)
    error('Nem találom a "%s" fájlt.', modelFile);
end

S = load(modelFile, 'bootstat');
bootstat = S.bootstat;
nNets = size(bootstat, 1);
fprintf('bootstat hálók száma: %d\n', nNets);

%% 1) Alap 12 elemű bemenet (ugyanaz struktúra, mint makeInput)

baseInput0 = [ ...
    30;        % 1 Szarito_T
    60;        % 2 Szarito_V
    3;         % 3 Mass_rate
    0.10;      % 4 LS_ratio
    600;       % 5 Screw_rotation
    30;        % 6 Szarito_4zonaT
    28.97;     % 7 Extruder_4zonaT
    25;        % 8 Extruder_3zonaT
    25;        % 9 Extruder_2zonaT
    25;        % 10 Extruder_1zonaT
    1;         % 11 Mill_type
    0.8        % 12 Mill_sieve
];

% Induló hőmérséklet (ami a rendszerben most van)
T0 = 16.67;
baseInput = baseInput0;
baseInput(1) = T0;
baseInput(6) = T0;

fprintf('\nKiinduló T0 = %.2f °C, baseInput(1) = %.2f, baseInput(6) = %.2f\n', ...
    T0, baseInput(1), baseInput(6));

%% 2) process_state felépítése

process_state = struct( ...
    'Dryer_Temp',      baseInput(1), ...
    'Dryer_Airflow',   baseInput(2), ...
    'Mass_rate',       baseInput(3), ...
    'LS_ratio',        baseInput(4), ...
    'Screw_rotation',  baseInput(5), ...
    'Extruder_Temp',   mean(baseInput(7:10)), ...
    'Mill_type',       baseInput(11), ...
    'Mill_sieve',      baseInput(12) );

%% 3) MpcController példány + beállítás

mpc = opc.MpcController(modelFile);
mpc.Debug        = true;         % lépésenkénti log
mpc.BaseInputVec = baseInput;    % ugyanaz, mint app.makeInput()
mpc.lastControl  = T0;           % induló T

setpoint = 4.0;   % cél nedvesség

fprintf('\n=== MPC teszt (line search, csak T, dinamikus kezdő lépés) ===\n');
fprintf('Setpoint moisture = %.3f\n', setpoint);

% MPC optimalizáció
[T_opt, y_pred, exitflag, iterLog] = mpc.computeOptimal(process_state, setpoint);

fprintf('\n[MPC eredmény]\n');
fprintf('  Setpoint      = %.3f\n', setpoint);
fprintf('  T_prev        = %.3f °C\n', T0);
fprintf('  T_opt (MPC)   = %.3f °C\n', T_opt);
fprintf('  y_pred (MPC)  = %.3f\n', y_pred);
fprintf('  exitflag      = %d\n', exitflag);

%% 4) T-söprés: megnézzük, mit gondol a háló T→nedvesség függvényről

fprintf('\n=== T-söprés (neuronháló viselkedés) ===\n');

T_min = mpc.MV_config.Dryer_Temp_min;
T_max = mpc.MV_config.Dryer_Temp_max;

T_grid = linspace(T_min, T_max, 40);
y_grid = zeros(size(T_grid));

for k = 1:numel(T_grid)
    T = T_grid(k);
    inp = baseInput;
    inp(1) = T;
    inp(6) = T;
    y_grid(k) = predict_moisture_local(bootstat, inp);
end

for k = 1:5:numel(T_grid)
    fprintf('  T = %6.2f °C  ->  y_pred = %7.3f\n', T_grid(k), y_grid(k));
end

%% 5) Ábra: nedvesség vs T + MPC iterációk

Ts_iter = [iterLog.T];
ys_iter = [iterLog.y];

figure;
plot(T_grid, y_grid, '-o'); hold on;
plot(Ts_iter, ys_iter, 'r-o', 'LineWidth', 1.5, 'MarkerSize', 6);
plot(T0, predict_moisture_local(bootstat, baseInput), 'gs', 'MarkerSize', 8, 'LineWidth', 1.5);
plot(T_opt, y_pred, 'kd', 'MarkerSize', 8, 'LineWidth', 1.5);

grid on;
xlabel('Dryer Temperature [°C]');
ylabel('Predicted Moisture [-]');
legend('Network prediction', 'MPC iterations', 'Initial T0', 'MPC optimal T', ...
    'Location', 'best');
title(sprintf('MLP moisture prediction vs T (setpoint = %.3f)', setpoint));

fprintf('\nÁbra elkészült: T vs predicted moisture + MPC lépések.\n');

%% Lokális predikciós függvény (ugyanaz logika, mint az osztályban)
function y = predict_moisture_local(bootstat, input_vec)
    input_vec = double(input_vec(:));
    nNets = size(bootstat,1);
    preds = zeros(nNets,1);
    for i = 1:nNets
        net = bootstat{i,1};
        preds(i) = sim(net, input_vec);
    end
    y = mean(preds);
end

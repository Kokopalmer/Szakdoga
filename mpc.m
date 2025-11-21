
% =====================================================================
% Minimal Model Predictive Control Loop using Trained MLP
% =====================================================================

% === Configuration ===
moisture_setpoint = 1.0;      % Target [%]
control_interval = 30;        % [s]
num_steps = 50;               % Simulation steps

% === Manipulated Variable Constraints ===
MV_config = struct(...
    'Dryer_Temp_min', 25, ...
    'Dryer_Temp_max', 90, ...
    'Dryer_Temp_rate_max', 5, ...
    'Dryer_Airflow_min', 10, ...
    'Dryer_Airflow_max', 130, ...
    'Dryer_Airflow_rate_max', 20);

% === Tuning ===
tuning = struct('w_tracking', 100, 'w_control_effort', 1, 'w_rate_change', 10);
soft_constraint = struct('enable', true, 'moisture_min', 0.1, ...
                         'moisture_max', 3.0, 'violation_penalty', 10);

% === Load trained MLP model ===
fprintf('Loading MLP model...\n');
load('ANN_model.mat'); 
mlp_model = ANN1_model;
fprintf('Model loaded.\n\n');

% === Initialize process state ===
process_state.Dryer_Temp = 40;
process_state.Dryer_Airflow = 70;
process_state.Mass_rate = 3;
process_state.LS_ratio = 0.14;
process_state.Screw_rotation = 200;
process_state.Extruder_Temp = 25;
process_state.Mill_type = 1;
process_state.Mill_sieve = 0.8;

u_previous = [process_state.Dryer_Temp; process_state.Dryer_Airflow];

fprintf('Step | Moisture_pred | Temp | Airflow\n');
fprintf('-----+---------------+------+---------\n');

% === MAIN MPC LOOP ===
for k = 1:num_steps
    % 1. Solve MPC optimization
    [u_opt, cost_val, exitflag, ~] = solve_mpc_optimization(...
        process_state, mlp_model, moisture_setpoint, u_previous, ...
        MV_config, tuning, soft_constraint);

    if exitflag < 1
        warning('Optimization failed at step %d, using previous control.', k);
        u_opt = u_previous;
    end

    % 2. Apply control
    process_state.Dryer_Temp = u_opt(1);
    process_state.Dryer_Airflow = u_opt(2);

    % 3. Predict new moisture
    input_vec = construct_mlp_input(process_state);
    y_pred = predict_moisture(mlp_model, input_vec);

    % 4. Display
    fprintf('%4d | %13.3f | %4.1f | %7.1f\n', k, y_pred, u_opt(1), u_opt(2));

    % 5. Feedback (update previous)
    u_previous = u_opt;

    pause(0.05); % simulate control interval
end

fprintf('\nMPC feedback simulation complete.\n');

% =====================================================================
% Supporting functions
% =====================================================================

function [u_opt, cost, exitflag, output] = solve_mpc_optimization(...
    state, model, setpoint, u_prev, mv_config, tuning, soft_cons)

    u0 = u_prev;
    lb = [mv_config.Dryer_Temp_min; mv_config.Dryer_Airflow_min];
    ub = [mv_config.Dryer_Temp_max; mv_config.Dryer_Airflow_max];

    % Linear rate limits
    A = [1, 0; -1, 0; 0, 1; 0, -1];
    b = [u_prev(1) + mv_config.Dryer_Temp_rate_max;
         -u_prev(1) + mv_config.Dryer_Temp_rate_max;
         u_prev(2) + mv_config.Dryer_Airflow_rate_max;
         -u_prev(2) + mv_config.Dryer_Airflow_rate_max];

    costFcn = @(u) compute_mpc_cost(u, state, model, setpoint, ...
        u_prev, tuning, soft_cons);

    options = optimoptions('fmincon','Display','off','Algorithm','sqp', ...
        'MaxIterations',30,'OptimalityTolerance',1e-4);

    [u_opt, cost, exitflag, output] = fmincon(costFcn,u0,A,b,[],[],lb,ub,[],options);
end

function J = compute_mpc_cost(u, state, model, setpoint, u_prev, tuning, soft_cons)
    test_state = state;
    test_state.Dryer_Temp = u(1);
    test_state.Dryer_Airflow = u(2);

    input_vec = construct_mlp_input(test_state);
    y_pred = predict_moisture(model, input_vec);

    tracking_error = (y_pred - setpoint)^2;
    control_effort = sum((u - u_prev).^2);
    rate_change = sum((u - u_prev).^2);

    violation_penalty = 0;
    if soft_cons.enable
        if y_pred < soft_cons.moisture_min
            violation_penalty = soft_cons.violation_penalty * ...
                (soft_cons.moisture_min - y_pred)^2;
        elseif y_pred > soft_cons.moisture_max
            violation_penalty = soft_cons.violation_penalty * ...
                (y_pred - soft_cons.moisture_max)^2;
        end
    end

    J = tuning.w_tracking * tracking_error + ...
        tuning.w_control_effort * control_effort + ...
        tuning.w_rate_change * rate_change + ...
        violation_penalty;
end

function input_vec = construct_mlp_input(state)
    input_vec = [
        state.Dryer_Temp;
        state.Dryer_Airflow;
        state.Mass_rate;
        state.LS_ratio;
        state.Screw_rotation;
        state.Dryer_Temp;
        state.Extruder_Temp;
        state.Extruder_Temp;
        state.Extruder_Temp;
        state.Extruder_Temp;
        state.Mill_type;
        state.Mill_sieve
    ];
end

function y = predict_moisture(model, input_vec)
    % Adjust this index if your ensemble model differs
    y = sim(model{44,1}, input_vec);
end
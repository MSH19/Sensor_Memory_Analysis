% ============================================================
% F02_STABLE_STATE_ANALYSIS
%
% Calculate stable-state reference responses for Oil and Water.
%
% Stable recordings:
%   Oil:   Runs 20 and 30
%   Water: Runs 21 and 45
%
% A sample is retained when:
%   1. Its mean response changes by no more than 0.05 percentage
%      points from the preceding sample.
%   2. Oil response is <= 5%, or Water response is >= 70%.
%
% Output:
%   results/stable_reference_summary.csv
%
% Stable reference samples are selected only for estimating
% representative Oil and Water response levels used in the
% sensor-memory analysis.
%
% ============================================================

clear;
clc;

input_file = 'data/dataset.csv';
run_file   = 'results/label_run_annotation.csv';
output_file = 'results/stable_reference_summary.csv';

max_change = 0.05;
oil_limit = 5;
water_limit = 70;


%% Load the data

data = readmatrix(input_file);
signal = data(:,1:10);

mean_response = mean(signal,2);

runs = readtable(run_file,'TextType','string');


%% Select stable samples

stable_runs = [20 21 30 45];

selected_run = [];
selected_state = strings(0,1);
selected_response = [];

for r = stable_runs

    % Mean responses belonging to this run
    idx = runs.start_sample(r):runs.end_sample(r);
    response = mean_response(idx);

    % Change from the preceding recorded sample
    change = [NaN; abs(diff(response))];

    % Apply the state-specific response limit
    if runs.state(r) == "Oil"
        keep = change <= max_change & response <= oil_limit;
    else
        keep = change <= max_change & response >= water_limit;
    end

    selected_run = [selected_run; repmat(r,sum(keep),1)];
    selected_state = [selected_state; repmat(runs.state(r),sum(keep),1)];
    selected_response = [selected_response; response(keep)];

end


%% Summarise each stable recording

summary = table;

for r = stable_runs

    response = selected_response(selected_run == r);

    new_row = table( ...
        "Run", ...
        runs.state(r), ...
        string(r), ...
        runs.n_samples(r), ...
        length(response), ...
        mean(response), ...
        std(response), ...
        'VariableNames', ...
        {'level','state','runs','n_total','n_retained', ...
         'response_mean','response_std'});

    summary = [summary; new_row];

end


%% Calculate the pooled Oil and Water references

states = ["Oil" "Water"];

for s = states

    response = selected_response(selected_state == s);

    state_runs = stable_runs(runs.state(stable_runs) == s);

    new_row = table( ...
        "State", ...
        s, ...
        strjoin(string(state_runs),','), ...
        sum(runs.n_samples(state_runs)), ...
        length(response), ...
        mean(response), ...
        std(response), ...
        'VariableNames', ...
        {'level','state','runs','n_total','n_retained', ...
         'response_mean','response_std'});

    summary = [summary; new_row];

end


%% Save and display the results

writetable(summary,output_file);

fprintf('\nSTABLE-STATE REFERENCES\n');
fprintf('-----------------------\n');

disp(summary);

oil = summary(summary.level == "State" & summary.state == "Oil",:);
water = summary(summary.level == "State" & summary.state == "Water",:);

fprintf('Oil:   %.4f +/- %.4f %% (N = %d)\n', ...
    oil.response_mean,oil.response_std,oil.n_retained);

fprintf('Water: %.4f +/- %.4f %% (N = %d)\n', ...
    water.response_mean,water.response_std,water.n_retained);

fprintf('\nDone.\n');
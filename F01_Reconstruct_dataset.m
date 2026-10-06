% ============================================================
% F01_RECONSTRUCT_DATASET
%
% Reconstruct the sequential structure of the published dataset.
%
% Consecutive samples with the same physical-state label are
% grouped into label runs. Boundaries between runs represent
% recorded state changes.
%
% Labels:
%   -1 = Oil
%   +1 = Water
%
% Runs 20, 21, 30, and 45 are prolonged stable-state recordings.
% ============================================================

clear;
clc;
close all;

input_file = 'data/dataset.csv';
output_dir = 'results';

if ~exist(output_dir,'dir')
    mkdir(output_dir);
end


%% Load the dataset

data = readmatrix(input_file);

signal = data(:,1:10);
label = data(:,11);

n_samples = size(data,1);
mean_response = mean(signal,2);


%% Reconstruct the label runs

run_start = [1; find(diff(label) ~= 0) + 1];
run_end = [run_start(2:end)-1; n_samples];

n_runs = length(run_start);

run_id = (1:n_runs)';
n_in_run = run_end - run_start + 1;

state = strings(n_runs,1);

for r = 1:n_runs

    if label(run_start(r)) == -1
        state(r) = "Oil";
    else
        state(r) = "Water";
    end

end


%% Identify the recording type

recording_type = repmat("Transition",n_runs,1);

stable_runs = [20 21 30 45];
recording_type(stable_runs) = "Stable";

run_table = table( ...
    run_id, state, run_start, run_end, n_in_run, recording_type, ...
    'VariableNames', ...
    {'run_id','state','start_sample','end_sample', ...
     'n_samples','recording_type'});

writetable(run_table, ...
    fullfile(output_dir,'label_run_annotation.csv'));


%% Reconstruct the recorded state changes

n_transitions = n_runs - 1;

transition_id = (1:n_transitions)';
source_run = (1:n_transitions)';
destination_run = (2:n_runs)';

source_state = state(source_run);
destination_state = state(destination_run);

direction = source_state + " -> " + destination_state;

source_recording_type = recording_type(source_run);
destination_recording_type = recording_type(destination_run);

transition_table = table( ...
    transition_id, source_run, destination_run, ...
    source_state, destination_state, direction, ...
    source_recording_type, destination_recording_type);

writetable(transition_table, ...
    fullfile(output_dir,'transition_annotation.csv'));


%% Plot the label runs

figure('Color','w','Position',[100 100 1500 1800]);

tiledlayout(9,5, ...
    'TileSpacing','compact', ...
    'Padding','compact');

for r = 1:n_runs

    nexttile;

    idx = run_start(r):run_end(r);

    plot(1:length(idx),mean_response(idx),'LineWidth',1.2);
    grid on;

    title(sprintf('Run %d - %s - %s (N=%d)', ...
        r,state(r),recording_type(r),length(idx)));

    xlabel('Sample within run');
    ylabel('Mean response (%)');

end

sgtitle('Mean Sensor Response Within the 45 Label Runs');

exportgraphics(gcf, ...
    fullfile(output_dir,'label_runs_mean_response.pdf'), ...
    'ContentType','vector');


%% Display the main results

fprintf('\nDATASET RECONSTRUCTION\n');
fprintf('----------------------\n');

fprintf('Total samples:          %d\n',n_samples);
fprintf('Label runs:             %d\n',n_runs);
fprintf('Recorded state changes: %d\n',n_transitions);

fprintf('Oil -> Water:           %d\n', ...
    sum(direction == "Oil -> Water"));

fprintf('Water -> Oil:           %d\n', ...
    sum(direction == "Water -> Oil"));

fprintf('Stable recordings:      %d\n', ...
    sum(recording_type == "Stable"));

fprintf('\nDone.\n');
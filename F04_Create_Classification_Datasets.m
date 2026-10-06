%% F04_CREATE_CLASSIFICATION_DATASETS
% Create the datasets used for classification analysis.
%
% Samples are assigned as Stable or Transition using the label-run
% reconstruction from F01. No samples are removed based on sensor response.
%
% F1 = mean response over the 1-s window
% F2 = temporal response change (last value - first value)

clear; clc; close all;

%% Paths
data_file = 'data/dataset.csv';
run_file  = 'results/label_run_annotation.csv';

output_full    = 'results/classification_dataset.csv';
output_unique  = 'results/classification_unique_dataset.csv';
summary_full   = 'results/classification_dataset_summary.csv';
summary_unique = 'results/classification_unique_summary.csv';

%% Load data
data = readmatrix(data_file);
runs = readtable(run_file);

signals = data(:,1:10);
labels  = data(:,11);

n_samples = size(data,1);

%% Features
F1 = mean(signals,2);
F2 = signals(:,end) - signals(:,1);

%% Add run information to each sample
run_id = zeros(n_samples,1);
recording_type = strings(n_samples,1);

for r = 1:height(runs)

    idx = runs.start_sample(r):runs.end_sample(r);

    run_id(idx) = runs.run_id(r);
    recording_type(idx) = string(runs.recording_type(r));

end

%% Physical state
state = strings(n_samples,1);
state(labels == -1) = "Oil";
state(labels ==  1) = "Water";

%% Classification groups
classification_group = recording_type + " " + state;

%% Full classification dataset
sample_id = (1:n_samples)';

classification_dataset = table( ...
    sample_id, run_id, state, recording_type, classification_group, ...
    F1, F2, ...
    'VariableNames', { ...
    'sample_id','run_id','state','recording_type', ...
    'classification_group','F1_mean_response','F2_temporal_change'});

writetable(classification_dataset, output_full);

%% Full dataset summary
groups = ["Stable Oil"; ...
          "Transition Oil"; ...
          "Stable Water"; ...
          "Transition Water"];

counts = zeros(4,1);

for i = 1:4
    counts(i) = sum(classification_group == groups(i));
end

full_summary = table(groups, counts, ...
    'VariableNames', {'classification_group','n_samples'});

writetable(full_summary, summary_full);

%% Unique-signal dataset
% Exact duplicate 10-value signals are represented once.
[~, unique_idx] = unique(signals, 'rows', 'stable');

classification_unique = classification_dataset(unique_idx,:);

writetable(classification_unique, output_unique);

%% Unique dataset summary
unique_groups = classification_unique.classification_group;
unique_counts = zeros(4,1);

for i = 1:4
    unique_counts(i) = sum(unique_groups == groups(i));
end

unique_summary = table(groups, unique_counts, ...
    'VariableNames', {'classification_group','n_samples'});

writetable(unique_summary, summary_unique);

%% Check duplicate signals across states and categories
[unique_signals, ~, signal_group] = unique(signals, 'rows', 'stable');

cross_state = 0;
cross_category = 0;

for i = 1:size(unique_signals,1)

    idx = signal_group == i;

    if numel(unique(state(idx))) > 1
        cross_state = cross_state + 1;
    end

    if numel(unique(classification_group(idx))) > 1
        cross_category = cross_category + 1;
    end

end

%% Display summary
fprintf('\nCLASSIFICATION DATASET\n');
fprintf('----------------------\n');

fprintf('Total samples:        %d\n\n', n_samples);

for i = 1:4
    fprintf('%-20s %d\n', groups(i) + ":", counts(i));
end

fprintf('\nUnique signals:       %d\n', height(classification_unique));
fprintf('Repeated samples:     %d\n', n_samples - height(classification_unique));
fprintf('Cross-state signals:  %d\n', cross_state);
fprintf('Cross-category signals: %d\n\n', cross_category);

fprintf('Done.\n');
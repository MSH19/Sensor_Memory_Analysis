%% F05_CLASSIFICATION_ANALYSIS
% Evaluate Oil/Water classification using the reconstructed label runs.
%
% Complete label runs are held out from training to prevent samples from
% the same run appearing in both training and test sets.
%
% F1 = mean response over the 1-s window
% F2 = temporal response change (last value - first value)

clear; clc; close all;

%% Paths
data_file   = 'results/classification_dataset.csv';
unique_file = 'results/classification_unique_dataset.csv';

output_results = 'results/classification_results.csv';
output_summary = 'results/classification_summary.csv';
output_unique  = 'results/classification_unique_sensitivity.csv';

%% Load dataset
data = readtable(data_file);

F1 = data.F1_mean_response;
F2 = data.F2_temporal_change;

run_id = data.run_id;
state = string(data.state);
category = string(data.classification_group);

% Oil = -1, Water = +1
labels = -ones(height(data),1);
labels(state == "Water") = 1;

runs = unique(run_id);

%% Methods
methods = ["Threshold F1"; ...
           "SVM F1"; ...
           "SVM F2"; ...
           "SVM F1+F2"; ...
           "Tree F1+F2"];

n_methods = numel(methods);
prediction = nan(height(data), n_methods);

%% Leave-one-label-run-out validation
for r = 1:numel(runs)

    test_idx  = run_id == runs(r);
    train_idx = ~test_idx;

    y_train = labels(train_idx);

    % Fixed 40% response threshold
    prediction(test_idx,1) = -1;
    prediction(test_idx & F1 >= 40,1) = 1;

    % Linear SVM using F1
    model = fitcsvm(F1(train_idx), y_train, ...
        'KernelFunction','linear', ...
        'BoxConstraint',1, ...
        'Standardize',true);

    prediction(test_idx,2) = predict(model, F1(test_idx));

    % Linear SVM using F2
    model = fitcsvm(F2(train_idx), y_train, ...
        'KernelFunction','linear', ...
        'BoxConstraint',1, ...
        'Standardize',true);

    prediction(test_idx,3) = predict(model, F2(test_idx));

    % Linear SVM using F1 and F2
    X_train = [F1(train_idx), F2(train_idx)];
    X_test  = [F1(test_idx),  F2(test_idx)];

    model = fitcsvm(X_train, y_train, ...
        'KernelFunction','linear', ...
        'BoxConstraint',1, ...
        'Standardize',true);

    prediction(test_idx,4) = predict(model, X_test);

    % Decision tree using F1 and F2
    model = fitctree(X_train, y_train);

    prediction(test_idx,5) = predict(model, X_test);

end

%% Classification accuracy
categories = ["Stable Oil"; ...
              "Transition Oil"; ...
              "Stable Water"; ...
              "Transition Water"];

accuracy = zeros(n_methods,4);

for m = 1:n_methods

    for c = 1:4

        idx = category == categories(c);

        accuracy(m,c) = ...
            100 * mean(prediction(idx,m) == labels(idx));

    end

end

mean_category_accuracy = mean(accuracy,2);

overall_accuracy = zeros(n_methods,1);

for m = 1:n_methods
    overall_accuracy(m) = ...
        100 * mean(prediction(:,m) == labels);
end

%% Save summary
summary_table = table( ...
    methods, ...
    accuracy(:,1), ...
    accuracy(:,2), ...
    accuracy(:,3), ...
    accuracy(:,4), ...
    mean_category_accuracy, ...
    overall_accuracy, ...
    'VariableNames', { ...
    'method', ...
    'stable_oil_accuracy', ...
    'transition_oil_accuracy', ...
    'stable_water_accuracy', ...
    'transition_water_accuracy', ...
    'mean_category_accuracy', ...
    'overall_accuracy'});

writetable(summary_table, output_summary);

%% Save sample-level results
results = data(:, ...
    {'sample_id','run_id','state','recording_type', ...
     'classification_group','F1_mean_response','F2_temporal_change'});

for m = 1:n_methods
    variable_name = matlab.lang.makeValidName(methods(m));
    results.(variable_name) = prediction(:,m);
end

writetable(results, output_results);

%% Display results
fprintf('\nCLASSIFICATION ANALYSIS\n');
fprintf('-----------------------\n');
fprintf('Validation: leave-one-label-run-out\n\n');

fprintf('%-18s %10s %10s %10s %10s %10s\n', ...
    'Method','St. Oil','Tr. Oil','St. Water','Tr. Water','Mean');

for m = 1:n_methods

    fprintf('%-18s %9.2f%% %9.2f%% %9.2f%% %9.2f%% %9.2f%%\n', ...
        methods(m), ...
        accuracy(m,1), ...
        accuracy(m,2), ...
        accuracy(m,3), ...
        accuracy(m,4), ...
        mean_category_accuracy(m));

end

fprintf('\nOverall accuracy:\n');

for m = 1:n_methods
    fprintf('%-18s %.2f%%\n', methods(m), overall_accuracy(m));
end

%% Unique-signal sensitivity analysis
% Repeat the F1+F2 linear SVM after exact duplicate signals are removed.

unique_data = readtable(unique_file);

F1_unique = unique_data.F1_mean_response;
F2_unique = unique_data.F2_temporal_change;

run_unique = unique_data.run_id;
state_unique = string(unique_data.state);
category_unique = string(unique_data.classification_group);

labels_unique = -ones(height(unique_data),1);
labels_unique(state_unique == "Water") = 1;

runs_unique = unique(run_unique);
prediction_unique = nan(height(unique_data),1);

for r = 1:numel(runs_unique)

    test_idx  = run_unique == runs_unique(r);
    train_idx = ~test_idx;

    X_train = [F1_unique(train_idx), F2_unique(train_idx)];
    X_test  = [F1_unique(test_idx),  F2_unique(test_idx)];

    model = fitcsvm(X_train, labels_unique(train_idx), ...
        'KernelFunction','linear', ...
        'BoxConstraint',1, ...
        'Standardize',true);

    prediction_unique(test_idx) = predict(model, X_test);

end

%% Unique-signal accuracy
unique_accuracy = zeros(4,1);

for c = 1:4

    idx = category_unique == categories(c);

    unique_accuracy(c) = ...
        100 * mean(prediction_unique(idx) == labels_unique(idx));

end

unique_mean_category_accuracy = mean(unique_accuracy);

unique_overall_accuracy = ...
    100 * mean(prediction_unique == labels_unique);

%% Save sensitivity summary
unique_summary = table( ...
    unique_accuracy(1), ...
    unique_accuracy(2), ...
    unique_accuracy(3), ...
    unique_accuracy(4), ...
    unique_mean_category_accuracy, ...
    unique_overall_accuracy, ...
    'VariableNames', { ...
    'stable_oil_accuracy', ...
    'transition_oil_accuracy', ...
    'stable_water_accuracy', ...
    'transition_water_accuracy', ...
    'mean_category_accuracy', ...
    'overall_accuracy'});

writetable(unique_summary, output_unique);

%% Display sensitivity results
fprintf('\nUNIQUE-SIGNAL SENSITIVITY\n');
fprintf('-------------------------\n');
fprintf('Unique signals: %d\n\n', height(unique_data));

for c = 1:4
    fprintf('%-20s %.2f%%\n', ...
        categories(c) + ":", unique_accuracy(c));
end

fprintf('\nMean category accuracy: %.2f%%\n', ...
    unique_mean_category_accuracy);

fprintf('Overall accuracy:       %.2f%%\n', ...
    unique_overall_accuracy);

fprintf('\nDone.\n');
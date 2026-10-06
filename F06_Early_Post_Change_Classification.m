%% F06_EARLY_POST_CHANGE_CLASSIFICATION
% Evaluate Oil/Water classification immediately after recorded state changes.
%
% The first five recorded 1-s windows of each destination label run are
% evaluated using:
%   1. Fixed 40% response threshold
%   2. Linear SVM using F1 + F2
%
% The complete destination label run is excluded from SVM training.

clear; clc; close all;

%% Paths
run_file = 'results/label_run_annotation.csv';
transition_file = 'results/transition_annotation.csv';
classification_file = 'results/classification_dataset.csv';

output_csv = 'results/early_classification_accuracy.csv';
output_pdf = 'results/early_classification.pdf';

%% Load data
runs = readtable(run_file);
transitions = readtable(transition_file);
data = readtable(classification_file);

threshold = 40;
n_windows = 5;

%% Retain transitions with at least five destination samples
run_length = zeros(height(transitions),1);

for j = 1:height(transitions)

    r = runs.run_id == transitions.destination_run(j);
    run_length(j) = runs.n_samples(r);

end

transitions = transitions(run_length >= n_windows,:);

direction = string(transitions.direction);

n_OW = sum(direction == "Oil -> Water");
n_WO = sum(direction == "Water -> Oil");

fprintf('\nEARLY POST-CHANGE CLASSIFICATION\n');
fprintf('--------------------------------\n');
fprintf('Windows analysed:       %d\n',n_windows);
fprintf('Oil -> Water:           %d transitions\n',n_OW);
fprintf('Water -> Oil:           %d transitions\n',n_WO);

%% Evaluate each transition
threshold_correct = nan(height(transitions),n_windows);
svm_correct = nan(height(transitions),n_windows);

for j = 1:height(transitions)

    dest_run = transitions.destination_run(j);

    % Exclude the complete destination run from training
    train_idx = data.run_id ~= dest_run;

    X_train = [ ...
        data.F1_mean_response(train_idx), ...
        data.F2_temporal_change(train_idx)];

    state_train = string(data.state(train_idx));

    y_train = -ones(sum(train_idx),1);
    y_train(state_train == "Water") = 1;

    model = fitcsvm(X_train,y_train, ...
        'KernelFunction','linear', ...
        'BoxConstraint',1, ...
        'Standardize',true);

    % First samples of the destination run
    r = runs.run_id == dest_run;
    first_sample = runs.start_sample(r);

    for k = 1:n_windows

        sample_id = first_sample + k - 1;

        F1 = data.F1_mean_response(sample_id);
        F2 = data.F2_temporal_change(sample_id);

        true_label = -1;
        if string(data.state(sample_id)) == "Water"
            true_label = 1;
        end

        % Fixed threshold
        threshold_pred = -1;

        if F1 >= threshold
            threshold_pred = 1;
        end

        % Linear SVM
        svm_pred = predict(model,[F1 F2]);

        threshold_correct(j,k) = ...
            threshold_pred == true_label;

        svm_correct(j,k) = ...
            svm_pred == true_label;

    end

end

%% Accuracy by transition direction
window = (1:n_windows)';

threshold_OW = zeros(n_windows,1);
svm_OW = zeros(n_windows,1);

threshold_WO = zeros(n_windows,1);
svm_WO = zeros(n_windows,1);

for k = 1:n_windows

    idx = direction == "Oil -> Water";

    threshold_OW(k) = ...
        100 * mean(threshold_correct(idx,k));

    svm_OW(k) = ...
        100 * mean(svm_correct(idx,k));

    idx = direction == "Water -> Oil";

    threshold_WO(k) = ...
        100 * mean(threshold_correct(idx,k));

    svm_WO(k) = ...
        100 * mean(svm_correct(idx,k));

end

%% Save results
results = table( ...
    window, ...
    repmat(n_OW,n_windows,1), ...
    threshold_OW, ...
    svm_OW, ...
    repmat(n_WO,n_windows,1), ...
    threshold_WO, ...
    svm_WO, ...
    'VariableNames',{ ...
    'post_change_window', ...
    'n_oil_to_water', ...
    'threshold_oil_to_water', ...
    'svm_oil_to_water', ...
    'n_water_to_oil', ...
    'threshold_water_to_oil', ...
    'svm_water_to_oil'});

writetable(results,output_csv);

%% Plot
fig = figure( ...
    'Color','w', ...
    'Position',[100 100 700 450]);

hold on;

plot(window,threshold_OW,'-o', ...
    'LineWidth',1.5, ...
    'DisplayName','Threshold: Oil \rightarrow Water');

plot(window,svm_OW,'-s', ...
    'LineWidth',1.5, ...
    'DisplayName','SVM: Oil \rightarrow Water');

plot(window,threshold_WO,'--o', ...
    'LineWidth',1.5, ...
    'DisplayName','Threshold: Water \rightarrow Oil');

plot(window,svm_WO,'--s', ...
    'LineWidth',1.5, ...
    'DisplayName','SVM: Water \rightarrow Oil');

xlabel('Recorded post-change window');
ylabel('Classification accuracy (%)');

xlim([1 n_windows]);
ylim([0 105]);
xticks(1:n_windows);

grid on;
box on;

legend('Location','best');

set(gca, ...
    'FontSize',11, ...
    'LineWidth',1);

exportgraphics( ...
    fig,output_pdf, ...
    'ContentType','vector');

%% Display results
fprintf('\nWindow   O->W Threshold   O->W SVM   W->O Threshold   W->O SVM\n');
fprintf('---------------------------------------------------------------\n');

for k = 1:n_windows

    fprintf('%3d %14.2f%% %10.2f%% %14.2f%% %10.2f%%\n', ...
        k, ...
        threshold_OW(k), ...
        svm_OW(k), ...
        threshold_WO(k), ...
        svm_WO(k));

end

fprintf('\nDone.\n');
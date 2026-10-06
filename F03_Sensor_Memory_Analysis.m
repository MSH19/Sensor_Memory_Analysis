% ============================================================
% F03_SENSOR_MEMORY_ANALYSIS
%
% Analyse sensor response following recorded state changes.
%
% The analysis:
%   1. Uses state changes entering Transition recordings.
%   2. Selects the longest post-change interval available for
%      at least 80% of transitions in both directions.
%   3. Calculates the mean response in each direction.
%   4. Calculates remaining memory relative to the stable-state
%      reference of the destination state.
%
% Remaining memory:
%   M(k) = 100 * E(k) / E(1)
%
% where E(k) is the difference between the mean response and
% the destination-state reference.
% ============================================================

clear;
clc;
close all;

min_fraction = 0.80;


%% Load the data

data = readmatrix('data/dataset.csv');
mean_response = mean(data(:,1:10),2);

runs = readtable( ...
    'results/label_run_annotation.csv', ...
    'TextType','string');

transitions = readtable( ...
    'results/transition_annotation.csv', ...
    'TextType','string');

references = readtable( ...
    'results/stable_reference_summary.csv', ...
    'TextType','string');


%% Select transitions for memory analysis

% Prolonged Stable recordings are not treated as post-change
% trajectories.
transitions = transitions( ...
    transitions.destination_recording_type == "Transition",:);

is_OW = transitions.direction == "Oil -> Water";
is_WO = transitions.direction == "Water -> Oil";

% Number of recorded samples following each state change.
run_length = runs.n_samples(transitions.destination_run);


%% Determine the analysis interval

max_length = max(run_length);

for k = 1:max_length

    fraction_OW = ...
        sum(is_OW & run_length >= k) / sum(is_OW);

    fraction_WO = ...
        sum(is_WO & run_length >= k) / sum(is_WO);

    if fraction_OW >= min_fraction && fraction_WO >= min_fraction
        analysis_length = k;
    end

end

% Retain transitions covering the complete selected interval.
transitions = transitions(run_length >= analysis_length,:);
run_length = runs.n_samples(transitions.destination_run);

is_OW = transitions.direction == "Oil -> Water";
is_WO = transitions.direction == "Water -> Oil";


%% Extract the post-change trajectories

response = zeros(height(transitions),analysis_length);

for t = 1:height(transitions)

    r = transitions.destination_run(t);

    first_sample = runs.start_sample(r);
    idx = first_sample:first_sample + analysis_length - 1;

    response(t,:) = mean_response(idx);

end


%% Calculate the mean response trajectories

window = (1:analysis_length)';

OW = response(is_OW,:);
WO = response(is_WO,:);

mean_OW = mean(OW,1)';
std_OW = std(OW,0,1)';

mean_WO = mean(WO,1)';
std_WO = std(WO,0,1)';


%% Load the stable-state references

oil_reference = references.response_mean( ...
    references.level == "State" & references.state == "Oil");

water_reference = references.response_mean( ...
    references.level == "State" & references.state == "Water");


%% Calculate remaining sensor memory

error_OW = abs(mean_OW - water_reference);
error_WO = abs(mean_WO - oil_reference);

memory_OW = 100 * error_OW / error_OW(1);
memory_WO = 100 * error_WO / error_WO(1);


%% Save the numerical results

summary = table( ...
    window, ...
    mean_OW, std_OW, memory_OW, ...
    mean_WO, std_WO, memory_WO, ...
    'VariableNames', ...
    {'window', ...
     'response_mean_OW','response_std_OW','memory_OW', ...
     'response_mean_WO','response_std_WO','memory_WO'});

writetable(summary, ...
    'results/sensor_memory_summary.csv');


%% Plot the results

figure('Color','w','Position',[100 100 1500 430]);

tiledlayout(1,3, ...
    'TileSpacing','compact', ...
    'Padding','compact');


% Oil -> Water

nexttile;
hold on;

for t = 1:size(OW,1)
    plot(window,OW(t,:), ...
        'Color',[0.75 0.85 1.00], ...
        'LineWidth',0.8);
end

upper = mean_OW + std_OW;
lower = mean_OW - std_OW;

fill([window; flipud(window)], ...
     [lower; flipud(upper)], ...
     [0.20 0.45 0.90], ...
     'FaceAlpha',0.16, ...
     'EdgeColor','none');

plot(window,mean_OW, ...
    'Color',[0.05 0.25 0.75], ...
    'LineWidth',2.4);

xlabel('Recorded post-change window');
ylabel('Sensor response (%)');
title('(a) Oil \rightarrow Water');

xlim([1 analysis_length]);
grid on;
box on;


% Water -> Oil

nexttile;
hold on;

for t = 1:size(WO,1)
    plot(window,WO(t,:), ...
        'Color',[1.00 0.82 0.72], ...
        'LineWidth',0.8);
end

upper = mean_WO + std_WO;
lower = mean_WO - std_WO;

fill([window; flipud(window)], ...
     [lower; flipud(upper)], ...
     [0.90 0.30 0.12], ...
     'FaceAlpha',0.16, ...
     'EdgeColor','none');

plot(window,mean_WO, ...
    'Color',[0.75 0.15 0.05], ...
    'LineWidth',2.4);

xlabel('Recorded post-change window');
ylabel('Sensor response (%)');
title('(b) Water \rightarrow Oil');

xlim([1 analysis_length]);
grid on;
box on;


% Remaining memory

nexttile;
hold on;

plot(window,memory_OW, ...
    'Color',[0.05 0.25 0.75], ...
    'LineWidth',2.5);

plot(window,memory_WO, ...
    'Color',[0.75 0.15 0.05], ...
    'LineWidth',2.5);

yline(50,':', ...
    '50% remaining memory', ...
    'Color',[0.35 0.35 0.35], ...
    'LineWidth',1.1);

xlabel('Recorded post-change window');
ylabel('Normalised remaining memory (%)');
title('(c) Sensor-memory persistence');

xlim([1 analysis_length]);
ylim([0 110]);

legend('Oil \rightarrow Water', ...
       'Water \rightarrow Oil', ...
       'Location','best');

grid on;
box on;


%% Save the figure

exportgraphics(gcf, ...
    'results/sensor_memory_analysis.pdf', ...
    'ContentType','vector');


%% Display the main results

fprintf('\nSENSOR-MEMORY ANALYSIS\n');
fprintf('----------------------\n');

fprintf('Selected interval:     %d windows\n',analysis_length);
fprintf('Oil -> Water:          %d transitions\n',sum(is_OW));
fprintf('Water -> Oil:          %d transitions\n',sum(is_WO));

fprintf('\nStable references:\n');
fprintf('Oil:                   %.3f %%\n',oil_reference);
fprintf('Water:                 %.3f %%\n',water_reference);

fprintf('\nAt window %d:\n',analysis_length);

fprintf('Oil -> Water response: %.2f +/- %.2f %%\n', ...
    mean_OW(end),std_OW(end));

fprintf('Oil -> Water memory:   %.2f %%\n',memory_OW(end));

fprintf('Water -> Oil response: %.2f +/- %.2f %%\n', ...
    mean_WO(end),std_WO(end));

fprintf('Water -> Oil memory:   %.2f %%\n',memory_WO(end));

fprintf('\nDone.\n');
# Sensor Memory Analysis

This repository contains derived datasets and MATLAB analysis code for studying sensor memory and early-state classification using a publicly available capacitive sensing dataset.

## Original dataset

The experimental measurements used in this work were previously published and released through IEEE DataPort:

Mahdi Saleh, Imad H. Elhajj, and Daniel Asmar,  
"Dataset for binary classification of digital sensor signals,"  
IEEE DataPort, 2020.  
DOI: 10.21227/6a44-0880

The dataset contains 4,475 one-second samples. Each sample consists of 10 consecutive intensity measurements and a physical-state label:

- `+1`: Water
- `-1`: Oil

The original dataset is not reproduced in this repository. It can be obtained directly from IEEE DataPort and placed at:

`data/dataset.csv`

## Dataset reconstruction

The sequential structure of the published dataset was reconstructed from the physical-state labels.

Consecutive samples with the same label were grouped into 45 label runs, producing 44 recorded state changes: 22 Oil → Water and 22 Water → Oil.

The label runs were categorised as:

- **Transition recordings:** alternating Oil/Water recordings used to study response following recorded state changes.
- **Stable recordings:** prolonged recordings in a single physical state used to estimate stable-state reference responses.

Four prolonged stable-state recordings were identified: Runs 20, 21, 30, and 45.

![Reconstructed label runs](results/label_runs_mean_response.png)

## Analysis

The analysis investigates:

- stable-state sensor response;
- sensor-memory persistence following recorded state changes;
- directional differences between Oil → Water and Water → Oil;
- classification using response magnitude and within-window temporal information;
- classification immediately following recorded state changes.

Each 1-s sample contains 10 measurements. Two simple features are used for classification:

- **F1:** mean response over the 1-s window;
- **F2:** temporal response change, calculated as the last value minus the first value.

## Scripts

The scripts should be run in the following order.

### F01 — Reconstruct dataset

`F01_Reconstruct_dataset.m`

Reconstructs the 45 label runs and 44 recorded state changes and identifies the prolonged stable-state recordings.

### F02 — Stable-state analysis

`F02_Stable_State_Analysis.m`

Estimates representative Oil and Water stable-state responses from the prolonged stable recordings. These references are used in the sensor-memory analysis.

### F03 — Sensor-memory analysis

`F03_Sensor_Memory_Analysis.m`

Analyses post-change response trajectories and compares Oil → Water and Water → Oil memory persistence. The analysis interval is selected according to transition availability in both directions.

### F04 — Create classification datasets

`F04_Create_Classification_Datasets.m`

Creates the classification datasets and calculates F1 and F2 for every sample. No samples are removed based on sensor response.

A second dataset containing one instance of each unique 10-value signal is generated for sensitivity analysis.

### F05 — Classification analysis

`F05_CLASSIFICATION_ANALYSIS.m`

Evaluates:

- fixed 40% response threshold;
- linear SVM using F1;
- linear SVM using F2;
- linear SVM using F1 + F2;
- decision tree using F1 + F2.

Classification is evaluated using leave-one-label-run-out validation so that samples from the test run are not included in classifier training.

The F1 + F2 SVM is also evaluated using the unique-signal dataset as a sensitivity analysis.

### F06 — Early post-change classification

`F06_Early_Post_Change_Classification.m`

Evaluates classification during the first five recorded 1-s windows following each recorded state change.

For each transition, the complete destination label run is excluded from SVM training. Performance is compared with the fixed 40% response threshold separately for Oil → Water and Water → Oil transitions.

## Results

Generated annotations, numerical results, and figures are stored in:

`results/`

These include:

- reconstructed label-run and state-change annotations;
- stable-state reference responses;
- sensor-memory analysis results;
- classification datasets and results;
- unique-signal sensitivity analysis;
- early post-change classification results.

## Citation

Citation details for the associated manuscript will be added following publication.
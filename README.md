# Sensor Memory Analysis

This repository contains derived datasets and analysis code for studying sensor memory and early-state classification using a publicly available capacitive sensing dataset.

## Original dataset

The experimental measurements used in this work were previously published and released through IEEE DataPort:

Mahdi Saleh, Imad H. Elhajj, and Daniel Asmar,  
"Dataset for binary classification of digital sensor signals,"  
IEEE DataPort, 2020.  
DOI: 10.21227/6a44-0880

The original dataset contains 4,475 one-second samples, each consisting of 10 consecutive intensity measurements and a physical-state label:

- `+1`: water
- `-1`: oil

The original dataset is not reproduced here. It can be obtained directly from IEEE DataPort.

## Derived data

The files in this repository are derived from the public dataset above and contain additional annotations and data products generated for the present sensor-memory analysis.

These include:

- temporal reconstruction into consecutive physical-state runs;
- recorded state-change annotations;
- sample provenance information;
- mean intensity and temporal response change features;
- low- and high-response-change categories;
- a balanced analysis dataset;
- transition and sensor-memory analysis outputs.

## Analysis

The accompanying scripts reproduce the main analyses used to study:

- sensor-memory persistence;
- oil-to-water and water-to-oil asymmetry;
- early-state classification;
- leave-one-run-out validation;
- classification performance as a function of time following a recorded state change.

## Citation

Citation details for the associated manuscript will be added following publication.

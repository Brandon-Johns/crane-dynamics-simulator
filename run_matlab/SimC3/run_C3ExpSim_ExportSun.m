%{
Written By: Brandon Johns
Date Version Created: 2022-02-25
Date Last Edited: 2022-02-25
Status: functional
Simulator: CDS

%%% PURPOSE %%%
Regarding the trials with a UR5 robot
    Import the experimental data into CDS
    Then generate sundials input files to run simulations that match the conditions of the experimental trials


%%% NOTES %%%
See run_C3ExpSim_ImportMultiple.m to process the results

Assumes
    All trials use same solution time vector
    All trials use same input (The parameter 'exMotion' from AddTrial)


%}

close all
clear all
clc
sympref('AbbreviateOutput',false);
sympref('MatrixWithSquareBrackets',true);
CDS_FindIncludes;
CDS_IncludeSimulator;
CDS_IncludeModels;
CDS_IncludeUtilities;

pathAppend = "expMulti";
dataPaths = CDS_GetDataLocations();
dataPath = dataPaths.exp_results;
sunGenPath = dataPaths.sun_generated(pathAppend);
sunResultsPath = dataPaths.sun_results;

%**********************************************************************
% User input
%***********************************
% Experiment trial
ImportMultiple = C3_ImportMultiple(dataPath, "", "");

%input = 2; % In this script, I assume that all have the same input

%ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P", "2P", "usePointMass");

% ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P", "1P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P", "2P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P", "3P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "3P", "1P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "3P", "2P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "3P", "3P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "FC", "1P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "FC", "2P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "FC", "3P");

% ImportMultiple.AddTrial("2021-11-29", "PH", input, "2P", "1P");
% ImportMultiple.AddTrial("2021-11-29", "PH", input, "2P", "2P");
% ImportMultiple.AddTrial("2021-11-29", "PH", input, "2P", "3P");
% ImportMultiple.AddTrial("2021-11-29", "PH", input, "3P", "1P");
% ImportMultiple.AddTrial("2021-11-29", "PH", input, "3P", "2P");
% ImportMultiple.AddTrial("2021-11-29", "PH", input, "3P", "3P");

%***********************************
% CraneDynamics Paper
% Fig: Sim VS Exp
input = 2;
ImportMultiple.AddTrial("2021-11-29", "PH", input, "3P", "3P");

% Fig: Compare models
% input = 1;
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P", "1P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P", "2P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P", "3P");

%**********************************************************************
% Run
%***********************************
ImportMultiple.ExportSun(sunGenPath);




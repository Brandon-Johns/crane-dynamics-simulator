%{
Written By: Brandon Johns
Date Version Created: 2022-02-01
Date Last Edited: 2022-03-14
Status: functional
Simulator: CDS

%%% PURPOSE %%%
Build a predefined model and import the previously solved simulation results, where the solver was sundials


%%% NOTES %%%
Instructions
    1) Use run_C3_ExportSun.m to export the model for solving with sundials
    2) Solve the exported model with with sundials
    3) Use this file to process the results

%}
close all
clear all
clc
sympref('AbbreviateOutput',false);
sympref('MatrixWithSquareBrackets',true);
CDS_FindIncludes;
CDS_IncludeSimulator;
CDS_IncludeModels;

dataPaths = CDS_GetDataLocations();

%**********************************************************************
% User input
%***********************************
inputPreset = 7;
modelPreset = "1P";
geometryPreset = 6;

pathAppend1 = "v1/SimC3-";
pathAppend2 = "Motion"+inputPreset + "_"+modelPreset + "_G"+geometryPreset + ".txt";

%**********************************************************************
% Load & Import data
%***********************************
% Import path
dataFileName = dataPaths.sun_results(pathAppend1+pathAppend2);
fprintf("%s\n", "Data filename = "+dataFileName+"\n");
if ~isfile(dataFileName); error("Results file not found"); end

% Value builder
VB = CDSvb_C3_Builder(geometryPreset, inputPreset);
V = VB.Values_Sim;

% Model builder
if     modelPreset=="1P"; MB = CDSm_C3_1p(V);
elseif modelPreset=="2P"; MB = CDSm_C3_2p(V);
elseif modelPreset=="3P"; MB = CDSm_C3_3p(V);
elseif modelPreset=="ZS"; MB = CDSm_C3_noSheave(V);
elseif modelPreset=="FC"; MB = CDSm_C3_sheave(V);
elseif modelPreset=="ZJ"; MB = CDSm_C3_noSheave2P(V);
elseif modelPreset=="FJ"; MB = CDSm_C3_sheave2P(V);
end

% Run in 2D where possible
MB.Flag_2D = V.Flag_2DPermitted;

%MB.Flag_pointI_truePosition = false; % Not implemented

% Build model and solve
MB.Build_SystemDescription;
SS = MB.ImportSolution_Sundials(dataFileName);
SSp = CDS_Solution_Plot(SS);
SSe = CDS_Solution_Export(SS);
SSa = CDS_Solution_Animate(SS);
SSg = CDS_Solution_GetData(SS);


%**********************************************************************
% Results
%***********************************
SSp.PlotConfigSpace
% SSp.PlotInput
SSp.PlotEnergyTotal
SSp.PlotEnergyAll
SSp.PlotTaskSpace

% SSe.DataToExcel

SSa.Set_View_Predefined("front")
SSa.PlotFrame
% SSa.Animate




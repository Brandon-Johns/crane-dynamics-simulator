%{
Written By: Brandon Johns
Date Version Created: 2021-12-14
Date Last Edited: 2022-03-14
Status: functional
Simulator: CDS

%%% PURPOSE %%%
Build a predefined model and export it for solving with sundials


%%% NOTES %%%
Instructions
    1) Use this file to export the model for solving with sundials
    2) Solve the exported model with with sundials
    3) Use run_C3_ImportSunResults.m to process the results

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

%**********************************************************************
% Auto input
%***********************************
% Cache path
pathAppend = "SimC3";
exportDirLeaf = "Motion"+inputPreset + "_"+modelPreset + "_G"+geometryPreset;

%**********************************************************************
% Run
%***********************************
% Export path
exportPath = dataPaths.sun_generated(pathAppend, exportDirLeaf);

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

% Build model and export
sys = MB.Build_SystemDescription;

SO = CDS_Solver_Options;
SO.exportPath = exportPath;
SO.time = [0, V.t_max];

S = CDS_Solver(SO);
S.Solve(sys, "sundials");
%S.Solve(sys, "ode45","export");


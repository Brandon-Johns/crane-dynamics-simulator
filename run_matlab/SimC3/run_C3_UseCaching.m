%{
Written By: Brandon Johns
Date Version Created: 2022-02-01
Date Last Edited: 2022-03-14
Status: functional
Simulator: CDS

%%% PURPOSE %%%
Build and simulate a predefined model


%%% NOTES %%%
This file is only for use with the MATLAB solvers
This file implements caching


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

% Force run the simulation & overwrite the cached results
Flag_refreshCached = 0;

%**********************************************************************
% Auto input
%***********************************
% Cache path
pathAppend = "SimC3";
fileName = "Motion"+inputPreset + "_"+modelPreset + "_G"+geometryPreset + ".xlsx";

%**********************************************************************
% Load & Import data
%***********************************
% Import path
dataFileName = dataPaths.cache(pathAppend, fileName);
fprintf("%s\n", "Data filename = "+dataFileName);

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
MB.Build_SystemDescription;

SO = CDS_Solver_Options();
% SO.EventsIsActive = 1;

% Solve or retrieve from cache
if exist(dataFileName, "file") && ~Flag_refreshCached
    fprintf("Simulator: Using Cached\n");
    SS = MB.ImportSolution_Saved(dataFileName);
else
    fprintf("Simulator: Solving\n");
    SS = MB.Solve();
    % Cache results
    fprintf("%s\n", "Caching: "+dataFileName);
    SSe = CDS_Solution_Export(SS);
    SSe.DataToExcel(dataFileName);
end

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

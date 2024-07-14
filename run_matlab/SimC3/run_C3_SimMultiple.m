%{
Written By: Brandon Johns
Date Version Created: 2022-03-14
Date Last Edited: 2022-03-14
Status: functional
Simulator: CDS

%%% PURPOSE %%%
Build and simulate multiple predefined models

Compare the results
Generate plots


%%% NOTES %%%


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

pathAppend = "SimC3";
dataPaths = CDS_GetDataLocations();
cachePath = dataPaths.cache(pathAppend);
figPath = dataPaths.fig(pathAppend);
sunGenPath = dataPaths.sun_generated(pathAppend);
sunResultsPath = dataPaths.sun_results;

%**********************************************************************
% User input
%***********************************
% Simulation trial
SimMultiple = C3_SimMultiple(cachePath, sunResultsPath);
SimMultiple.Flag_refreshCached = true;
SimMultiple.Flag_DoNotCache = true;

input = 7; % In this script, I assume that all have the same input
geometryValues = 6;

SimMultiple.AddTrial(input, "1P", geometryValues);
SimMultiple.AddTrial(input, "2P", geometryValues);
SimMultiple.AddTrial(input, "3P", geometryValues);

%**********************************************************************
% Run
%***********************************
S = SimMultiple.BuildSolution;
R = SimMultiple.ChangeCoordinates;
time = S(1).t;

if ~exist("legendStr","var"); legendStr = SimMultiple.LegendStr; end
figFileNameBase = SimMultiple.FigFileNameBase(figPath);

if ~exist("LagIdx","var"); LagIdx = zeros(size(legendStr)); end

Sp = CDS_Solution_Plot(S);
Se = CDS_Solution_Export(S);
Sa = CDS_Solution_Animate(S);
Sg = CDS_Solution_GetData(S);

%**********************************************************************
%% Results - Playground
%***********************************
%idx=1;

%Sp(idx).PlotInput
%Sp(idx).PlotTaskSpace

%Sa(idx).Set_View_Predefined("front")
%Sa(idx).PlotFrame(0)
%Sa(idx).Animate

%**********************************************************************
%% Results - Compare
%***********************************
P = CDSu_PlotMultiple;
StartZero = @(in) P.RemoveLag( P.OffsetDataToZero(in, 'xy'), LagIdx );
% StartZero = @(in) P.OffsetDataToZero(in, 'xyz');
% export="png";
export="";

% P.PlotXYZ_KM(time, R.K_relImesA2, R.M_relImesA2, legendStr,figFileNameBase+"_relI_measA2",export);
% P.PlotXYZ_KM(time, R.K, R.M, legendStr,figFileNameBase,export);

P.PlotXYZ_KM(time, StartZero(R.K_relImesA2), StartZero(R.M_relImesA2), legendStr,figFileNameBase+"_relI_measA2_zeroOffset",export);
P.PlotXYZ_KM(time, StartZero(R.K), StartZero(R.M), legendStr,figFileNameBase+"_zeroOffset",export);


% P.PlotXYZ(time, R.K_relImesA2{1}-R.K_relImesA2{2}, "Error: "+legendStr(1)+" VS "+legendStr(2));

%P.PlotXYZ(time, R.I_relImesA2, legendStr);
%P.PlotXYZ(time, R.I, legendStr);

% Plot XZ path
% P.PlotPath_OnPlane(R.I, "y")
% P.PlotPath_OnPlane(R.K, "y")
% P.PlotPath_OnPlane(R.M, "y")

% Plot XY path
% P.PlotPath_OnPlane(R.I, "z")
% P.PlotPath_OnPlane(R.K, "z")
% P.PlotPath_OnPlane(R.M, "z")





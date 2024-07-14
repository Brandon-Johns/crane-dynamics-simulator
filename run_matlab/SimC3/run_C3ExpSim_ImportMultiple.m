%{
Written By: Brandon Johns
Date Version Created: 2022-02-14
Date Last Edited: 2022-05-18
Status: functional
Simulator: CDS

%%% PURPOSE %%%
Regarding the trials with a UR5 robot
    Import the experimental data into CDS
    Run simulations that match the conditions of the experimental trials
    Import the sundials results, if these simulations needed to be run with sundials

Then compare the results

Generate plots
    (including some of the plots that were used in the research article)


%%% NOTES %%%
See run_C3ExpSim_ExportSun.m to generate sundials input files

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
cachePath = dataPaths.cache(pathAppend);
figPath = dataPaths.fig(pathAppend);
sunResultsPath = dataPaths.sun_results;

%**********************************************************************
% User input
%***********************************
% Experiment trial
ImportMultiple = C3_ImportMultiple(dataPath, cachePath, sunResultsPath);

%input = 2; % In this script, I assume that all have the same input

%ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P", "2P");
%ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P", "2P", "usePointMass");

% ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "3P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "FC");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P", "1P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P", "2P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P", "3P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "3P", "1P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "3P", "2P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "3P", "3P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "FC", "1P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "FC", "2P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "FC", "3P");

% ImportMultiple.AddTrial("2021-11-29", "PH", input, "2P");
% ImportMultiple.AddTrial("2021-11-29", "PH", input, "3P");
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
ImportMultiple.AddTrial("2021-11-29", "PH", input, "3P");
ImportMultiple.AddTrial("2021-11-29", "PH", input, "3P", "3P");
LagIdx = [0, 0]; % ~no lag yay
legendStr = ["experiment","simulation"];

% Fig: Compare models
% input = 1;
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "3P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "FC");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P", "1P");
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P", "2P", "", "v1", pathAppend);
% ImportMultiple.AddTrial("2021-11-29", "PL", input, "2P", "3P", "", "v1", pathAppend);
% LagIdx = [40, 40, 40, 0, 0, 0];
% legendStr = ["exp-2P","exp-3P","exp-FC","sim-1P","sim-2P","sim-3P"];

%**********************************************************************
% Run
%***********************************
S = ImportMultiple.BuildSolution;
R = ImportMultiple.ChangeCoordinates;
time = S(1).t;

if ~exist("legendStr","var"); legendStr = ImportMultiple.LegendStr; end
figFileNameBase = ImportMultiple.FigFileNameBase(figPath);

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
P.FontSizeAll = 20;
% P.FontSizeAll = 30; % For zoomed in view
P.lineStyle = ["-","--","-",":","-","--"]; % For fig in CraneDynamics Paper

%P.PlotXYZ_KM(time, R.K_relImesA2, R.M_relImesA2, legendStr,figFileNameBase+"_relI_measA2",export);
P.PlotXYZ_KM(time, R.K, R.M, legendStr,figFileNameBase,export);

%P.PlotXYZ_KM(time, StartZero(R.K_relImesA2), StartZero(R.M_relImesA2), legendStr,figFileNameBase+"_relI_measA2_zeroOffset",export);
%P.PlotXYZ_KM(time, StartZero(R.K), StartZero(R.M), legendStr,figFileNameBase+"_zeroOffset",export);

% P.PlotXYZ(time, R.K_relImesA2{1}-R.K_relImesA2{2}, "Error: "+legendStr(1)+" VS "+legendStr(2));

%P.PlotXYZ(time, R.I_relImesA2, legendStr);
%P.PlotXYZ(time, R.I, legendStr);

%%% Plot XZ path
% P.PlotPath_OnPlane(R.I, "y")
% P.PlotPath_OnPlane(R.K, "y")
% P.PlotPath_OnPlane(R.M, "y")

%%% Plot XY path
% P.PlotPath_OnPlane(R.I, "z")
% P.PlotPath_OnPlane(R.K, "z")
% P.PlotPath_OnPlane(R.M, "z")


%%% Special request plot for EA
% P = CDSu_PlotMultiple;
% P.FontSizeAll=20;
% P.lineWidth=1.4;
% a=P.PlotXY(time, StartZero(R.M_relImesA2), legendStr);
% title(a.Children.Children(3), "Trajectory of Payload COM");
% P.exportFig(a, "ea", "png");


%%
%%% Modifications to CraneDynamics Paper > Fig: Sim VS Exp
a = gcf;
for idx=2:7; a.Children.Children(idx).Children(1).LineWidth = 1.5; end
%P.exportFig(a, figFileNameBase+"_v2a", "png");
%P.exportFig(a, figFileNameBase+"_relI_measA2_zeroOffset_v2", "png");

%{
%%
%%%% Modifications to CraneDynamics Paper > Fig: Compare models
a = gcf;
for idx=2:7; a.Children.Children(idx).Children(3).LineStyle = "-"; end %Sim-1P
for idx=2:7; a.Children.Children(idx).Children(2).LineStyle = ":"; end %Sim-2P
for idx=2:7; a.Children.Children(idx).Children(4).LineStyle = ":"; end %Exp-FC
for idx=2:7; a.Children.Children(idx).Children(1).LineWidth = 2; end %Sim-3P
for idx=2:7; a.Children.Children(idx).Children(2).LineWidth = 3; end %Sim-2P
for idx=2:7; a.Children.Children(idx).Children(3).LineWidth = 2; end %Sim-1P
for idx=2:7; a.Children.Children(idx).Children(4).LineWidth = 1; end %Exp-FC
for idx=2:7; a.Children.Children(idx).Children(5).LineWidth = 1.5; end %Exp-3P
for idx=2:7; a.Children.Children(idx).Children(6).LineWidth = 1.5; end %Exp-2P
%%% Draw rectangles corresponding to the zoomed in view
zoomXLim = nan(2,7);
zoomYLim = nan(2,7);
for idx=[5,6,7]; zoomXLim(:,idx) = [14,14.6]; end % Point K
for idx=[2,3,4]; zoomXLim(:,idx) = [14,14.6]; end % Point M
for idx=[4,7]; zoomYLim(:,idx) = [0.08,0.13]+.8; end % x
for idx=[3,6]; zoomYLim(:,idx) = [-0.35,0]; end % y
for idx=[2,5]; zoomYLim(:,idx) = [0.35,0.5]; end % z
zoom_xywh = [zoomXLim(1,:);zoomYLim(1,:); zoomXLim(2,:)-zoomXLim(1,:); zoomYLim(2,:)-zoomYLim(1,:)];
for idx=2:7; rectangle(a.Children.Children(idx), 'Position',zoom_xywh(:,idx), 'LineWidth',2); end

%P.exportFig(a, figFileNameBase+"_v3bZoomboxes", "png");
%P.exportFig(a, figFileNameBase+"_relI_measA2_zeroOffset_v3", "png");

%%

%%% Modifications to CraneDynamics Paper > Fig: Compare models
%%% Zoomed in view
a = gcf;
lw=3;
for idx=2:7; a.Children.Children(idx).Children(3).LineStyle = "-"; end %Sim-1P
for idx=2:7; a.Children.Children(idx).Children(2).LineStyle = ":"; end %Sim-2P
for idx=2:7; a.Children.Children(idx).Children(4).LineStyle = ":"; end %Exp-FC
for idx=2:7; a.Children.Children(idx).Children(1).LineWidth = lw*2; end %Sim-3P
for idx=2:7; a.Children.Children(idx).Children(2).LineWidth = lw*3; end %Sim-2P
for idx=2:7; a.Children.Children(idx).Children(3).LineWidth = lw*2; end %Sim-1P
for idx=2:7; a.Children.Children(idx).Children(4).LineWidth = lw*2; end %Exp-FC
for idx=2:7; a.Children.Children(idx).Children(5).LineWidth = lw*3; end %Exp-3P
for idx=2:7; a.Children.Children(idx).Children(6).LineWidth = lw*2; end %Exp-2P
%%% Zoom V1 - using zero offset
% for idx=2:7; a.Children.Children(idx).Children(6).LineWidth = 1.5*1.5; end %Exp-2P
% for idx=[5,6,7]; a.Children.Children(idx).XLim = [13,14.5]; end % Point K
% for idx=[2,3,4]; a.Children.Children(idx).XLim = [13,14.5]; end % Point M
% for idx=[4,7]; a.Children.Children(idx).YLim = [0.05,0.3]; end % x
% for idx=[3,6]; a.Children.Children(idx).YLim = [-0.7,-0.1]; end % y
% for idx=[2,5]; a.Children.Children(idx).YLim = [0.3,0.75]; end % z
%%% Zoom V2 - using zero offset
% for idx=[5,6,7]; a.Children.Children(idx).XLim = [13,13.4]; end % Point K
% for idx=[2,3,4]; a.Children.Children(idx).XLim = [13,13.4]; end % Point M
% for idx=[4,7]; a.Children.Children(idx).YLim = [0.1,0.3]; end % x
% for idx=[3,6]; a.Children.Children(idx).YLim = [-0.68,-0.65]; end % y
% for idx=[2,5]; a.Children.Children(idx).YLim = [0.4,0.7]; end % z
% for idx=[2,3,4]; a.Children.Children(idx).YTickLabel = {}; end
%%% Zoom V2 - using bare
for idx=[5,6,7]; a.Children.Children(idx).XLim = [14,14.6]; end % Point K
for idx=[2,3,4]; a.Children.Children(idx).XLim = [14,14.6]; end % Point M
for idx=[4,7]; a.Children.Children(idx).YLim = [0.08,0.13]+.8; end % x
for idx=[3,6]; a.Children.Children(idx).YLim = [-0.35,0]; end % y
for idx=[2,5]; a.Children.Children(idx).YLim = [0.35,0.5]; end % z
for idx=[2,3,4]; a.Children.Children(idx).YTickLabel = {}; end
for idx=[3,4]; a.Children.Children(idx).XTick = a.Children.Children(2).XTick; end
for idx=[6,7]; a.Children.Children(idx).XTick = a.Children.Children(5).XTick; end
delete(a.Children.Children(7).Legend);
title(a.Children, "zoomed view", 'FontSize',P.FontSizeAll)
%P.exportFig(a, figFileNameBase+"_vbZoom", "png");

%}



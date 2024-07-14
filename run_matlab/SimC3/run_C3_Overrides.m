%{
Written By: Brandon Johns
Date Version Created: 2022-03-22
Date Last Edited: 2022-03-22
Status: functional
Simulator: CDS

%%% PURPOSE %%%
Build and simulate a predefined model while overriding values from preset
For testing solution variation with model param variation


%%% NOTES %%%
This file is only for use with the MATLAB solvers


%}
close all
clear all
clc
for modelPreset = ["1P", "2P", "3P", "ZS", "FC"]
    sympref('AbbreviateOutput',false);
    sympref('MatrixWithSquareBrackets',true);
    CDS_FindIncludes;
    CDS_IncludeSimulator;
    CDS_IncludeModels;

    %**********************************************************************
    % User input
    %***********************************
    inputPreset = 9;
    % modelPreset = "1P";
    % modelPreset = "ZS";
    % modelPreset = "FC";
    geometryPreset = 7;

    %**********************************************************************
    % Run
    %***********************************
    % Value builder
    VB = CDSvb_C3_Builder(geometryPreset, inputPreset);
    V = VB.Values_Sim;

    % Overrides
    %V.mass_K = 0.409; % Default 0.409
    V.mass_M = 0.25; % Default 0.586
    %V.L_AB = 1.108; % Default 1.108
    %V.a_DE_eq = 0.6; % Default 0.6
    V.a_DE_IC = V.a_DE_eq;


    % Model builder
    if     modelPreset=="1P"; MB = CDSm_C3_1p(V);
    elseif modelPreset=="2P"; MB = CDSm_C3_2p(V);
    elseif modelPreset=="3P"; MB = CDSm_C3_3p(V);
    elseif modelPreset=="ZS"; MB = CDSm_C3_noSheave(V);
    elseif modelPreset=="FC"; MB = CDSm_C3_sheave(V);
    elseif modelPreset=="ZJ"; MB = CDSm_C3_noSheave2P(V);
    elseif modelPreset=="FJ"; MB = CDSm_C3_sheave2P(V);
    else; error("Model not set");
    end

    % Run in 2D where possible
    MB.Flag_2D = V.Flag_2DPermitted;

    %MB.Flag_pointI_truePosition = false; % Not implemented

    % Build model and solve
    MB.Build_SystemDescription;
    SS = MB.Solve;%("drawIC");
    SSp = CDS_Solution_Plot(SS);
    SSe = CDS_Solution_Export(SS);
    SSa = CDS_Solution_Animate(SS);
    SSg = CDS_Solution_GetData(SS);

    %**********************************************************************
    % Results
    %***********************************
    % SSp.PlotConfigSpace
    % SSp.PlotInput
    % SSp.PlotEnergyTotal
    % SSp.PlotEnergyAll
    % SSp.PlotTaskSpace

    % SSe.DataToExcel

    SSa.Set_View_Predefined("front")
    % SSa.PlotFrame(0, "")
    % SSa.Animate

    %**********************************************************************
    % Results - interesting features
    %***********************************
    % Data to record
    fprintf("%.15e\n", max(SSg.AngleFromVertical("I","J")))
    fprintf("%.15e\n", max(SSg.AngleFromVertical("J","L")))
    fprintf("%.15e\n", max(SSg.AngleFromVertical("L","M")))

    %file = fopen('tmp_out.txt','a+');
    %fprintf(file,"%.15e\n", max(SSg.AngleFromVertical("I","J")));
    %fprintf(file,"%.15e\n", max(SSg.AngleFromVertical("J","L")));
    %fprintf(file,"%.15e\n", max(SSg.AngleFromVertical("L","M")));
    %fclose(file);

    % Test for error in start position
    %SSg.Px(["I","J","L","M"],1) - SSg.Px(["I"],1)
    %SSg.Px(["E"],1) - SSg.Px(["D"],1)
    %SSg.Px(["H"],1) - SSg.Px(["B"],1)

    if modelPreset~="FC"; clear all; end
end


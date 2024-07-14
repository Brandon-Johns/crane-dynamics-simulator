%{
Written By: Brandon Johns
Date Version Created: 2021-12-10
Date Last Edited: 2024-04-14
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Import experimental data into CDS to verify
    Correct processing of data between:
        Output of Vicon Tracker
        Output of "run_experiments\cmake\src\craneExp1_4\ExpMain1_4.cpp" with MotionMode=Stationary
    Correct construction of the simulator solution object


%%% NOTES %%%
Stationary data was captured and recorded with tracker,
then 1) exported directly to a CSV
and  2) replayed through VDS, and run through by craneExp1_4 with MotionMode=Stationary

Input of either into this script should produce the same result


%%% RESULTS %%%
Everything passes for current version ~ yay


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

dataPaths = CDS_GetDataLocations();
dataPath = dataPaths.exp_results("2021-12-16");
dataPathProcessed = dataPaths.exp_results("2021-12-16_Processed");

%**********************************************************************
% User input
%***********************************
% Options
dataFrom = "Tracker";
dataFrom = "VDS_withoutT";
dataFrom = "VDS_withT";


%**********************************************************************
% User input - automated
%***********************************
% Load preset numerical values: constants, ICs, inputs, etc.
VB = CDSvb_C3_Builder(3,0);
V = VB.Values_Exp;

% Override World frame
%   Use this to read in data that wasn't transformed by CraneExp1_4
%   e.g. if read directly from VDS
%   T_ViconGlobal_UR5Base is found from calibration
if dataFrom=="Tracker" || dataFrom=="VDS_withoutT"
    T_Simulator_UR5Base = CDS_T("at", "x", -sym(pi/2));
    T_ViconGlobal_UR5Base = CDS_T("P", [-1177.99,145.878,958.273]*1e-3);
    T_Simulator_ViconGlobal = T_Simulator_UR5Base * T_ViconGlobal_UR5Base.Inv;
    V.T_w0 = T_Simulator_ViconGlobal;
end

% Read in the CSV
fprintf("Data From " + dataFrom + "\n");
if dataFrom=="Tracker"
    ExpDataRaw = readmatrix( dataPaths.exp_results("2021-12-16", "bj_stationary45up_2021_12_16_v1.csv"), 'NumHeaderLines',5 );
    
    frames = ExpDataRaw(:, 1);
    idxStartT = 3;
    % Boom head
    raw_BH_eulerXYZ = ExpDataRaw(:, idxStartT:idxStartT+2);
    raw_BH_P = ExpDataRaw(:, idxStartT+3:idxStartT+5);
    idxStartT=idxStartT+6;
    % Payload (CWM)
    raw_PP_eulerXYZ = ExpDataRaw(:, idxStartT:idxStartT+2);
    raw_PP_P = ExpDataRaw(:, idxStartT+3:idxStartT+5);
    idxStartT=idxStartT+6;
    % Hook block
    raw_HB_eulerXYZ = ExpDataRaw(:, idxStartT:idxStartT+2);
    raw_HB_P = ExpDataRaw(:, idxStartT+3:idxStartT+5);
    idxStartT=idxStartT+6;
    
    t = (frames-1)/100;
    raw_BH_R = CDS_SolutionExp.eulerXYZ_to_R_rowMajor(raw_BH_eulerXYZ);
    raw_HB_R = CDS_SolutionExp.eulerXYZ_to_R_rowMajor(raw_HB_eulerXYZ);
    raw_PP_R = CDS_SolutionExp.eulerXYZ_to_R_rowMajor(raw_PP_eulerXYZ);
    
elseif dataFrom=="VDS_withoutT" || dataFrom=="VDS_withT"
    if dataFrom=="VDS_withoutT"
        ExpDataRaw = readmatrix( dataPaths.exp_results("2021-12-16", "raw_Stationary_PL_withoutT.csv") );
    else
        ExpDataRaw = readmatrix( dataPaths.exp_results("2021-12-16", "raw_Stationary_PL_withT.csv") );
    end

    t = ExpDataRaw(:, 1);
    idxStartT = 2;
    % Boom head
    raw_BH_R = ExpDataRaw(:, idxStartT:idxStartT+8);
    raw_BH_P = ExpDataRaw(:, idxStartT+9:idxStartT+11);
    idxStartT=idxStartT+12;
    % Hook block
    raw_HB_R = ExpDataRaw(:, idxStartT:idxStartT+8);
    raw_HB_P = ExpDataRaw(:, idxStartT+9:idxStartT+11);
    idxStartT=idxStartT+12;
    % Payload
    raw_PP_R = ExpDataRaw(:, idxStartT:idxStartT+8);
    raw_PP_P = ExpDataRaw(:, idxStartT+9:idxStartT+11);
    idxStartT=idxStartT+12;
else
    error("Bad input: dataFrom")
end

% Convert to mm -> m
raw_BH_P = raw_BH_P * 1e-3;
raw_HB_P = raw_HB_P * 1e-3;
raw_PP_P = raw_PP_P * 1e-3;


%**********************************************************************
% Define Geometry - Parameters
%***********************************
params = CDS_Params();
points = CDS_Points(params);

params.Create('input', 'theta_1').SetAnalytic(V.theta_1_t);
params.Create('input', 'theta_2').SetAnalytic(V.theta_2_t);
params.Create('input', 'theta_10').SetAnalytic(V.theta_10_t);

%**********************************************************************
% Define Geometry - Other
%***********************************
% Points and chains
A = points.Create('A');
I = points.Create('I');
J = points.Create('J');
K = points.Create('K', V.mass_K, V.inertia_K);
L = points.Create('L');
L2 = points.Create('L2');
M = points.Create('M', V.mass_M, V.inertia_M);

chains = {[A,I,J,K,L,M], [L,L2]};

%**********************************************************************
% Build Solution Object
%***********************************
SS = CDS_SolutionExp(params, t);

SS.AddPoint_Analytic(A);
SS.AddPoint_Exp(I, V.T_w0, raw_BH_R, raw_BH_P, V.T_BH_I);
SS.AddPoint_Exp(J, V.T_w0, raw_HB_R, raw_HB_P, V.T_HB_J);
SS.AddPoint_Exp(K, V.T_w0, raw_HB_R, raw_HB_P, V.T_HB_K);
SS.AddPoint_Exp(L, V.T_w0, raw_HB_R, raw_HB_P, V.T_HB_L);
SS.AddPoint_Exp(L2, V.T_w0, raw_PP_R, raw_PP_P, V.T_PP_L);
SS.AddPoint_Exp(M, V.T_w0, raw_PP_R, raw_PP_P, V.T_PP_M);

SS.SetChains(chains);

SSp = CDS_Solution_Plot(SS);
SSe = CDS_Solution_Export(SS);
SSa = CDS_Solution_Animate(SS);
SSg = CDS_Solution_GetData(SS);

%**********************************************************************
% Results - General
%***********************************
SSp.PlotConfigSpace
SSp.PlotInput
SSp.PlotEnergyTotal
SSp.PlotEnergyAll
SSp.PlotTaskSpace_Mass

% SSe.DataToExcel

% SSa.Set_View_Predefined("front")
% SSa.Set_View_Predefined("3D-2")
SSa.PlotFrame
% SSa.Animate

SSg.xyz(1)

%**********************************************************************
%% Results - Compare Transforms
%***********************************
idx = 1;

R_w0 = CDS_T(double(V.T_w0.T)).R;
P_w0 = CDS_T(double(V.T_w0.T)).P;

P_w_BH = P_w0 + R_w0 * raw_BH_P(idx,:).';
P_w_HB = P_w0 + R_w0 * raw_HB_P(idx,:).';
P_w_PP = P_w0 + R_w0 * raw_PP_P(idx,:).';
R_w_BH = R_w0 * reshape(raw_BH_R(idx,:),3,3).';
R_w_HB = R_w0 * reshape(raw_HB_R(idx,:),3,3).';
R_w_PP = R_w0 * reshape(raw_PP_R(idx,:),3,3).';

SSa.PlotFrame(t(idx))
ax = gca;
hold(ax,'on')
plotTransforms(P_w_BH.', rotm2quat( R_w_BH ),'FrameSize',0.1)
plotTransforms(P_w_HB.', rotm2quat( R_w_HB ),'FrameSize',0.1)
plotTransforms(P_w_PP.', rotm2quat( R_w_PP ),'FrameSize',0.1)
hold(ax,'off')

%**********************************************************************
% Compare exported data
%***********************************
% Test that all 3 version give the same results
%   Generate the 3 files with SSe.DataToExcel()
%{
for sheet = ["Px", "Py", "Pz"]
    compare1 = readmatrix(dataPathProcessed+filesep+"compare_Tracker.xlsx", "Sheet",sheet);
    compare2 = readmatrix(dataPathProcessed+filesep+"compare_withoutT.xlsx", "Sheet",sheet);
    compare3 = readmatrix(dataPathProcessed+filesep+"compare_withT.xlsx", "Sheet",sheet);
    
    % Downsample Tracker data
    compare1_ds = compare1(floor(linspace(1,size(compare1,1),size(compare2,1))), :);
    
    % The files are not in sync
    % They do not start at the same point in the recording
    % => can only compare by standard deviation or range etc.
    errorMax = [...
        max(compare2-compare3, [],'all'),...
        max(compare1_ds-compare3, [],'all')]
    
    errorStandardDev = [...
        max(std(compare2-compare3,0, 1)),...
        max(std(compare1_ds-compare3,0, 1))]
    
    standardDev = [...
        max(std(compare1,0, 1)),...
        max(std(compare2,0, 1)),...
        max(std(compare3,0, 1))]
end
%}

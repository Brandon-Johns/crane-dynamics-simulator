%{
Written By: Brandon Johns
Date Version Created: 2022-01-30
Date Last Edited: 2024-04-08
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Use to test every solver & solveMode combo


%%% SYSTEM DESCRIPTION %%%
Triple pendulum


%}
close all
clear all
clc
sympref('AbbreviateOutput',false);
sympref('MatrixWithSquareBrackets',true);
CDS_FindIncludes;
CDS_IncludeSimulator;
dataPaths = CDS_GetDataLocations();
dataPath = @(fileName_) dataPaths.cache("VerifySimulatorAnalytic", fileName_);

%**********************************************************************
% Define System
%***********************************
params = CDS_Params();
points = CDS_Points(params);

% Parameters
params.Create('free', 'L_AB').SetIC(1); % Constrained link
params.Create('const', 'L_BC').SetNum(1);
params.Create('const', 'L_CD').SetNum(1);
params.Create('const', 'g').SetNum(9.8);

params.Create('free', 'theta_1').SetIC(deg2rad(90));
params.Create('free', 'theta_2').SetIC(0);
params.Create('free', 'theta_3').SetIC(0);

% Forward transformations
T_AA2 = CDS_T('atP', 'z', theta_1-sym(pi)/2, [0;0;0]);
T_A2B = CDS_T('atP', 'z', theta_2, [L_AB;0;0]);
T_BC  = CDS_T('atP', 'z', theta_3, [L_BC;0;0]);
T_CD  = CDS_T('atP', 'z', 0, [L_CD;0;0]);

T_AB = T_AA2*T_A2B;
T_AC = T_AB*T_BC;
T_AD = T_AC*T_CD;

mass = 1;
% inertia = [1,1,1];
inertia = [0,0,0];

A = points.Create('A');
B = points.Create('B', mass, inertia).SetT_0n(T_AB);
C = points.Create('C', mass, inertia).SetT_0n(T_AC);
D = points.Create('D', mass, inertia).SetT_0n(T_AD);

% Direction of gravity in base frame
g0 = [0; -g; 0];

chains = {[A,B,C,D]};
sys = CDS_SystemDescription(params, points, chains, g0);

sys.SetConstraint(L_AB);


%**********************************************************************
% Solve
%***********************************
SO = CDS_Solver_Options();
SO.time = 0 : 0.02 : 20;
SO.RelTol = 1e-10;
SO.AbsTol = 1e-10;
% SO.RelTol = 1e-7;
% SO.AbsTol = 1e-7;
SO.RelTol = 1e-14;
SO.AbsTol = 1e-14;

% solver = "drawIC"
% solver = "sundials"
% solver = "ode45"
% solver = "ode23"
% solver = "ode113"
% solver = "ode78"
solver = "ode89"
% solver = "ode15s"
% solver = "ode23t"
% solver = "ode23s" % Requires constant mass matrix
% solver = "ode23tb"
% solver = "ode15i"

mode = "auto";
% mode = "massMatrix"

S = CDS_Solver(SO);
tic;
[t,x,xd] = S.Solve(sys, solver, mode);
timeToSolve = toc;


%**********************************************************************
% Output
%***********************************
CE = CDS_Calc_Energy(sys);
SS = CDS_SolutionSim(sys, t,x,xd);
SSp = CDS_Solution_Plot(SS);
SSe = CDS_Solution_Export(SS);
SSa = CDS_Solution_Animate(SS);
SSg = CDS_Solution_GetData(SS);

SSp.PlotConfigSpace
%SSp.PlotInput
%SSp.PlotEnergyTotal
%SSp.PlotEnergyAll
%SSp.PlotTaskSpace

% SSe.DataToExcel(dataPath("Test_3P_1C_"+solver+".xlsx"))
% SSe.DataToExcel(dataPath("Test_3P_1C_"+solver+"_"+mode+".xlsx"))

SSa.Set_View_Predefined("front")
% SSa.PlotFrame
% SSa.Animate

% CE.InputList_0Vel
e_IC = CE.E0; % Initial conditions
e_eq = CE.E_0Vel([params.Param("L_AB").q0; 0;0;0]); % Equilibrium position
e_total = e_IC - e_eq;


finalValuesStr = strjoin(compose("%g", SSg.q(SS.q_free, length(SS.t)) ),",");
fprintf("Final values ["+strjoin(SS.q_free.Str,",")+"]: ["+finalValuesStr+"]\n")
fprintf("Max deviation of total energy (normalised by total energy): %g\n", max(abs((SS.E)))/e_total)
fprintf("Time to Form and Solve (s): %g\n", timeToSolve)

%{
RMSE = @(a_,b_) sqrt(mean((a_ - b_).^2, 2));
maxRMSE = @(a_,b_) max(RMSE(a_,b_));

% Import from excel
SSmt = CDS_SolutionSaved(sys, dataPath("Test_3P_1C_ode89_maxTol.xlsx"));
SS_45 = CDS_SolutionSaved(sys, dataPath("Test_3P_1C_ode45.xlsx"));
SS_23 = CDS_SolutionSaved(sys, dataPath("Test_3P_1C_ode23.xlsx"));
SS_113 = CDS_SolutionSaved(sys, dataPath("Test_3P_1C_ode113.xlsx"));
SS_78 = CDS_SolutionSaved(sys, dataPath("Test_3P_1C_ode78.xlsx"));
SS_89 = CDS_SolutionSaved(sys, dataPath("Test_3P_1C_ode89.xlsx"));
SS_15s = CDS_SolutionSaved(sys, dataPath("Test_3P_1C_ode15s.xlsx"));
SS_23t = CDS_SolutionSaved(sys, dataPath("Test_3P_1C_ode23t.xlsx"));
SS_23tb = CDS_SolutionSaved(sys, dataPath("Test_3P_1C_ode23tb.xlsx"));

maxRMSE(SSmt.qf, SS_45.qf)
maxRMSE(SSmt.qf, SS_23.qf)
maxRMSE(SSmt.qf, SS_113.qf)
maxRMSE(SSmt.qf, SS_78.qf)
maxRMSE(SSmt.qf, SS_89.qf)
maxRMSE(SSmt.qf, SS_15s.qf)
maxRMSE(SSmt.qf, SS_23t.qf)
maxRMSE(SSmt.qf, SS_23tb.qf)


%}




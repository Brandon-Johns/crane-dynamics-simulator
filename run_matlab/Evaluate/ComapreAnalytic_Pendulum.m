%{
Written By: Brandon Johns
Date Version Created: 2021-06-01
Date Last Edited: 2024-04-08
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Compare
    Analytic single pendulum
    Simulator single pendulum


%}
close all
clear all
clc
sympref('AbbreviateOutput',false);
sympref('MatrixWithSquareBrackets',true);
CDS_FindIncludes;
CDS_IncludeSimulator;
CDS_IncludeUtilities;

%**********************************************************************
% Define System
%***********************************
params = CDS_Params();
points = CDS_Points(params);

theta_IC = 0.9*pi;
L_AB_num = 1.5;
g_num = 9.8;
mass = 1; % Doesn't have any effect

params.Create('free', 'theta_1').SetIC(theta_IC);
params.Create('const', 'L_AB').SetNum(L_AB_num);
params.Create('const', 'g').SetNum(g_num);

% Forward transformations
T_AA2 = CDS_T('atP', 'z', theta_1-sym(pi)/2, [0;0;0]);
T_A2B = CDS_T('atP', 'z', 0, [L_AB;0;0]);

T_OB = T_AA2*T_A2B;

A = points.Create('A');
B = points.Create('B', mass).SetT_0n(T_OB);

% Direction of gravity in base frame
g0 = [0; -g; 0];

chains = {[A,B]};
sys = CDS_SystemDescription(params, points, chains, g0);


%**********************************************************************
% Solve
%***********************************
SO = CDS_Solver_Options();
SO.time = [0,20];
SO.RelTol = 1e-10;
SO.AbsTol = 1e-10;

S = CDS_Solver(SO);
tic;
[t,x,xd] = S.Solve(sys);
timeToSolve = toc;

%**********************************************************************
% Output
%***********************************
SS = CDS_SolutionSim(sys, t,x,xd);
SSp = CDS_Solution_Plot(SS);
SSe = CDS_Solution_Export(SS);
SSa = CDS_Solution_Animate(SS);
SSg = CDS_Solution_GetData(SS);

SSp.PlotConfigSpace
%SSp.PlotEnergyTotal
%SSp.PlotEnergyAll

%SSa.Set_View_Predefined("front")
%SSa.PlotFrame
%SSa.Animate


%**********************************************************************
% Compare to Analytic
%***********************************
theta_simulated = SSg.q("theta_1");

% Period - very rough due to using findpeaks()
[~,idxPeak]=findpeaks(theta_simulated);
T_simulated = t(idxPeak(end))/length(idxPeak);

% Analytic solution
AS = CDSu_Analytic_1P(L_AB_num, g_num, theta_IC);
theta_analytic = AS.Evaluate_Signal(t);

% Error of Period
%T_absErr = abs((AS.Evaluate_Period - T_simulated)/AS.Evaluate_Period)

% Error of full signal
% Root mean square error, normalised by length
RMSE_lengthNormalised = sqrt(mean((theta_simulated - theta_analytic).^2))/L_AB_num;


fprintf("Period (Simulated, rough):   %g\n", T_simulated)
fprintf("Period (Small Angle Approx): %g\n", AS.Evaluate_Period_SmallAngleApprox)
fprintf("Period (Analytic):           %g\n", AS.Evaluate_Period)
fprintf("RMSE (Normalised by Link Length): %g\n", RMSE_lengthNormalised)
fprintf("Time to Form and Solve (s): %g\n", timeToSolve)

%figure; plot(t,theta_analytic)



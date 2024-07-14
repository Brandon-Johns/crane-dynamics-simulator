%{
Written By: Brandon Johns
Date Version Created: 2021-06-04
Date Last Edited: 2024-04-08
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Compare
    Analytic single pendulum
    Simulator 4-parallel-bar linkage with point mass on bottom link


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

% Parameters
theta_IC = 0.9*pi;
g_num = 9.8;
L_AB_num = 1.5;
L_BC_num = 2;
L_AD_num = L_BC_num;
mass = 1; % Doesn't have any effect

params.Create('free', 'theta_1').SetIC(theta_IC);
params.Create('free', 'theta_2').SetIC(theta_IC);
params.Create('const', 'L_AB').SetNum(L_AB_num);
params.Create('const', 'L_BC').SetNum(L_BC_num);
params.Create('const', 'L_AD').SetNum(L_AD_num);
params.Create('const', 'g').SetNum(g_num);

% Forward transformations
T_AA2 = CDS_T('atP', 'z', -(sym(pi/2) - theta_1), [0;0;0]);
T_A2B = CDS_T('atP', 'z', sym(pi/2) - theta_2, [L_AB;0;0]);
T_BG = CDS_T('atP', 'z', 0, [L_BC/2;0;0]);
T_BC = CDS_T('atP', 'z', 0, [L_BC;0;0]);
T_AD = CDS_T('atP', 'z', 0, [L_AD;0;0]);

% Solve dependent transformations - Prep
% Forward transform D->C
T_AC = T_AA2*T_A2B*T_BC;
T_DA = T_AD.Inv;
T_DC = T_DA*T_AC;

% Invert T_DC for P_CD in terms of independent vars
T_CD = T_DC.Inv;
P_CD = T_CD.P;

% Solve dependent transformations - Solved by hand
se = @(x) simplify(expand(x));

psi_1 = atan2(P_CD(2),P_CD(1));
a_CD = se(sqrt(P_CD(2)^2 + P_CD(1)^2));

% Forward transforms in terms of independent variables
T_CC2 = CDS_T('atP', 'z', psi_1, [0;0;0]);
T_C2D = CDS_T('atP', 'z', 0, [a_CD;0;0]);

% Combine
T_AB = T_AA2*T_A2B;
T_AC = T_AB*T_BC;
T_AD = T_AC*T_CC2*T_C2D;
T_AG = T_AB*T_BG;

A = points.Create('A');
B = points.Create('B').SetT_0n(T_AB);
C = points.Create('C').SetT_0n(T_AC);
D = points.Create('D').SetT_0n(T_AD);
G = points.Create('G', mass).SetT_0n(T_AG);

% Direction of gravity in base frame
g0 = [0; -g; 0];

chains = {[A, B, C, D]};
sys = CDS_SystemDescription(params, points, chains, g0);

% Using this as a constraint allows the bars to invert when passing through singularity (@theta1 = 0.5*pi)
%   Technically feasible... just not what I'm after
%   Safe to enable for: theta_IC < 0.5*pi
%sys.SetConstraint(a_CD);

% Simpler constraint, but prevents the linkage from inverting and still tests the formulation fine
sys.SetConstraint(theta_1-theta_2);


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
% Compare to analytic
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


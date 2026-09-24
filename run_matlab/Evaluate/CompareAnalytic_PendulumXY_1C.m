%{
Written By: Brandon Johns
Date Version Created: 2024-10-02
Date Last Edited: 2024-10-04
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Compare
    Analytic single pendulum
    Simulator single pendulum via constraint x^2+y^2=L^2

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
sys = CDS_SystemDescription();
params = sys.params;

theta_IC = 0.9*pi;
L_AB_num = 1.5;
g_num = 9.8;
mass = 1; % Doesn't have any effect

params.Create('free', 'Lx').SetIC(L_AB_num*sin(theta_IC));
params.Create('free', 'Ly').SetIC(-L_AB_num*cos(theta_IC));
params.Create('const', 'L_AB').SetNum(L_AB_num);
params.Create('const', 'g').SetNum(g_num);

% Forward transformations
T_OB = CDS_T('P', [Lx;Ly;0]);

A = sys.CreatePoint('A');
B = sys.CreatePoint('B', mass).SetT_0n(T_OB);

sys.SetChains([A,B]);
sys.SetGravity([0; -g; 0]);
sys.CreateConstraint("lenAB").SetConstraint(Lx^2 + Ly^2 - L_AB_num^2);
sys.SetConstraint_StabilisationFactors(1000); % This massively reduces error


%**********************************************************************
% Solve
%***********************************
SO = CDS_Solver_Options();
SO.time = [0,20];
SO.RelTol = 1e-6;
SO.AbsTol = 1e-6;
SO.EventsIsActive = true;

S = CDS_Solver(SO);
tic;
[t,x,xd] = S.Solve(sys);
%[t,x,xd] = S.Solve(sys, "ode89");
%[t,x,xd] = S.Solve(sys, "idas","massMatrix");
%[t,x,xd] = S.Solve(sys, "ode15s","massMatrix");
%[t,x,xd] = S.Solve(sys, "ode23t","massMatrix");
%[t,x,xd] = S.Solve(sys, "ode15i");
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
SSp.PlotConstraintViolation
SSp.PlotEnergyTotal
%SSp.PlotEnergyAll

%SSa.Set_View_Predefined("front")
%SSa.PlotFrame
%SSa.Animate


%**********************************************************************
% Compare to Analytic
%***********************************
x_simulated = SSg.q("Lx");
y_simulated = SSg.q("Ly");
theta_simulated = wrapToPi(atan2(y_simulated,x_simulated) + pi/2);

% Analytic solution
AS = CDSu_Analytic_1P(L_AB_num, g_num, theta_IC);
theta_analytic = AS.Evaluate_Signal(t);
x_analytic = L_AB_num*sin(theta_analytic);
y_analytic = -L_AB_num*cos(theta_analytic);

% Error of full signal
% Root mean square error, normalised by length
RMSE_lengthNormalised = sqrt(mean((theta_simulated - theta_analytic).^2))/L_AB_num;
RMSE_lengthNormalised_x = sqrt(mean((x_simulated - x_analytic).^2))/L_AB_num;
RMSE_lengthNormalised_y = sqrt(mean((y_simulated - y_analytic).^2))/L_AB_num;

fprintf("Period (Analytic):           %g\n", AS.Evaluate_Period)
fprintf("RMSE (Normalised by Link Length):   %g\n", RMSE_lengthNormalised)
fprintf("RMSE x (Normalised by Link Length): %g\n", RMSE_lengthNormalised_x)
fprintf("RMSE y (Normalised by Link Length): %g\n", RMSE_lengthNormalised_y)
fprintf("Time to Form and Solve (s): %g\n", timeToSolve)

%figure; plot(t,theta_analytic)



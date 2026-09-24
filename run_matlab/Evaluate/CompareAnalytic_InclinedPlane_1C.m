%{
Written By: Brandon Johns
Date Version Created: 2024-10-02
Date Last Edited: 2024-10-04
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Compare
    Analytic particle sliding down a frictionless inclined plane
    Simulator particle sliding down a frictionless inclined plane

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
mass = 1;
gravity = 9.8;
gradient = -3/4; % Slope is a 3:4:5 triangle because I can

% Calculate known dynamics
% x = x0 + v0*t + 0.5*a*t^2
% v = v0 + a*t
% E = 0.5*m*v^2
slope_dx = 1;
slope_dy = gradient;
slope_ds = sqrt(1 + gradient^2);
xdd_true = @(t) (-gravity*(slope_dx*slope_dy/slope_ds^2))*ones(size(t));
xd_true  = @(t) xdd_true(t).*t;
x_true   = @(t) 0.5*xdd_true(t).*t.^2;
ydd_true = @(t) (-gravity*(slope_dy^2/slope_ds^2))*ones(size(t));
yd_true  = @(t) ydd_true(t).*t;
y_true   = @(t) 0.5*ydd_true(t).*t.^2;
Ek_true  = @(t) 0.5*mass*(xd_true(t).^2 + yd_true(t).^2);
Ev_true  = @(t) gravity*mass*y_true(t);
P_abs_true = @(t) sqrt(x_true(t).^2 + y_true(t).^2);


sys = CDS_SystemDescription();
params = sys.params;
% Initial conditions should be consistent with the constraint
params.Create('free', 'Lx').SetIC(x_true(0), xd_true(0));
params.Create('free', 'Ly').SetIC(y_true(0), yd_true(0));
params.Create('const', 'g').SetNum(gravity);

T_OA = CDS_T('P', [Lx;Ly;0]);
A = sys.CreatePoint('A', mass).SetT_0n(T_OA);

sys.SetChains();
sys.SetGravity([0; -g; 0]);
sys.CreateConstraint("path").SetConstraint(Ly - gradient*Lx);


%**********************************************************************
% Solve
%***********************************
SO = CDS_Solver_Options();
SO.time = [0,5];
SO.RelTol = 1e-10;
SO.AbsTol = 1e-10;

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
%SSp.PlotLambda
SSp.PlotEnergyTotal
%SSp.PlotEnergyAll

%SSa.Set_View_Predefined("front")
%SSa.PlotFrame
%SSa.Animate


%**********************************************************************
% Compare to Analytic
%***********************************
P_abs = sqrt(SSg.q("Lx").^2 + SSg.q("Ly").^2);

% Root mean square error
RMSE = @(simulated_, analytic_) sqrt(mean((simulated_ - analytic_).^2));

fprintf("RMSE (x): %g\n", RMSE(SSg.q("Lx"), x_true(t)))
fprintf("RMSE (y): %g\n", RMSE(SSg.q("Ly"), y_true(t)))
fprintf("RMSE (P): %g\n", RMSE(P_abs, P_abs_true(t)))
fprintf("RMSE (xd): %g\n", RMSE(SSg.qd("Lx"), xd_true(t)))
fprintf("RMSE (yd): %g\n", RMSE(SSg.qd("Ly"), yd_true(t)))
fprintf("RMSE (xdd): %g\n", RMSE(SSg.qdd("Lx"), xdd_true(t)))
fprintf("RMSE (ydd): %g\n", RMSE(SSg.qdd("Ly"), ydd_true(t)))
fprintf("Max Error (Energy K): %g\n", max(abs(SS.K_mass - Ek_true(t))))
fprintf("Max Error (Energy V): %g\n", max(abs(SS.V_mass - Ev_true(t))))
fprintf("Max Error (Energy):   %g\n", max(abs(SS.E)))
fprintf("Time to Form and Solve (s): %g\n", timeToSolve)


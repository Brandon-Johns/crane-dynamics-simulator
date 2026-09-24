%{
Written By: Brandon Johns
Date Version Created: 2023-11-20
Date Last Edited: 2024-10-06
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Test solver with multiple constraints vs without constraints


%%% SYSTEM DESCRIPTION %%%
Double Pendulum
Each link is held constant length through a constraint


%%% NOTES %%%
With ode15i, I can't get it to solve with both constraints active T_T
... but guess what solveTime3 can do~


%}
close all
clear all
clc
sympref('AbbreviateOutput',false);
sympref('MatrixWithSquareBrackets',true);
CDS_FindIncludes;
CDS_IncludeSimulator;


%nConstraints = 0;
%nConstraints = 1;
nConstraints = 2;


%**********************************************************************
% Define System
%***********************************
sys = CDS_SystemDescription();
params = sys.params;

L_AB_num = 1;
L_BC_num = 1;

% Parameters
if(nConstraints >= 1); params.Create('free', 'L_AB').SetIC(1); else; params.Create('const', 'L_AB').SetNum(L_AB_num); end
if(nConstraints >= 2); params.Create('free', 'L_BC').SetIC(1); else; params.Create('const', 'L_BC').SetNum(L_BC_num); end
params.Create('const', 'g').SetNum(9.8);
params.Create('free', 'theta_1').SetIC(deg2rad(10));
params.Create('free', 'theta_2').SetIC(deg2rad(10));

% Forward transformations
T_AA2 = CDS_T('atP', 'z', theta_1-sym(pi)/2, [0;0;0]);
T_A2B = CDS_T('atP', 'z', theta_2, [L_AB;0;0]);
T_BC  = CDS_T('atP', 'z', 0, [L_BC;0;0]);

T_AB = T_AA2*T_A2B;
T_AC = T_AB*T_BC;

mass = 1;
inertia = [0,0,0];

A = sys.CreatePoint('A');
B = sys.CreatePoint('B', mass, inertia).SetT_0n(T_AB);
C = sys.CreatePoint('C', mass, inertia).SetT_0n(T_AC);

sys.SetChains([A,B,C]);
sys.SetGravity([0; -g; 0]);
sys.SetConstraint_StabilisationFactors(10);

if nConstraints == 1
    sys.CreateConstraint("lenAB").SetConstraint(L_AB-L_AB_num);

    % From looking at the solution
    %params.lambda(1).SetIC(18.74);

elseif nConstraints == 2
    sys.CreateConstraint("lenAB").SetConstraint(L_AB-L_AB_num);
    sys.CreateConstraint("lenBC").SetConstraint(L_BC-L_BC_num);

    % From looking at the solution while applying only 1 constraint at a time
    %params.lambda(1).SetIC(18.74);
    %params.lambda(2).SetIC(9.23);

    % For testing multiple time varying constraints
    %sys.CreateConstraint("lenAB").SetConstraint(L_AB-L_AB_num-0.1*sym('t','real'));
    %sys.CreateConstraint("lenBC").SetConstraint(L_BC-L_BC_num+0.1*sym('t','real'));
end


%**********************************************************************
% Solve
%***********************************
SO = CDS_Solver_Options();
S = CDS_Solver(SO);
SO.time = 0 : 0.02 : 5;

%SO.RelTol = 1e-6;
%SO.AbsTol = 1e-4;
%[t,x,xd] = S.Solve(sys, "ode15i", "fullyImplicit");

SO.RelTol = 1e-10;
SO.AbsTol = 1e-10;
[t,x,xd] = S.Solve(sys, "ode89", "solveTime3");
%[t,x,xd] = S.Solve(sys, "idas","massMatrix");
%[t,x,xd] = S.Solve(sys, "ode15s","massMatrix");
%[t,x,xd] = S.Solve(sys, "ode23t","massMatrix");


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
SSp.PlotLambda
SSp.PlotEnergyTotal

SSa.Set_View_Predefined("front")
SSa.Animate






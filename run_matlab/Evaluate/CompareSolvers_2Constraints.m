%{
Written By: Brandon Johns
Date Version Created: 2023-11-20
Date Last Edited: 2024-04-08
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Test solver with multiple constraints vs without constraints


%%% SYSTEM DESCRIPTION %%%
Double Pendulum
Each link is held constant length through a constraint


%%% NOTES %%%
I can't get it to solve with both constraints active T_T
Goes to show how imprecise ode15i is right?

If I edit CDS_Solver to add in
    DAEs_EL = simplify(expand(DAEs_EL));
Then it can solve up to
    t = 1.380803e-01
And the result looks reasonable
So it seems to be at least somewhat working


%}
close all
clear all
clc
sympref('AbbreviateOutput',false);
sympref('MatrixWithSquareBrackets',true);
CDS_FindIncludes;
CDS_IncludeSimulator;


nConstraints = 0;
%nConstraints = 1;
%nConstraints = 2;


%**********************************************************************
% Define System
%***********************************
params = CDS_Params();
points = CDS_Points(params);

% Parameters
if(nConstraints >= 1); params.Create('free', 'L_AB').SetIC(1); else params.Create('const', 'L_AB').SetNum(1); end
if(nConstraints >= 2); params.Create('free', 'L_BC').SetIC(1); else params.Create('const', 'L_BC').SetNum(1); end
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

A = points.Create('A');
B = points.Create('B', mass, inertia).SetT_0n(T_AB);
C = points.Create('C', mass, inertia).SetT_0n(T_AC);

% Direction of gravity in base frame
g0 = [0; -g; 0];

chains = {[A,B,C]};
sys = CDS_SystemDescription(params, points, chains, g0);

if nConstraints == 1
    sys.SetConstraint([L_AB]);

    % From looking at the solution
    params.lambda(1).SetIC(18.74);

elseif nConstraints == 2
    sys.SetConstraint([L_AB, L_BC]);

    % From looking at the solution while applying only 1 constraint at a time
    params.lambda(1).SetIC(18.74);
    params.lambda(2).SetIC(9.23);
end


%**********************************************************************
% Solve
%***********************************
SO = CDS_Solver_Options();
SO.time = 0 : 0.02 : 5;
SO.RelTol = 1e-6;
SO.AbsTol = 1e-4;

S = CDS_Solver(SO);
[t,x,xd] = S.Solve(sys, "ode15i", "fullyImplicit");


%**********************************************************************
% Output
%***********************************
SS = CDS_SolutionSim(sys, t,x,xd);
SSp = CDS_Solution_Plot(SS);
SSe = CDS_Solution_Export(SS);
SSa = CDS_Solution_Animate(SS);
SSg = CDS_Solution_GetData(SS);

SSp.PlotConfigSpace
SSp.PlotLambda
SSp.PlotEnergyTotal

SSa.Set_View_Predefined("front")
SSa.Animate






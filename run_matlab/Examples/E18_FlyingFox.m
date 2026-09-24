%{
Written By: Brandon Johns
Date Version Created: 2026-09-15
Date Last Edited: 2026-09-15
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Example Simulation: Flying Fox (zipline, playground equipment)


%%% SYSTEM DESCRIPTION %%%
The rope supports are fixed in space
The fox slides along the rope
The seat hangs off the fox

Parameters / Variables
    theta_1 = angle of link AB, down from horizontal
    theta_2 = angle of link BC, upward from extension of AB
    theta_p = angle of link BG, from negative vertical
    L1 = length between A and B (part of the rope)
    L2 = length between B and C (part of the rope)
    Lp = length between B and G (from the fox, to the seat)
    g = gravity

Locations
    A: stationary joint
    B: the fox (pulley)
    C: stationary joint
    G: seat + human

Diagram
    A
     \     C
      \   /
        B
        |
        G
%}
close all
clear all
clc
sympref('AbbreviateOutput',false);
sympref('MatrixWithSquareBrackets',true);
CDS_FindIncludes;
CDS_IncludeSimulator;

%**********************************************************************
% Define System
%***********************************
sys = CDS_SystemDescription();
params = sys.params;

% Generalised coordinates and system parameters
params.Create('free', 'theta_1').SetIC( deg2rad(60) );
params.Create('free', 'theta_2').SetIC( deg2rad(62) ); % Keep greater than theta1 to give an uphill
params.Create('free', 'theta_p').SetIC( deg2rad(0) );
params.Create('free', 'L1').SetIC(0.25);
params.Create('free', 'L2').SetIC(3);
params.Create('const', 'Lp').SetNum(0.5);
params.Create('const', 'g').SetNum(9.8);

% Forward transformations as homogeneous transformation matrices
T_AA2 = CDS_T('at', 'z', -theta_1);
T_A2B = CDS_T('atP', 'z', theta_2, [L1;0;0]);
T_BC = CDS_T('atP', 'z', 0, [L2;0;0]);
T_BG = CDS_T('at', 'z', theta_p+theta_1-theta_2-sym(pi)/2) * CDS_T('P', [Lp;0;0]);

T_AB = T_AA2*T_A2B;
T_AC = T_AB*T_BC;
T_AG = T_AB*T_BG;

% Points are locations defined by a transformation matrix (they have both position and orientation)
%   Particles are points that have mass
%   Rigid bodies are points that have mass and moment of inertia
% NOTE
%   Even though point C is fixed, it is only fixed by constraints, so it needs to be given mass to have a happy solver
mass = 1; % [kg]
momentOfInertia = [.2, .2, .2]; % [kg*m^2]
A = sys.CreatePoint('A', 1);
B = sys.CreatePoint('B', mass, momentOfInertia).SetT_0n(T_AB);
C = sys.CreatePoint('C', 1).SetT_0n(T_AC);
G = sys.CreatePoint('G', mass, momentOfInertia).SetT_0n(T_AG);

% Kinematic chains (used only for plotting the animation)
%   2 separate chains are defined
sys.SetChains([A,B,C], [B,G]);

% Direction of gravity in base frame
sys.SetGravity([0; -g; 0]);

% Constraints
% 1) The length of the rope is constant
% 2,3) End point must be fixed in-place
sys.CreateConstraint("rope").SetConstraint(L1 + L2, "offsetToIC");
sys.CreateConstraint("endX").SetConstraint( T_AC.x, "offsetToIC");
sys.CreateConstraint("endY").SetConstraint( T_AC.y, "offsetToIC");
sys.SetConstraint_StabilisationFactors();

%**********************************************************************
% Solve
%***********************************
SO = CDS_Solver_Options();
SO.time = 0 : 0.02 : 20;
SO.RelTol = 1e-8;
SO.AbsTol = 1e-8;

% Generate and solve equation of motion
S = CDS_Solver(SO);
[t,x,xd] = S.Solve(sys);

%**********************************************************************
% Output
%***********************************
SS = CDS_SolutionSim(sys, t, x, xd);
SSp = CDS_Solution_Plot(SS);
SSe = CDS_Solution_Export(SS);
SSa = CDS_Solution_Animate(SS);
SSg = CDS_Solution_GetData(SS);

SSp.PlotConfigSpace
SSp.PlotConstraintViolation
SSp.PlotEnergyTotal
SSp.PlotEnergyAll
SSp.PlotTaskSpace
SSa.Animate




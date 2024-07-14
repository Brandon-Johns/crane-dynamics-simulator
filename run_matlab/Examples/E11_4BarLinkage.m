%{
Written By: Brandon Johns
Date Version Created: 2024-04-05
Date Last Edited: 2024-04-05
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Example Simulation: 4-non-parallel-bar linkage


%%% SYSTEM DESCRIPTION %%%
4-bar-linkage with unequal-length bars.
The top bar is fixed in space
The bottom bar is given mass and moment of inertia

Parameters / Variables
    theta_1 = angle of link AB from vertical
    theta_2 = angle
    theta_3 = angle
    L_AB = length between A and B (length of the 1st link)
    L_BC = length between B and C (length of the 2nd link)
    L_CD = length between C and D (length of the 3rd link)
    L_AD = length between D and A (length of the 4th link)
    g = gravity

Locations
    A: stationary joint
    B: joint
    C: joint
    D: stationary joint
    G: centre of mass of link BC

Diagram
    A-----D
    |    /
    B---C

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
params = CDS_Params();
points = CDS_Points(params);

% Generalised coordinates and system parameters
params.Create('free', 'theta_1').SetIC( deg2rad(50) );
params.Create('free', 'theta_2').SetIC( deg2rad(0) );
params.Create('const', 'L_AB').SetNum(1);
params.Create('const', 'L_BC').SetNum(1.5);
params.Create('const', 'L_AD').SetNum(2);
params.Create('const', 'g').SetNum(9.8);

% Forward transformations as homogeneous transformation matrices
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

% Solve dependent transformations - Solved by hand
theta_3 = atan2(T_CD.y, T_CD.x);
L_CD = simplify(expand( sqrt(T_CD.y^2 + T_CD.x^2) ));

% Forward transforms in terms of independent variables
T_CC2 = CDS_T('atP', 'z', theta_3, [0;0;0]);
T_C2D = CDS_T('atP', 'z', 0, [L_CD;0;0]);

% Combine
T_AB = T_AA2*T_A2B;
T_AC = T_AB*T_BC;
T_AD = T_AC*T_CC2*T_C2D;
T_AG = T_AB*T_BG;

% Points are locations defined by a transformation matrix (they have both position and orientation)
%   Particles are points that have mass
%   Rigid bodies are points that have mass and moment of inertia
mass = 1; % [kg]
momentOfInertia = [1,1,1]; % [kg*m^2]
A = points.Create('A');
B = points.Create('B').SetT_0n(T_AB);
C = points.Create('C').SetT_0n(T_AC);
D = points.Create('D').SetT_0n(T_AD);
G = points.Create('G', mass, momentOfInertia).SetT_0n(T_AG);

% Kinematic chains (used only for plotting the animation)
chains = {[A,B,C,D]};

% Direction of gravity in base frame
g0 = [0; -g; 0];

% This holds the complete system description
sys = CDS_SystemDescription(params, points, chains, g0);

% If the bars are parallel, this constraint allows the bars to invert when passing through singularity (@theta1 = 0.5*pi)
% This can make the equations stiff
sys.SetConstraint(L_CD);


%**********************************************************************
% Solve
%***********************************
SO = CDS_Solver_Options();
SO.time = 0 : 0.02 : 10;
SO.RelTol = 1e-8;
SO.AbsTol = 1e-8;
%SO.EventsIsActive = true;

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
SSp.PlotEnergyTotal
SSp.PlotEnergyAll
SSp.PlotTaskSpace
SSa.Animate




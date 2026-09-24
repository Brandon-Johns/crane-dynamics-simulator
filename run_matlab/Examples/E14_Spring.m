%{
Written By: Brandon Johns
Date Version Created: 2024-07-21
Date Last Edited: 2024-08-30
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Example Simulation: A falling particle attached to a spring


%%% SYSTEM DESCRIPTION %%%
A particle is released from rest
It then accelerates downward due to gravity
It oscillates due to the spring

Parameters / Variables
    Ly = height of the particle
    g = gravity
    k = spring constant
    Ln = spring natural length

Locations
    O: stationary origin
    A: particle

Diagram
    A
    |
  spring
    |
    O

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
params.Create('free', 'Ly').SetIC(6);
params.Create('const', 'g').SetNum(9.8);
params.Create('const', 'k').SetNum(10);
params.Create('const', 'Ln').SetNum(5);

% Forward transformations as homogeneous transformation matrices
T_OA = CDS_T('P', [0;Ly;0]);

% Points are locations defined by a transformation matrix (they have both position and orientation)
%   Particles are points that have mass
%   Rigid bodies are points that have mass and moment of inertia
mass = 1; % [kg]
O = sys.CreatePoint('O');
A = sys.CreatePoint('A', mass).SetT_0n(T_OA);

% Direction of gravity in base frame
sys.SetGravity([0; -g; 0]);

% Linear springs
%   The 2 following implementations are not necessarily the same
%   They behave differently if the spring length goes negative
sys.CreateLinearSpring("OA").SetLength(Ly, A).SetSpringConstant(k).SetNaturalLength(Ln);
%sys.CreateLinearSpring("OA").SetConnections(A).SetSpringConstant(k).SetNaturalLength(Ln);


%**********************************************************************
% Solve
%***********************************
SO = CDS_Solver_Options();
SO.time = 0 : 0.02 : 5;
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
SSp.PlotEnergyTotal
SSp.PlotEnergyAll
SSp.PlotTaskSpace
SSa.Animate



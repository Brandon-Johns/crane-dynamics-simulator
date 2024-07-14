%{
Written By: Brandon Johns
Date Version Created: 2024-03-19
Date Last Edited: 2024-04-01
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Example Simulation: A free-falling particle


%%% SYSTEM DESCRIPTION %%%
A particle is released from rest
It then free-falls with constant downward acceleration due to gravity

Parameters / Variables
    Ly = height of the particle
    g = gravity

Locations
    O: stationary origin
    A: particle

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
params.Create('free', 'Ly').SetIC(0);
params.Create('const', 'g').SetNum(9.8);

% Forward transformations as homogeneous transformation matrices
T_OA = CDS_T('P', [0;Ly;0]);

% Points are locations defined by a transformation matrix (they have both position and orientation)
%   Particles are points that have mass
%   Rigid bodies are points that have mass and moment of inertia
mass = 1; % [kg]
A = points.Create('A', mass).SetT_0n(T_OA);

% Kinematic chains (used only for plotting the animation)
chains = {A};

% Direction of gravity in base frame
g0 = [0; -g; 0];

% This holds the complete system description
sys = CDS_SystemDescription(params, points, chains, g0);


%**********************************************************************
% Solve
%***********************************
SO = CDS_Solver_Options();
SO.time = 0 : 0.02 : 2;
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



%{
Written By: Brandon Johns
Date Version Created: 2024-04-05
Date Last Edited: 2024-04-05
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Example Simulation: 3D rigid-body pendulum


%%% SYSTEM DESCRIPTION %%%


Parameters / Variables
    theta_yaw  = angle of rotation about the vertical axis
    theta_sway = angle of rotation away from the negative vertical axis
    theta_twist = angle of rotation about the link
    L_OA = length to the centre of mass of the pendulum rod
    g = gravity

Locations
    O: stationary origin
    A: pendulum bob
    B: massless marker to show the orientation of the bob

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
params.Create('free', 'theta_yaw').SetIC(0, 5); % Initial angular velocity
params.Create('free', 'theta_sway').SetIC(deg2rad(60));
params.Create('free', 'theta_twist').SetIC(0);
params.Create('const', 'L_OA').SetNum(1);
params.Create('const', 'g').SetNum(9.8);

% Forward transformations as homogeneous transformation matrices
T_OO1 = CDS_T('at', 'y', theta_yaw);
T_O1O2 = CDS_T('at', 'z', theta_sway - pi/2);
T_O2O3 = CDS_T('at', 'x', theta_twist);
T_3OA = CDS_T('P', [L_OA;0;0]);
T_AB = CDS_T('P', [0;0.2;0]);

T_OA = T_OO1 * T_O1O2 * T_O2O3 * T_3OA;
T_OB = T_OA * T_AB;

% Points are locations defined by a transformation matrix (they have both position and orientation)
%   Particles are points that have mass
%   Rigid bodies are points that have mass and moment of inertia
mass = 1; % [kg]
momentOfInertia = [1,1,1]; % [kg*m^2]
O = points.Create('O');
A = points.Create('A', mass, momentOfInertia).SetT_0n(T_OA);
B = points.Create('B').SetT_0n(T_OB);

% Kinematic chains (used only for plotting the animation)
chains = {[O,A,B]};

% Direction of gravity in base frame
g0 = [0; -g; 0];

% This holds the complete system description
sys = CDS_SystemDescription(params, points, chains, g0);


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

SSa.Set_View_Predefined("side")
SSa.Animate
view([0,4,-20])



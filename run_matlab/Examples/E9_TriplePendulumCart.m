%{
Written By: Brandon Johns
Date Version Created: 2024-04-05
Date Last Edited: 2024-04-05
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Example Simulation: Triple point-mass pendulum cart


%%% SYSTEM DESCRIPTION %%%
Triple point-mass pendulum attached at the top to a cart that can roll in the horizontal plane

Parameters / Variables
    theta1 = angle between the 1st pendulum link and the vertical
    theta2 = angle between the 2nd pendulum link and the 1st
    theta3 = angle between the 3rd pendulum link and the 2nd
    d_OA = displacement of A from O (displacement of the cart)
    L_AB = length between A and B (length of the 1st link)
    L_BC = length between B and C (length of the 2nd link)
    L_CD = length between C and D (length of the 3rd link)
    g = gravity

Locations
    O: stationary origin
    A: cart
    B: pendulum bob 1
    C: pendulum bob 2
    D: pendulum bob 3

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
params.Create('free', 'theta_1').SetIC(pi/4);
params.Create('free', 'theta_2').SetIC(0);
params.Create('free', 'theta_3').SetIC(0);
params.Create('free', 'd_OA').SetIC(0);
params.Create('const', 'L_AB').SetNum(1);
params.Create('const', 'L_BC').SetNum(1);
params.Create('const', 'L_CD').SetNum(1);
params.Create('const', 'g').SetNum(9.8);

% Forward transformations as homogeneous transformation matrices
T_OA = CDS_T('P', [d_OA;0;0]);
T_AA2 = CDS_T('atP', 'z', theta_1-sym(pi)/2, [0;0;0]);
T_A2B = CDS_T('atP', 'z', theta_2, [L_AB;0;0]);
T_BC  = CDS_T('atP', 'z', theta_3, [L_BC;0;0]);
T_CD  = CDS_T('atP', 'z', 0, [L_CD;0;0]);

T_OB = T_OA * T_AA2 * T_A2B;
T_OC = T_OB * T_BC;
T_OD = T_OC * T_CD;

% Points are locations defined by a transformation matrix (they have both position and orientation)
%   Particles are points that have mass
%   Rigid bodies are points that have mass and moment of inertia
mass = 1; % [kg]
O = points.Create('O');
A = points.Create('A', mass).SetT_0n(T_OA);
B = points.Create('B', mass).SetT_0n(T_OB);
C = points.Create('C', mass).SetT_0n(T_OC);
D = points.Create('D', mass).SetT_0n(T_OD);

% Kinematic chains (used only for plotting the animation)
chains = {[A,B,C,D]};

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
SSa.Animate




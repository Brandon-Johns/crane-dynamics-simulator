%{
Written By: Brandon Johns
Date Version Created: 2026-09-21
Date Last Edited: 2026-09-21
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Control Systems Simulation
    Point-mass inverted pendulum cart
    with manually tuned PD Controller
    and random disturbance force


%%% SYSTEM DESCRIPTION %%%
Point-mass pendulum attached at the top to a cart that can roll in the horizontal plane
Control force applied to the cart
Disturbance force applied to the pendulum bob

Parameters / Variables
    theta1 = angle between the 1st pendulum link and the vertical
    d_OA = displacement of A from O (displacement of the cart)
    L_AB = length between A and B (length of the 1st link)
    g = gravity

Locations
    O: stationary origin
    A: cart
    B: pendulum bob 1

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
SO = CDS_Solver_Options();
SO.time = 0 : 0.02 : 15;

sys = CDS_SystemDescription();
params = sys.params;

% Generalised coordinates and system parameters
params.Create('free', 'theta_1').SetIC(pi/8);
params.Create('free', 'd_OA').SetIC(0);
params.Create('const', 'L_AB').SetNum(1);
params.Create('const', 'g').SetNum(9.8);

% Forward transformations as homogeneous transformation matrices
T_OA = CDS_T('P', [d_OA;0;0]);
T_AA2 = CDS_T('atP', 'z', theta_1+sym(pi)/2, [0;0;0]);
T_A2B = CDS_T('P', [L_AB;0;0]);

T_OB = T_OA * T_AA2 * T_A2B;

% Points are locations defined by a transformation matrix (they have both position and orientation)
%   Particles are points that have mass
%   Rigid bodies are points that have mass and moment of inertia
mass = 1; % [kg]
O = sys.CreatePoint('O');
A = sys.CreatePoint('A', mass).SetT_0n(T_OA);
B = sys.CreatePoint('B', mass).SetT_0n(T_OB);

% Kinematic chains (used only for plotting the animation)
sys.SetChains([A,B]);

% Direction of gravity in base frame
sys.SetGravity([0; -g; 0]);


% Disturbance force
maxFrequency = 5;
amplitude = 5;
disturbance_spline = CDSu_RandSignal().SetRandSeed(0).GenerateSignal_PP(SO.time, maxFrequency, amplitude);
params.Create('input', 'f_dist').SetSpline(disturbance_spline);

sys.CreateGeneralisedForce("disturbance").SetLocation(theta_1).SetQ(f_dist);

% PD Controller
syms theta_1d d_OAd
kp = 200;
kd = 10;
kp_cart = -5;
kd_cart = -7;
Q = - kp*theta_1 - kd*theta_1d - kp_cart*d_OA - kd_cart*d_OAd;

sys.CreateGeneralisedForce("controller").SetLocation(d_OA).SetQ(Q);


%**********************************************************************
% Solve
%***********************************
SO.RelTol = 1e-8;
SO.AbsTol = 1e-8;
SO.EventsIsActive = true;

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
SSp.PlotForces
SSa.Animate




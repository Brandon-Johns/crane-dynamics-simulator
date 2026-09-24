%{
Written By: Brandon Johns
Date Version Created: 2024-09-02
Date Last Edited: 2024-09-13
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Example Simulation:
    Damped harmonic motion
    Mass connected to ground by parallel spring and damper


%%% SYSTEM DESCRIPTION %%%
A particle is released from rest
It then accelerates downward due to gravity
It oscillates due to the spring
It slows due to a linear damper
It is driven by an external force

Parameters / Variables
    Ly = height of the particle
    g = gravity
    k = spring constant
    Ln = spring natural length
    b = damping constant
    F1 = arbitrary external force acting upward on the mass

Locations
    O: stationary origin
    A: particle

Equation of motion
    m*x_dd + b*x_d + k*x = k*Ln - m*g + F1, where F1 is a constant

Diagram
    ^ F
    |
  -----
  | m |
  -----
  |   |
  b   k
  |   |
  -----
  /////

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
syms t real
params.Create('free', 'Ly').SetIC(3, 2);
params.Create('const', 'g').SetNum(9.8);
params.Create('const', 'k').SetNum(10);
params.Create('const', 'Ln').SetNum(5);
params.Create('const', 'b').SetNum(0.5);

% Forward transformations as homogeneous transformation matrices
T_OA = CDS_T('P', [0;Ly;0]);

% Points are locations defined by a transformation matrix (they have both position and orientation)
%   Particles are points that have mass
%   Rigid bodies are points that have mass and moment of inertia
mass = 1; % [kg]
O = sys.CreatePoint('O');
A = sys.CreatePoint('A', mass).SetT_0n(T_OA);

% Kinematic chains (used only for plotting the animation)
sys.SetChains([O,A]);

% Direction of gravity in base frame
sys.SetGravity([0; -g; 0]);

% Linear springs
%   The 2 following implementations are not necessarily the same
%   They behave differently if the spring length goes negative
sys.CreateLinearSpring("OA").SetLength(Ly, A).SetSpringConstant(k).SetNaturalLength(Ln);
%sys.CreateLinearSpring("OA").SetConnections(A).SetSpringConstant(k).SetNaturalLength(Ln);

% Linear dampers
%   The 3 following implementations are effectively the same
sys.CreateLinearDamper("OA").SetVelocity(sys.params.Subset(Ly).Sym(1), Ly, A).SetDampingConstant(b);
%sys.CreateLinearDamper("OA").SetLength(Ly, A).SetDampingConstant(b);
%sys.CreateLinearDamper("OA").SetConnections(A).SetDampingConstant(b);

% Point Forces: Force acting upwards on the mass [N]
% Try changing this!
F1 = 1;
F1 = -50*Ly;
F1 = 2*sin(t);
F1 = t;
sys.CreatePointForce("A").SetLocation(A).SetF([0;F1;0]);


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
SSp.PlotEnergyTotal
SSp.PlotEnergyAll
SSp.PlotTaskSpace
SSa.Animate



%{
Written By: Brandon Johns
Date Version Created: 2024-04-05
Date Last Edited: 2024-10-06
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Example Simulation:
    Particle on a path
    Variant using Ly as a dependent variable


%%% SYSTEM DESCRIPTION %%%
A particle is constrained to move along a path

Parameters / Variables
    Lx = horizontal position of the particle
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
sys = CDS_SystemDescription();
params = sys.params;

% Generalised coordinates and system parameters
params.Create('free', 'Lx').SetIC(1);
params.Create('const', 'g').SetNum(9.8);

% Dependent variables
syms t real
Ly = Lx^2*t;
%Ly = (Lx-.8)*(Lx-.5)*(Lx+.5)*(Lx+.8);
%Ly = sin(Lx) + 0.2*Lx;

% Forward transformations as homogeneous transformation matrices
T_OA = CDS_T('P', [Lx;Ly;0]);

% Points are locations defined by a transformation matrix (they have both position and orientation)
%   Particles are points that have mass
%   Rigid bodies are points that have mass and moment of inertia
mass = 1; % [kg]
A = sys.CreatePoint('A', mass).SetT_0n(T_OA);

% Kinematic chains (used only for plotting the animation)
sys.SetChains(A);

% Direction of gravity in base frame
sys.SetGravity([0; -g; 0]);


%**********************************************************************
% Solve
%***********************************
SO = CDS_Solver_Options();
SO.time = 0 : 0.02 : 10;
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

% Plot constraint path
minX = min(SS.Px,[],'all');
maxX = max(SS.Px,[],'all');
spanX = maxX - minX;
minX_padded = minX - 0.2*spanX;
maxX_padded = maxX + 0.2*spanX;
path_x = linspace(minX_padded, maxX_padded, 100);

path_y_fun = matlabFunction(Ly, "Vars",{Lx,sym('t','real')});
path_y_fun_t = @(t_) path_y_fun(path_x, t_);
path_z = zeros(size(path_x));

SSa.Add_Curve(path_x, path_y_fun_t, path_z);

SSp.PlotConfigSpace
SSp.PlotEnergyTotal
SSp.PlotEnergyAll
SSp.PlotTaskSpace
SSa.Animate

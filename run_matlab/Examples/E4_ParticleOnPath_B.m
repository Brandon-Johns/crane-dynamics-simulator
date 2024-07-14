%{
Written By: Brandon Johns
Date Version Created: 2024-04-05
Date Last Edited: 2024-04-05
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Example Simulation:
    Particle on a path
    Variant using a constraint equation


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
params = CDS_Params();
points = CDS_Points(params);

% Generalised coordinates and system parameters
params.Create('free', 'Lx').SetIC(1);
params.Create('free', 'Ly'); % Defer setting the initial condition
params.Create('const', 'g').SetNum(9.8);

% Constraint equation
%constraint = Ly - Lx^2;
constraint = Ly - (Lx-.8)*(Lx-.5)*(Lx+.5)*(Lx+.8);
%constraint = Ly - sin(Lx) + 0.2*Lx;

% Forward transformations as homogeneous transformation matrices
T_OA = CDS_T('P', [Lx;Ly;0]);

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

% Apply the constraint equation
sys.SetConstraint(constraint);

% Initial conditions should be consistent with the constraint
constraint_y = solve(constraint, Ly);
path_y_fun = matlabFunction(constraint_y, "Vars",Lx);
params.Param("Ly").SetIC( path_y_fun(params.Param("Lx").q0) );


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

SSp.PlotConfigSpace
SSp.PlotEnergyTotal
SSp.PlotEnergyAll
SSp.PlotTaskSpace
SSa.Animate


% Plot constraint path
min_x = min(SSg.q("Lx"));
max_x = max(SSg.q("Lx"));
range_x = max_x - min_x;
path_x = linspace(min_x-0.1*range_x, max_x+0.1*range_x, 1000);

path_y = double(path_y_fun(path_x));

hold on
plot(path_x, path_y)


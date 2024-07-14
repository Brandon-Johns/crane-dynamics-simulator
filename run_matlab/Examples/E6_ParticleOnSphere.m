%{
Written By: Brandon Johns
Date Version Created: 2024-04-05
Date Last Edited: 2024-04-05
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Example Simulation:
    Particle on the surface of a sphere


%%% SYSTEM DESCRIPTION %%%
A particle is constrained to move on the surface of a sphere
It is not able to fall inwards, but may travel on the upper hemisphere

Parameters / Variables
    Lx,Ly,Lz = position of the particle (For this simulation, Lz is up!)
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
params.Create('free', 'Lx').SetIC(0.9);
params.Create('free', 'Ly').SetIC(0, 1); % Initial velocity
params.Create('free', 'Lz'); % Defer setting the initial condition
params.Create('const', 'g').SetNum(9.8);

% Constraint equation
%   Equation for sphere: 1 = Lx^2 + Ly^2 + Lz^2
%   Equation for hemisphere
%       (upper): Lz =  sqrt(1 - Lx^2 - Ly^2)
%       (lower): Lz = -sqrt(1 - Lx^2 - Ly^2)
%   In this case, solving the constraint equation in terms of Lz would invalidate the geometry
%   Hence, this constraint can not be rewritten as a dependent variable (see: Example 3 vs Example 4)
%   But when given as a constraint equation, it just works
%   Alternatively, working in spherical coordinates could bypass this issue
constraint = 1 - (Lx^2 + Ly^2 + Lz^2);

% Forward transformations as homogeneous transformation matrices
T_OA = CDS_T('P', [Lx;Ly;Lz]);

% Points are locations defined by a transformation matrix (they have both position and orientation)
%   Particles are points that have mass
%   Rigid bodies are points that have mass and moment of inertia
mass = 1; % [kg]
A = points.Create('A', mass).SetT_0n(T_OA);

% Kinematic chains (used only for plotting the animation)
chains = {A};

% Direction of gravity in base frame
g0 = [0; 0; -g];

% This holds the complete system description
sys = CDS_SystemDescription(params, points, chains, g0);

% Apply the constraint equation
sys.SetConstraint(constraint);

% Initial conditions should be consistent with the constraint
constraint_z = solve(constraint, Lz); % Has 2 solutions (upper or lower hemisphere)
constraint_z = constraint_z(1); % Take the a solution
path_z_fun = matlabFunction(constraint_z, "Vars",[Lx,Ly]);
Lz_IC_upperHemisphere =  abs( path_z_fun(params.Param("Lx").q0, params.Param("Ly").q0) );

% Choose one
params.Param("Lz").SetIC(  Lz_IC_upperHemisphere ); % Z starts on upper hemisphere
%params.Param("Lz").SetIC( -Lz_IC_upperHemisphere ); % Z starts on lower hemisphere


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

SSa.Set_View_Predefined("3D-1")
SSa.Animate

% Plot surface
[meshX,meshY] = meshgrid(-1:0.02:1, -1:0.02:1);
meshZ = path_z_fun(meshX, meshY);
meshZ(imag(meshZ)~=0) = nan; % Remove complex values
meshZ = real(meshZ);

hold on
surf(meshX,meshY,meshZ, 'LineStyle','none', 'FaceAlpha',0.5)
view([18,7,7])
camup([0,0,1]);


%{
Written By: Brandon Johns
Date Version Created: 2024-09-02
Date Last Edited: 2024-09-02
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Example Simulation: Rigid body rotates about spring-loaded pin joint


%%% SYSTEM DESCRIPTION %%%
A rigid body is constrained to rotate about pin joint
It rotates in the horizontal plane (no gravity)
It oscillates due to a torsion spring on the pin joint

The moment of inertia is dependent on
    The moment of inertia about the centre of mass of the body
    The radius of the centre of mass from the centre of rotation
    i.e.
        Izz_total = Izz + m*r^2;
    This is equivalent to using the parallel axis theorem

For this simulation, z is up!

Parameters / Variables
    theta = angle of the rigid body
    L1 = length of the rigid body
    g = gravity
    k = spring constant
    thetaN = spring natural angle

Locations
    O: stationary origin (pin joint)
    A: centre of mass of the rigid body

Diagram
    |
    A
    |
    O(with torsion spring)

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
params.Create('free', 'theta').SetIC(deg2rad(45));
params.Create('const', 'L1').SetNum(1);
params.Create('const', 'g').SetNum(9.8);
params.Create('const', 'k').SetNum(10);
params.Create('const', 'thetaN').SetNum(deg2rad(0));

% Forward transformations as homogeneous transformation matrices
T_OO2 = CDS_T('at', 'z', theta);
T_O2A = CDS_T('P', [L1;0;0]);
T_OA = T_OO2 * T_O2A;

% Points are locations defined by a transformation matrix (they have both position and orientation)
%   Particles are points that have mass
%   Rigid bodies are points that have mass and moment of inertia
mass = 1; % [kg]
momentOfInertia = [1,1,1]; % [kg*m^2]
O = sys.CreatePoint('O');
A = sys.CreatePoint('A', mass, momentOfInertia).SetT_0n(T_OA);

% Kinematic chains (used only for plotting the animation)
sys.SetChains([O,A]);

% Direction of gravity in base frame
sys.SetGravity([0; 0; -g]);

% Torsion springs
sys.CreateTorsionSpring("OA").SetAngle(theta).SetSpringConstant(k).SetNaturalAngle(thetaN);


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
SSa.Set_View_Predefined("front")

SSp.PlotConfigSpace
SSp.PlotEnergyTotal
SSp.PlotEnergyAll
SSp.PlotTaskSpace
SSa.Animate



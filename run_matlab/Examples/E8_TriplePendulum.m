%{
Written By: Brandon Johns
Date Version Created: 2024-04-01
Date Last Edited: 2024-04-01
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Example Simulation: Triple point-mass pendulum

This example relates to "README-Tutorial.md"


%%% SYSTEM DESCRIPTION %%%
Triple point-mass pendulum attached at the top to a stationary point

Parameters / Variables
    theta1 = angle between the 1st pendulum link and the vertical
    theta2 = angle between the 2nd pendulum link and the 1st
    theta3 = angle between the 3rd pendulum link and the 2nd
    L_1 = length between O and A (length of the 1st link)
    L_2 = length between A and B (length of the 2nd link)
    L_3 = length between B and C (length of the 3rd link)
    g = gravity

Locations
    O: stationary origin
    A: pendulum bob 1
    B: pendulum bob 2
    C: pendulum bob 3

%}
close all
clear all
clc
CDS_FindIncludes;
CDS_IncludeSimulator;

%**********************************************************************
% Define System
%***********************************
% Builder/manager object
params = CDS_Params();

% System parameters
%   Define and set the numeric value
params.Create('const', 'L_1').SetNum(1);
params.Create('const', 'L_2').SetNum(1);
params.Create('const', 'L_3').SetNum(1);
params.Create('const', 'g').SetNum(9.8);

% Generalised coordinates
%   Define and set the initial conditions
params.Create('free', 'theta_1').SetIC(pi/4);
params.Create('free', 'theta_2').SetIC(0);
params.Create('free', 'theta_3').SetIC(0);

% Forward kinematics between the frames
% NOTE: Using shorthand notation. See the aside for explanation
T_OO2 = CDS_T('atP', 'z', theta_1-sym(pi)/2, [0;0;0]);
T_O2A = CDS_T('atP', 'z', theta_2, [L_1;0;0]);
T_AB  = CDS_T('atP', 'z', theta_3, [L_2;0;0]);
T_BC  = CDS_T('atP', 'z', 0, [L_3;0;0]);

% Combine to obtain the transformation to each frame as relative to the base frame
T_OA = T_OO2 * T_O2A;
T_OB = T_OA * T_AB;
T_OC = T_OB * T_BC;

% Builder/manager object
points = CDS_Points(params);

% SYNTAX: .Create('Name', mass, inertia)
O = points.Create('O');
A = points.Create('A', 1).SetT_0n(T_OA);
B = points.Create('B', 1).SetT_0n(T_OB);
C = points.Create('C', 1).SetT_0n(T_OC);

% Kinematic chains (used only for plotting the animation)
chains = {[O,A,B,C]};

% Direction of gravity in base frame
g0 = [0; -g; 0];

% System description
% This contains all of the information required to simulate the system
sys = CDS_SystemDescription(params, points, chains, g0);


%**********************************************************************
% Solve
%***********************************
SO = CDS_Solver_Options();
SO.time = 0 : 0.02 : 20;
SO.RelTol = 1e-10;
SO.AbsTol = 1e-10;

% Generate and solve equation of motion
S = CDS_Solver(SO);
[t,x,xd] = S.Solve(sys);


%**********************************************************************
% Output
%***********************************
SS = CDS_SolutionSim(sys, t,x,xd);
SSp = CDS_Solution_Plot(SS);
SSa = CDS_Solution_Animate(SS);

SSp.PlotConfigSpace
SSp.PlotLambda
SSp.PlotInput
SSp.PlotEnergyTotal
SSp.PlotEnergyAll
SSp.PlotTaskSpace

SSa.Set_View_Predefined("front")
SSa.PlotFrame
SSa.Animate("play") % Click the "Repeat" button on the figure to play the animation!
%SSa.Animate("gif")
%SSa.Animate("video")

% Export
%SSe = CDS_Solution_Export(SS);
%SSe.DataToExcel("mySolution.xlsx");

SSg = CDS_Solution_GetData(SS);

% Get the value of theta_2, and its derivatives at the time 3.8 seconds
idx = SSg.t_idx(3.8);
fprintf("theta_2 at 3.8s = %g\n",           SSg.q("theta_2", idx));
fprintf("d[theta_2]/dt at 3.8s = %g\n",     SSg.qd("theta_2", idx));
fprintf("d^2[theta_2]/dt^2 at 3.8s = %g\n", SSg.qdd("theta_2", idx));

% Get the x,y,z locations of each point at this same time
fprintf("x coordinate of point C at 3.8s = %g\n", SSg.Px("C", idx));
fprintf("y coordinate of point C at 3.8s = %g\n", SSg.Py("C", idx));
fprintf("z coordinate of point C at 3.8s = %g\n", SSg.Pz("C", idx));


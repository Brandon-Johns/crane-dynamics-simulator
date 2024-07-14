%{
Written By: Brandon Johns
Date Version Created: 2021-08-03
Date Last Edited: 2024-04-08
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Compare scale model for how mass and time should be scaled

Results
    mass : length^3
    time : sqrt(length)

    (given that gravity is not changed during scaling)


%%% SYSTEM DESCRIPTION %%%
Pendulum-cart


%}
close all
clear all
clc
sympref('AbbreviateOutput',false);
sympref('MatrixWithSquareBrackets',true);
CDS_FindIncludes;
CDS_IncludeSimulator;


%**********************************************************************
% Scale the System
%***********************************
% Scaling problem:
% Period (Small angle approx): T_approx = 2*pi*sqrt(l/g)
% but gravity is fixed in real and experiment
% => must scale solution time
% RIP

% Change this!
scale = 1; % Length scale factor


% Automatic
d_OA_max_num = (1/5)*scale;
L_AB_num = 1*scale;
Bx_num = 0.25*scale;
By_num = 0.25*scale;
Bz_num = 0.25*scale;
B_density_num = 1;

m_B_num = B_density_num*Bx_num*By_num*Bz_num;
I_B_num = (1/12)*m_B_num*[...
    By_num^2+Bz_num^2,...
    Bx_num^2+Bz_num^2,...
    Bx_num^2+By_num^2];

syms t
t_scale = t/sqrt(scale); % Must replace all 't' with 't_scale'
t_max = 20*sqrt(scale);


%**********************************************************************
% Define System
%***********************************
params = CDS_Params();
points = CDS_Points(params);

params.Create('free', 'theta_1').SetIC(pi-1);
params.Create('input', 'd_OA').SetAnalytic((t_scale*d_OA_max_num)*sin(2*t_scale));
params.Create('const', 'L_AB').SetNum(L_AB_num);
params.Create('const', 'g').SetNum(9.8);

% Direction of gravity in base frame
g0 = [0; -g; 0];

% Forward transformations
T_OA = CDS_T('atP', 'z', 0, [d_OA;0;0]); % With control input
%T_OA = CDS_T('atP', 'z', 0, [0;0;0]); % No control input

T_AA2 = CDS_T('atP', 'z', theta_1-sym(pi)/2, [0;0;0]);
T_A2B = CDS_T('atP', 'z', 0, [L_AB;0;0]);

T_OB = T_OA*T_AA2*T_A2B;

O = points.Create('O');
A = points.Create('A').SetT_0n(T_OA);
B = points.Create('B', m_B_num, I_B_num).SetT_0n(T_OB);

chains = {[O,A,B]};
sys = CDS_SystemDescription(params, points, chains, g0);


%**********************************************************************
% Solve
%***********************************
SO = CDS_Solver_Options();
SO.time = [0,t_max];

S = CDS_Solver(SO);
[t,x,xd] = S.Solve(sys);


%**********************************************************************
% Output
%***********************************
SS = CDS_SolutionSim(sys, t,x,xd);
SSp = CDS_Solution_Plot(SS);

SSp.PlotConfigSpace
SSp.PlotInput
SSp.PlotEnergyTotal



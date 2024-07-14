%{
Written By: Brandon Johns
Date Version Created: 2023-11-21
Date Last Edited: 2024-04-06
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Example Simulation:
    Particle on a path
    I tried out lots of different paths that look cool


%%% SYSTEM DESCRIPTION %%%
A particle is constrained to move along a path

Parameters / Variables
    (L_OA, theta_1) = particle location in polar coordinates
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


syms L_OA theta_1

Run( L_OA - 1 );                             % Circle
Run( L_OA*50 - theta_1 - theta_1^2 );        % Roller coaster - slanted
Run( L_OA*500 - 100*theta_1 + theta_1^2 );   % Roller coaster
Run( L_OA - 2*(0.95 - cos(theta_1)) );       % Cardioid
Run( L_OA - 2*(0.7 - cos(theta_1+pi/2)) );   % Lowercase omega
Run( L_OA - 2*(0.55 - sqrt((sin(theta_1))^2) ) );       % Teardrop
Run( L_OA - cos(theta_1)^2 + sin(theta_1)^2 );          % Teardrop V2
Run( L_OA - 2*cos(theta_1)^2 - sin(theta_1)^2 );        % IDK, but it looks really cool!
Run( L_OA/2 - cos(cos(theta_1)^2 - sin(theta_1)^2) );   % Almost butterfly
Run( L_OA/2 - cos(cos(theta_1)^2 - 2*sin(theta_1)^2) ); % Butterfly
Run( L_OA*0.8 - cos(cos(theta_1)^2 - 2*sin(theta_1)^2) - 0.05*theta_1 ); % Butterflies


function Run(constraint)
    %**********************************************************************
    % Define System
    %***********************************
    params = CDS_Params();
    points = CDS_Points(params);

    % Generalised coordinates and system parameters
    params.Create('free', 'L_OA'); % Constrained link. Defer setting IC
    params.Create('const', 'g').SetNum(9.8);
    params.Create('free', 'theta_1').SetIC(deg2rad(400));

    % Forward transformations as homogeneous transformation matrices
    T_OO2 = CDS_T('atP', 'z', theta_1, [0;0;0]);
    T_O2A = CDS_T('atP', 'z', 0, [L_OA;0;0]);

    T_OA = T_OO2*T_O2A;

    % Points are locations defined by a transformation matrix (they have both position and orientation)
    %   Particles are points that have mass
    %   Rigid bodies are points that have mass and moment of inertia
    mass = 1;
    O = points.Create('O');
    A = points.Create('A', mass).SetT_0n(T_OA);

    % Kinematic chains (used only for plotting the animation)
    chains = {[O,A]};

    % Direction of gravity in base frame
    g0 = [0; -g; 0];

    sys = CDS_SystemDescription(params, points, chains, g0);
    sys.SetConstraint(constraint);

    % Initial conditions should be consistent with the constraint
    constraint_L = solve(constraint, L_OA);
    path_L_fun = matlabFunction(constraint_L, "Vars",theta_1);
    params.Param("L_OA").SetIC(path_L_fun(params.Param("theta_1").q0));


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
    SS = CDS_SolutionSim(sys, t,x,xd);
    SSa = CDS_Solution_Animate(SS);
    SSg = CDS_Solution_GetData(SS);

    SSa.Set_View_Predefined("front")
    SSa.Animate

    % Plot constraint path
    min_theta = min(SSg.q("theta_1"));
    max_theta = max(SSg.q("theta_1"));
    range_theta = max_theta - min_theta;
    path_theta = min_theta-0.1*range_theta : 0.05 : max_theta+0.1*range_theta;

    path_x_fun = matlabFunction(T_OA.x, "Vars",[L_OA; theta_1]);
    path_y_fun = matlabFunction(T_OA.y, "Vars",[L_OA; theta_1]);
    path_L = double(path_L_fun(path_theta));
    path_x = double(path_x_fun(path_L, path_theta));
    path_y = double(path_y_fun(path_L, path_theta));

    hold on
    plot(path_x, path_y)
end




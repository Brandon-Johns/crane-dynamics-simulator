%{
Written By: Brandon Johns
Date Version Created: 2024-03-31
Date Last Edited: 2024-12-30
Status: Functional
Simulator: CDS

%%% PURPOSE %%%
Run all integration tests


%%% NOTES %%%
Due to the use of ODE solvers and assertions based on integration error
    It is possible that these tests may break between matlab releases due to slightly higher error
    At the discretion of the user, the tolerances may need to be relaxed


%%% TODO %%%
Add more tests
    models with input

%}
close all
clear all
clc
sympref('AbbreviateOutput',false);
sympref('MatrixWithSquareBrackets',true);
CDS_FindIncludes;
CDS_IncludeSimulator;
CDS_IncludeUtilities;

sun = ~isMATLABReleaseOlderThan("R2024b"); % Sundials solvers avaliable starting this release
IT1 = IntegrationTest_1;
IT2 = IntegrationTest_2;
IT3 = IntegrationTest_3;
IT4 = IntegrationTest_4;
IT5 = IntegrationTest_5;
IT6 = IntegrationTest_6;
IT7 = IntegrationTest_7;
IT8 = IntegrationTest_8;

IT1.RunVerbose({"auto","auto"}, 1e-8, 1e-12)
IT1.RunVerbose({"ode15i","fullyImplicit"}, 1e-8, 1e-3)
IT1.RunVerbose({"ode45","massMatrix"}, 1e-8, 1e-12)
IT1.RunVerbose({"ode45","setupTime"}, 1e-8, 1e-12)
IT1.RunVerbose({"ode45","solveTime"}, 1e-8, 1e-12)
IT1.RunVerbose({"ode45","solveTime2"}, 1e-8, 1e-12)

IT2.RunVerbose({"auto","auto"}, 1e-8, 1e-12)
IT2.RunVerbose({"ode15i","fullyImplicit"}, 1e-12, 1e-6)
IT2.RunVerbose({"ode15s","massMatrix"}, 1e-8, 1e-3)
IT2.RunVerbose({"ode23t","massMatrix"}, 1e-8, 1e-3)
% if sun; IT2.RunVerbose({"idas","massMatrix"}, 1e-8, 1e-10); end % idas plz. The accelerations...
IT2.RunVerbose({"ode45","setupTime"}, 1e-8, 1e-12)
IT2.RunVerbose({"ode45","solveTime"}, 1e-8, 1e-12)
IT2.RunVerbose({"ode45","solveTime2"}, 1e-8, 1e-12)

IT3.RunVerbose({"auto","auto"}, 1e-10, 1e-12)
IT3.RunVerbose({"ode15i","fullyImplicit"}, 1e-8, 1e-3)
IT3.RunVerbose({"ode45","setupTime"}, 1e-8, 1e-12)
IT3.RunVerbose({"ode45","solveTime"}, 1e-8, 1e-12)
IT3.RunVerbose({"ode45","solveTime2"}, 1e-8, 1e-12)
if sun; IT3.RunVerbose({"cvodesnonstiff","auto"}, 1e-13, 1e-10); end
if sun; IT3.RunVerbose({"idas","auto"}, 1e-13, 1e-12); end

IT4.RunVerbose()

IT5.RunVerbose({"auto","auto"}, 1e-10, 1e-8)
% IT5.RunVerbose({"ode15i","fullyImplicit"}, 1e-4, 1e-2) % RIP ode15i
% IT5.RunVerbose({"ode15s","massMatrix"}, 1e-8, 1e-3)    % RIP ode15s. Almost makes it
IT5.RunVerbose({"ode23t","massMatrix"}, 1e-7, 1e-4)
IT5.RunVerbose({"ode45","setupTime"}, 1e-10, 1e-8)
IT5.RunVerbose({"ode45","solveTime"}, 1e-10, 1e-8)
IT5.RunVerbose({"ode45","solveTime2"}, 1e-10, 1e-8)

% Last 3 args: LnNum, Ly_IC, Ly_d_IC
IT6.RunVerbose({"auto","auto"}, 1e-10, 1e-7,     0, 4.92, 0)
IT6.RunVerbose({"auto","auto"}, 1e-10, 1e-7,  2.78, 4.92, 0)
IT6.RunVerbose({"auto","auto"}, 1e-10, 1e-6, -5.43, 3.68, 0)
IT6.RunVerbose({"auto","auto"}, 1e-10, 1e-7,    0, -2.72, 0)
IT6.RunVerbose({"auto","auto"}, 1e-10, 1e-7,    0,     0, 8.72)

% Last 3 args: thetaNNum, theta_IC, theta_d_IC
IT7.RunVerbose({"auto","auto"}, 1e-10, 1e-8,     0, 4.92, 0)
IT7.RunVerbose({"auto","auto"}, 1e-10, 1e-8,  2.78, 4.92, 0)
IT7.RunVerbose({"auto","auto"}, 1e-10, 1e-7, -5.43, 3.68, 0)
IT7.RunVerbose({"auto","auto"}, 1e-10, 1e-8,    0, -2.72, 0)
IT7.RunVerbose({"auto","auto"}, 1e-10, 1e-7,    0,     0, 8.72)

% Last 4 args: Ly_IC, Ly_d_IC, wn, d
IT8.RunVerbose({"ode45","solveTime2"},1e-10,1e-7,4.92, 0, 0.783, 0.132)
IT8.RunVerbose({"auto","auto"}, 1e-10, 1e-7, 4.92,     0, 0.783, 0.132)
IT8.RunVerbose({"auto","auto"}, 1e-10, 1e-7, 4.92,     0, 0.783, 9.35)
IT8.RunVerbose({"auto","auto"}, 1e-10, 1e-7, 3.68, -2.72,  1.93, 0.872)
IT8.RunVerbose({"auto","auto"}, 1e-10, 1e-6, -2.72, 8.72,  5.93, 1.27)
IT8.RunVerbose({"auto","auto"}, 1e-10, 1e-6,     0, 8.72,  5.93, 1.27)


fprintf("(TEST) All Tests Passed\n")

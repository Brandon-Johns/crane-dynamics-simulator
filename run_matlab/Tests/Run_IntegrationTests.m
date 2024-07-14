%{
Written By: Brandon Johns
Date Version Created: 2024-03-31
Date Last Edited: 2024-03-31
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
    moment of inertia - maybe do a rotating bearing with initial velocity condition (no gravity)
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

args_auto = {{{"auto"}}};

args1 = {
    {{"auto","auto"}, 1e-8, 1e-12};
    {{"ode15i","fullyImplicit"}, 1e-8, 1e-3};
    {{"ode45","setupTime"}, 1e-8, 1e-12};
    {{"ode45","solveTime"}, 1e-8, 1e-12};
    {{"ode45","solveTime2"}, 1e-8, 1e-12};
};
RunTestSet(IntegrationTest_1, args1)

args2 = {
    {{"auto","auto"}, 1e-8, 1e-12};
    {{"ode15i","fullyImplicit"}, 1e-5, 1e-3};
    {{"ode15s","massMatrix"}, 1e-8, 1e-3};
    {{"ode23t","massMatrix"}, 1e-8, 1e-3};
    {{"ode45","setupTime"}, 1e-8, 1e-12};
    {{"ode45","solveTime"}, 1e-8, 1e-12};
    {{"ode45","solveTime2"}, 1e-8, 1e-12};
};
RunTestSet(IntegrationTest_2, args2)

args3 = {
    {{"auto","auto"}, 1e-10, 1e-12};
    {{"ode15i","fullyImplicit"}, 1e-8, 1e-3};
    {{"ode45","setupTime"}, 1e-8, 1e-12};
    {{"ode45","solveTime"}, 1e-8, 1e-12};
    {{"ode45","solveTime2"}, 1e-8, 1e-12};
};
RunTestSet(IntegrationTest_3, args3)

RunTestSet(IntegrationTest_4)

args5 = {
    {{"auto","auto"}, 1e-10, 1e-8};
    {{"ode15i","fullyImplicit"}, 1e-4, 1e-2};
    {{"ode15s","massMatrix"}, 1e-6, 1e-3};
    {{"ode23t","massMatrix"}, 1e-6, 1e-3};
    {{"ode45","setupTime"}, 1e-10, 1e-8};
    {{"ode45","solveTime"}, 1e-10, 1e-8};
    {{"ode45","solveTime2"}, 1e-10, 1e-8};
};
RunTestSet(IntegrationTest_5, args5)



function RunTestSet(testClass, argSets)
    arguments
        testClass
        argSets = {{{"auto"}}}
    end
    fprintf("(TEST) " + class(testClass) +"\n")
    fprintf("(TEST) " + testClass.Description +"\n")
    for idx = 1:length(argSets)
        args = argSets{idx};
        fprintf("(TEST) solverArgs = " + strjoin([args{1}{:}], ",")+"\n")
        testClass.Run(args{:});
        fprintf("(TEST) Run Complete\n\n")
    end
    fprintf("(TEST) Set Complete\n\n")
end

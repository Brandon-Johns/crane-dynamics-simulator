%{
PURPOSE
    Pass miscellaneous options to CDS_Solver
%}

classdef CDS_Solver_Options < handle
properties
    % The time to solve over
    %   If DIM[1,2]: Start and end times. In-between times are chosen by the solver
    %   If DIM[1,n]: Output solution at these times exactly
    time(1,:) double = [0,5]

    % Should this.Events be passed to odeset()?
    EventsIsActive(1,1) logical = 0

    % Options passed to odeset()
    RelTol(1,1) double = 10^(-7)
    AbsTol(1,1) double = 10^(-7)
    Stats(1,1) string = "on"
    Events(1,1) function_handle = @CDS_Solver_Options.myEventsFcn

    % Used with CDS_Solver.Solver(..., solveMode="export")
    %   If solverName="sundials": Relative path to the directory to output the generated files in
    %   Otherwise:                Relative path to the file to output, including the filename
    exportPath(1,1) string = ""
end
methods (Static)
    % Default events function
    % Prints the time that the solver is currently up to
    % PURPOSE
    %   If solving is taking a long time, turn this on to check where the solver is stuck at
    %   Really small time increments can indicate that the equations are stiff
    % INPUT
    %   t: (double) Current solve time during solving
    % INPUT (Repeating)
    %   varargin: Required by solver, but ignored by this events function implementation
    % OUTPUT
    %   value      (double) DIM[1,1] Meaningless. Always 1
    %   isTerminal (double) DIM[1,1] Meaningless. Always 0
    %   direction  (double) DIM[1,1] Meaningless. Always 0
    function [value,isTerminal,direction] = myEventsFcn(t, varargin)
        % Using varargin because some solvers (e.g. implicit) have extra inputs
        % Explicitly declare argument 't' as work around for a MATLAB bug (seen in R2025a)
        %   The new ode solver ode() fails internally on a check that basically equates to
        %   if nargin(@userSuppliedEventsFcn)==-1; try to use an argument that wasn't supplied by the internal caller
        value=1;
        isTerminal=0;
        direction=0;
        disp(t);
    end
end
end

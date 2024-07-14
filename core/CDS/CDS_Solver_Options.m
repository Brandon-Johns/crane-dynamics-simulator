%{
PURPOSE
    Pass miscellaneous options to CDS_Solver
%}

classdef CDS_Solver_Options < handle
properties (Access=public)
    % The time to solve over
    %   If 1x2 array: The start and end times. In-between times are chosen by the solver
    %   If 1xn array: The solution is output at these time coordinates
    time(1,:) double = [0,5]

    % Boolean flag: Pass events function to odeset()?
    EventsIsActive(1,1) logical = 0
    
    % Options passed to odeset()
    RelTol(1,1) double = 10^(-7)
    AbsTol(1,1) double = 10^(-7)
    Stats(1,1) string = 'on'
    Events(1,1) function_handle = @(~,~) "ERROR"

    % Options for exporting
    %   solverName="sundials":         Path to the directory to output the generated files in
    %   (otherwise export for matlab): Path to the file to output, including the filename
    exportPath(1,1) string = ""
end
methods
    function this = CDS_Solver_Options()
        this.Events = @this.myEventsFcn;

    end
end
methods (Access=public)
    % Default events function
    %   Prints the time that the solver is currently up to
    % PURPOSE
    %   If solving is taking a long time, turn this on to check where the solver is stuck at
    %   Really small time increments can indicate that the equations are stiff
    function [value,isTerminal,direction] = myEventsFcn(~, t,~)
        value=1;
        isTerminal=0;
        direction=0;
        disp(t);
    end
end
end

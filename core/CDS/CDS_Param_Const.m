%{
PURPOSE
    A constant parameter

DETAILS
    Each instance of this class is one parameter

EXAMPLE
    % Create a parameter with the name "g" and value 9.8
    sys = CDS_SystemDescription();
    params = sys.params;
    params.Create("const", "g").SetNum(9.8);

    % Get the value of the parameter with the name "g"
    params.Subset("g").Num
%}

classdef CDS_Param_Const < CDS_Param
properties (Access=private)
    num(1,1) double {mustBeFinite} = 0
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % Intended for internal use only
    % Creation should be done through CDS_Params.m
    % Most uses should use the property .params of an instance of CDS_SystemDescription.m
    function this = CDS_Param_Const(varargin)
        this@CDS_Param(varargin);
    end

    %**********************************************************************
    % Interface: Set
    %***********************************
    % Numerical value of the parameter
    % INPUT
    %   Value to set
    function this = SetNum(this, numIn)
        arguments
            this(1,1)
            numIn(1,1) double {mustBeFinite}
        end
        this.num = numIn;
    end

    %**********************************************************************
    % Interface: Get
    %***********************************
    % OUTPUT
    %   (double) DIM[size(this)]
    function out = Num(this); out = this.PropArray(this.num); end
end
end

%{
Creation should be done through CDS_Params.m

PURPOSE
    Instances of this class represent constant system parameters

EXAMPLE
    % Create a parameter with the name "g" and value 9.8
    params = CDS_Params();
    params.Create("const", "g").SetNum(9.8);

    % Get the value of the parameter with the name "g"
    params.Param("g").Num
%}

classdef CDS_Param_Const < CDS_Param
properties (Access=private)
    num(1,1) double {mustBeFinite(num)} = 0
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    function this = CDS_Param_Const(varargin)
        this@CDS_Param(varargin);
    end
    
    %**********************************************************************
    % Interface: Set
    %***********************************
    % Numerical value of the parameter
    function this = SetNum(this, numIn)
        this.num = numIn;
    end
    
    %**********************************************************************
    % Interface: Get
    %***********************************
    % Numerical value of the parameter
    function out = Num(this); out = this.PropArray(this.num); end
end
end

%{
Creation is automatic. Should not be manually created
Creation should be done through CDS_Params.m

PURPOSE
    Instances of this class represent Lagrange multipliers
    Used for constrained systems when using a DAE solver
%}

classdef CDS_Param_Lambda < CDS_Param
properties (Access=private)
    % Initial conditions
    q0_(1,1) double {mustBeFinite(q0_)} = 0
    q_d0_(1,1) double {mustBeFinite(q_d0_)} = 0
    
    % For implicit solvers - Disallow solver from changing specified initial conditions
    q0_fixed_(1,1) logical = 0
    q_d0_fixed_(1,1) logical = 0 % Setting this fixed can make solver unhappy
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    function this = CDS_Param_Lambda(varargin)
        this@CDS_Param(varargin);
    end
    
    %**********************************************************************
    % Interface: Set
    %***********************************
    % Set initial conditions
    % Similar to as in CDS_Param_Free.m
    function this = SetIC(this, q0,q_d0, q0_fixed,q_d0_fixed)
        if nargin >= 2; this.q0_ = q0; end
        if nargin >= 3; this.q_d0_ = q_d0; end
        
        if nargin >= 4; this.q0_fixed_ = q0_fixed; end
        if nargin >= 5; this.q_d0_fixed_ = q_d0_fixed; end
    end
    
    %**********************************************************************
    % Interface: Get
    %***********************************
    % Initial conditions
    function out = q0(this); out = this.PropArray(this.q0_); end
    function out = q_d0(this); out = this.PropArray(this.q_d0_); end
    function out = q0_fixed(this); out = this.PropArray(this.q0_fixed_); end
    function out = q_d0_fixed(this); out = this.PropArray(this.q_d0_fixed_); end
end
end

%{
PURPOSE
    A Lagrange multiplier

DETAILS
    Each instance of this class is one Lagrange multiplier
    Used for constrained systems when using a DAE solver
%}

classdef CDS_Param_Lambda < CDS_Param
properties (Access=private)
    % Initial conditions
    q0_(1,1) double {mustBeFinite} = 0
    q_d0_(1,1) double {mustBeFinite} = 0

    % For implicit solvers - Disallow solver from changing specified initial conditions
    q0_fixed_(1,1) logical = 0
    q_d0_fixed_(1,1) logical = 0 % Setting this fixed can make solver unhappy
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % Intended for internal use only
    % Creation is automatic. Should not be manually created
    % Creation should be done through CDS_Params.m
    % Most uses requiring manual creation should use the property .params of an instance of CDS_SystemDescription.m
    function this = CDS_Param_Lambda(varargin)
        this@CDS_Param(varargin);
    end

    %**********************************************************************
    % Interface: Set
    %***********************************
    % Set initial conditions
    % INPUT
    %   q0:         Initial value
    %   q_d0:       Initial velocity
    %   q0_fixed:   Disallow implicit solvers from changing the initial condition?
    %   q_d0_fixed: Disallow implicit solvers from changing the initial condition?
    % NOTE
    %   Initial velocity
    %       Value used by implicit solvers only
    %       Since the value is fully determined by the system equations, it does not need to be specified
    %       The solver can usually automatically determine it
    function this = SetIC(this, q0,q_d0, q0_fixed,q_d0_fixed)
        arguments
            this(1,1)
            q0(1,1) double {mustBeFinite} = this.q0_
            q_d0(1,1) double {mustBeFinite} = this.q_d0_
            q0_fixed(1,1) logical = this.q0_fixed_
            q_d0_fixed(1,1) logical = this.q_d0_fixed_
        end
        this.q0_ = q0;
        this.q_d0_ = q_d0;
        this.q0_fixed_ = q0_fixed;
        this.q_d0_fixed_ = q_d0_fixed;
    end

    %**********************************************************************
    % Interface: Get
    %***********************************
    % Initial conditions
    % OUTPUT
    %   (double) DIM[size(this)]
    function out = q0(this); out = this.PropArray(this.q0_); end
    function out = q_d0(this); out = this.PropArray(this.q_d0_); end

    % Are implicit solvers disallowed from adjusting the initial condition
    % OUTPUT
    %   (logical) DIM[size(this)]
    function out = q0_fixed(this); out = logical(this.PropArray(this.q0_fixed_)); end
    function out = q_d0_fixed(this); out = logical(this.PropArray(this.q_d0_fixed_)); end
end
end

%{
PURPOSE
    A generalised coordinate

DETAILS
    Each instance of this class is one generalised coordinate (degree of freedom)

EXAMPLE
    % Create a generalised coordinate with the name "theta_1", initial value 0, and initial velocity 0
    % Create a generalised coordinate with the name "theta_2", initial value 2, and initial velocity 0
    % Create a generalised coordinate with the name "theta_3", initial value 3, and initial velocity 30
    sys = CDS_SystemDescription();
    params = sys.params;
    params.Create("free", "theta_1")
    params.Create("free", "theta_2").SetIC(2);
    params.Create("free", "theta_3").SetIC(3, 30);

    % Get the values of the initial conditions
    params.Subset(["theta_1", "theta_2", "theta_3"]).q0
    % Returns [0; 2; 3]
    params.Subset(["theta_3", "theta_1", "theta_2"]).q0
    % Returns [3; 0; 2]
    params.Subset("theta_3").q0
    % Returns 3
    params.Subset("theta_3").q_d0
    % Returns: 30
%}

classdef CDS_Param_Free < CDS_Param
properties (Access=private)
    % Initial conditions
    q0_(1,1) double {mustBeFinite} = 0
    q_d0_(1,1) double {mustBeFinite} = 0
    q_dd0_(1,1) double {mustBeFinite} = 0

    % For implicit solvers - Disallow solver from changing specified initial conditions
    q0_fixed_(1,1) logical = 1
    q_d0_fixed_(1,1) logical = 0 % Setting this fixed can make solver unhappy
    q_dd0_fixed_(1,1) logical = 0 % Setting this fixed can make solver unhappy

    % For implicit solvers with DAEs reduced to index-1
    q_ddd0_(1,1) double {mustBeFinite} = 0
    q_ddd0_fixed_(1,1) logical = 0 % Setting this fixed can make solver unhappy
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % Intended for internal use only
    % Creation should be done through CDS_Params.m
    % Most uses should use the property .params of an instance of CDS_SystemDescription.m
    function this = CDS_Param_Free(varargin)
        this@CDS_Param(varargin);
    end

    %**********************************************************************
    % Interface: Set
    %***********************************
    % Set initial conditions
    % INPUT
    %   q0:          Initial value
    %   q_d0:        Initial velocity
    %   q_dd0:       Initial acceleration
    %   q0_fixed:    Disallow implicit solvers from changing the initial condition?
    %   q_d0_fixed:  Disallow implicit solvers from changing the initial condition?
    %   q_dd0_fixed: Disallow implicit solvers from changing the initial condition?
    % NOTE
    %   Initial acceleration
    %       Value used by implicit solvers only
    %       Since the value is fully determined by the system equations, it does not need to be specified
    %       The solver can usually automatically determine it
    function this = SetIC(this, q0,q_d0,q_dd0, q0_fixed,q_d0_fixed,q_dd0_fixed)
        arguments
            this(1,1)
            q0(1,1) double {mustBeFinite} = this.q0_
            q_d0(1,1) double {mustBeFinite} = this.q_d0_
            q_dd0(1,1) double {mustBeFinite} = this.q_dd0_
            q0_fixed(1,1) logical = this.q0_fixed_
            q_d0_fixed(1,1) logical = this.q_d0_fixed_
            q_dd0_fixed(1,1) logical = this.q_dd0_fixed_
        end
        this.q0_ = q0;
        this.q_d0_ = q_d0;
        this.q_dd0_ = q_dd0;
        this.q0_fixed_ = q0_fixed;
        this.q_d0_fixed_ = q_d0_fixed;
        this.q_dd0_fixed_ = q_dd0_fixed;
    end

    % Intended for internal use only
    % For interface CDS_Param_x
    function this = SetIC_offset_d(this, q_d0,q_dd0)
        arguments
            this(1,1)
            q_d0
            q_dd0
        end
        this.q_d0_ = q_d0;
        this.q_dd0_ = q_dd0;
    end
    function this = SetIC_offset_dd(this, q_dd0,q_ddd0)
        arguments
            this(1,1)
            q_dd0
            q_ddd0
        end
        this.q_dd0_ = q_dd0;
        this.q_ddd0_ = q_ddd0;
    end

    %**********************************************************************
    % Interface: Get
    %***********************************
    % Initial conditions
    % OUTPUT
    %   (double) DIM[size(this)]
    function out = q0(this); out = this.PropArray(this.q0_); end
    function out = q_d0(this); out = this.PropArray(this.q_d0_); end
    function out = q_dd0(this); out = this.PropArray(this.q_dd0_); end

    % Are implicit solvers disallowed from adjusting the initial condition
    % OUTPUT
    %   (logical) DIM[size(this)]
    function out = q0_fixed(this); out = logical(this.PropArray(this.q0_fixed_)); end
    function out = q_d0_fixed(this); out = logical(this.PropArray(this.q_d0_fixed_)); end
    function out = q_dd0_fixed(this); out = logical(this.PropArray(this.q_dd0_fixed_)); end

    % Intended for internal use only
    function out = q_ddd0(this); out = this.PropArray(this.q_ddd0_); end
    function out = q_ddd0_fixed(this); out = logical(this.PropArray(this.q_ddd0_fixed_)); end
end
end

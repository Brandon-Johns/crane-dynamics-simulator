%{
Creation should be done through CDS_Params.m

PURPOSE
    Instances of this class represent generalised coordinates / degrees of freedom

EXAMPLE
    % Create a generalised coordinate with the name "theta_1", initial value 0, and initial velocity 0
    % Create a generalised coordinate with the name "theta_2", initial value 2, and initial velocity 0
    % Create a generalised coordinate with the name "theta_3", initial value 3, and initial velocity 30
    params = CDS_Params();
    params.Create("free", "theta_1")
    params.Create("free", "theta_2").SetIC(2);
    params.Create("free", "theta_3").SetIC(3, 30);

    % Get the values of the initial conditions
    params.Param(["theta_1", "theta_2", "theta_3"]).q0
    % Returns [0; 2; 3]
    params.Param(["theta_3", "theta_1", "theta_2"]).q0
    % Returns [3; 0; 2]
    params.Param("theta_3").q0
    % Returns 3
    params.Param("theta_3").q_d0
    % Returns: 30
%}

classdef CDS_Param_Free < CDS_Param
properties (Access=private)
    % Initial conditions
    q0_(1,1) double {mustBeFinite(q0_)} = 0
    q_d0_(1,1) double {mustBeFinite(q_d0_)} = 0
    q_dd0_(1,1) double {mustBeFinite(q_dd0_)} = 0
    
    % For implicit solvers - Disallow solver from changing specified initial conditions
    q0_fixed_(1,1) logical = 1
    q_d0_fixed_(1,1) logical = 0 % Setting this fixed can make solver unhappy
    q_dd0_fixed_(1,1) logical = 0 % Setting this fixed can make solver unhappy
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    function this = CDS_Param_Free(varargin)
        this@CDS_Param(varargin);
    end
    
    %**********************************************************************
    % Interface: Set
    %***********************************
    % Set initial conditions
    % INPUT
    %   q0:     Initial value
    %   q_d0:   Initial velocity
    %   q_dd0:  Initial acceleration
    %   q0_fixed:       (boolean) (default=false) For implicit solvers. Allow solver to change the initial condition?
    %   q_d0_fixed:     (boolean) (default=true)
    %   q_dd0_fixed:    (boolean) (default=true)
    function this = SetIC(this, q0,q_d0,q_dd0, q0_fixed,q_d0_fixed,q_dd0_fixed)
        if nargin >= 2; this.q0_ = q0; end
        if nargin >= 3; this.q_d0_ = q_d0; end
        if nargin >= 4; this.q_dd0_ = q_dd0; end
        
        if nargin >= 5; this.q0_fixed_ = q0_fixed; end
        if nargin >= 6; this.q_d0_fixed_ = q_d0_fixed; end
        if nargin >= 7; this.q_dd0_fixed_ = q_dd0_fixed; end
    end
    
    % Intended for internal use only
    % For interface CDS_Param_x
    function this = SetIC_offset(this, q_d0,q_dd0)
        this.q_d0_ = q_d0;
        this.q_dd0_ = q_dd0;
    end
    
    %**********************************************************************
    % Interface: Get
    %***********************************
    % Initial conditions
    function out = q0(this); out = this.PropArray(this.q0_); end
    function out = q_d0(this); out = this.PropArray(this.q_d0_); end
    function out = q_dd0(this); out = this.PropArray(this.q_dd0_); end
    function out = q0_fixed(this); out = this.PropArray(this.q0_fixed_); end
    function out = q_d0_fixed(this); out = this.PropArray(this.q_d0_fixed_); end
    function out = q_dd0_fixed(this); out = this.PropArray(this.q_dd0_fixed_); end
end
end

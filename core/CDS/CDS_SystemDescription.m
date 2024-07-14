%{
PURPOSE
    Hold all of the information required to simulate a system
    An instance of this fully defines a system
%}

classdef CDS_SystemDescription < handle
properties (SetAccess=private)
    params(1,1) CDS_Params
    points(1,:) CDS_Points % Would force (1,1), but dumb errors
    chains(1,:) cell
    
    g0(3,1) sym = zeros(3,1)
    C(:,1) sym = []
end

methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % INPUT
    %   params: CDS_Params that holds every param used in points and g0
    %   points: CDS_Points that holds every point to evaluate. Must hold every point that has mass / moment of inertia
    %   chains:
    %       Kinematic chains (used only for plotting the animation)
    %       Cell array of linear arrays of CDS_Point instances, where each array is a chain
    %   g0:
    %       Gravitational acceleration vector
    %       Defines the magnitude of gravity, and the down direction
    function this = CDS_SystemDescription(params, points, chains, g0)
        arguments
            params
            points
            chains
            g0
        end
        this.params = params;
        this.points = points;
        this.chains = chains;
        this.g0 = g0;
        
        % Validate chains
        for idx = 1:length(chains)
            if ~isa(chains{idx}, "CDS_Point"); error("Bad input: Chains must be point objects"); end
        end
    end
    
    %**********************************************************************
    % Interface: Set
    %***********************************
    % INPUT
    %   (symbolic expression) Algebraic constraint equation of the form C=0
    function this = SetConstraint(this, C)
        % Set constraint equation
        this.C = C;

        % Validate
        if any( symvar(C) == sym('t') )
            error("Constraint may not explicitly depend on time (because I differentiate the constraint internally)")
       end

        % If this triggers, the constraint won't do anything I think
        %   The equations may not be consistent
        %   e.g. with solveMode=massMatrix, the state equation will include a row like [0, ..., 0]*x = -dC/dt
        %   which is fine in some cases, so I won't throw an error
        if ~any( symvar(C) == this.params.x.Sym )
            warning("Constraint is not a function of the generalised coordinates")
       end
        
        % Create lagrange multipliers
        for idx = 1:length(C)
            this.params.Create("lambda", strcat("lambda_",num2str(idx)));
        end
    end
end
end

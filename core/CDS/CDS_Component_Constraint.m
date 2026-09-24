%{
PURPOSE
    Holonomic constraint

DETAILS
    Each instance of this class is one constraint
    Holonomic constraints restrict the geometry of the system, but not the velocity

THEORY
    C(q, t) : Constraint equation in the form C=0
    Key equations
        C=0

EXAMPLE
    % Given:
    %   L1: sym registered with sys as CDS_Param_Free
    %   L2: sym registered with sys as CDS_Param_Free
    %   L3: sym registered with sys as CDS_Param_Input
    %   sys: CDS_SystemDescription
    % Apply a constraint, and name it "RopeLen". The constraint describes that the length of the rope is L1+L2+L3
    sys.CreateConstraint("RopeLen").SetConstraint(L1+L2+L3, "offsetToIC");
%}

classdef CDS_Component_Constraint < CDS_NamedItem
properties (Access=private)
    sys(1,1) CDS_SystemDescription

    % Algebraic constraint equation of the form C=0
    constraint(1,1) sym = 0

    % The associated lagrange multiplier
    % Treated as immutable
    lambda(1,1) sym = 0
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % Intended for internal use only
    % Creation should be done through CDS_SystemDescription.m
    function this = CDS_Component_Constraint(sys, name, lambda)
        arguments
            sys(1,1) CDS_SystemDescription
            name(1,1) string
            lambda(1,1) sym
        end
        this@CDS_NamedItem(name);
        this.sys = sys;

        % Validate Lambda
        if ~isSymType(lambda,'variable')
            error("Bad input: Lambda is not a symbolic variable (e.g. might be a symbolic expression)");
        end
        if ~sys.params.lambda.Contains(lambda)
            error('Bad input: Lambda not registered: %s', lambda)
        end
        this.lambda = lambda;
    end

    %**********************************************************************
    % Interface: Set
    %***********************************
    % Algebraic constraint equation of the form C=0
    % INPUT
    %   C: (symbolic expression)
    %   mode
    %       "specified"
    %           The constraint equation is set as specified
    %       "offsetToIC"
    %           The constraint equation is offset by a constant to make it equal 0
    %           This calculation is performed immediately (be careful not to change ICs after)
    function this = SetConstraint(this, C, mode)
        arguments
            this(1,1)
            C(1,1) sym
            mode(1,1) string {mustBeMember(mode,["specified","offsetToIC"])} = "specified"
        end
        if mode=="offsetToIC"
            % Shift constraint by constant offset to make C=0
            C = C - this.sys.params.EvaluateSymExpr_IC(C);
        end

        this.sys.params.isZeroDifferentialOrder(C, "ErrorOnFalse");

        % If this triggers, the constraint won't do anything I think
        %   The equations may not be consistent
        %   e.g. with solveMode=massMatrix, the state equation will include a row like [0, ..., 0]*x = -dC/dt
        %   which is fine in some cases, so I won't throw an error
        if ~any(ismember(symvar(C), this.sys.params.x.Sym))
            warning("Constraint is not a function of the generalised coordinates")
        end

        this.constraint = C;
    end

    %**********************************************************************
    % Interface: Get
    %***********************************
    % OUTPUT
    %   (string) DIM[size(this)]
    function out = NameReadable(this); out = strcat("Constraint ", this.Name); end

    % Algebraic constraint equation of the form C=0
    % IMPORTANT
    %   This is used by the solver, and the solver assumes: all(sys.constraints.Lambda == sys.params.lambda.Sym)
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = C(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.constraint);
    end

    % The associated lagrange multiplier
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Lambda(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.lambda);
    end

    %**********************************************************************
    % Interface: Get - Energy and Power
    %***********************************
    % Time-rate of work done on the system
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Power_dWdt(this)
        if isempty(this)
            out = sym.empty(size(this));
            return;
        end
        % dW/dt = - Q . qd = - d[ C . lambda ]/d[q] . qd
        q = this(1).sys.params.q.Sym;
        qd = this(1).sys.params.q.Sym(1);
        C_Lam = this(:).C .* this(:).Lambda;
        out = - jacobian(C_Lam, q) * qd;
        out = reshape(out, size(this));
    end

    %**********************************************************************
    % Interface: Get - Forces
    %***********************************
    % The force exerted by the constraint on the system,
    % as a generalised force vector, ordered with respect to sys.params.q
    % INPUT
    %   Required input if 'this' can be empty, otherwise optional
    % OUTPUT
    %   (symbolic expression) DIM[length(sys.params.q), size(this)] Using convention (tensor dims, batch dims)
    function out = Q(this, sys)
        arguments
            this
            sys(1,1) CDS_SystemDescription = this(1).sys
        end
        % Q = - d[C]/d[q] . lambda = - d[ C . lambda ]/d[q]
        q = sys.params.q.Sym;
        num_q = length(q);
        C_Lam = this(:).C .* this(:).Lambda;
        out = - jacobian(C_Lam, q).';
        out = reshape(out, [num_q, size(this)]);
    end
end
end

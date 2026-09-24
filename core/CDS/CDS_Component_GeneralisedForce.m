%{
PURPOSE
    A Generalised force acting on the system

DETAILS
    This class is not the total generalised force, it applies a generalised force in addition to any others
    Each instance of this class is one component of the generalised force, acting along a single degree of freedom only

THEORY
    Q(q, qd, t) : Generalised force
    q           : Generalised coordinate along which the force acts (acting in the positive direction)
    Key equations
        The Euler-Lagrange formulation
        sum(Q) = d[dL/d[qd]]/dt - dL/dq

EXAMPLE
    % Given:
    %   x1: CDS_Param_Free
    %   sys: CDS_SystemDescription
    % Apply a force on x1, and name this force "Q1". The force has a value of 20 Newtons, as measured in the world frame
    sys.CreateGeneralisedForce("Q1").SetLocation(x1).SetQ(20);
%}

classdef CDS_Component_GeneralisedForce < CDS_NamedItem
properties (Access=private)
    sys(1,1) CDS_SystemDescription

    force(1,1) sym = 0
    q_free(1,1) sym = 0
    q_free_d(1,1) sym = 0
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % Intended for internal use only
    % Creation should be done through CDS_SystemDescription.m
    function this = CDS_Component_GeneralisedForce(sys, name)
        this@CDS_NamedItem(name);
        this.sys = sys;
    end

    %**********************************************************************
    % Interface: Set
    %***********************************
    % Value of the force
    % INPUT
    %   (symbolic expression) Permits values from [CDS_Params.const.Sym; CDS_Params.q.Sym; CDS_Params.q.Sym(1); sym('t','real')]
    function this = SetQ(this, Q)
        arguments
            this(1,1)
            Q(1,1) sym
        end
        this.sys.params.isLessThanMaxDifferentialOrder(Q, "ErrorOnFalse");
        this.force = Q;
    end

    % The degree of freedom along which the force is applied
    % INPUT
    %   q_free
    %       (string)            Value from CDS_Params.q_free.Str
    %       (symbolic variable) Value from CDS_Params.q_free.Sym
    %       (CDS_Param_Free)    Value from CDS_Params.q_free
    function this = SetLocation(this, q_free)
        arguments
            this(1,1)
            q_free(1,1) {mustBeA(q_free,["string", "sym", "CDS_Param_Free"])}
        end
        q_free_object = this.sys.params.q_free.Subset(q_free, warnMissing=false);
        if isempty(q_free_object)
            error("Bad input: Not a free generalised coordinate");
        end
        this.q_free = q_free_object.Sym;
        this.q_free_d = q_free_object.Sym(1);
    end

    %**********************************************************************
    % Interface: Get
    %***********************************
    % OUTPUT
    %   (string) DIM[size(this)]
    function out = NameReadable(this); out = strcat("Generalised Force ", this.Name); end

    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Q_scalar(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.force);
    end

    % Corresponds to this.SetLocation()
    % OUTPUT
    %   (symbolic variable) DIM[size(this)]
    function out = q(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.q_free);
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
        % dW/dt = Q*qd
        out = this.Q_scalar .* this.PropArray(this.q_free_d);
    end

    %**********************************************************************
    % Interface: Get - Forces
    %***********************************
    % The force exerted on the system,
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
        qVec = sys.params.q.Sym;
        num_q = length(qVec);
        out = sym(zeros(num_q, numel(this)));
        for idx = 1:numel(this)
            % Map the scalar element of Q onto the vector Q
            out(:, idx) = jacobian(qVec, this(idx).q) * this(idx).Q_scalar;
        end
        out = reshape(out, [num_q, size(this)]);
    end

    % The force exerted on the system,
    % as a generalised force vector, in the free generalised coordinates, ordered with respect to sys.params.q_free
    % INPUT
    %   Required input if 'this' can be empty, otherwise optional
    % OUTPUT
    %   (symbolic expression) DIM[length(sys.params.q_free), size(this)] Using convention (tensor dims, batch dims)
    function out = Qf(this, sys)
        arguments
            this
            sys(1,1) CDS_SystemDescription = this(1).sys
        end
        qfVec = sys.params.q_free.Sym;
        num_qf = length(qfVec);
        out = sym(zeros(num_qf, numel(this)));
        for idx = 1:numel(this)
            % Map the scalar element of Q onto the vector Q
            out(:, idx) = jacobian(qfVec, this(idx).q) * this(idx).Q_scalar;
        end
        out = reshape(out, [num_qf, size(this)]);
    end
end
end

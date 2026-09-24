%{
PURPOSE
    A force acting on the system, as applied to a point in task space

DETAILS
    Each instance of this class is one point force that acts on the system

THEORY
    F(q, qd, t) : Force
    r(q, t)     : Location where the force acts (in world coordinates)
    Key equations
        Projection onto the generalised coordinates
        Q_i = F . d[r]/d[q_i]    for all i

EXAMPLE
    % Given:
    %   A: CDS_Point
    %   sys: CDS_SystemDescription
    % Apply a force at point A, and name this force "A1". The force has a vector value of [20;0;0] Newtons in the world frame
    sys.CreatePointForce("A1").SetLocation(A).SetF( [20; 0; 0] );

%}

classdef CDS_Component_PointForce < CDS_NamedItem
properties (Access=private)
    sys(1,1) CDS_SystemDescription

    % Forces are stored split to work better with propArray
    force_x(1,1) sym = 0
    force_y(1,1) sym = 0
    force_z(1,1) sym = 0

    pointOfApplication(1,1) CDS_T = CDS_T
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % Intended for internal use only
    % Creation should be done through CDS_SystemDescription.m
    function this = CDS_Component_PointForce(sys, name)
        this@CDS_NamedItem(name);
        this.sys = sys;
    end

    %**********************************************************************
    % Interface: Set
    %***********************************
    % Value of the force
    % INPUT
    %   (symbolic expression) Permits values from [CDS_Params.const.Sym; CDS_Params.q.Sym; CDS_Params.q.Sym(1); sym('t','real')]
    function this = SetF(this, F)
        arguments
            this(1,1)
            F(3,1) sym
        end
        this.sys.params.isLessThanMaxDifferentialOrder(F, "ErrorOnFalse");
        this.force_x = F(1);
        this.force_y = F(2);
        this.force_z = F(3);
    end

    % The location where the force is applied
    % NOTE
    %   The symbolic expression permits values from [CDS_Params.const.Sym; CDS_Params.q.Sym; sym('t','real')]
    % INPUT
    %   point
    %       (CDS_Point)                  DIM[1,1] The position vector CDS_Point.T_0n.P is extracted
    %       (CDS_T(symbolic expression)) DIM[1,1] The position vector CDS_T.P is extracted
    %       (symbolic expression)        DIM[3,1] The position vector
    %       (double)                     DIM[3,1] The position vector
    function this = SetLocation(this, point)
        arguments
            this(1,1)
            point {mustBeA(point,["CDS_Point","CDS_T","sym","double"])}
        end
        T_0F = CDS_Components_Common.SanitiseLocations(point);
        this.sys.params.isZeroDifferentialOrder(T_0F.T, "ErrorOnFalse");
        this.pointOfApplication = T_0F;
    end

    %**********************************************************************
    % Interface: Get
    %***********************************
    % OUTPUT
    %   (string) DIM[size(this)]
    function out = NameReadable(this); out = strcat("Point Force ", this.Name); end

    % OUTPUT
    %   (CDS_T) DIM[size(this)]
    function out = Point(this)
        % Enforce the class of the output, even if empty
        if isempty(this); out=CDS_T.Zeros(size(this)); return; end
        out = this.PropArray(this.pointOfApplication);
    end

    % The x,y,z components of the force
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Fx(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.force_x);
    end
    function out = Fy(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.force_y);
    end
    function out = Fz(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.force_z);
    end

    % The force
    % OUTPUT
    %   (symbolic expression) DIM[3,size(this)] Using convention (tensor dims, batch dims)
    function out = F(this)
        if isempty(this); out=sym.empty([3,size(this)]); return; end
        out = [this(:).force_x; this(:).force_y; this(:).force_z];
        out = reshape(out, [3, size(this)]);
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
        % dW/dt = Q . qd = (d[rT]/d[q] . F) . qd = F . d[r]/d[qT] . qd
        q = this(1).sys.params.q.Sym;
        qd = this(1).sys.params.q.Sym(1);
        out = zeros(size(this),'sym');
        for idx=1:numel(this)
            out(idx) = (this(idx).F.') * jacobian(this(idx).Point.P, q) * qd;
        end
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
        % Q = d[rT]/d[q] . F
        q = sys.params.q.Sym;
        num_q = length(q);
        out = sym(zeros(num_q, numel(this)));
        for idx = 1:numel(this)
            out(:, idx) = (jacobian(this(idx).Point.P, q).') * this(idx).F;
        end
        out = reshape(out, [num_q, size(this)]);
    end
end
end

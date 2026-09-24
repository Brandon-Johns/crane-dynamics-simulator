%{
PURPOSE
    A linear damper (F = -k*v)

DETAILS
    Each instance of this class is one damper that obeys: force = - dampingConstant * velocity

THEORY
    l(q, t)     : Length of the damper
    v(q, qd, t) : Rate of change of length of the damper
    k(const)    : Damping constant
    Key equations
        Rayleigh dissipation function
        R = 0.5 . k . (dl/dt)^2
        R = 0.5 . k . v^2

EXAMPLE
    % Given:
    %   O: CDS_Point
    %   A: CDS_Point
    %   B: CDS_Point
    %   sys: CDS_SystemDescription
    % Create damper with name "OA", that routes through a straight line path: origin->A
    % Create damper with name "OAB", that routes through a piecewise straight line path: origin->A->B
    sys.CreateLinearDamper("OA").SetConnections(O,A).SetDampingConstant(20);
    sys.CreateLinearDamper("OA").SetConnections(O,A,B).SetDampingConstant(20);

    % Given:
    %   L1:     sym registered as a CDS_Param_Free
    %   a:      sym registered as a CDS_Param_Const
    %   sys:    CDS_SystemDescription
    % Create damper with name "S1", that routes through an arbitrary path, with path-length L1+a+5
    sys.CreateLinearDamper("S1").SetLength(L1+a+5).SetDampingConstant(20);
    % OR
    vel = sys.params.Subset(L1).Sym(1);
    sys.CreateLinearDamper("S1").SetVelocity(vel).SetDampingConstant(20);
%}

classdef CDS_Component_LinearDamper < CDS_NamedItem
properties (Access=private)
    sys(1,1) CDS_SystemDescription

    velocity(1,1) sym = 0
    dampingConstant(1,1) sym = 0

    % Connections are not necessary for calculating energy, but are necessary for plotting
    % this.SetConnections: Use if damper stays straight => easy to plot
    % this.SetLength:      Use in general case, but hard to plot e.g. negative length, curved path
    % If not specified, then leave empty
    connections(:,1) CDS_T = CDS_T.empty

    % Length is not necessary for solving, but can be useful to calculate e.g. to check the maximum/minimum
    % If not specified, then set nan
    len(1,1) sym = nan
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % Intended for internal use only
    % Creation should be done through CDS_SystemDescription.m
    function this = CDS_Component_LinearDamper(sys, name)
        this@CDS_NamedItem(name);
        this.sys = sys;
    end

    %**********************************************************************
    % Interface: Set
    %***********************************
    % Length of the damper
    % NOTE
    %   Connections are only used for the animation and are not validated to match L
    %   Animations of the solution will plot the damper as a line connecting the specified points
    % INPUT
    %   L (symbolic expression)
    %       Permits values from [CDS_Params.const.Sym; CDS_Params.q.Sym; sym('t','real')]
    % INPUT (Repeating)
    %   connections
    %       (CDS_Point)                  DIM[1,1] The position vector CDS_Point.T_0n.P is extracted
    %       (CDS_T(symbolic expression)) DIM[1,1] The position vector CDS_T.P is extracted
    %       (symbolic expression)        DIM[3,1] The position vector
    %       (double)                     DIM[3,1] The position vector
    function this = SetLength(this, L, connections)
        arguments
            this(1,1)
            L(1,1) sym
        end
        arguments(Repeating)
            connections {mustBeA(connections,["CDS_Point","CDS_T","sym","double"])}
        end
        connections = CDS_Components_Common.SanitiseConnections_AllowEmpty(connections{:});
        this.sys.params.isZeroDifferentialOrder(L, "ErrorOnFalse");
        this.sys.params.isZeroDifferentialOrder([connections.T], "ErrorOnFalse");
        % Must call SetVelocity() first because it clears length and connections
        this.SetVelocity(this.sys.params.TotalDiff(L));
        this.len = L;
        this.connections = connections;
    end

    % Rate of change of length of the damper
    % NOTE
    %   Connections and L are only used for plotting/animations and are not validated to match v
    %   Animations of the solution will plot the damper as a line connecting the specified points
    % INPUT
    %   v (symbolic expression)
    %       Permits values from [CDS_Params.const.Sym; CDS_Params.q.Sym; CDS_Params.q.Sym(1); sym('t','real')]
    %   L (symbolic expression)
    %       Permits values from [CDS_Params.const.Sym; CDS_Params.q.Sym; sym('t','real')]
    % INPUT (Repeating)
    %   connections
    %       (CDS_Point)                  DIM[1,1] The position vector CDS_Point.T_0n.P is extracted
    %       (CDS_T(symbolic expression)) DIM[1,1] The position vector CDS_T.P is extracted
    %       (symbolic expression)        DIM[3,1] The position vector
    %       (double)                     DIM[3,1] The position vector
    function this = SetVelocity(this, v, L, connections)
        arguments
            this(1,1)
            v(1,1) sym
            L(1,1) sym = nan
        end
        arguments(Repeating)
            connections {mustBeA(connections,["CDS_Point","CDS_T","sym","double"])}
        end
        connections = CDS_Components_Common.SanitiseConnections_AllowEmpty(connections{:});
        this.sys.params.isLessThanMaxDifferentialOrder(v, "ErrorOnFalse");
        this.sys.params.isZeroDifferentialOrder(L, "ErrorOnFalse");
        this.sys.params.isZeroDifferentialOrder([connections.T], "ErrorOnFalse");
        this.velocity = v;
        this.len = L;
        this.connections = connections;
    end

    % The start and end connection points of the damper, and any route points
    % DETAIL
    %   1) Sets the total damper length as sum of lengths between each point it routes through
    %       Effectively .SetLength(|P_A - P_B| + |P_B - P_C| + |P_C - P_D| + ...)
    %   2) Sets the velocity as the derivative of this
    %   3) Animations of the solution will plot the damper as a line connecting the specified points
    % LIMITATIONS
    %   1) The calculation of total length can result in high numerical error or 'Div by 0' errors during solving
    %       due to factors in fractions that should cancel out, but do not
    %   2) The calculation of total length does not allow negative damper lengths
    %       because norm takes the absolute value of the displacement
    %       Although this will not effect this.Energy_D() because it uses Velocity^2
    %   3) The calculation of total length does not allow the damper to follow curved paths
    %   Alternative (1&2&3):
    %       Manually calculate the length, and specify it with .SetLength()
    % NOTE
    %   The symbolic expression permits values from [CDS_Params.const.Sym; CDS_Params.q.Sym; sym('t','real')]
    %   Repeat argument for any number of connections; each argument is 1 connection
    %   If only 1 connection is specified, the other connection will default to the origin
    % INPUT (Repeating)
    %   connections
    %       (CDS_Point)                  DIM[1,1] The position vector CDS_Point.T_0n.P is extracted
    %       (CDS_T(symbolic expression)) DIM[1,1] The position vector CDS_T.P is extracted
    %       (symbolic expression)        DIM[3,1] The position vector
    %       (double)                     DIM[3,1] The position vector
    function this = SetConnections(this, connections)
        arguments
            this(1,1)
        end
        arguments(Repeating)
            connections {mustBeA(connections,["CDS_Point","CDS_T","sym","double"])}
        end
        connections = CDS_Components_Common.SanitiseConnections(connections{:});
        this.sys.params.isZeroDifferentialOrder([connections.T], "ErrorOnFalse");
        % Must call SetLength() first because it clears connections
        this.SetLength(CDS_Components_Common.LinearRouteLength(connections));
        this.connections = connections;
    end

    % Damping constant
    % INPUT
    %   (symbolic expression) Permits values from CDS_Params.const.Sym
    function this = SetDampingConstant(this, k)
        arguments
            this(1,1)
            k(1,1) sym
        end
        this.sys.params.isConst(k, "ErrorOnFalse");
        this.dampingConstant = k;
    end

    %**********************************************************************
    % Interface: Get
    %***********************************
    % OUTPUT
    %   (string) DIM[size(this)]
    function out = NameReadable(this); out = strcat("Damper ", this.Name); end

    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Length(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.len);
    end
    function out = Velocity(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.velocity);
    end
    function out = DampingConstant(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.dampingConstant);
    end

    % OUTPUT
    %   (CDS_T) DIM[:,1]
    function out = Connections(this)
        arguments
            this(1,1)
        end
        out = this.connections;
    end

    %**********************************************************************
    % Interface: Get - Energy and Power
    %***********************************
    % Damper potential energy
    % NOTES
    %   Although this is an energy function, it does not represent the total work done by the damper
    %   There does not seem to be any expression for the total work that is easy to evaluate
    %   So far, I can only think to numerically integrate the power, but this would have pretty bad numerical error
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Energy_D(this)
        if isempty(this)
            out = sym.empty(size(this));
            return;
        end
        out = 0.5*this.DampingConstant.*( this.Velocity ).^2;
    end

    % Time-rate of work done on the system (negative of the rate of energy dissipation)
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Power_dWdt(this)
        if isempty(this)
            out = sym.empty(size(this));
            return;
        end
        % dW/dt = - d[D]/d[qd] . qd
        q_d = this(1).sys.params.q.Sym(1);
        out = - jacobian(this(:).Energy_D, q_d) * q_d;
        out = reshape(out, size(this));
    end

    %**********************************************************************
    % Interface: Get - Forces
    %***********************************
    % The force exerted by the damper on the system,
    % as a generalised force vector, ordered with respect to sys.params.q
    % INPUT
    %   Required input if 'this' can be empty, otherwise optional
    % OUTPUT
    %   (symbolic expression) DIM[length(sys.params.q), size(this)] Using convention (tensor dims, batch dims)
    function out = Q(this, sys)
        arguments
            this
            sys CDS_SystemDescription = this(1).sys
        end
        % Q = - d[D]/d[qd]
        qd = sys.params.q.Sym(1);
        num_q = length(qd);
        out = - jacobian(this(:).Energy_D, qd).';
        out = reshape(out, [num_q, size(this)]);
    end
end
end

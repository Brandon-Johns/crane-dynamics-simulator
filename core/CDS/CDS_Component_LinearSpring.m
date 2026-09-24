%{
PURPOSE
    A linear spring (F = k*x)

DETAILS
    Each instance of this class is one spring that obeys: force = springConstant * (currentLength - naturalLength)

THEORY
    l(q, t)   : Length of the spring
    ln(const) : Natural (unstretched) length of the spring
    k(const)  : Spring constant
    Key equations
        Potential function
        V = 0.5 . k . (l - ln)^2

ADVICE
    Carefully consider if, when passing through zero-length, your spring should
        Turn around:          .SetLength( abs(L1) )
        Have negative length: .SetLength( L1 )
    The direction and magnitude of the force is very different between these
    Note that .SetConnections() always takes the absolute value

EXAMPLE
    % Given:
    %   O: CDS_Point
    %   A: CDS_Point
    %   B: CDS_Point
    %   sys: CDS_SystemDescription
    % Create spring with name "OA", that routes through a straight line path: origin->A
    % Create spring with name "OAB", that routes through a piecewise straight line path: origin->A->B
    sys.CreateLinearSpring("OA").SetConnections(O,A).SetSpringConstant(20).SetNaturalLength(50);
    sys.CreateLinearSpring("OA").SetConnections(O,A,B).SetSpringConstant(20).SetNaturalLength(50);

    % Given:
    %   L1:     sym registered as a CDS_Param_Free
    %   a:      sym registered as a CDS_Param_Const
    %   sys:    CDS_SystemDescription
    % Create spring with name "S1", that routes through an arbitrary path, with path-length L1+a+5
    %   and is at its natural length in the initial conditions
    sys.CreateLinearSpring("S1").SetLength(L1+a+5).SetSpringConstant(20).SetNaturalLength(0,"offsetFromIC");
%}

classdef CDS_Component_LinearSpring < CDS_NamedItem
properties (SetAccess=private)
    % Intended for internal use only
    sys(1,1) CDS_SystemDescription
end
properties (Access=private)
    % Avoid variable name "length" due to name collision
    len(1,1) sym = 0
    naturalLength(1,1) sym = 0
    springConstant(1,1) sym = 0

    % Connections are not necessary for calculating energy, but are necessary for plotting
    % this.SetConnections: Use if spring stays straight => easy to plot
    % this.SetLength:      Use in general case, but hard to plot e.g. negative length, curved path
    % If not specified, then leave empty
    connections(:,1) CDS_T = CDS_T.empty
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % Intended for internal use only
    % Creation should be done through CDS_SystemDescription.m
    function this = CDS_Component_LinearSpring(sys, name)
        this@CDS_NamedItem(name);
        this.sys = sys;
    end

    %**********************************************************************
    % Interface: Set
    %***********************************
    % Length of the spring
    % NOTE
    %   Connections are only used for the animation and are not validated to match L
    %   Animations of the solution will plot the spring as a line connecting the specified points
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
        this.len = L;
        this.connections = connections;
    end

    % The start and end connection points of the spring, and any route points
    % DETAIL
    %   1) Sets the total spring length as sum of lengths between each point it routes through
    %       Effectively .SetLength(|P_A - P_B| + |P_B - P_C| + |P_C - P_D| + ...)
    %   2) Animations of the solution will plot the spring as a line connecting the specified points
    % LIMITATIONS
    %   1) The calculation of total length can result in high numerical error or 'Div by 0' errors during solving
    %       due to factors in fractions that should cancel out, but do not
    %   2) The calculation of total length does not allow negative spring lengths
    %       because norm takes the absolute value of the displacement
    %       Although this will not effect this.Energy_D() because it uses Velocity^2
    %   3) The calculation of total length does not allow the spring to follow curved paths
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

    % Unstretched length of the spring
    % INPUT
    %   L: (symbolic expression) Permits values from CDS_Params.const.Sym
    %   mode
    %       "specified"
    %           The input L is used directly
    %       "offsetFromIC"
    %           The input L is added to the length of the spring in the initial conditions
    %           This calculation is performed immediately (be careful not to change ICs after)
    function this = SetNaturalLength(this, L, mode)
        arguments
            this(1,1)
            L(1,1) sym
            mode(1,1) string {mustBeMember(mode,["specified","offsetFromIC"])} = "specified"
        end
        if mode=="offsetFromIC"
            L = L + this.sys.params.EvaluateSymExpr_IC(this.len);
        end
        this.sys.params.isConst(L, "ErrorOnFalse");
        this.naturalLength = L;
    end

    % Spring constant
    % INPUT
    %   (symbolic expression) Permits values from CDS_Params.const.Sym
    function this = SetSpringConstant(this, k)
        arguments
            this(1,1)
            k(1,1) sym
        end
        this.sys.params.isConst(k, "ErrorOnFalse");
        this.springConstant = k;
    end

    %**********************************************************************
    % Interface: Get
    %***********************************
    % OUTPUT
    %   (string) DIM[size(this)]
    function out = NameReadable(this); out = strcat("Spring ", this.Name); end

    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Length(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.len);
    end
    function out = SpringConstant(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.springConstant);
    end
    function out = NaturalLength(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.naturalLength);
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
    % Spring potential energy
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Energy_V(this)
        if isempty(this)
            out = sym.empty(size(this));
            return;
        end
        out = 0.5*this.SpringConstant.*( this.Length - this.NaturalLength ).^2;
    end

    % Total energy contribution
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Energy_E(this); out = this.Energy_V; end

    % H: Total Hamiltonian contribution form, using hybrid forward-and-inverse-dynamics interpretation
    % Hf: Total Hamiltonian contribution form, using traditional interpretation
    % Decompositions thereof
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Hamiltonian_H(this);                     out = this.Energy_V + this.Hamiltonian_H_velocityDependentV; end
    function out = Hamiltonian_Hf(this);                    out = this.Energy_V + this.Hamiltonian_Hf_velocityDependentV; end
    function out = Hamiltonian_H_velocityDependentV(this);  out = CDS_Components_Common.Hamiltonian_H_velocityDependentV(this); end
    function out = Hamiltonian_Hf_velocityDependentV(this); out = CDS_Components_Common.Hamiltonian_Hf_velocityDependentV(this); end

    % dEdt: Time-rate of total energy contribution
    % Decompositions thereof
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Power_dEdt(this); out = this.Power_dVdt; end
    function out = Power_dVdt(this); out = CDS_Components_Common.Power_dVdt(this); end

    % dWdt: Time-rate of work done on the system
    % Decompositions thereof
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Power_dWdt(this); out = this.Power_dWdt_timeDependentV + this.Power_dWdt_velocityDependentV; end
    function out = Power_dWdt_timeDependentV(this);         out = CDS_Components_Common.Power_dWdt_timeDependentV(this); end
    function out = Power_dWdt_velocityDependentV(this);     out = CDS_Components_Common.Power_dWdt_velocityDependentV(this); end

    %**********************************************************************
    % Interface: Get - Forces
    %***********************************
    % The force exerted by the spring on the system,
    % as a generalised force vector, ordered with respect to sys.params.q
    % Decompositions thereof
    % INPUT
    %   Required input if 'this' can be empty, otherwise optional
    % OUTPUT
    %   (symbolic expression) DIM[length(sys.params.q), size(this)] Using convention (tensor dims, batch dims)
    function out = Q(this, sys)
        arguments
            this
            sys(1,1) CDS_SystemDescription = this(1).sys
        end
        out = this.Q_potential(sys) + this.Q_velocityDependentV(sys);
    end
    function out = Q_potential(this, sys)
        arguments
            this
            sys(1,1) CDS_SystemDescription = this(1).sys
        end
        out = CDS_Components_Common.Q_potential(this, sys);
    end
    function out = Q_velocityDependentV(this, sys)
        arguments
            this
            sys(1,1) CDS_SystemDescription = this(1).sys
        end
        out = CDS_Components_Common.Q_velocityDependentV(this, sys);
    end
end
end

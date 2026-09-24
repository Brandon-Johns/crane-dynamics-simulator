%{
PURPOSE
    A linear torsion spring (torque = k*theta)

DETAILS
    Each instance of this class is one spring that obeys: torque = springConstant * (currentAngle - naturalAngle)

THEORY
    angle(q, t)    : Angle of the spring
    angle_n(const) : Natural (unstretched) angle of the spring
    k(const)       : Spring constant
    Key equations
        Potential function
        V = 0.5 . k . (angle - angle_n)^2

ADVICE
    Carefully consider if, when passing through zero-length, your spring should
        Turn around:          .SetAngle( abs(L1) )
        Have negative length: .SetAngle( L1 )
    The direction and magnitude of the force is very different between these

EXAMPLE
    % Given:
    %   L1:     sym registered as a CDS_Param_Free
    %   a:      sym registered as a CDS_Param_Const
    %   sys:    CDS_SystemDescription
    % Create spring with name "S1", that routes through an arbitrary path, with angular displacement L1+a+5
    %   and is at its natural angle in the initial conditions
    sys.CreateTorsionSpring("S1").SetAngle(L1+a+5).SetSpringConstant(20).SetNaturalAngle(0,"offsetFromIC");
%}

classdef CDS_Component_TorsionSpring < CDS_NamedItem
properties (SetAccess=private)
    % Intended for internal use only
    sys(1,1) CDS_SystemDescription
end
properties (Access=private)
    angle(1,1) sym = 0
    naturalAngle(1,1) sym = 0
    springConstant(1,1) sym = 0
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % Intended for internal use only
    % Creation should be done through CDS_SystemDescription.m
    function this = CDS_Component_TorsionSpring(sys, name)
        this@CDS_NamedItem(name);
        this.sys = sys;
    end

    %**********************************************************************
    % Interface: Set
    %***********************************
    % Angle of the spring
    % INPUT
    %   (symbolic expression) Permits values from [CDS_Params.const.Sym; CDS_Params.q.Sym; sym('t','real')]
    function this = SetAngle(this, theta)
        arguments
            this(1,1)
            theta(1,1) sym
        end
        this.sys.params.isZeroDifferentialOrder(theta, "ErrorOnFalse");
        this.angle = theta;
    end

    % Unstretched angle of the spring
    % INPUT
    %   theta: (symbolic expression) Permits values from CDS_Params.const.Sym
    %   mode
    %       "specified"
    %           The input theta is used directly
    %       "offsetFromIC"
    %           The input theta is added to the angle of the spring in the initial conditions
    %           This calculation is performed immediately (be careful not to change ICs after)
    function this = SetNaturalAngle(this, theta, mode)
        arguments
            this(1,1)
            theta(1,1) sym
            mode(1,1) string {mustBeMember(mode,["specified","offsetFromIC"])} = "specified"
        end
        if mode=="offsetFromIC"
            theta = theta + this.sys.params.EvaluateSymExpr_IC(this.angle);
        end
        this.sys.params.isConst(theta, "ErrorOnFalse");
        this.naturalAngle = theta;
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
    function out = NameReadable(this); out = strcat("Torsion Spring ", this.Name); end

    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Angle(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.angle);
    end
    function out = SpringConstant(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.springConstant);
    end
    function out = NaturalAngle(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.naturalAngle);
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
        out = 0.5*this.SpringConstant.*( this.Angle - this.NaturalAngle ).^2;
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

%{
PURPOSE
    A particle, rigid body, or massless location

DETAILS
    Each instance of this class is one location
    The location is defined by a transformation matrix (it has both position and orientation)

THEORY
    Rigid body
        T_0n(q, t)  : Location and orientation of the centre of mass of the body (in world coordinates)
        m(const)    : Mass
        I_p(const)  : Mass moment of inertia tensor, as measured at T_0n
        R_np(const) : Rotation from the orientation defined by T_0n, to the orientation that I_p was measured in
    Particle
        T_0n(q, t)  : Location of the centre of mass of the particle (in world coordinates)
        m(const)    : Mass
        I_p(const)  : (Set as a 3x3 matrix of zeros)
        R_np(const) : (Not used)
    Massless location
        T_0n(q, t)  : Location (in world coordinates)
        m(const)    : (Set as 0)
        I_p(const)  : (Set as a 3x3 matrix of zeros)
        R_np(const) : (Not used)

NOTATION
    T_AB means the transformation matrix that satisfies the relation P_A = T_AB * P_B, where
        P_A is a point as measured in frame A
        P_B is the same point as measured in frame B
    Frames
        0: The world frame (must be the same for all points in a system)
        n: This point, where
            The origin is at the centre of mass
            The orientation is the orientation of the body (mostly only relevant for rigid bodies)
        p: This point, where
            The origin is the same as for frame n
            The orientation is that about which the moment of inertia was measured
    The transformation T_np is intended to be a constant
%}

classdef CDS_Point < CDS_NamedItem
properties (SetAccess=private)
    % Intended for internal use only
    sys(1,1) CDS_SystemDescription
end
properties (Access=private)
    T_0n_(1,1) CDS_T = CDS_T(eye(4))

    m_(1,1) sym = 0 % Default no mass at point
    I_p_(3,3) sym = zeros(3) % Default point mass assumption
    R_np_(3,3) sym = eye(3) % Default aligned
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % Intended for internal use only
    % Creation should be done through CDS_SystemDescription.m
    function this = CDS_Point(sys, name)
        this@CDS_NamedItem(name);
        this.sys = sys;

        % Initialise as work around for a MATLAB memory corruption bug in live scripts (seen in R2020b)
        %   related to using IfHasMass with unsuppressed output
        this.m_ = 0;
        this.I_p_ = zeros(3);
    end

    %**********************************************************************
    % Interface: Set
    %***********************************
    % Pose of the point in the world frame
    % This defines frame 'n'
    % DEFAULT
    %   At origin
    % INPUT
    %   (CDS_T(symbolic expression))
    %       Transformation matrix from the world frame to the point frame
    %       The symbolic expression permits values from [CDS_Params.const.Sym; CDS_Params.q.Sym; sym('t','real')]
    function this = SetT_0n(this, T)
        arguments
            this(1,1)
            T(1,1) CDS_T
        end
        this.sys.params.isZeroDifferentialOrder(T.T, "ErrorOnFalse");
        this.T_0n_ = T;
    end

    % Mass of the point
    % DEFAULT
    %   No mass
    % INPUT
    %   (symbolic expression) Permits values from CDS_Params.const.Sym
    function this = SetMass(this, m)
        arguments
            this(1,1)
            m(1,1) sym
        end
        this.sys.params.isConst(m, "ErrorOnFalse");
        this.m_ = m;
    end

    % Mass moment of inertia of the point
    % The frame that this is specified in defines frame 'p'
    % DEFAULT
    %   No moment of inertia (point mass assumption)
    % INPUT
    %   (symbolic expression) Permits values from CDS_Params.const.Sym
    function this = SetInertia(this, I)
        arguments
            this(1,1)
            I(3,3) sym
        end
        this.sys.params.isConst(I, "ErrorOnFalse");
        this.I_p_ = I;
    end

    % Orientation at which the moment of inertia was measured, relative to the nominal point frame
    % In other words, the orientation of frame 'p', relative to frame 'n'
    % DEFAULT
    %   Aligned (identity matrix)
    % INPUT
    %   (symbolic expression) Permits values from CDS_Params.const.Sym
    function this = SetInertiaR(this, R_np)
        arguments
            this(1,1)
            R_np(3,3) sym
        end
        this.sys.params.isConst(R_np, "ErrorOnFalse");
        this.R_np_ = R_np;
    end

    %**********************************************************************
    % Interface: Get
    %***********************************
    % OUTPUT
    %   (string) DIM[size(this)]
    function out = NameReadable(this); out = strcat("Point ", this.Name); end

    % OUTPUT
    %   (CDS_T) DIM[size(this)]
    function out = T_0n(this)
        if isempty(this); out=CDS_T.empty(size(this)); return; end
        out = this.PropArray(this.T_0n_);
    end

    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = m(this)
        if isempty(this); out=sym.empty(size(this)); return; end
        out = this.PropArray(this.m_);
    end

    % Motion of inertia tensor, as measured in frame 'p'
    % OUTPUT
    %   (symbolic expression) DIM[3,3, size(this)] Using convention (tensor dims, batch dims)
    function out = I_p(this)
        if isempty(this); out=sym.empty([3,3,size(this)]); return; end
        out = reshape([this.I_p_],  [3,3, size(this)]);
    end

    % Motion of inertia tensor, as measured in frame 'n'
    % OUTPUT
    %   (symbolic expression) DIM[3,3, size(this)] Using convention (tensor dims, batch dims)
    function out = I_n(this)
        % Note: page functions don't support symbolic arrays
        out = sym.zeros([3,3, length(this)]);
        for idx = 1:numel(this)
            % Moment of inertia: nominal frame <- specified frame
            out(:,:,idx) = this(idx).R_np_ * this(idx).I_p_ * (this(idx).R_np_.');
        end
        out = reshape(out, [3,3, size(this)]);
    end

    % Orientation at which the moment of inertia was measured, relative to the nominal point frame
    % In other words, the orientation of frame 'p', relative to frame 'n'
    % OUTPUT
    %   (symbolic expression) DIM[3,3, size(this)] Using convention (tensor dims, batch dims)
    function out = R_np(this)
        if isempty(this); out=sym.empty([3,3,size(this)]); return; end
        out = reshape([this.R_np_],  [3,3, size(this)]);
    end

    % Test properties of the point
    % OUTPUT
    %   (logical) DIM[size(this)]
    function result = HasLinearInertia(this)
        result = logical(this.m~=0);
    end
    function result = HasRotationalInertia(this)
        result = false(size(this));
        for idx = 1:length(this)
            result(idx) = ~isequal(this(idx).I_p, sym(zeros(3)));
        end
    end
    function result = HasMass(this)
        result = this.HasLinearInertia | this.HasRotationalInertia;
    end
    function result = IsPointMass(this)
        result = this.HasLinearInertia & ~this.HasRotationalInertia;
    end
    function result = IsRigidBody(this)
        result = this.HasLinearInertia & this.HasRotationalInertia;
    end

    % From an array of point objects, get all the point objects that have mass
    % OUTPUT
    %   (CDS_Point) DIM[]
    %       with orientation as a row/col vector to match the input
    %       if iscolumn(this): with DIM[n,1], where 0<=n<=length(this)
    %       if isrow(this):    with DIM[1,n], where 0<=n<=length(this)
    function selfSubset = GetIfHasMass(this)
        arguments
            this {mustBeVector}
        end
        selfSubset = this(this.HasMass);
    end

    %**********************************************************************
    % Interface: Get - Energy and Power
    %***********************************
    % Gravitational potential energy
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Energy_V(this)
        if isempty(this)
            out = sym.empty(size(this));
            return;
        end

        out = sym(zeros(size(this)));
        for idx = 1:numel(this)
            if ~this(idx).HasLinearInertia
                continue;
            end

            % Position of center of mass
            % Value of mass
            P0n = this(idx).T_0n().P;
            mass = this(idx).m;

            % Potential energy = sum(-mg.P)
            out(idx) = -mass*(this(1).sys.g0.')*P0n;
        end
        this(1).sys.params.isLessThanMaxDifferentialOrder(out, "ErrorOnFalse");
    end

    % Kinetic energy
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Energy_K(this)
        if isempty(this)
            out = sym.empty(size(this));
            return;
        end

        q = this(1).sys.params.q.Sym;
        q_d = this(1).sys.params.q.Sym(1);
        q_swap = this(1).sys.params.q_SymSwap;
        q_swap_t = this(1).sys.params.q_SymSwap('t');

        out = sym(zeros(size(this)));
        for idx = 1:numel(this)
            if ~this(idx).HasMass
                continue;
            end

            % Position & orientation of center of mass
            P0n = this(idx).T_0n().P;
            R0n = this(idx).T_0n().R;

            % Velocity of center of mass
            P0n_d = jacobian(P0n, q)*q_d + jacobian(P0n, sym('t','real'));

            % Branch: using point mass assumption or not
            if this(idx).IsPointMass
                % Set moment of inertia = 0
                % => angular velocity doesn't matter => set w=0
                Inn = zeros(3,3);
                wnn = [0;0;0];
            else
                % Moment of inertia: joint frame <- principal frame
                Inn = this(idx).R_np * this(idx).I_p * (this(idx).R_np.');

                % Angular velocity of center of mass
                %   NOTE: Carefully define input T0n for correct R0n.
                %   > Conflict with 'moving then rotating' instead of 'rotating then moving'
                %   > T0n should not rotate towards next link
                % Derivation for relation for R->w
                %   https://en.wikipedia.org/wiki/Rotation_formalisms_in_three_dimensions#Rotation_matrix_%E2%86%94_angular_velocities
                R0n_t = subs(R0n, q_swap, q_swap_t);
                Wnn = diff(R0n_t, sym('t','real'))*(R0n_t.'); % Angular velocity tensor
                wnn_t = [Wnn(3,2); Wnn(1,3); Wnn(2,1)]; % Decompose angular velocity tensor
                wnn = subs(wnn_t, q_swap_t, q_swap);
                % TODO: rigorously test the following replacement code
                %Wnn = this(idx).sys.params.TotalDiff(R0n) * (R0n.'); % Angular velocity tensor
                %wnn = [Wnn(3,2); Wnn(1,3); Wnn(2,1)]; % Decompose angular velocity tensor
            end

            mass = this(idx).m;

            % Kinetic energy = sum(0.5m(v').v + 0.5(w').I.w)
            out(idx) = (1/2)*mass*(P0n_d.')*P0n_d + (1/2)*(wnn.')*Inn*wnn;
        end
        this(1).sys.params.isLessThanMaxDifferentialOrder(out, "ErrorOnFalse");
    end

    % Total energy contribution
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Energy_E(this)
        out = this.Energy_V + this.Energy_K;
    end

    % H: Total Hamiltonian contribution form, using hybrid forward-and-inverse-dynamics interpretation
    % Hf: Total Hamiltonian contribution form, using traditional interpretation
    % Decompositions thereof
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Hamiltonian_H(this)
        out = this.Energy_K + this.Energy_V + this.Hamiltonian_H_nonQuadraticK + this.Hamiltonian_H_velocityDependentV;
    end
    function out = Hamiltonian_Hf(this)
        out = this.Energy_K + this.Energy_V + this.Hamiltonian_Hf_nonQuadraticK + this.Hamiltonian_Hf_velocityDependentV;
    end
    function out = Hamiltonian_H_nonQuadraticK(this);       out = CDS_Components_Common.Hamiltonian_H_nonQuadraticK(this); end
    function out = Hamiltonian_Hf_nonQuadraticK(this);      out = CDS_Components_Common.Hamiltonian_Hf_nonQuadraticK(this); end
    function out = Hamiltonian_H_velocityDependentV(this);  out = CDS_Components_Common.Hamiltonian_H_velocityDependentV(this); end
    function out = Hamiltonian_Hf_velocityDependentV(this); out = CDS_Components_Common.Hamiltonian_Hf_velocityDependentV(this); end

    % dEdt: Time-rate of total energy contribution
    % Decompositions thereof
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Power_dEdt(this); out = this.Power_dKdt + this.Power_dVdt; end
    function out = Power_dKdt(this); out = CDS_Components_Common.Power_dKdt(this); end
    function out = Power_dVdt(this); out = CDS_Components_Common.Power_dVdt(this); end

    % dWdt: Time-rate of work done on the system
    % Decompositions thereof
    % OUTPUT
    %   (symbolic expression) DIM[size(this)]
    function out = Power_dWdt(this)
        out = this.Power_dWdt_timeDependent + this.Power_dWdt_nonQuadraticK + this.Power_dWdt_velocityDependentV;
    end
    function out = Power_dWdt_timeDependent(this)
        out = this.Power_dWdt_timeDependentK + this.Power_dWdt_timeDependentV;
    end
    function out = Power_dWdt_timeDependentK(this);     out = CDS_Components_Common.Power_dWdt_timeDependentK(this); end
    function out = Power_dWdt_timeDependentV(this);     out = CDS_Components_Common.Power_dWdt_timeDependentV(this); end
    function out = Power_dWdt_nonQuadraticK(this);      out = CDS_Components_Common.Power_dWdt_nonQuadraticK(this); end
    function out = Power_dWdt_velocityDependentV(this); out = CDS_Components_Common.Power_dWdt_velocityDependentV(this); end

    %**********************************************************************
    % Interface: Get - Forces
    %***********************************
    % The generalised force vector, ordered with respect to sys.params.q
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
        out = this.Q_inertial(sys) + this.Q_CentrifugalAndCoriolis(sys) + this.Q_timeDependentK(sys);
        out = out + this.Q_velocityDependentV(sys) + this.Q_potential(sys);
    end
    function out = Q_inertial(this, sys)
        arguments
            this
            sys(1,1) CDS_SystemDescription = this(1).sys
        end
        out = CDS_Components_Common.Q_inertial(this, sys);
    end
    function out = Q_CentrifugalAndCoriolis(this, sys)
        arguments
            this
            sys(1,1) CDS_SystemDescription = this(1).sys
        end
        out = CDS_Components_Common.Q_CentrifugalAndCoriolis(this, sys);
    end
    function out = Q_timeDependentK(this, sys)
        arguments
            this
            sys(1,1) CDS_SystemDescription = this(1).sys
        end
        out = CDS_Components_Common.Q_timeDependentK(this, sys);
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

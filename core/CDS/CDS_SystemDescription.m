%{
PURPOSE
    Defines 1 system

DETAILS
    This class is used to build and access the attributes that define a system
    It holds all of the information required to simulate a system
    An instance of this fully defines a system

    Build instances of
        CDS_Point
        CDS_Component_LinearSpring
        CDS_Component_TorsionSpring
        CDS_Component_LinearDamper
        CDS_Component_PointForce
        CDS_Component_GeneralisedForce
        CDS_Component_Constraint
    Track every instance that it creates
    For any CDS_Point with mass / moment of inertia, automatically create required CDS_Param instances

    All parameters of the system should be built using the CDS_Params instance contained in the property .params

INTERNAL
    Using builder and factory patterns
%}

classdef CDS_SystemDescription < handle
properties (SetAccess=private)
    % Dedicated parameter builder/manager for this system
    % All contained parameters contribute to the system definition
    % Only the parameters contained by this instance may be used in the definition of this system
    params(1,1) CDS_Params

    % All components built by this instance
    % All contained components contribute to the system definition
    % Contained symbolic expressions permit only the syms registered in this.params
    points(:,1) CDS_Point
    linearSprings(:,1) CDS_Component_LinearSpring
    torsionSprings(:,1) CDS_Component_TorsionSpring
    linearDampers(:,1) CDS_Component_LinearDamper
    pointForces(:,1) CDS_Component_PointForce
    generalisedForces(:,1) CDS_Component_GeneralisedForce
    constraints(:,1) CDS_Component_Constraint

    % Kinematic chains (used only for plotting the animation)
    % Each cell is one chain
    % Permits only the points registered in this.points
    chains(1,:) cell = {} % (cell{CDS_Point(:,1)})

    % Gravitational acceleration vector
    % Permits only the syms registered in this.params
    g0(3,1) sym = zeros(3,1)

    % Constraint stabilisation factors (used during solving)
    BaumgarteStabilisation_alpha(1,1) double = 0
    BaumgarteStabilisation_beta(1,1) double = 0
end

methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % AUTO CREATES
    %   params: CDS_Params that holds every param used in points and g0
    function this = CDS_SystemDescription()
        this.params = CDS_Params();

        % Initialise as work around for a MATLAB memory corruption bug (seen in R2025a)
        %   For no reason, the solution will be full of NaN.
        %   Try viewing sys.g0, and the message displays
        %       "Warning: Unable to display symbolic object because 'symengine' was reset. Repeat commands to regenerate result."
        %   Very similar to bug seen 5 years ago affecting CDS_Point, but not related to live scripts this time
        this.g0 = zeros(3,1);
    end

    %**********************************************************************
    % Interface: Build
    %***********************************
    % Build instances of CDS_Point
    % INPUT
    %   sym_append
    %       Name to represent the point. Each point must have a unique name
    %       Must be a valid variable name
    %   mass_num
    %       Mass of the point
    %   inertia_num DIM[[3,3] | [3,1]]
    %       Mass moment of inertia of the point
    %       Inputs of size 3x1 are expanded into a diagonal 3x3 matrix
    % OUTPUT
    %   (CDS_Point) DIM[1,1]
    %       The created object
    %       The properties not in the call signature default zero. Chain the .Set methods on the output
    % SIDE EFFECTS
    %   A sym is automatically instanced in the scope of the caller
    %       sym=sym_append
    %   A CDS_Param_Const is created for each provided non-zero mass and moment of inertia element
    %       Mass:    sym="m"+sym_append
    %       Inertia: sym="I_xx"+sym_append, etc.
    function builtObject = CreatePoint(this, sym_append, mass_num, inertia_num)
        arguments
            this(1,1)
            sym_append(1,1) string
            mass_num(1,1) double {mustBeFinite} = 0
            inertia_num(:,:) double {mustBeFinite} = [0;0;0]
        end
        % Check Moment of inertia input
        if isvector(inertia_num); inertia_num=inertia_num(:); end
        if ( isvector(inertia_num) && length(inertia_num)~=3 ) || ( ~isvector(inertia_num) && any(size(inertia_num,1)~=3) )
            error("Moment of inertia must be size: 3x1 or 3x3");
        end

        % Check if duplicate
        if this.points.Contains(sym_append)
            error('Point already exists and registered: %s', sym_append)
        end

        % Create and register
        builtObject = CDS_Point(this, sym_append);
        this.points(end+1) = builtObject;

        % Mass
        if mass_num == 0
            %
        else
            % Create new parameters & set num
            m = this.params.Create('const', strcat('m',sym_append));
            m.SetNum(mass_num);

            builtObject.SetMass(m.Sym);
        end

        % Inertia
        % Create new parameters & set num
        if isequal(inertia_num, [0;0;0]) || isequal(inertia_num, zeros(3,3))
            % No Moment of inertia (No mass or Point mass)
        elseif isvector(inertia_num)
            % Moment of inertia aligned with principle axis
            Ixx = this.params.Create('const', strcat('I_xx',sym_append));
            Iyy = this.params.Create('const', strcat('I_yy',sym_append));
            Izz = this.params.Create('const', strcat('I_zz',sym_append));
            Ixx.SetNum(inertia_num(1));
            Iyy.SetNum(inertia_num(2));
            Izz.SetNum(inertia_num(3));

            builtObject.SetInertia(diag([Ixx.Sym, Iyy.Sym, Izz.Sym]));
        else
            % General moment of inertia tensor
            Ixx = this.params.Create('const', strcat('I_xx',sym_append)).SetNum(inertia_num(1,1));
            Ixy = this.params.Create('const', strcat('I_xy',sym_append)).SetNum(inertia_num(1,2));
            Ixz = this.params.Create('const', strcat('I_xz',sym_append)).SetNum(inertia_num(1,3));
            Iyx = this.params.Create('const', strcat('I_yx',sym_append)).SetNum(inertia_num(2,1));
            Iyy = this.params.Create('const', strcat('I_yy',sym_append)).SetNum(inertia_num(2,2));
            Iyz = this.params.Create('const', strcat('I_yz',sym_append)).SetNum(inertia_num(2,3));
            Izx = this.params.Create('const', strcat('I_zx',sym_append)).SetNum(inertia_num(3,1));
            Izy = this.params.Create('const', strcat('I_zy',sym_append)).SetNum(inertia_num(3,2));
            Izz = this.params.Create('const', strcat('I_zz',sym_append)).SetNum(inertia_num(3,3));

            inertia_sym = [Ixx.Sym,Ixy.Sym,Ixz.Sym; Iyx.Sym,Iyy.Sym,Iyz.Sym; Izx.Sym,Izy.Sym,Izz.Sym];
            builtObject.SetInertia(inertia_sym);
        end
    end

    % Build instances of CDS_Component_LinearSpring
    % INPUT
    %   Name to represent the component. Each component must have a unique name within its type
    % OUTPUT
    %   (CDS_Component_LinearSpring) DIM[1,1]
    %       The created object
    %       All properties default zero. Chain the .Set methods on the output
    function builtObject = CreateLinearSpring(this, name)
        arguments
            this(1,1)
            name(1,1) string
        end
        if this.linearSprings.Contains(name)
            error('Component already exists and registered: %s', name)
        end
        builtObject = CDS_Component_LinearSpring(this, name);
        this.linearSprings(end+1) = builtObject;
    end

    % Build instances of CDS_Component_TorsionSpring
    % INPUT
    %   Name to represent the component. Each component must have a unique name within its type
    % OUTPUT
    %   (CDS_Component_TorsionSpring) DIM[1,1]
    %       The created object
    %       All properties default zero. Chain the .Set methods on the output
    function builtObject = CreateTorsionSpring(this, name)
        arguments
            this(1,1)
            name(1,1) string
        end
        if this.torsionSprings.Contains(name)
            error('Component already exists and registered: %s', name)
        end
        builtObject = CDS_Component_TorsionSpring(this, name);
        this.torsionSprings(end+1) = builtObject;
    end

    % Build instances of CDS_Component_LinearDamper
    % INPUT
    %   Name to represent the component. Each component must have a unique name within its type
    % OUTPUT
    %   (CDS_Component_LinearDamper) DIM[1,1]
    %       The created object
    %       All properties default zero. Chain the .Set methods on the output
    function builtObject = CreateLinearDamper(this, name)
        arguments
            this(1,1)
            name(1,1) string
        end
        if this.linearDampers.Contains(name)
            error('Component already exists and registered: %s', name)
        end
        builtObject = CDS_Component_LinearDamper(this, name);
        this.linearDampers(end+1) = builtObject;
    end

    % Build instances of CDS_Component_PointForce
    % INPUT
    %   Name to represent the component. Each component must have a unique name within its type
    % OUTPUT
    %   (CDS_Component_PointForce) DIM[1,1]
    %       The created object
    %       All properties default zero. Chain the .Set methods on the output
    function builtObject = CreatePointForce(this, name)
        arguments
            this(1,1)
            name(1,1) string
        end
        if this.pointForces.Contains(name)
            error('Component already exists and registered: %s', name)
        end
        builtObject = CDS_Component_PointForce(this, name);
        this.pointForces(end+1) = builtObject;
    end

    % Build instances of CDS_Component_GeneralisedForce
    % INPUT
    %   Name to represent the component. Each component must have a unique name within its type
    % OUTPUT
    %   (CDS_Component_GeneralisedForce) DIM[1,1]
    %       The created object
    %       All properties default zero. Chain the .Set methods on the output
    function builtObject = CreateGeneralisedForce(this, name)
        arguments
            this(1,1)
            name(1,1) string
        end
        if this.generalisedForces.Contains(name)
            error('Component already exists and registered: %s', name)
        end
        builtObject = CDS_Component_GeneralisedForce(this, name);
        this.generalisedForces(end+1) = builtObject;
    end

    % Build instances of CDS_Component_Constraint
    % INPUT
    %   Name to represent the component. Each component must have a unique name within its type
    % OUTPUT
    %   (CDS_Component_Constraint) DIM[1,1]
    %       The created object
    %       All properties default zero. Chain the .Set methods on the output
    % SIDE EFFECTS
    %   A CDS_Param_Lambda (a lagrange multiplier) is created, and immutably linked to the constraint
    %   Lagrange multiplier: sym="lambda_"+sym_append
    function builtObject = CreateConstraint(this, name)
        arguments
            this(1,1)
            name(1,1) string
        end
        if this.constraints.Contains(name)
            error('Component already exists and registered: %s', name)
        end
        % IMPORTANT
        %   The solver assumes: all(sys.constraints.Lambda == sys.params.lambda.Sym)
        %   Thus, the creation/management of lambda and constraints should be strictly tied together
        %   This function fulfils this role

        % Create lagrange multiplier
        lam = this.params.Create("lambda", strcat("lambda_",name));

        % Create and register
        builtObject = CDS_Component_Constraint(this, name, lam.Sym);
        this.constraints(end+1) = builtObject;
    end

    %**********************************************************************
    % Interface: Set
    %***********************************
    % Kinematic chains (used only for plotting the animation)
    % INPUT (Repeating)
    %   Where each array of points is a kinematic chain
    function this = SetChains(this, chains)
        arguments
            this(1,1)
        end
        arguments (Repeating)
            chains(1,:) CDS_Point
        end
        for idx = 1:length(chains)
            notFound = ~this.points.Contains(chains{idx});
            if any(notFound)
                error("Bad input: Points not registered: " + strjoin(chains{idx}(notFound).NameReadable, ", "));
            end
        end
        this.chains = chains;
    end

    % Gravitational acceleration vector
    % INPUT
    %   (symbolic expression) Vector specifying magnitude and direction of gravity
    function this = SetGravity(this, g0)
        arguments
            this(1,1)
            g0(3,1) sym
        end
        this.params.isConst(g0, "ErrorOnFalse");
        this.g0 = g0;
    end

    % Baumgarte stabilisation factors
    % REFERENCE
    %   CITATION: Baumgarte J. 1972. "Stabilization of constraints and integrals of motion in dynamical systems".
    %   SECTION:  Type 1, holonomic constraints. See equations 23,35,42,43
    % THEORY
    %   This concerns the use of constraints, and controlling accumulated numerical error
    %   Consider the idea of 'PID' control
    %       The constraint equations are double-differentiated internally
    %       The solver objective is therefore to minimise the error of
    %           0 = C_dd
    %       This is like a 'D' controller, but for the 2nd derivative
    %       Therefore, the position can drift to a large value while the error in 0=C_dd stays small
    %       0 = C + (slowly accumulating error)
    %   Baumgarte stabilisation changes the solver objective to minimise the error of
    %       0 = C_dd + 2*alpha*C_d + (beta^2)*C
    %       This is like a 'PD' controller... or rather a 'P-D-DD' (position,derivative,double-derivative)
    % RECOMMENDED VALUES
    %   The article requires
    %       alpha > 0
    %   The article suggests
    %       alpha = beta
    %       alpha ~ 10
    %   Some oher articles suggest
    %       alpha = 1/(solver step size)
    % DEFAULT
    %   No stabilisation is applied. alpha=beta=0
    % INPUT
    %   alpha: Baumgarte stabilisation factors alpha
    %   beta:  Baumgarte stabilisation factors beta
    function this = SetConstraint_StabilisationFactors(this, alpha, beta)
        arguments
            this(1,1)
            alpha(1,1) double = 10
            beta(1,1) double = alpha
        end
        this.BaumgarteStabilisation_alpha = alpha;
        this.BaumgarteStabilisation_beta = beta;
    end
end
end

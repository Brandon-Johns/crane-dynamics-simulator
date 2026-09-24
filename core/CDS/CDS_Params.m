%{
PURPOSE
    Build and access system parameters

DETAILS
    All instances of CDS_Param subclasses for a given system should be built through 1 instance of this
    The instance tracks every instance and interface that it creates

INTERNAL
    Builder pattern:
        Separate object construction from object representation
        => Simplifies logic in the created object e.g. complex relations and validation
    Factory method pattern:
        Centralise object creation, allowing choice from several implementations
        => Can create objects without specifying class of object to create
%}

classdef CDS_Params < handle
properties (SetAccess=private)
    % All parameters built by this instance
    const(:,1) CDS_Param_Const
    q_free(:,1) CDS_Param_Free
    q_input(:,1) CDS_Param_Input
    lambda(:,1) CDS_Param_Lambda

    % Intended for internal use only
    % Set the state vector interface to include or exclude lambda
    %   Include if using an implicit solver
    %   Exclude if the constraint has been solved by reforming the equations
    x_mode(1,1) string {mustBeMember(x_mode,["withoutLambda","withLambda"])} = "withLambda"

    % Intended for internal use only
    % Set the maximum order of q_free that appears in the state vector
    %   Set 1 for almost all cases
    %   Set 2 to achieve index-1 DAEs when using an implicit solver
    x_order_qf(1,1) double {mustBeMember(x_order_qf,[1,2])} = 1
end
properties (Access=private)
    q_free_interface(:,1) CDS_Param_x
    q_free_d_interface(:,1) CDS_Param_x
    q_free_dd_interface(:,1) CDS_Param_x
    lambda_interface(:,1) CDS_Param_x
    q_input_interface(:,1) CDS_Param_u
    q_input_d_interface(:,1) CDS_Param_u
    q_input_dd_interface(:,1) CDS_Param_u
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % Most uses should not manually instance this class, but instead
    % use the property .params of an instance of CDS_SystemDescription.m
    function this = CDS_Params()
        %
    end

    %**********************************************************************
    % Interface: Build
    %***********************************
    % Build instances of CDS_Param subclasses
    % INPUT
    %   paramType
    %       "const":  Build CDS_Param_Const
    %       "free":   Build CDS_Param_Free
    %       "input":  Build CDS_Param_Input
    %       "lambda": Build CDS_Param_Lambda (Intended for internal use only)
    %   paramIn
    %       Symbolic variable to represent the parameter. Each parameter must have a unique sym
    % OUTPUT
    %   (CDS_Param) DIM[1,1]
    %       One of [CDS_Param_Const; CDS_Param_Free; CDS_Param_Input; CDS_Param_Lambda]
    %       The created parameter
    %       Most properties of the created parameter default zero. Chain the .Set methods on the output
    function builtObject = Create(this, paramType, paramIn)
        arguments
            this(1,1)
            paramType(1,1) string {mustBeMember(paramType, ["const","free","input","lambda"])}
            paramIn(1,1) string
        end
        % Disallow empty string
        % Disallow t
        % Disallow ending in d, except for constants
        if paramIn==""; error("Parameter name is an empty string"); end
        if paramIn=="t"; error("Parameter name 't' is reserved to represent time"); end
        if paramType~="const" && extract(paramIn,strlength(paramIn))=="d"
            error("Parameter names (of non-constant parameters) ending in 'd' are reserved to represent time derivatives: "+paramIn);
        end

        % Check if duplicate
        if this.All.Contains(paramIn)
            error('Parameter already exists and registered: %s', paramIn)
        end

        % Check if already defined within scope of caller
        % exist()==7 is such a troll
        inputExists = evalin('caller', "any(exist('"+paramIn+"')==[1:6,8])&&(class("+paramIn+")~=""sym"")");
        if inputExists
            warning('Variable of same name, which is not a sym, is already defined in caller. It will be overwritten.')
        end

        % Define inputs as syms in scope of caller
        assignin('caller', paramIn, sym(paramIn, 'real'));

        % Create & register new param
        if strcmp(paramType, 'const')
            % Create Param
            builtObject = CDS_Param_Const(paramIn);
            this.const(end+1) = builtObject;

        elseif strcmp(paramType, 'free')
            % Create Param
            builtObject = CDS_Param_Free(paramIn);
            this.q_free(end+1) = builtObject;

            % Create Interfaces
            interface = CDS_Param_x(builtObject);
            interface_d = CDS_Param_x(builtObject, 1);
            interface_dd = CDS_Param_x(builtObject, 2);
            this.q_free_interface(end+1) = interface;
            this.q_free_d_interface(end+1) = interface_d;
            this.q_free_dd_interface(end+1) = interface_dd;

        elseif strcmp(paramType, 'input')
            % Create Param
            builtObject = CDS_Param_Input(paramIn);
            this.q_input(end+1) = builtObject;

            % Create Interfaces
            interface = CDS_Param_u(builtObject);
            interface_d = CDS_Param_u(builtObject, 1);
            interface_dd = CDS_Param_u(builtObject, 2);
            this.q_input_interface(end+1) = interface;
            this.q_input_d_interface(end+1) = interface_d;
            this.q_input_dd_interface(end+1) = interface_dd;

        elseif strcmp(paramType, 'lambda')
            % Create Param
            builtObject = CDS_Param_Lambda(paramIn);
            this.lambda(end+1) = builtObject;

            % Create Interface
            interface = CDS_Param_x(builtObject);
            this.lambda_interface(end+1) = interface;
        else
            error('Invalid input: paramType')
        end
    end

    %**********************************************************************
    % Interface: Set
    %***********************************
    % Intended for internal use only
    function SetStateVectorMode(this, mode)
        arguments
            this(1,1)
            mode
        end
        this.x_mode = mode;
    end

    % Intended for internal use only
    function SetStateVectorMode_differential_order_of_q_free(this, order)
        arguments
            this(1,1)
            order
        end
        this.x_order_qf = order;
    end

    % Intended for internal use only
    function out = StateVectorMode_differential_order_of_q_free(this)
        arguments
            this(1,1)
        end
        out = this.x_order_qf;
    end

    %**********************************************************************
    % Interface: Get - Built Objects
    %***********************************
    % Array of all built objects
    % NOTE
    %   'All objects' is not 'all syms'
    %   All syms is rather context dependent. It can be found by
    %   unique([
    %       params.const.Sym;
    %       params.x("withLambda",2).Sym;
    %       params.x("withLambda",2).Sym(1);
    %       params.u.Sym;
    %       sym('t','real')
    %   ], "stable");
    %   Although, even this list excludes the symfun representations (see SymSwap)
    % OUTPUT
    %   (CDS_Param) DIM[numObjects,1] Heterogeneous array of [CDS_Param_Const; CDS_Param_Free; CDS_Param_Input; CDS_Param_Lambda]
    function heldObjects = All(this)
        arguments
            this(1,1)
        end
        heldObjects = [this.const; this.q_free; this.q_input; this.lambda];
    end

    % Array of all built free and input generalised coordinates
    % OUTPUT
    %   (CDS_Param) DIM[numGeneralisedCoords,1] Heterogeneous array of [CDS_Param_Free; CDS_Param_Input]
    function heldObjects = q(this)
        arguments
            this(1,1)
        end
        heldObjects = [this.q_free; this.q_input];
    end

    % Intended for internal use only
    % Get the state vector interface
    % NOTE
    %   Output is dependent on setting of "SetStateVectorMode" and "StateVectorMode_differential_order_of_q_free"
    function heldObjects = x(this, x_mode, x_order_qf)
        arguments
            this(1,1)
            x_mode(1,1) string {mustBeMember(x_mode,["withoutLambda","withLambda"])} = this.x_mode
            x_order_qf(1,1) double {mustBeMember(x_order_qf,[1,2])} = this.x_order_qf
        end
        % IMPORTANT:
        %   Changes require careful testing
        %   Equations assuming the order of the state vector are hardcoded in
        %       CDS_Solver_ODEs_Eval.Evaluate()
        %       CDS_Solver_ODEs2_Eval.Evaluate()
        %       CDS_Solver_ReformEquations.Implicit(), .MassMatrix(), .Solve_WithConstraint(), .Solve_NoConstraint()
        %       CDS_SolutionSim.CDS_SolutionSim()
        %       Maybe other places
        heldObjects = [this.q_free_d_interface; this.q_free_interface];
        if strcmp(x_mode, "withLambda")
            heldObjects = [heldObjects; this.lambda_interface];
        end
        if x_order_qf==2
            % The order of the state vector is a little weird now, but oh well
            heldObjects = [heldObjects; this.q_free_dd_interface];
        end
    end

    % Intended for internal use only
    % Get the state input interface
    function heldObjects = u(this)
        arguments
            this(1,1)
        end
        heldObjects = [this.q_input_interface; this.q_input_d_interface; this.q_input_dd_interface];
    end

    % Get specific built objects, as referenced by name or sym
    % NOTE
    %   Shortcut for calling this.All.Subset
    % INPUT
    %   namesIn
    %       (string)            Vector of values from CDS_Param.Str
    %       (symbolic variable) Vector of values from CDS_Param.Sym
    %       (CDS_Param)         Vector of CDS_Param
    % INPUT (Name=Value)
    %   warnMissing
    %       true:  Warn if any names in namesIn do not match the names of any items in the object array
    %       false: Do not emit warning
    %   warnDuplicates
    %       true:  Warn if any duplicate names exist in namesIn
    %       false: Do not emit warning
    %   keepDuplicates
    %       true:  Keep any duplicates
    %       false: Given duplicate names in namesIn, keep only the first of each. Discard the rest
    % OUTPUT
    %   (CDS_Param) DIM[numFound, 1]
    %       Heterogeneous array of (CDS_Param_Const|CDS_Param_Free|CDS_Param_Input|CDS_Param_Lambda)
    %       The order and size of the output corresponds to that of the input
    %       If a object is not found, then that element is dropped
    function heldObjects = Subset(this, namesIn, options)
        arguments
            this(1,1)
            namesIn(:,1) {mustBeA(namesIn, ["string", "sym", "CDS_Param"])}
            options.warnMissing(1,1) logical = true
            options.warnDuplicates(1,1) logical = true
            options.keepDuplicates(1,1) logical = true
        end
        optionsCell = namedargs2cell(options);
        heldObjects = this.All.Subset(namesIn, optionsCell{:});
    end

    %**********************************************************************
    % Interface: Get - Properties
    %***********************************
    % Intended for internal use only
    function out = q_SymSwap(this, t)
        arguments
            this(1,1)
            t(1,1) char = '0'
        end
        if t=='t'
            out = [this.q.Sym(0,t,2); this.q.Sym(0,t,1); this.q.Sym(0,t);];
        else
            out = [this.q.Sym(2); this.q.Sym(1); this.q.Sym(0)];
        end
    end

    % Intended for internal use only
    function out = x_SymSwap(this, t)
        arguments
            this(1,1)
            t(1,1) char = '0'
        end
        if t=='t'
            out = [this.x.Sym(0,t,1); this.x.Sym(0,t)];
        else
            out = [this.x.Sym(1); this.x.Sym(0)];
        end
    end

    %**********************************************************************
    % Interface: Operate on symbolic expressions of the registered params
    %***********************************
    % Test if an array of symbolic expressions
    % 1) Has all syms registered
    % 2) Is an expr of only values from this.const.Sym and doubles
    % INPUT
    %   symExprs: (symbolic expression) Expressions to test
    %   optError
    %       "ErrorOnFalse": Error if the output would be false
    %       "NoError":      Output the result
    % OUTPUT
    %   (logical) DIM[1,1] Overall result for the array
    function result = isConst(this, symExprs, optError)
        arguments
            this(1,1)
            symExprs sym
            optError string {mustBeMember(optError,["ErrorOnFalse","NoError"])} = "NoError"
        end
        if ~all(isSymType(symExprs,'expression'),'all') || any(hasSymType(symExprs,'symfun|unit'),'all')
            error("Bad input: Symbolic expression is of an unsupported type");
        end
        provided_syms = symvar(symExprs);
        allowed_syms = this.const.Sym;
        error_syms = provided_syms( ~ismember(provided_syms,allowed_syms) );
        result = isempty(error_syms);
        if ~result && optError=="ErrorOnFalse"
            error("Bad input: Expression must be constant, and syms must be registered. Disallowed syms: " + strjoin(string(error_syms),", "));
        end
    end

    % Test if an array of symbolic expressions
    % 1) Has all syms registered
    % 2) Is an expr of only values from [this.const.Sym; this.q.Sym; sym('t','real')] and doubles
    % NOTES
    %   Edge case: this function cannot determine if expressions of 't' have been differentiated or not
    %   e.g. It is not possible to know if "y=t+2" been differentiated or not
    %   Therefore, this function is invariant to the explicit presence/absence of 't'
    % INPUT
    %   symExprs: (symbolic expression) Expressions to test
    %   optError
    %       "ErrorOnFalse": Error if the output would be false
    %       "NoError":      Output the result
    % OUTPUT
    %   (logical) DIM[1,1] Overall result for the array
    function result = isZeroDifferentialOrder(this, symExprs, optError)
        arguments
            this(1,1)
            symExprs sym
            optError string {mustBeMember(optError,["ErrorOnFalse","NoError"])} = "NoError"
        end
        if ~all(isSymType(symExprs,'expression'),'all') || any(hasSymType(symExprs,'symfun|unit'),'all')
            error("Bad input: Symbolic expression is of an unsupported type");
        end
        provided_syms = symvar(symExprs);
        allowed_syms = [this.const.Sym; this.q.Sym; this.lambda.Sym; sym('t','real')];
        error_syms = provided_syms( ~ismember(provided_syms,allowed_syms) );
        result = isempty(error_syms);
        if ~result && optError=="ErrorOnFalse"
            error("Bad input: Expression must not contain derivative terms, and syms must be registered. Disallowed syms: " + strjoin(string(error_syms),", "));
        end
    end

    % Test if an array of symbolic expressions
    % 1) Has all syms registered
    % 2) Is an expr of only values from [this.const.Sym; this.q.Sym; this.q.Sym(1); sym('t','real')] and doubles
    % 3) Has at most 1 derivative sym per term
    % NOTE 1
    %   Edge case: this function cannot determine if expressions of 't' have been differentiated or not
    %   e.g. It is not possible to know if "y=t+2" been differentiated or not
    %   Therefore, this function is invariant to the explicit presence/absence of 't'
    % NOTE 2
    %   This function does not check the polynomial degree of the included differential terms
    %   e.g. If "theta" is a sym, "theta_d^2" then is second order
    %   Example code to check this:
    %       derivative1_syms = this.q.Sym(1);
    %       polyDegree = max(polynomialDegree(symExprs, derivative1_syms));
    %       isVelocity = polyDegree<2;
    % INPUT
    %   symExprs: (symbolic expression) Expressions to test
    %   optError
    %       "ErrorOnFalse": Error if the output would be false
    %       "NoError":      Output the result
    % OUTPUT
    %   (logical) DIM[1,1] Overall result for the array
    function result = isLessThanMaxDifferentialOrder(this, symExprs, optError)
        arguments
            this(1,1)
            symExprs sym
            optError string {mustBeMember(optError,["ErrorOnFalse","NoError"])} = "NoError"
        end
        if ~all(isSymType(symExprs,'expression'),'all') || any(hasSymType(symExprs,'symfun|unit'),'all')
            error("Bad input: Symbolic expression is of an unsupported type");
        end
        provided_syms = symvar(symExprs);
        allowed_syms = [this.const.Sym; this.q.Sym; this.q.Sym(1); this.lambda.Sym; sym('t','real')];
        error_syms = provided_syms( ~ismember(provided_syms,allowed_syms) );
        result = isempty(error_syms);
        if ~result && optError=="ErrorOnFalse"
            error("Bad input: Expression must not exceed the maximum permitted level of derivative, and syms must be registered. Disallowed syms: " + strjoin(string(error_syms),", "));
        end
    end

    % Symbolically evaluate the total time derivative of an array of symbolic expressions
    % INPUT
    %   (symbolic expression) Expressions to differentiate
    % OUTPUT
    %   (symbolic expression) DIM[size(symExprs)]
    function result = TotalDiff(this, symExprs)
        arguments
            this(1,1)
            symExprs sym
        end
        if ~all(isSymType(symExprs,'expression'),'all') || any(hasSymType(symExprs,'symfun|unit'),'all')
            error("Bad input: Symbolic expression is of an unsupported type");
        end
        size_out = size(symExprs);
        syms t real
        q = this.q.Sym;
        q_d = this.q.Sym(1);
        q_dd = this.q.Sym(2);
        lam = this.lambda.Sym;
        lam_d = this.lambda.Sym(1);
        symExprs = symExprs(:);

        % Validate assumptions
        % Can not exceed maximum level of derivative for the parameter
        this.isLessThanMaxDifferentialOrder(symExprs, "ErrorOnFalse");

        % Chain rule method
        result =        jacobian(symExprs, q)*q_d + jacobian(symExprs, q_d)*q_dd;
        result = result + jacobian(symExprs, lam)*lam_d;
        result = result + jacobian(symExprs, t);
        result = reshape(result, size_out);

        % Swap method
        % Assumes no mixed syms e.g. this.q.Sym(1,t,1)
        %swap   = [this.q.Sym(2);     this.q.Sym(1);     this.q.Sym(0);   this.lambda.Sym(1);     this.lambda.Sym(0)];
        %swap_t = [this.q.Sym(0,t,2); this.q.Sym(0,t,1); this.q.Sym(0,t); this.lambda.Sym(0,t,1); this.lambda.Sym(0,t)];
        %symExprs_t = subs(symExprs, swap, swap_t);
        %dfdt_t = diff(symExprs_t, sym('t','real'));
        %dfdt_alternative = subs(dfdt_t, swap_t, swap);
        %dfdt_alternative = reshape(dfdt_alternative, size_out);

        % Simplify struggles to reduce this
        % Don't worry too much if it fails for expressions longer than a few lines
        %assert(all(simplify(result==dfdt_alternative)))
    end

    % Evaluate an array of symbolic expressions by substituting in numeric values
    % AUTOMATIC SUBSTITUTIONS
    %   sym('t','real')     for 0
    %   this.const.Sym      for this.const.Num
    %   this.q_free.Sym     for this.q_free.q0
    %   this.q_free.Sym(1)  for this.q_free.q_d0
    %   this.q_free.Sym(2)  for this.q_free.q_dd0
    %   this.lambda.Sym     for this.lambda.q0
    %   this.lambda.Sym(1)  for this.lambda.q_d0
    %   this.q_input.Sym    for this.q_input.q(0)
    %   this.q_input.Sym(1) for this.q_input.q_d(0)
    %   this.q_input.Sym(2) for this.q_input.q_dd(0)
    % NOTE
    %   Behaviour regarding the size of the input/output is different from that of this.EvaluateSymExpr()
    %   This function does not check that the initial conditions are consistent with the system equations
    % INPUT
    %   (symbolic expression) Expressions to evaluate
    % OUTPUT
    %   (double) DIM[size(symExprs)]
    function result = EvaluateSymExpr_IC(this, symExprs)
        arguments
            this(1,1)
            symExprs sym
        end
        % Only need to include what is not automatically included by EvaluateSymExpr()
        vars = [this.q_free.Sym; this.q_free.Sym(1); this.q_free.Sym(2); this.lambda.Sym; this.lambda.Sym(1)];
        vals = [this.q_free.q0;  this.q_free.q_d0;   this.q_free.q_dd0;  this.lambda.q0;  this.lambda.q_d0];
        % Different behaviour to EvaluateSymExpr()
        % The output will exactly match the shape of the input, (difference is for row vectors and empty)
        result = this.EvaluateSymExpr(symExprs(:), 0, vars, vals);
        result = reshape(result, size(symExprs));
    end

    % Evaluate an array of symbolic expressions by substituting in numeric values
    % (Input values override defaults)
    % DEFAULT SUBSTITUTIONS
    %   sym('t','real')     for                      input values
    %   this.const.Sym      for this.const.Num    OR input values
    %   this.q_free.Sym(1)  for 0
    %   this.lambda.Sym(1)  for 0
    %   this.q_input.Sym    for this.q_input.q(t) OR input values
    %   this.q_input.Sym(1) for 0
    %   this.q_input.Sym(2) for this.q_input.q(t) OR input values
    % ADDITIONAL SUBSTITUTIONS
    %   Any other provided syms for input values
    % NOTE
    %   This function does not check that the substituted values are consistent with the system equations
    %   Be especially careful to ensure consistent conditions for equations involving accelerations
    % NOTE
    %   Row vectors have DIM[1,n] which implies nDims=2, but if nDims=1 is specified,
    %   then, instead of throwing an error for "symExprs has more dimensions than is specified by nDimsIn",
    %   it is automatically corrected into a column vector
    % INPUT
    %   symExprs: (symbolic expression) DIM[e1,e2,...,e(nDimsIn)] Expressions to evaluate
    %   t:        DIM[1,n] Time values to substitute into sym('t','real')
    % INPUT (Repeating)
    %   symVars: (symbolic variable) DIM[s,1] Variables that might be in symExprs
    %   vals:    DIM[[s,n] | [s,1]] Values to substitute into the corresponding symVars
    % INPUT (Name=Value)
    %   nDimsIn: Number of dimensions of symExprs
    % OUTPUT
    %   (double) DIM[e1,e2,...,e(nDimsIn), n] Using convention (tensor dims, batch dims)
    function result = EvaluateSymExpr_StaticCondition(this, symExprs, t, symVars, vals, options)
        arguments
            this(1,1)
            symExprs sym
            t(1,:) double = 0
        end
        arguments (Repeating)
            symVars(:,1) sym
            vals double
        end
        arguments
            options.nDimsIn(1,1) uint64 {mustBePositive} = 1
        end
        % All velocity terms
        % The user is not permitted to override these values
        % If the user tries to provide any of these values, then EvaluateSymExpr() will error on detection of duplicates
        % Other terms are handled by EvaluateSymExpr()
        dSym = [this.q_free.Sym(1); this.lambda.Sym(1); this.q_input.Sym(1)];
        dNum = zeros(size(dSym));
        % Zip repeating args
        symVars_and_vals = [symVars; vals];
        symVars_and_vals = symVars_and_vals(:);
        result = this.EvaluateSymExpr(symExprs, t, dSym, dNum, symVars_and_vals{:}, nDimsIn=options.nDimsIn);
    end

    % Evaluate an array of symbolic expressions by substituting in numeric values
    % (Input values override defaults)
    % DEFAULT SUBSTITUTIONS
    %   sym('t','real')     for                         input values
    %   this.const.Sym      for this.const.Num       OR input values
    %   this.q_input.Sym    for this.q_input.q(t)    OR input values
    %   this.q_input.Sym(1) for this.q_input.q_d(t)  OR input values
    %   this.q_input.Sym(2) for this.q_input.q_dd(t) OR input values
    % ADDITIONAL SUBSTITUTIONS
    %   Any other provided syms for input values
    % NOTE
    %   This function does not check that the substituted values are consistent with the system equations
    % NOTE
    %   Row vectors have DIM[1,n] which implies nDims=2, but if nDims=1 is specified,
    %   then, instead of throwing an error for "symExprs has more dimensions than is specified by nDimsIn",
    %   it is automatically corrected into a column vector
    % SIZES
    %   e1,e2,...,e(nDimsIn) = size of symExprs
    %   s = Number of symVars in a (symVars,vals) pair. Can change between pairs
    %   n = Number of points to evaluate each symbolic expression at
    % INPUT
    %   symExprs (symbolic expression) DIM[e1,e2,...,e(nDimsIn)]
    %       Expressions to evaluate
    %   t DIM[1,n]
    %       Time values to substitute into sym('t','real')
    % INPUT (Repeating)
    %   symVars (symbolic variable) DIM[s,1]
    %       Variables that might be in symExprs
    %   vals DIM[[s,n] | [s,1]]
    %       Values to substitute into the corresponding symVars
    %       Specified values override default values
    %       If DIM[s,1], The value will be repeated in each n
    %       If DIM[s,n], The value will change for each n
    % INPUT (Name=Value)
    %   nDimsIn
    %       Number of dimensions of symExprs
    %       This is used to account for possible trailing length-1 dimensions
    % OUTPUT
    %   (double) DIM[e1,e2,...,e(nDimsIn), n] Using convention (tensor dims, batch dims)
    function result = EvaluateSymExpr(this, symExprs, t, symVars, vals, options)
        arguments
            this(1,1)
            symExprs sym
            t(1,:) double = 0
        end
        arguments (Repeating)
            symVars(:,1) sym
            vals double
        end
        arguments
            options.nDimsIn(1,1) uint64 {mustBePositive} = 1
        end

        % Validate and normalise shape of symExprs
        % Note about the output of ndims()
        %   It is always >=2, hence the "elseif"
        %   It ignores trailing singleton dimensions, hence the ">" instead of "~="
        if options.nDimsIn==1 && ( isvector(symExprs) || all(size(symExprs)==0) )
            % Normalise
            %   Row vector -> column vector
            %   Fully empty DIM[0,0] -> empty column vector DIM[0,1]
            symExprs = symExprs(:);
        elseif ndims(symExprs) > options.nDimsIn
            error("Bad input: symExprs has "+ndims(symExprs)+" dimensions, which is more than the specified nDimsIn="+options.nDimsIn);
        end

        % Set size of output
        % Be careful with how matlab handles trailing length-1 dims
        % https://au.mathworks.com/help/matlab/math/arrays-with-dimensions-of-size-1.html
        % https://au.mathworks.com/help/matlab/math/detailed-rules-about-array-indexing.html
        lenSeries = numel(t);
        sizeSymExprs = size(symExprs, 1:options.nDimsIn);
        sizeOut = [sizeSymExprs, lenSeries];

        if lenSeries==0 || isempty(symExprs)
            % Skip unnecessary validation for better speed
            result = double.empty(sizeOut);
            return;
        end

        % hasSymType() is way too slow, especially massive equations, so we skip that check
        if ~all(isSymType(symExprs,'expression'),'all') %|| any(hasSymType(symExprs,'symfun|unit'),'all')
            error("Bad input: symExprs is of an unsupported symbolic type");
        end

        % Prepend time to the arguments list
        % Note: The output of arguments(Repeating) is always a cell array
        symVars = [{sym('t','real')}, symVars];
        vals = [{t}, vals];

        % Input validation and sorting
        if length(symVars)~=length(vals); error("Bad input: Mismatching number of arguments"); end
        scalarSyms = zeros(0,1,'sym');
        scalarVals = [];
        seriesSyms = zeros(0,1,'sym');
        seriesVals = [];
        for idx = 1:length(symVars)
            s = symVars{idx};
            v = vals{idx};

            % Determine lengths
            % (case scalar only) Correct potentially incorrect shape with transpose
            % Check same number of vals as syms
            numS = length(s);
            if numS~=1 && isvector(v); v=v(:); end
            if size(v,1)~=numS; error("Bad input: Mismatching size for set: "+strjoin(string(s),",")); end
            lenV = size(v,2);

            if lenV==1
                % Case: Scalar
                scalarSyms = [scalarSyms; s];
                scalarVals = [scalarVals; v];
            else
                % Case: Series
                if lenV~=lenSeries; error("Bad input: Mismatching series length for set: "+strjoin(string(s),",")+"\nShould be: "+lenSeries+"\nIs:        "+lenV,[]); end
                seriesSyms = [seriesSyms; s];
                seriesVals = [seriesVals; v];
            end
        end

        allSymsIn = [scalarSyms;seriesSyms];
        if ~all(isSymType(allSymsIn, 'variable'),'all')
            error("Bad input: Some symVars are not symbolic variables (e.g. might be symbolic expressions)");
        end
        if numel(allSymsIn)~=numel(unique(allSymsIn))
            [~,idxUnique,~] = unique(allSymsIn, 'sorted');
            duplicatedSyms = allSymsIn;
            duplicatedSyms(idxUnique) = [];
            error("Bad input: Some symVars provided multiple times: "+strjoin(string(duplicatedSyms),","));
        end

        % Find any used u and c that were not given by the user
        allSymsUsed = symvar(symExprs);
        uParams = this.u;
        cParams = this.const;
        uSym = uParams.Sym; % Slow to call. Avoid calling multiple times
        cSym = cParams.Sym; % Slow to call. Avoid calling multiple times
        uMask = ~ismember(uSym, allSymsIn) & ismember(uSym, allSymsUsed);
        cMask = ~ismember(cSym, allSymsIn) & ismember(cSym, allSymsUsed);

        % Autogenerate u(t), and add to scalar or series syms as appropriate
        uNum = uParams(uMask).q(t);
        if isscalar(t)
            scalarSyms = [scalarSyms; uSym(uMask); cSym(cMask)];
            scalarVals = [scalarVals; uNum; cParams(cMask).Num];
        else
            scalarSyms = [scalarSyms; cSym(cMask)];
            scalarVals = [scalarVals; cParams(cMask).Num];
            seriesSyms = [seriesSyms; uSym(uMask)];
            seriesVals = [seriesVals; uNum];
        end
        allSymsAvailable = [scalarSyms; seriesSyms];

        % Test with detailed error message because I expect this to be a pain point
        missing_syms = allSymsUsed( ~ismember(allSymsUsed,allSymsAvailable) );
        if ~isempty(missing_syms)
            error("Bad input: Some syms in the expression cannot be substituted for values. Possible fixes:\n- Provide the sym as an argument\n- Register the sym as a constant or input\n\nMissing syms: " + strjoin(string(missing_syms),","), []);
        end

        % Speed is a massive factor here
        %   subs()              Slow, but faster than matlabFunction for scalar only inputs
        %   matlabFunction()    Very slow to create, but fast to call
        %   symvar()            ~30x slower than creating 1 matlabFunction
        %   ismember()          Slow enough to avoid calling
        % Loop used to avoid errors internal to matlabFunction if one of the outputs is constant
        %   e.g. it tries to eval @ [in1(1,:), 0, 0]
        %   which causes a concatenation error
        % Linear indexing used to allow symExprs and result to be of arbitrary dimensionality
        %   result(idx1, ..., idxN, :)    is as result(idx:numExpr:end)
        %   result(:,    ..., :,    idxT) is as result(((idx-1)*numExpr)+1 : idx*numExpr)
        %   But flattening and using reshape() are basically free compared to the other operations
        %
        % Performance tests
        %   CONST
        %       Always best choice, where possible
        %   SCALAR
        %       Always best choice (after CONST), where possible
        %       Variant using subs is slower for small-large equations, but faster for massive equations
        %   LOOP-EVAL
        %       For small-large equations (in terms of equation complexity, not matrix size)
        %           Starting at ~2x faster than SEPARATED for few loops (main overhead is building matlabFunction),
        %           then approaching speed of SEPARATED at ~10,000 loops (overhead split between build and evaluate)
        %       For massive equations, can be much slower than SEPARATED (evaluate slows down massively)
        %   LOOP-BUILD
        %       Generally comparable to SEPARATED, but always very slightly slower
        %   SEPARATED
        %       For small-large equations
        %           overhead is split between arrayfun-symvar and building matlabFunction
        %           Roughly equally split for 32 symExprs
        %       For massive equations, faster than LOOP-EVAL
        %
        % Performance stress test
        %   "run_C3_Normal.m" with input=7,model=ZS,geometry=6.
        %   Profile line
        %       b_3D = sys.params.EvaluateSymExpr(ODEs2_obj.b, t_sol, xu,xu_sol, nDimsIn=2);
        %   Results
        %       SCALAR (no subs) for first element:   ~7s total run
        %       SCALAR (with subs) for first element: ~5s total run
        %       LOOP-EVAL:  ~14s to build matlabFunction, ~40s to evaluate the function
        %       LOOP-BUILD: ~8s  to build matlabFunction, ~5s to evaluate the function
        %       SEPARATED:  ~8s  to build matlabFunction, ~5s to evaluate the function (~0.4s faster than LOOP-BUILD)
        % Approach
        %   Currently set to optimise for the worst case (massive equations)
        numExpr = numel(symExprs);

        if ~any( ismember(allSymsUsed, seriesSyms) )
            % MODE: CONST
            % No series values
            % Repeat constant values per size required by input
            doubleExprs = double( subs(symExprs, scalarSyms, scalarVals) );
            result = repmat(doubleExprs, [ones(1,numel(sizeSymExprs)), lenSeries]);
            return
        end
        if numExpr==1
            % MODE: SCALAR
            % Scalar expr with series values
            % (with subs)
            exprSemiNum = subs(symExprs, scalarSyms, scalarVals);
            exprHandle = matlabFunction(exprSemiNum, 'Vars', {seriesSyms});
            result = reshape(exprHandle(seriesVals), sizeOut);
            % (no subs)
            %exprHandle = matlabFunction(symExprs,'Vars',{seriesSyms, scalarSyms});
            %result = reshape(exprHandle(seriesVals, scalarVals), sizeOut);
            return
        end

        %% MODE: LOOP-EVAL
        %% With series values
        %exprHandle = matlabFunction(symExprs,'Vars',{seriesSyms, scalarSyms});
        %result = zeros(sizeOut);
        %for idx = 1:lenSeries
        %    result(((idx-1)*numExpr)+1 : idx*numExpr) = exprHandle(seriesVals(:,idx), scalarVals);
        %end

        % MODE: LOOP-BUILD
        % General case
        %   Condition inputs to matlabFunction by flattening dimensions and separating out constant elements
        %   But the combination of calling subs() and repeated symvar() calls makes this slower
        %exprSemiNum = subs(symExprs, scalarSyms, scalarVals);
        %exprFlat = exprSemiNum(:);
        %isConst = arrayfun(@(e) isempty(symvar(e)), exprFlat);
        %result = zeros(numExpr, lenSeries);
        %if any(isConst)
        %    result(isConst, :) = repmat(double(exprFlat(isConst)), [1, lenSeries]);
        %end
        %for idx = 1:numExpr
        %    if ~isConst(idx)
        %        exprHandle = matlabFunction(exprFlat(idx), 'Vars', {seriesSyms});
        %        result(idx, :) = exprHandle(seriesVals);
        %    end
        %end
        %result = reshape(result, sizeOut);

        % MODE: SEPARATED
        % General case
        %   Condition inputs to matlabFunction by flattening dimensions and separating out constant elements
        %   But the combination of calling subs() and repeated symvar() calls makes this slower
        exprSemiNum = subs(symExprs, scalarSyms, scalarVals);
        exprFlat = exprSemiNum(:);
        isConst = arrayfun(@(e) isempty(symvar(e)), exprFlat);
        result = zeros(numExpr, lenSeries);
        if any(isConst)
            result(isConst, :) = repmat(double(exprFlat(isConst)), [1, lenSeries]);
        end
        if any(~isConst)
            exprHandle = matlabFunction(exprFlat(~isConst), 'Vars', {seriesSyms});
            result(~isConst, :) = exprHandle(seriesVals);
        end
        result = reshape(result, sizeOut);
    end
end
end

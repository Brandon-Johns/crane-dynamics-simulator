%{
PURPOSE
    A time-dependent variable system parameter

DETAILS
    Each instance of this class is one parameter

EXAMPLE
    % See the How-To Reference "Explicit Time Dependence"
%}

classdef CDS_Param_Input < CDS_Param
properties (SetAccess=private)
    %**********************************************************************
    % Interface: Get
    %***********************************
    % Evaluate parameter at time 't'
    % Fully vectorised element-wise operation
    % NOTE
    %   function handle signature
    %       handle input:      t: (double) DIM[any]     Simulation times
    %       handle output: value: (double) DIM[size(t)] Value of the parameter at the input times
    q(1,1) function_handle = @(t) 0    % 0th time derivative
    q_d(1,1) function_handle = @(t) 0  % 1st time derivative
    q_dd(1,1) function_handle = @(t) 0 % 2nd time derivative

    % Mathematical category of input
    mode(1,1) string {mustBeMember(mode, ["analytic","analyticPiecewise","spline"])} = "analytic"
end
properties (Access=private)
    %**********************************************************************
    % Internal
    %***********************************
    % For analytic input. Original symbolic expression, and as differentiated
    q_sym(3,:) sym = [0;0;0]

    % For analytic input > piecewise
    % The cell arrays are of function handles
    time_transition(1,:) double
    array_q(1,:) cell
    array_q_d(1,:) cell
    array_q_dd(1,:) cell
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % Intended for internal use only
    % Creation should be done through CDS_Params.m
    % Most uses should use the property .params of an instance of CDS_SystemDescription.m
    function this = CDS_Param_Input(varargin)
        this@CDS_Param(varargin);
    end

    %**********************************************************************
    % Interface: Set
    %***********************************
    % Common interface for setting the input
    % The appropriate .Set method is automatically determined
    % INPUT
    %   Same as the corresponding method
    %   Optionally pack into a cell array
    function this = Set_Selector(this, varargin)
        arguments
            this(1,1)
        end
        arguments(Repeating)
            varargin
        end
        % Unpack cell
        if nargin==2 && isa(varargin{1},"cell")
            varargin = varargin{1};
        end

        % Select input mode
        if     length(varargin)==1 && any(class(varargin{1})==["sym","double"])
            this = this.SetAnalytic(varargin{:});
        elseif length(varargin)==2 && any(class(varargin{1})==["sym","double"]) && isa(varargin{2},"double")
            this = this.SetPiecewise(varargin{:});
        elseif length(varargin)==1 && this.isSpline(varargin{1})
            this = this.SetSpline(varargin{:});
        else
            error("Bad input");
        end
    end

    % Set the value of the parameter to an analytic function of time
    % INPUT
    %   (symbolic expression) Expr of sym('t','real')
    function this = SetAnalytic(this, q_symIn)
        arguments
            this(1,1)
            q_symIn(1,1) sym
        end
        this.mode = "analytic";
        syms t real

        % Validate
        if ~all(isSymType(q_symIn,'expression'),'all') || any(hasSymType(q_symIn,'symfun|unit'),'all')
            error("Bad input: Symbolic expression is of an unsupported type");
        end
        if any(symvar(q_symIn)~=t); error("Bad input: q may only consist of numbers and sym('t','real')"); end

        % Save sym expression for CDS_Solver_ODEs_Export
        this.q_sym = [q_symIn; diff(q_symIn,t,1); diff(q_symIn,t,2)];

        % Functions to evaluate
        this.q    = this.sym2Handle(this.q_sym(1));
        this.q_d  = this.sym2Handle(this.q_sym(2));
        this.q_dd = this.sym2Handle(this.q_sym(3));
    end

    % Set the value of the parameter to a analytic piecewise function of time
    % The first expression will be used until the first transition time, then the next expression will be used, etc.
    % INPUT
    %   q_symIn (symbolic expression)
    %       Vector of exprs of sym('t','real')
    %   transitionTimes DIM[1, 1-length(q_symIn)]
    %       Array of times to switch between the expressions
    function this = SetPiecewise(this, q_symIn, transitionTimes)
        arguments
            this(1,1)
            q_symIn(1,:) sym
            transitionTimes(1,:) double = []
        end
        % Switch mode if single segment
        if isscalar(q_symIn) && isempty(transitionTimes)
            this = this.SetAnalytic(q_symIn);
            return;
        end

        this.mode = "analyticPiecewise";
        syms t real

        % Validate
        if ~all(isSymType(q_symIn,'expression'),'all') || any(hasSymType(q_symIn,'symfun|unit'),'all')
            error("Bad input: Symbolic expression is of an unsupported type");
        end
        if any(symvar(q_symIn)~=t); error("Bad input: q may only consist of numbers and sym('t','real')"); end
        if length(q_symIn)-1 ~= length(transitionTimes); error("Mismatching inputs"); end

        % Save sym expression for CDS_Solver_ODEs_Export
        this.q_sym = [q_symIn; diff(q_symIn,t,1); diff(q_symIn,t,2)];

        % Functions to evaluate
        for idx = 1:length(q_symIn)
            this.array_q{idx}    = this.sym2Handle(this.q_sym(1,idx));
            this.array_q_d{idx}  = this.sym2Handle(this.q_sym(2,idx));
            this.array_q_dd{idx} = this.sym2Handle(this.q_sym(3,idx));
        end

        this.time_transition = transitionTimes;
        this.q    = @(t_) this.EvaluatePiecewise(t_, 0);
        this.q_d  = @(t_) this.EvaluatePiecewise(t_, 1);
        this.q_dd = @(t_) this.EvaluatePiecewise(t_, 2);
    end

    % Set the value of the parameter to a 1D spline, which fits a function of time
    % REQUIRES
    %   Curve Fitting Toolbox
    % INPUT
    %   A spline that was fit by the inbuilt function spline()
    %       Spline dimensionality: 1D
    %       Spline polynomial order: Greater than 2
    function this = SetSpline(this, q_spline)
        arguments
            this(1,1)
            q_spline(1,1) struct
        end
        this.mode = "spline";

        % Validate
        if ~this.isSpline(q_spline); error("Invalid input: q might not be a 1D piecewise polynomial spline"); end

        % Differentiate spline
        % Requires Curve Fitting Toolbox
        q_spline_d = fnder(q_spline);
        q_spline_dd = fnder(q_spline,2);

        % Functions to evaluate
        this.q =    @(t_) ppval(q_spline, t_);
        this.q_d =  @(t_) ppval(q_spline_d, t_);
        this.q_dd = @(t_) ppval(q_spline_dd, t_);
    end

    %**********************************************************************
    % Interface: Get
    %***********************************
    % For this.mode = "analytic" or "analyticPiecewise"
    % INPUT
    %   d
    %       0: Get the expression of the input
    %       1: Get the 1st derivative of the expression of the input
    %       2: Get the 2nd derivative of the expression of the input
    % OUTPUT
    %   (symbolic expression) DIM[1,numPiecewiseExprs]
    function out = q_Sym(this, d)
        arguments
            this(1,1)
            d(1,1) double {mustBeMember(d,[0,1,2])} = 0
        end
        if ~any(this.mode == ["analytic","analyticPiecewise"])
            error("To use this function, input must be analytic or analyticPiecewise");
        end
        out = this.q_sym(d+1, :);
    end

    % For this.mode = "analyticPiecewise"
    % Times where the piecewise function transitions between expressions
    % OUTPUT
    %   (double) DIM[1, (numPiecewiseExprs - 1)]
    function out = TransitionTimes(this)
        arguments
            this(1,1)
        end
        if this.mode~="analyticPiecewise"
            error("To use this function, input must be analyticPiecewise");
        end
        out = this.time_transition;
    end
end
methods (Access=private)
    function out = isSpline(~, in)
        % I wonder how fragile this validation is to matlab changing the internals of splines
        out = isa(in,"struct")...
            && all(isfield(in, ["form","breaks","coefs","pieces","order","dim"]))...
            && (in.form=="pp")...
            && (in.dim==1)...
            && (in.order>2);
    end

    % Improved version of matlabFunction()
    %   If symIn is a constant, matlabFunction() returns: f_h = @(vars) 0
    %   This causes input to always return a scalar (so much for vectorised operations)
    %   => fix by returning my own handle
    function h = sym2Handle(~, symIn)
        if ~isempty(symvar(symIn))
            h = matlabFunction(symIn, 'Vars',{sym('t','real')});
        else
            constVal = double(symIn);
            h = @(t_) ones(size(t_))*constVal;
        end
    end

    % INPUT
    %   t: (vector) time values to evaluate at
    %   d: (1,1) derivative order
    function out = EvaluatePiecewise(this, t, d)
        % Select the derivative
        if     d==0; arrayQ = this.array_q;
        elseif d==1; arrayQ = this.array_q_d;
        elseif d==2; arrayQ = this.array_q_dd;
        else;  error("Bad input: d")
        end

        % Optimised version for during solving
        % It make a fairly significant difference
        if isscalar(t)
            for idx = 1:length(this.time_transition)
                if t<this.time_transition(idx)
                    out = arrayQ{idx}(t);
                    return
                end
            end
            out = arrayQ{idx+1}(t);
            return
        end

        % Optimised version for vectorised operations
        out = zeros(size(t));
        isNotSet = true(size(t));
        for idxPiece = 1:length(this.time_transition)
            isAfter = t>=this.time_transition(idxPiece);
            inRange = isNotSet & ~isAfter;
            out(inRange) = arrayQ{idxPiece}(t(inRange));
            isNotSet = isAfter;
        end
        out(isNotSet) = arrayQ{idxPiece+1}(t(isNotSet));
    end
end
end

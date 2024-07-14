%{
Creation should be done through CDS_Params.m

PURPOSE
    Instances of this class represent time and state dependent variable system parameters

NOTE
    The following methods (input modes) are incomplete and should not be used
        SetAnalyticFeedback - Limited input validation. Correctness of the physics not thoroughly tested
        SetFeedback         - Highly unstable. Correctness of the physics not thoroughly tested
        SetSampled          - Not implemented

EXAMPLE
    % See the HowTo Reference "Define a time dependent parameter (an input)"
%}

classdef CDS_Param_Input < CDS_Param
properties (SetAccess=private)
    %**********************************************************************
    % Interface: Get
    %***********************************
    % Evaluate input at input time 't' and state 'x'
    % 'x' matches the state vector used by the solver
    % For modes "analytic" and "analyticPiecewise", the value of x is not used. The user might choose to input NaN
    q(1,1) function_handle = @(t,x) 0
    q_d(1,1) function_handle = @(t,x) 0
    q_dd(1,1) function_handle = @(t,x) 0
    
    % Type of input provided by the user
    mode(1,1) string {mustBeMember(mode, ["analytic","analyticFeedback","FeedbackObject","analyticPiecewise","sampled"])} = "analytic"
end
properties (Access=private)
    %**********************************************************************
    % Internal
    %***********************************
    % For analytic input
    q_sym(3,:) sym = [0;0;0]
    
    % For analytic input > piecewise
    time_transition(1,:) double
    array_q(1,:) cell
    array_q_d(1,:) cell
    array_q_dd(1,:) cell
    
    % For sampled input
    time_sampled(1,:) double
    q_samples(1,:) double
    q_d_samples(1,:) double
    q_dd_samples(1,:) double
end

methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    function this = CDS_Param_Input(varargin)
        this@CDS_Param(varargin);
    end
    
    %**********************************************************************
    % Interface: Set
    %***********************************
    % Common interface for this.SetAnalytic and this.SetPiecewise
    % The appropriate method is automatically determined
    % INPUT
    %   Same as the corresponding method
    %   Optionally pack into a cell array
    function this = Set_Selector(this, varargin)
        % Unpack cell
        if nargin==2 && isa(varargin{1},"cell")
            varargin = varargin{1};
        end

        % Select input mode
        if     length(varargin)==1 && any(class(varargin{1})==["sym","double"])
            this = this.SetAnalytic(varargin{:});
        elseif length(varargin)==2 && isa(varargin{1},"sym") && isa(varargin{2},"sym")
            this = this.SetAnalyticFeedback(varargin{:});
        elseif length(varargin)==2 && isa(varargin{1},"sym") && isa(varargin{2},"double")
            this = this.SetPiecewise(varargin{:});
        end
    end

    % Set the value of the parameter to an analytic function of time
    % INPUT
    %   q_symIn: Symbolic expression of the variable sym('t'), where 't' represents time
    function this = SetAnalytic(this, q_symIn)
        arguments
            this
            q_symIn(1,1) sym
        end
        this.mode = "analytic";
        syms t
        
        % Validate
        q_vars = symvar(q_symIn);
        q_vars = q_vars(q_vars~=t); % remove 't' from list
        if ~isempty(q_vars); error("Invalid input: q may only consist of numbers and sym('t')"); end
        
        % Set user interface
        this.q_sym = [q_symIn; diff(q_symIn,t,1); diff(q_symIn,t,2)];
        
        % Functions to evaluate
        syms x_unused
        this.q = this.sym2Handle(this.q_sym(1), x_unused);
        this.q_d = this.sym2Handle(this.q_sym(2), x_unused);
        this.q_dd = this.sym2Handle(this.q_sym(3), x_unused);
    end
    
    % Set the value of the parameter to a analytic piecewise function of time
    % The first expression will be used until the first transition time, then the next expression will be used, etc.
    % INPUT
    %   q_symIn: Array of symbolic expressions of the variable sym('t'), where 't' represents time
    %   transitionTimes: Array of times to switch between the expressions
    %       length = 1 - length(q_symIn)
    function this = SetPiecewise(this, q_symIn, transitionTimes)
        arguments
            this
            q_symIn(1,:) sym
            transitionTimes(1,:) double = []
        end
        % Switch mode if single segment
        if length(q_symIn)==1 && isempty(transitionTimes)
            this = this.SetAnalytic(q_symIn);
            return;
        end

        warning("This mode is not fully tested (need to test sundials export)");
        this.mode = "analyticPiecewise";
        syms t
        
        % Validate
        q_vars = symvar(q_symIn);
        q_vars = q_vars(q_vars~=t); % Remove 't' from list
        if ~isempty(q_vars); error("Invalid input: q may only consist of numbers and sym('t')"); end
        if length(q_symIn)-1 ~= length(transitionTimes); error("Mismatching inputs"); end
        
        this.time_transition = transitionTimes;

        % Set user interface
        this.q_sym = [q_symIn; diff(q_symIn,t,1); diff(q_symIn,t,2)];
        
        % Functions to evaluate
        syms x_unused
        for idx = 1:length(q_symIn)
            this.array_q{idx}    = this.sym2Handle(this.q_sym(1,idx), x_unused);
            this.array_q_d{idx}  = this.sym2Handle(this.q_sym(2,idx), x_unused);
            this.array_q_dd{idx} = this.sym2Handle(this.q_sym(3,idx), x_unused);
        end
        
        this.q    = @(t,x_unused) this.EvaluatePiecewise(t, 0);
        this.q_d  = @(t,x_unused) this.EvaluatePiecewise(t, 1);
        this.q_dd = @(t,x_unused) this.EvaluatePiecewise(t, 2);
    end

    %**********************************************************************
    % Interface: Set (INCOMPLETE)
    %***********************************
    function this = SetSampled(this)
        this.mode = "sampled";
        error("TODO")
        % interpolate with: interp1(t, input, t_now, 'linear','extrap')
    end

    % Limitation: Must set all x before setting this (does not have error checking for this yet)
    % TODO:
    %   Write test to check against known physics
    %   Remove need to input xSym
    %   Remove need to set all x before calling
    %       maybe defer calling sym2Handle
    %       maybe add interface to call sym2Handle again and check the state of xSym
    function this = SetAnalyticFeedback(this, q_symIn, xSym)
        arguments
            this
            q_symIn(1,:) sym
            xSym(:,1) sym
        end
        warning("This mode is not fully functional or tested");
        this.mode = "analyticFeedback";
        syms t
        
        % Validate
        q_vars = symvar(q_symIn);
        q_vars = q_vars(q_vars~=t); % remove 't' from list
        if ~all(has(q_vars, xSym)); error("Invalid input: q may only consist of numbers, t, and x(:)"); end
        
        % Set user interface
        % TODO: This might be incorrect? Use multivariable chain rule accounting for x?
        this.q_sym = [q_symIn; diff(q_symIn,t,1); diff(q_symIn,t,2)];
        
        % Functions to evaluate
        this.q = this.sym2Handle(this.q_sym(1), xSym);
        this.q_d = this.sym2Handle(this.q_sym(2), xSym);
        this.q_dd = this.sym2Handle(this.q_sym(3), xSym);
    end
    
    % This never really worked out very well...
    % The feedback object needs better internal differentiation
    function this = SetFeedback(this, feedbackObject)
        arguments
            this
            feedbackObject(1,1) CDS_Param_Input_Fun
        end
        warning("This mode is not fully functional or tested");
        this.mode = "FeedbackObject";

        this.q = @(t_,x_) feedbackObject.Eval_q(t_,x_);
        this.q_d = @(t_,x_) feedbackObject.Eval_q_d(t_,x_);
        this.q_dd = @(t_,x_) feedbackObject.Eval_q_dd(t_,x_);
    end
    
    %**********************************************************************
    % Interface: Get
    %***********************************
    % For analytic modes
    % INPUT
    %   d: differential offset
    % OUTPUT
    %   d=0: Symbolic expression that was input by the user
    %   d=1: 1st time derivative of the symbolic expression that was input by the user
    %   d=2: 2nd time derivative of the symbolic expression that was input by the user
    function symOut = q_Sym(this, d)
        arguments
            this
            d(1,1) double {mustBeMember(d,[0,1,2])} = 0
        end
        if ~any(this.mode == ["analytic","analyticFeedback","analyticPiecewise"])
            error("To use this function, input must be analytic, analyticFeedback or analyticPiecewise");
        end
        symOut = this.q_sym(d+1, :);
    end

    % mode="analyticPiecewise": Times where the piecewise function transitions between expressions
    function out = switchTimes(this)
        if     this.mode=="analyticPiecewise"; out = this.time_transition;
        elseif this.mode=="sampled";           out = this.time_sampled;
        else
            error("To use this function, input must be analyticPiecewise or sampled");
        end
    end
end
methods (Access=private)
    % Improved version of matlabFunction()
    %   If symIn is a constant, matlabFunction() returns: f_h = @(vars) 0
    %   This causes input to always return a scalar (so much for vectorised operations)
    %   => fix by returning my own handle
    function h = sym2Handle(~, symIn, x)
        if ~isempty(symvar(symIn))
            h = matlabFunction(symIn, 'Vars',{sym('t'), x});
        else
            constVal = double(symIn);
            h = @(t_,x_) ones(size(t_))*constVal;
        end
    end

    % INPUT
    %   t(vector): time values to evaluate at
    %   d(1,1): derivative order
    function out = EvaluatePiecewise(this, t, d)
        % Select the piece of the piecewise function
        idxPiece = ones(size(t));
        for idx = 1:length(this.time_transition)
            idxPiece( t>=this.time_transition(idx) ) = idx+1;
        end

        % Select the derivative
        if     d==0; arrayQ = this.array_q;
        elseif d==1; arrayQ = this.array_q_d;
        elseif d==2; arrayQ = this.array_q_dd;
        else
            error("Bad input: d")
        end

        % Evaluate
        out = zeros(size(t));
        for idx = 1:length(t)
            out(idx) = arrayQ{idxPiece(idx)}(t(idx));
        end
    end
end
end

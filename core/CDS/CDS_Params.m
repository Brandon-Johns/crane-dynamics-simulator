%{
PURPOSE
    Build instances of CDS_Param subclasses
    Track every instance and interface that it creates

NOTES
    Builder pattern:
        Separate object construction from object representation
        => Simplifies logic in the created object e.g. complex relations and validation
    Factory method pattern:
        Centralise object creation, allowing choice from several implementations
        => Can create objects without specifying class of object to create
%}

classdef CDS_Params < handle
properties (SetAccess=private)
    % The parameters created by this instance
    const(:,1) CDS_Param_Const
    q_free(:,1) CDS_Param_Free
    q_input(:,1) CDS_Param_Input
    lambda(:,1) CDS_Param_Lambda
    
    % For internal use
    % Set the state vector interface to include or exclude lambda
    %   Include if using an implicit solver
    %   Exclude if the constraint has been solved by reforming the equations
    x_mode(1,1) string {mustBeMember(x_mode,["withoutLambda","withLambda"])} = "withLambda"
end
properties (Access=private)
    q_free_interface(:,1) CDS_Param_x
    q_free_d_interface(:,1) CDS_Param_x
    lambda_interface(:,1) CDS_Param_x
    q_input_interface(:,1) CDS_Param_u
    q_input_d_interface(:,1) CDS_Param_u
    q_input_dd_interface(:,1) CDS_Param_u
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    function this = CDS_Params()
        %
    end
    
    % Build instances of CDS_Param subclasses
    % INPUT
    %   paramType
    %       "const":  Build CDS_Param_Const
    %       "free":   Build CDS_Param_Free
    %       "input":  Build CDS_Param_Input
    %       "lambda": Build CDS_Param_Lambda (Intended for internal use only)
    %   paramIn
    %       (string) Symbolic variable to represent the parameter (each parameter must have a unique sym)
    % OUTPUT
    %   The created parameter
    %   The remaining properties are default zero. Change these by calling the set methods on the output
    function paramObject = Create(this, paramType, paramIn)
        arguments
            this
            paramType(1,1) string
            paramIn(1,1) string
        end
        
        % Check if duplicate
        if ~isempty(this.Param(paramIn,"KeepDuplicates","NoWarn"))
            error('Parameter already exists and registered: %s', paramIn)
        end
        
        % Check if already defined within scope of caller
        inputExists = evalin('caller', "exist('"+paramIn+"')&&(class("+paramIn+")~=""sym"")");
        if inputExists
            warning('Variable of same name, which is not a sym, is already defined in caller. It will be overwritten.')
        end
        
        % Define inputs as syms in scope of caller
        assignin('caller', paramIn, sym(paramIn));
        
        % Create & register new param
        if strcmp(paramType, 'const')
            % Create Param
            paramObject = CDS_Param_Const(paramIn);
            this.const(end+1) = paramObject;
            
        elseif strcmp(paramType, 'free')
            % Create Param
            paramObject = CDS_Param_Free(paramIn);
            this.q_free(end+1) = paramObject;
            
            % Create Interfaces
            interface = CDS_Param_x(paramObject);
            interface_d = CDS_Param_x(paramObject, 1);
            this.q_free_interface(end+1) = interface;
            this.q_free_d_interface(end+1) = interface_d;
            
        elseif strcmp(paramType, 'input')
            % Create Param
            paramObject = CDS_Param_Input(paramIn);
            this.q_input(end+1) = paramObject;
            
            % Create Interfaces
            interface = CDS_Param_u(paramObject);
            interface_d = CDS_Param_u(paramObject, 1);
            interface_dd = CDS_Param_u(paramObject, 2);
            this.q_input_interface(end+1) = interface;
            this.q_input_d_interface(end+1) = interface_d;
            this.q_input_dd_interface(end+1) = interface_dd;
            
        elseif strcmp(paramType, 'lambda')
            % Create Param
            paramObject = CDS_Param_Lambda(paramIn);
            this.lambda(end+1) = paramObject;
            
            % Create Interface
            interface = CDS_Param_x(paramObject);
            this.lambda_interface(end+1) = interface;
        else
            error('Invalid input: paramType')
        end
    end
    
    %**********************************************************************
    % Interface: Set
    %***********************************
    % For internal use
    function SetStateVectorMode(this, mode)
        this.x_mode = mode;
    end
    
    %**********************************************************************
    % Interface: Get - Objects
    %***********************************
    % Get the array of all created CDS_Param objects
    function all = All(this)
        all = [this.const; this.q_free; this.q_input; this.lambda];
    end
    
    % Get the array of all created CDS_Param_Free and CDS_Param_Input objects
    function paramObjectArray = q(this)
        paramObjectArray = [this.q_free; this.q_input];
    end
    
    % For internal use
    % Get the state vector interface
    function paramObjectArray = x(this, x_mode)
        arguments
            this
            x_mode(1,1) string {mustBeMember(x_mode,["withoutLambda","withLambda"])} = this.x_mode
        end
        if strcmp(x_mode, "withLambda")
            paramObjectArray = [this.q_free_d_interface; this.q_free_interface; this.lambda_interface];
        else
            paramObjectArray = [this.q_free_d_interface; this.q_free_interface];
        end
    end
    
    % For internal use
    % Get the state input interface
    function paramObjectArray = u(this)
        arguments
            this
        end
        paramObjectArray = [this.q_input_interface; this.q_input_d_interface ; this.q_input_dd_interface];
    end
    
    % Get specific param objects
    % INPUT
    %   Same as CDS_Param.ParamIdx
    function paramObject = Param(this, varargin)
        paramObject = this.All.Param(varargin{:});
    end
    
    %**********************************************************************
    % Interface: Get - Properties
    %***********************************
    % For internal use
    function symOut = q_SymSwap(this, t)
        arguments
            this
            t(1,1) char = '0' % Default value represents plain output option
        end
        if t=='t'
            symOut = [this.q.Sym(0,t,2); this.q.Sym(0,t,1); this.q.Sym(0,t);];
        else
            symOut = [this.q.Sym(2); this.q.Sym(1); this.q.Sym(0)];
        end
    end
    
    % For internal use
    function symOut = x_SymSwap(this, t)
        arguments
            this
            t(1,1) char = '0' % Default value represents plain output option
        end
        if t=='t'
            symOut = [this.x.Sym(0,t,1); this.x.Sym(0,t)];
        else
            symOut = [this.x.Sym(1); this.x.Sym(0)];
        end
    end
end
end

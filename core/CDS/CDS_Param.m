%{
Abstract Class

PURPOSE
    Instances of this class represent system parameters

COMMON INPUTS
    d: Work with a time derivative of the parameter.
        d=0: (default) the parameter
        d=1: the 1st time derivative of the parameter. Appends 'd' to Sym
        d=2: the 2nd time derivative of the parameter. Appends 'dd' to Sym

NOTES
    matlab.mixin.Heterogeneous
        Allows creation of arrays of params of differing subtypes
        Restrictions (only applies to mixed arrays):
            Can only call methods from common base, and they must be sealed

    Avoid str2sym(), it turns 'i'&'j' into '1i' because imaginary numbers
%}

classdef (Abstract) CDS_Param < handle & matlab.mixin.Heterogeneous
properties (GetAccess=private, SetAccess=immutable)
    %**********************************************************************
    % Internal
    %***********************************
    sym(1,1) sym = 0 % Set on creation
end
properties (GetAccess=protected, SetAccess=immutable)
    % For CDS_Param_x
    %   0: normal
    %   1: interface for q_d
    d_offset(1,1) double {mustBeMember(d_offset,[0,1,2])} = 0
end
properties (Access=protected)
    sym_short(:,1) CDS_Helper_PropPointer
    name_readable(:,1) CDS_Helper_PropPointer
end
methods (Sealed=true)
    %**********************************************************************
    % Interface: Methods inherited from 'handle'
    %***********************************
    % Required because matlab.mixin.Heterogeneous wants sealed methods
    %   See: matlab.mixin.Heterogeneous "Sealing Inherited Methods"
    %       https://au.mathworks.com/help/matlab/ref/matlab.mixin.heterogeneous-class.html
    %   Add more as required - will get errors about method not sealed
    %       https://au.mathworks.com/help/matlab/handle-classes.html
    function varargout = eq(this,varargin)
        % Copies of a handle variable always compare as equal
        [varargout{1:nargout}] = eq@handle(this,varargin{:});
    end
    function varargout = ne(this,varargin)
        % Different handles are always not equal
        [varargout{1:nargout}] = ne@handle(this,varargin{:});
    end
    function varargout = findobj(this,varargin)
        % e.g. objectArray.findobj('-class',"CDS_Param_Free")
        [varargout{1:nargout}] = findobj@handle(this,varargin{:});
    end
end
methods (Sealed=true)
    %**********************************************************************
    % Interface: Create
    %***********************************
    % For internal use
    function this = CDS_Param(symIn, d_offset, symShortPtr, nameReadablePtr)
        arguments
            symIn(1,1) string
            d_offset(1,1) double {mustBeMember(d_offset,[0,1,2])} = 0
            symShortPtr(1,1) CDS_Helper_PropPointer = CDS_Helper_PropPointer("sym",symIn)
            nameReadablePtr(1,1) CDS_Helper_PropPointer = CDS_Helper_PropPointer("string",symIn)
        end
        this.sym = sym(symIn);
        this.sym_short = symShortPtr;
        this.name_readable = nameReadablePtr;
        
        this.d_offset = d_offset;
    end
    
    %**********************************************************************
    % Interface: Set
    %***********************************
    function this = SetSymShort(this, nameIn)
        this.sym_short.SetProp(nameIn);
    end
    
    function this = SetNameReadable(this, nameIn)
        this.name_readable.SetProp(nameIn);
    end
    
    %**********************************************************************
    % Interface: Get
    %***********************************
    % Symbolic variable to represent the parameter
    % INPUT
    %   d: Output as derivative by appending 'd'
    %   t:
    %       t='0': (default) Output as a symbolic variable
    %       t='t': Output as a symbolic function of time
    %   nDiff: For t='t'. Output as derivative by wrapping in diff()
    function symOut = Sym(this, d, t, nDiff)
        arguments
            this
            d(1,1) double {mustBeMember(d,[0,1,2])} = 0
            t(1,1) char = '0' % Default value represents plain output option
            nDiff(1,1) double {mustBeMember(nDiff,[0,1,2])} = 0
        end
        % Validate
        if d+nDiff>2; error("Bad input: Differential order greater than 2"); end
        if t~='t' && nDiff>0; error("Bad input: Not function of time => can't differentiate"); end
        
        if t=='t'
            % Form sym
            symOut = str2sym(strcat(this.Str(d),'(t)'));
            
            % Differentiate
            symOut = diff(symOut,sym('t'),nDiff);
        else
            % Form sym
            symOut = sym(this.Str(d));
        end
    end
    
    % Same as this.Sym, but output as a string
    function strOut = Str(this, d)
        arguments
            this
            d(1,1) double {mustBeMember(d,[0,1,2])} = 0
        end
        symArray = this.PropArray(this.sym);
        
        % Apply offset to interface objects
        d = d + this.PropArray(this.d_offset);
        if d>2; error("Bad input: working with offset interface"); end
        
        % Form output string
        strOut = strings(size(this));
        idx = d==0; strOut(idx) = string(symArray(idx));
        idx = d==1; strOut(idx) = strcat(string(symArray(idx)),'d');
        idx = d==2; strOut(idx) = strcat(string(symArray(idx)),'dd');
    end
    
    % For code generation. Variable name to represent the parameter in the generated code
    function symOut = SymShort(this, d)
        arguments
            this
            d(1,1) double {mustBeMember(d,[0,1,2])} = 0
        end
        symOut =  sym(this.StrShort(d));
    end
    
    % Same as this.SymShort, but output as a string
    function strOut = StrShort(this, d)
        arguments
            this
            d(1,1) double {mustBeMember(d,[0,1,2])} = 0
        end
        symArray = this.PropArray(this.sym_short).Prop;
        
        % Apply offset to interface objects
        d = d + this.PropArray(this.d_offset);
        if d>2; error("Bad input: working with offset interface"); end
        
        % Form output string
        strOut = strings(size(this));
        idx = d==0; strOut(idx) = string(symArray(idx));
        idx = d==1; strOut(idx) = strcat(string(symArray(idx)),'d');
        idx = d==2; strOut(idx) = strcat(string(symArray(idx)),'dd');
    end
    
    % Friendly name to identify the parameter by
    % Used in in outputs, error messages, generated code
    function strOut = NameReadable(this, d)
        arguments
            this
            d(1,1) double {mustBeMember(d,[0,1,2])} = 0
        end
        nameArray = this.PropArray(this.name_readable).Prop;
        
        % Apply offset to interface objects
        d = d + this.PropArray(this.d_offset);
        if d>2; error("Bad input: working with offset interface"); end
        
        % Form output string
        strOut = strings(size(this));
        idx = d==0; strOut(idx) = string(nameArray(idx));
        idx = d==1; strOut(idx) = strcat(nameArray(idx)," [d]");
        idx = d==2; strOut(idx) = strcat(nameArray(idx)," [dd]");
    end

    % Get specific param objects from an array of param objects
    % INPUT
    %   Same as this.ParamIdx
    function paramObject = Param(this, varargin)
        paramObject = this( this.ParamIdx(varargin{:}) );
    end

    % Get positions of params in array of param objects
    %   The order of the output corresponds to the order of the input
    %   If a param is not found, then that element is dropped
    % INPUT:
    %   paramsIn
    %       (sym): Array of the values matching the output of CDS_Param.Sym
    %       (string): Array of the values matching the output of CDS_Param.Str
    %       (CDS_Param): Array of CDS_Param
    %   optDuplicates
    %       KeepDuplicates: strictly follow to the input
    %       RemoveDuplicates: Drop duplicate CDS_Param from the output
    %   optWarn
    %       EnableWarn: Warn if for one of the inputs, not matching CDS_Param is found
    %       NoWarn: Disable warnings
    % OUTPUT:
    %   Array of indices to the array calling this method
    function idxMatch = ParamIdx(this, paramsIn, optDuplicates, optWarn)
        arguments
            this
            paramsIn(1,:) {mustBeA(paramsIn, ["char", "string", "sym", "CDS_Param"])}
            optDuplicates(1,1) string {mustBeMember(optDuplicates,["KeepDuplicates","RemoveDuplicates"])} = "KeepDuplicates"
            optWarn(1,1) string {mustBeMember(optWarn,["EnableWarn","NoWarn"])} = "EnableWarn"
        end
        % Interpret input type (effectively implements input overloading)
        if isa(paramsIn, "CDS_Param")
            NameIn=paramsIn.Str;
        elseif isa(paramsIn, "sym")
            NameIn=string(paramsIn);
        elseif isa(paramsIn, "char")
            % I'd rather outright reject chars, but they're not always auto-converting to strings it seems
            % => allow a single char input
            if ~isscalar(this); error("Input param as array of strings, not chars. Input: " + paramsIn); end
            NameIn=string(paramsIn);
        else
            NameIn=paramsIn;
        end

        % This method will match the order in the input, removing not found, but keeping duplicate points
        idxMatch=[];
        for idxIn = 1:length(NameIn)
            idxMatch = [idxMatch , find(NameIn(idxIn)==this.Str)];
        end
        
        if strcmp(optWarn,"EnableWarn") && length(idxMatch)~=length(NameIn)
            warning("Some points not found");
        end
        
        if strcmp(optDuplicates,"RemoveDuplicates")
            idxMatch=unique(idxMatch);
        end
    end

    %**********************************************************************
    % Internal
    %***********************************
    % Get 'pointer' to properties
    %   Used so interfaces share properties with underlying param
    function propObject = SymShortPtr(this)
        propObject = this.PropArray(this.sym_short);
    end
    function propObject = NameReadablePtr(this)
        propObject = this.PropArray(this.name_readable);
    end
end
methods (Sealed=true, Access=protected)
    % Helper to allow using functions with an array of objects
    % NOTE: Only intended for 1D arrays
    % Input: List of properties
    % OUTPUT: Array of properties corresponding to the object
    % EXAMPLE: PropArray(this.prop)
    function propArray = PropArray(this, varargin)
        propArray = reshape([varargin{:}],size(this));
    end
end
end

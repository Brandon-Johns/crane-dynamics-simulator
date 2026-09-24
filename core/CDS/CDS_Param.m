%{
PURPOSE
    Superclass of system parameters

DETAILS
    A system parameter is a symbolic variable with associated meaning and numeric data
    e.g. It may represent a constant, a lagrange multiplier, a generalised coordinate, or an expression of time
    Data associated with the parameter is stored with it e.g. numeric value, initial condition

INTERNAL
    matlab.mixin.Heterogeneous
        Allows creation of arrays of params of differing subtypes
        Restrictions (only applies to mixed arrays):
            Can only call methods from common base, and they must be sealed

    Avoid str2sym(), it turns 'i'&'j' into '1i' because imaginary numbers
%}

classdef (Abstract) CDS_Param < CDS_NamedItem & matlab.mixin.Heterogeneous
properties (GetAccess=protected, SetAccess=immutable)
    % For CDS_Param_x
    %   0: normal
    %   1: interface for q_d
    d_offset(1,1) double {mustBeMember(d_offset,[0,1,2])} = 0

    % Eager cache of commonly called variants of this.Sym(), as already offset by d_offset
    % Cache always valid due do to only depending on immutable params and pure functions
    % This has a large impact on overall speed
    sym_0 sym
    sym_1 sym
    sym_2 sym
end
properties (Access=protected)
    sym_short(:,1) CDS_Helper_PropPointer
end
methods (Sealed=true)
    %**********************************************************************
    % Interface: Create
    %***********************************
    % Intended for internal use only
    function this = CDS_Param(symIn, d_offset, symShortPtr)
        arguments
            symIn(1,1) string
            d_offset(1,1) double {mustBeMember(d_offset,[0,1,2])} = 0
            symShortPtr(1,1) CDS_Helper_PropPointer = CDS_Helper_PropPointer("sym",sym(symIn))
        end
        % Validate
        %   Must be a valid variable name
        %   Must be able to be cast to a sym
        if symIn==""; error("Bad input: (empty string)"); end
        if ~isvarname(symIn); error("Bad input, not a valid variable name: "+symIn); end
        sym(symIn, 'real');

        this@CDS_NamedItem(symIn);
        this.sym_short = symShortPtr;

        this.d_offset = d_offset;

        % Important: Run after setting d_offset
        % Eager cache of commonly called variants of this.Sym(), as already offset by d_offset
        this.sym_0 = sym(this.Str(0), 'real');
        this.sym_1 = sym(this.Str(1), 'real');
        if d_offset<=1
            this.sym_2 = sym(this.Str(2), 'real');
        end
    end

    %**********************************************************************
    % Interface: Set
    %***********************************
    % Intended for internal use only
    % For code generation. Variable name to represent the parameter in the generated code
    function this = SetSymShort(this, nameIn)
        arguments
            this(1,1)
            nameIn
        end
        this.sym_short.SetProp(nameIn);
    end

    %**********************************************************************
    % Interface: Get
    %***********************************
    % Symbolic variable to represent the parameter
    % INPUT
    %   d
    %       0: Get the sym
    %       1: Get sym for the 1st derivative (append 'd')
    %       2: Get sym for the 2nd derivative (append 'dd')
    %   t
    %       '0': Output as a symbolic variable
    %       't': Output as a symbolic function of time
    %   nDiff
    %       0: No effect
    %       1: Use with t='t'. Output wrapped in diff(..., sym('t','real'), 1)
    %       2: Use with t='t'. Output wrapped in diff(..., sym('t','real'), 2)
    % OUTPUT
    %   (sym) DIM[size(this)]
    %       If t='0': (symbolic variable)
    %       If t='t': (symbolic function)
    function out = Sym(this, d, t, nDiff)
        arguments
            this
            d(1,1) double {mustBeMember(d,[0,1,2])} = 0
            t(1,1) char {mustBeMember(t,['0','t'])} = '0'
            nDiff(1,1) double {mustBeMember(nDiff,[0,1,2])} = 0
        end
        % Validate
        % Offset to interface objects is applied in this.Str(), so only use for validation here
        d_withOffset = this.PropArray(this.d_offset) + d + nDiff;
        if d+nDiff>3; error("Bad input: Differential order greater than 3"); end
        if any(d_withOffset>3); error("Bad input: Differential order greater than 3 (using offset interface)"); end
        if t~='t' && nDiff>0; error("Bad input: Not function of time => can't differentiate"); end

        if isempty(this)
            out = sym.empty(size(this));
            return
        end

        if t=='t'
            % Form sym
            out = str2sym(strcat(this.Str(d),'(t)'));

            % Differentiate
            out = diff(out,sym('t','real'),nDiff);
        else
            % Retrieve sym from cache (as already offset by d_offset)
            % Fallback: form sym
            if     d==0; out = this.PropArray(this.sym_0);
            elseif d==1; out = this.PropArray(this.sym_1);
            elseif d==2; out = this.PropArray(this.sym_2);
            else;        out = sym(this.Str(d), 'real');
            end
        end
    end

    % Symbolic variable to represent the parameter
    % INPUT
    %   d
    %       0: Get the sym
    %       1: Get sym for the 1st derivative (append 'd')
    %       2: Get sym for the 2nd derivative (append 'dd')
    % OUTPUT
    %   (string) DIM[size(this)]
    function out = Str(this, d)
        arguments
            this
            d(1,1) double {mustBeMember(d,[0,1,2])} = 0
        end
        % Apply offset to interface objects
        d = d + this.PropArray(this.d_offset);
        if any(d>3); error("Bad input: Differential order greater than 3 (using offset interface)"); end

        % Form output string
        out = this.Name;
        idx = d==1; out(idx) = strcat(out(idx),'d');
        idx = d==2; out(idx) = strcat(out(idx),'dd');
        idx = d==3; out(idx) = strcat(out(idx),'ddd');
    end

    % Intended for internal use only
    % For code generation. Variable name to represent the parameter in the generated code
    function out = SymShort(this, d)
        arguments
            this
            d(1,1) double {mustBeMember(d,[0,1,2])} = 0
        end
        out =  sym(this.StrShort(d), 'real');
    end

    % Intended for internal use only
    % Same as this.SymShort, but output as a string
    function out = StrShort(this, d)
        arguments
            this
            d(1,1) double {mustBeMember(d,[0,1,2])} = 0
        end
        symArray = this.SymShortPtr.Prop;

        % Apply offset to interface objects
        d = d + this.PropArray(this.d_offset);
        if any(d>3); error("Bad input: working with offset interface"); end

        % Form output string
        out = strings(size(this));
        idx = d==0; out(idx) = string(symArray(idx));
        idx = d==1; out(idx) = strcat(string(symArray(idx)),'d');
        idx = d==2; out(idx) = strcat(string(symArray(idx)),'dd');
        idx = d==3; out(idx) = strcat(string(symArray(idx)),'ddd');
    end

    % Friendly name to identify the parameter by
    % Used in some outputs, error messages, generated code
    % INPUT
    %   d
    %       0: Get name of the param
    %       1: Get name of the 1st derivative (append '[d]')
    %       2: Get name of the 2nd derivative (append '[dd]')
    % OUTPUT
    %   (string) DIM[size(this)]
    function out = NameReadable(this, d)
        arguments
            this
            d(1,1) double {mustBeMember(d,[0,1,2])} = 0
        end
        nameArray = this.Name;

        % Apply offset to interface objects
        d = d + this.PropArray(this.d_offset);
        if any(d>3); error("Bad input: working with offset interface"); end

        % Form output string
        out = strings(size(this));
        idx = d==0; out(idx) = string(nameArray(idx));
        idx = d==1; out(idx) = strcat(nameArray(idx)," [d]");
        idx = d==2; out(idx) = strcat(nameArray(idx)," [dd]");
        idx = d==3; out(idx) = strcat(nameArray(idx)," [ddd]");
    end

    %**********************************************************************
    % Internal
    %***********************************
    % Intended for internal use only
    % Get 'pointer' to properties
    %   Used so interfaces share properties with underlying param
    function propObject = SymShortPtr(this)
        if isempty(this)
            propObject = CDS_Helper_PropPointer.empty(size(this));
            return;
        end
        propObject = this.PropArray(this.sym_short);
    end
end
end

%{
Intended for internal use only

PURPOSE
    A handle container for a single variable
    This allows the container to be copied (e.g. returned by value), and changed universally from any copy
    In practice, the objects that use this helper hide the functionality behind their own Get/Set methods

EXAMPLE
    a = CDS_Helper_PropPointer("string", "I am A");
    b = a;
    b.SetProp("I am B");
    a.Prop
    % Returns: "I am B"
%}

classdef CDS_Helper_PropPointer < handle
properties (Access=private)
    prop
    type(1,1) string = ""
end
methods
    function this = CDS_Helper_PropPointer(type, prop)
        this.type = type;
        this.prop = this.ValidateProp(prop);
    end
    
    function SetProp(this, prop)
        this.prop = this.ValidateProp(prop);
    end
    
    function prop = Prop(this)
        prop = this.PropArray(this.prop);
    end
end
methods (Access=private)
    % Helper to allow using functions with an array of objects
    % NOTE: Only intended for 1D arrays
    % Input: List of properties
    % OUTPUT: Array of properties corresponding to the object
    % EXAMPLE: this.PropArray(this.prop)
    function propArray = PropArray(this, varargin)
        propArray = reshape([varargin{:}],size(this));
    end
    
    function prop = ValidateProp(this, prop)
        try % First check if type exactly matches
            mustBeA(prop, this.type)
            return
        catch
            % Try next option
        end
        try % Then try to cast it
            if strcmp(this.type, "string")
                prop = string(prop);
                return
            elseif strcmp(this.type, "sym")
                prop = sym(prop);
                return
            end
            
            prop = cast(prop, this.type);
            return
        catch
            % Try next option
        end
        error("Bad input: Can't cast to type '%s'", this.type)
    end
end
end

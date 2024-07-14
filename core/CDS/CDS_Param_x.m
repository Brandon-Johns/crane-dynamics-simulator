%{
Intended for internal use only

PURPOSE
    Interface to CDS_Param_Free and CDS_Param_Lambda
    Allows pretending that q and q_d are separate variables (but not q_dd)
    Therefore, all methods and properties can be called through a common interface with differential automatic offset
%}

classdef CDS_Param_x < CDS_Param
properties (SetAccess=immutable, GetAccess=private)
    % The actual object
    x
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    function this = CDS_Param_x(x_object, d_offset)
        arguments
            x_object(1,1) {mustBeA(x_object, ["CDS_Param_Free", "CDS_Param_Lambda"])}
            d_offset(1,1) double {mustBeMember(d_offset,[0,1])} = 0
        end
        this@CDS_Param(x_object.Sym, d_offset, x_object.SymShortPtr, x_object.NameReadablePtr);
        
        % Validate input
        if d_offset == 1 && ~isa(x_object, "CDS_Param_Free")
            error("Bad input")
        end
            
        this.x = x_object;
    end
    
    %**********************************************************************
    % Interface: Set
    %***********************************
    function this = SetIC(this, x0,x_d0)
        d = this.PropArray(this.d_offset);
        
        for idx = 1:length(d)
            if this(idx).d_offset == 0
                this(idx).x.SetIC(x0(idx),x_d0(idx));
            else
               this(idx).x.SetIC_offset(x0(idx),x_d0(idx));
            end
        end
    end
    
    %**********************************************************************
    % Interface: Get
    %***********************************
    % Initial conditions
    function out = x0(this)
        d = this.PropArray(this.d_offset);
        ObjectArray = [this.x];
        
        % Get output
        out = zeros(size(this));
        for idx = 1:length(d)
            if d(idx)==0
                out(idx) = [ObjectArray(idx).q0];
            else
                out(idx) = [ObjectArray(idx).q_d0];
            end
        end
    end
    function out = x_d0(this)
        d = this.PropArray(this.d_offset);
        ObjectArray = [this.x];
        
        % Get output
        out = zeros(size(this));
        for idx = 1:length(d)
            if d(idx)==0
                out(idx) = [ObjectArray(idx).q_d0];
            else
                out(idx) = [ObjectArray(idx).q_dd0];
            end
        end
    end
    function out = x0_fixed(this)
        d = this.PropArray(this.d_offset);
        ObjectArray = [this.x];
        
        % Get output
        out = zeros(size(this));
        for idx = 1:length(d)
            if d(idx)==0
                out(idx) = [ObjectArray(idx).q0_fixed];
            else
                out(idx) = [ObjectArray(idx).q_d0_fixed];
            end
        end
    end
    function out = x_d0_fixed(this)
        d = this.PropArray(this.d_offset);
        ObjectArray = [this.x];
        
        % Get output
        out = zeros(size(this));
        for idx = 1:length(d)
            if d(idx)==0
                out(idx) = [ObjectArray(idx).q_d0_fixed];
            else
                out(idx) = [ObjectArray(idx).q_dd0_fixed];
            end
        end
    end
    
    % Get underlying objects
    %   Retrieving "this.x" gives underlying CDS_Param_Free or CDS_Param_Lambda
    %   Retrieving "this" would give CDS_Param_x
    function [param, d_offset, type] = ParamUnderlying(this)
        param = this.PropArray(this.x);
        d_offset = this.PropArray(this.d_offset);
        
        type = strings(size(this));
        for idx = 1:length(this)
            type(idx) = class(param(idx));
        end
    end
end
end

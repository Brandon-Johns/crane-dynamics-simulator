%{
Intended for internal use only

PURPOSE
    Interface to CDS_Param_Input
    Allows pretending that q, q_d and q_dd are separate variables
    Therefore, all methods and properties can be called through a common interface with differential automatic offset
%}

classdef CDS_Param_u < CDS_Param
properties (SetAccess=immutable, GetAccess=private)
    % The actual object
    u
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    function this = CDS_Param_u(u_object, d_offset)
        arguments
            u_object(1,1) CDS_Param_Input
            d_offset(1,1) double {mustBeMember(d_offset,[0,1,2])} = 0
        end
        this@CDS_Param(u_object.Sym, d_offset, u_object.SymShortPtr, u_object.NameReadablePtr);
            
        this.u = u_object;
    end
    
    %**********************************************************************
    % Interface: Set
    %***********************************
    
    %**********************************************************************
    % Interface: Get
    %***********************************
    % Initial conditions
    %   NOTE:
    %       Conflict - how to decide if to match output dimensions to u or t
    %           Could choose to always follow 1, but if it is entered as a single value,
    %           then the intended direction would be unknown.
    %           => Always use [u(t_0); ...; u(t_n)]
    function out = q(this)
        % Special case if empty
        if isempty(this)
            out = @(t_,x_) [];
            return
        end
        
        % Setup
        d = [this.d_offset];
        ObjectArray = [this.u];
        
        % Get output
        cellArrayOfHandles = cell(size(this));
        idx = d==0; cellArrayOfHandles(idx) = {ObjectArray(idx).q};
        idx = d==1; cellArrayOfHandles(idx) = {ObjectArray(idx).q_d};
        idx = d==2; cellArrayOfHandles(idx) = {ObjectArray(idx).q_dd};
        
        % Array of indexes to address the cell array at
        %   Output dimensions will match this array, per how arrayfun works
        %idx_handle = ( 1:length(cellArrayOfHandles) ).';
        
        % Merge into 1 function handle with array output
        %   TODO: optimise
        %out = @(t_) arrayfun(@(n) cellArrayOfHandles{n}(t_), idx_handle);
        %out = @(t_) arrayfun(@(n) cellArrayOfHandles{n}(t_), idx_handle, 'UniformOutput',false);
        out = @(t_,x_) this.evalCellOfHandles(cellArrayOfHandles, t_, x_);
    end
    
    function out = evalCellOfHandles(~, h, t, x)
        % Always use output dimensions [u(t_0); ...; u(t_n)]
        out = zeros(length(h),length(t));
        for idx_h = 1:length(h)
            out(idx_h,:) = h{idx_h}(t,x);
        end
    end
end
end

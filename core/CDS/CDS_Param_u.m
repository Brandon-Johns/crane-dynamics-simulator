%{
Intended for internal use only

PURPOSE
    Interface to CDS_Param_Input
    Allows pretending that q, q_d, and q_dd are separate variables
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
        this@CDS_Param(u_object.Sym, d_offset, u_object.SymShortPtr);

        this.u = u_object;
    end

    %**********************************************************************
    % Interface: Get
    %***********************************
    % Evaluate as a function of time
    % INPUT
    %   t: time
    % OUTPUT
    %   [u_1(t); ...; u_n(t)] with DIM[length(this), length(t)]
    %   Using convention (tensor dims, batch dims), as limited to 1D object arrays and 1D inputs
    function result = q(this, t)
        arguments
            this(:,1)
            t(:,1)
        end
        q_h = this.q_h;
        result = q_h(t);
    end

    % Handle to evaluate as a function of time
    % OUTPUT
    %   Handle to function that evaluates [u_1(t); ...; u_n(t)] with DIM[length(this), length(t)]
    %   Using convention (tensor dims, batch dims), as limited to 1D object arrays and 1D inputs
    function out = q_h(this)
        arguments
            this(:,1)
        end
        if isempty(this)
            out = @(t_) double.empty(0, length(t_));
            return
        end

        % Get handles according to offset
        % Keep the order of u, but flatten into vertical 1D array
        d = [this.d_offset];
        ObjectArray = [this.u];
        cellArrayOfHandles = cell(size(this));
        idx = d==0; cellArrayOfHandles(idx) = {ObjectArray(idx).q};
        idx = d==1; cellArrayOfHandles(idx) = {ObjectArray(idx).q_d};
        idx = d==2; cellArrayOfHandles(idx) = {ObjectArray(idx).q_dd};

        % Merge into 1 function handle with array output
        out = @(t_) this.evalCellOfHandles(cellArrayOfHandles, t_);
    end
end
methods (Access=private)
    % OUTPUT
    %   [u_1(t); ...; u_n(t)]
    function out = evalCellOfHandles(~, h, t)
        out = zeros(length(h),length(t));
        for idx_h=1:length(h); out(idx_h,:)=h{idx_h}(t); end
    end
end
end

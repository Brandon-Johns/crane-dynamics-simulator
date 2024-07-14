%{
PURPOSE
    Extract data from CDS_Solution via the names of parameters/points

COMMON INPUTS
Data is retrieved for the input parameters/points
    params
        (string): Array of the values matching the output of CDS_Param.Str
        (CDS_Param): Array of CDS_Param
    points
        (string): Array of the values matching the output of CDS_Point.NameShort
        (CDS_Point): Array of CDS_Point
Data is retrieved for the specified times
    idx_time: (default = all time coordinates) Time coordinates by index, according the time in CDS_Solution.t

NOTES
    The solution array time indices all correspond to the same times
    Therefore the method t_idx() is key to getting data at specified times

EXAMPLE
    % Given: SS = CDS_Solution

    % Get the x coordinates of points ["A", "B"] at the times [2.3, 5.7, 6.5] seconds
    SSg = CDS_Solution_GetData(SS);
    idx = SSg.t_idx([2.3, 5.7, 6.5]);
    position_x = SSg.Px(["A", "B"], idx);

    % Get the time rate of change of theta_1 at the same times
    theta_1_d = SSg.qd("theta_1", idx);
%}

classdef CDS_Solution_GetData < handle
properties (Access=private)
    SS(1,1) CDS_Solution
end
methods
    % INPUT
    %   CDS_Solution
    function this = CDS_Solution_GetData(solution)
        % This results that: Input array -> output array of objects
        %   (instead of assigning the input array to the property of 1 output object)
        %   https://au.mathworks.com/help/matlab/matlab_oop/creating-object-arrays.html
        if nargin==0; return; end
        for idx = length(solution):-1:1
            this(idx).SS = solution(idx);
        end
    end
    
    %**********************************************************************
    % Plain data
    %***********************************
    % INPUT
    %   frameTimes: Array of solution times
    % OUTPUT
    %   Indices of the nearest time coordinates to the input times
    function idx_time = t_idx(this, frameTimes)
        arguments
            this(1,1)
            frameTimes(:,1) double
        end
        % Note: this function can also return the error from the nearest points,
        %   in case I need that later
        idx_time = dsearchn(this.SS.t.', frameTimes(:));
    end

    % Get the configurations of given parameters at given times
    function out = q(this, params, idx_time)
        arguments
            this(1,1)
            params(:,1) {mustBeA(params, ["string", "CDS_Param"])} = this.SS.q_free
            idx_time(:,1) uint64 = 1:length(this.SS.t)
        end
        out = [];
        for idx = 1:length(params)
            idxPointInSS = this.SS.q_free.ParamIdx(params(idx), "KeepDuplicates", "NoWarn");
            if ~isempty(idxPointInSS)
                out(end+1, :) = this.SS.qf(idxPointInSS, idx_time);
                continue;
            end
            
            idxPointInSS = this.SS.q_input.ParamIdx(params(idx), "KeepDuplicates", "NoWarn");
            if ~isempty(idxPointInSS)
                out(end+1, :) = this.SS.qi(idxPointInSS, idx_time);
                continue;
            end
            
            idxPointInSS = this.SS.q_lambda.ParamIdx(params(idx), "KeepDuplicates", "NoWarn");
            if ~isempty(idxPointInSS)
                out(end+1, :) = this.SS.ql(idxPointInSS, idx_time);
                continue;
            end

            % If this is reached, then the point is not found
            if isa(params, "string")
                warning("Param not found: " + params(idx));
            else
                warning("Param not found: " + params(idx).NameReadable);
            end
        end
    end

    % Get the configurations of given parameters at given times
    % First time derivative
    function out = qd(this, params, idx_time)
        arguments
            this(1,1)
            params(:,1) {mustBeA(params, ["string", "CDS_Param"])} = this.SS.q_free
            idx_time(:,1) uint64 = 1:length(this.SS.t)
        end
        out = [];
        for idx = 1:length(params)
            idxPointInSS = this.SS.q_free.ParamIdx(params(idx), "KeepDuplicates", "NoWarn");
            if ~isempty(idxPointInSS)
                out(end+1, :) = this.SS.qf_d(idxPointInSS, idx_time);
                continue;
            end
            
            idxPointInSS = this.SS.q_input.ParamIdx(params(idx), "KeepDuplicates", "NoWarn");
            if ~isempty(idxPointInSS)
                out(end+1, :) = this.SS.qi_d(idxPointInSS, idx_time);
                continue;
            end
            
            idxPointInSS = this.SS.q_lambda.ParamIdx(params(idx), "KeepDuplicates", "NoWarn");
            if ~isempty(idxPointInSS)
                out(end+1, :) = this.SS.ql_d(idxPointInSS, idx_time);
                continue;
            end

            % If this is reached, then the point is not found
            if isa(params, "string")
                warning("Param not found: " + params(idx));
            else
                warning("Param not found: " + params(idx).NameReadable);
            end
        end
    end

    % Get the configurations of given parameters at given times
    % Second time derivative
    function out = qdd(this, params, idx_time)
        arguments
            this(1,1)
            params(:,1) {mustBeA(params, ["string", "CDS_Param"])} = this.SS.q_free
            idx_time(:,1) uint64 = 1:length(this.SS.t)
        end
        out = [];
        for idx = 1:length(params)
            idxPointInSS = this.SS.q_free.ParamIdx(params(idx), "KeepDuplicates", "NoWarn");
            if ~isempty(idxPointInSS)
                out(end+1, :) = this.SS.qf_dd(idxPointInSS, idx_time);
                continue;
            end
            
            idxPointInSS = this.SS.q_input.ParamIdx(params(idx), "KeepDuplicates", "NoWarn");
            if ~isempty(idxPointInSS)
                out(end+1, :) = this.SS.qi_dd(idxPointInSS, idx_time);
                continue;
            end
            
            % If this is reached, then the point is not found
            % Note: acceleration for q_lambda is not calculated
            if isa(params, "string")
                warning("Param not found: " + params(idx));
            else
                warning("Param not found: " + params(idx).NameReadable);
            end
        end
    end

    % Get the position of given points at given times
    % x,y,z coordinates
    function out = Px(this, points, idx_time)
        arguments
            this(1,1)
            points(:,1) {mustBeA(points, ["string", "CDS_Point"])} = this.SS.p_mass
            idx_time(:,1) uint64 = 1:length(this.SS.t)
        end
        out = this.SS.Px( this.SS.p_all.PointIdx(points), idx_time);
    end
    function out = Py(this, points, idx_time)
        arguments
            this(1,1)
            points(:,1) {mustBeA(points, ["string", "CDS_Point"])} = this.SS.p_mass
            idx_time(:,1) uint64 = 1:length(this.SS.t)
        end
        out = this.SS.Py( this.SS.p_all.PointIdx(points), idx_time);
    end
    function out = Pz(this, points, idx_time)
        arguments
            this(1,1)
            points(:,1) {mustBeA(points, ["string", "CDS_Point"])} = this.SS.p_mass
            idx_time(:,1) uint64 = 1:length(this.SS.t)
        end
        out = this.SS.Pz( this.SS.p_all.PointIdx(points), idx_time);
    end

    % Get the position of 1 given point at given times
    % Position vector
    function out = P(this, point, idx_time)
        arguments
            this(1,1)
            point(1,1) {mustBeA(point, ["string", "CDS_Point"])}
            idx_time(:,1) uint64 = 1:length(this.SS.t)
        end
        out = [...
            this.SS.Px( this.SS.p_all.PointIdx(point), idx_time);
            this.SS.Py( this.SS.p_all.PointIdx(point), idx_time);
            this.SS.Pz( this.SS.p_all.PointIdx(point), idx_time)];
    end

    % Get the position of given points at 1 given time
    % Position vector
    function data = xyz(this, idx_time, points)
        arguments
            this(1,1)
            idx_time(1,1) uint64 = this.t_idx(0)
            points(:,1) {mustBeA(points, ["string", "CDS_Point"])} = this.SS.p_all
        end
        % Get ordered indices of points to plot
        idxP = this.SS.p_all.PointIdx(points, "KeepDuplicates", "NoWarn");
        
        % Get ordered points
        data = [...
            this.SS.Px(idxP,idx_time),...
            this.SS.Py(idxP,idx_time),...
            this.SS.Pz(idxP,idx_time)];
    end

    %**********************************************************************
    % Formatted data
    %***********************************
    % Same as this.xyz(), but the output is formatted as a table
    function dataTable = xyzTable(this, frameTime, points)
        arguments
            this(1,1)
            frameTime(1,1) double = 0
            points(:,1) {mustBeA(points, ["string", "CDS_Point"])} = this.SS.p_all
        end
        % Find closest frames to specified times
        idx_time = this.t_idx(frameTime);

        % Get ordered indices of points to plot
        idxP = this.SS.p_all.PointIdx(points, "RemoveDuplicates");
        
        % Get ordered points
        data = [...
            this.SS.Px(idxP,idx_time),...
            this.SS.Py(idxP,idx_time),...
            this.SS.Pz(idxP,idx_time)];

        dataTable = array2table(data, 'VariableName',["x","y","z"], 'RowNames',this.SS.p_all(idxP).NameShort);
    end
    
    % Same as this.xyz(), but with the output table transposed
    function dataTable = xyzTable_t(this, varargin)
        dataTable = rows2vars( this.xyzTable(varargin{:}) );
    end

    %**********************************************************************
    % Operate on data
    %***********************************
    % INPUT
    %   point1:
    %   point2: (default = [0,0,0])
    % OUTPUT
    %   Norm of the task space distance between the 2 points
    function absDistance = AbsDistance(this, point1, point2)
        arguments
            this(1,1)
            point1(1,1) {mustBeA(point1, ["string", "CDS_Point"])}
            point2(1,1) {mustBeA(point2, ["string", "CDS_Point"])} = strings(0)
        end
        IsSingleInput = isempty(point2);

        idxP1 = this.SS.p_all.PointIdx(point1);
        idxP2 = this.SS.p_all.PointIdx(point2);

        % Test points exist
        if isempty(idxP1); error("First point not found"); end
        if isempty(idxP2) && ~IsSingleInput; error("Second point not found"); end

        if ~IsSingleInput
            distance_x = this.SS.Px(idxP1, :) - this.SS.Px(idxP2, :);
            distance_y = this.SS.Py(idxP1, :) - this.SS.Py(idxP2, :);
            distance_z = this.SS.Pz(idxP1, :) - this.SS.Pz(idxP2, :);
        else
            distance_x = this.SS.Px(idxP1, :);
            distance_y = this.SS.Py(idxP1, :);
            distance_z = this.SS.Pz(idxP1, :);
        end

        absDistance = vecnorm([distance_x(:), distance_y(:), distance_z(:)], 2, 2);
    end

    % ASSUMES
    %   y axis is up
    % INPUT
    %   point1:
    %   point2:
    % OUTPUT
    %   The acute angle between the line joining the 2 points and a vertical line
    function angleFromVertical = AngleFromVertical(this, point1, point2)
        arguments
            this(1,1)
            point1(1,1) {mustBeA(point1, ["string", "CDS_Point"])}
            point2(1,1) {mustBeA(point2, ["string", "CDS_Point"])}
        end
        
        idxP1 = this.SS.p_all.PointIdx(point1);
        idxP2 = this.SS.p_all.PointIdx(point2);

        % Test points exist
        if isempty(idxP1); error("First point not found"); end
        if isempty(idxP2); error("Second point not found"); end

        distance_y = this.SS.Py(idxP1, :) - this.SS.Py(idxP2, :);
        absDistance = this.AbsDistance(point1, point2);
        angleFromVertical = acos( distance_y(:) ./ absDistance(:) );
    end
end
end

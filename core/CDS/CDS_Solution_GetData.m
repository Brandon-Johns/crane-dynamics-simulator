%{
PURPOSE
    Extract solution data by querying CDS_Solution with the names of parameters/points

NOTES
    The solution array time indices all correspond to the same times
    Use CDS_Solution.t_idx() to convert solution time values to solution time indices

EXAMPLE
    % Given:
    %   SS: CDS_Solution

    % Get the x coordinates of points ["A", "B"] at the times [2.3, 5.7, 6.5] seconds
    SSg = CDS_Solution_GetData(SS);
    idx = SS.t_idx([2.3, 5.7, 6.5]);
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
    %   The solution to query
    function this = CDS_Solution_GetData(solution)
        arguments
            solution CDS_Solution
        end
        if isempty(solution)
            this = CDS_Solution_GetData.empty(size(solution));
            return;
        end
        if isscalar(solution)
            this.SS = solution;
            return;
        end
        for idx = 1:numel(solution)
            this(idx) = CDS_Solution_GetData(solution(idx));
        end
        this = reshape(this, size(solution));
    end

    %**********************************************************************
    % Plain data
    %***********************************
    % Get the configurations of given parameters at given times
    % INPUT
    %   params
    %       (string)            Vector of values from CDS_Param.Str
    %       (symbolic variable) Vector of values from CDS_Param.Sym
    %       (CDS_Param)         Vector of CDS_Param
    %   idx_time: Time coordinates, specified by index to CDS_Solution.t
    % OUTPUT
    %   (double) DIM[length(params), length(idx_time)]
    function out = q(this, params, idx_time)
        arguments
            this(1,1)
            params(:,1) {mustBeA(params, ["string", "sym", "CDS_Param"])} = this.SS.sys.params.q_free
            idx_time(:,1) uint64 = 1:length(this.SS.t)
        end
        out = [];
        for idx = 1:length(params)
            idxP = this.SS.sys.params.q_free.SubsetIdx(params(idx), warnMissing=false);
            if ~isempty(idxP)
                out(end+1, :) = this.SS.qf(idxP, idx_time);
                continue;
            end

            idxP = this.SS.sys.params.q_input.SubsetIdx(params(idx), warnMissing=false);
            if ~isempty(idxP)
                out(end+1, :) = this.SS.qi(idxP, idx_time);
                continue;
            end

            % Extra test in case lambda was not solved for
            idxP = this.SS.sys.params.lambda.SubsetIdx(params(idx), warnMissing=false);
            if ~isempty(idxP) && ~isempty(this.SS.ql)
                out(end+1, :) = this.SS.ql(idxP, idx_time);
                continue;
            end

            % If this is reached, then the point is not found
            if any(class(params)==["string","sym"])
                warning("Param not found: " + string(params(idx)));
            else
                warning("Param not found: " + params(idx).NameReadable);
            end
        end
    end

    % Get the configurations of given parameters at given times
    % First time derivative
    % INPUT
    %   params
    %       (string)            Vector of values from CDS_Param.Str
    %       (symbolic variable) Vector of values from CDS_Param.Sym
    %       (CDS_Param)         Vector of CDS_Param
    %   idx_time: Time coordinates, specified by index to CDS_Solution.t
    % OUTPUT
    %   (double) DIM[length(params), length(idx_time)]
    function out = qd(this, params, idx_time)
        arguments
            this(1,1)
            params(:,1) {mustBeA(params, ["string", "sym", "CDS_Param"])} = this.SS.sys.params.q_free
            idx_time(:,1) uint64 = 1:length(this.SS.t)
        end
        out = [];
        for idx = 1:length(params)
            idxP = this.SS.sys.params.q_free.SubsetIdx(params(idx), warnMissing=false);
            if ~isempty(idxP)
                out(end+1, :) = this.SS.qf_d(idxP, idx_time);
                continue;
            end

            idxP = this.SS.sys.params.q_input.SubsetIdx(params(idx), warnMissing=false);
            if ~isempty(idxP)
                out(end+1, :) = this.SS.qi_d(idxP, idx_time);
                continue;
            end

            % Extra test in case lambda was not solved for
            idxP = this.SS.sys.params.lambda.SubsetIdx(params(idx), warnMissing=false);
            if ~isempty(idxP) && ~isempty(this.SS.ql_d)
                out(end+1, :) = this.SS.ql_d(idxP, idx_time);
                continue;
            end

            % If this is reached, then the point is not found
            if any(class(params)==["string","sym"])
                warning("Param not found: " + string(params(idx)));
            else
                warning("Param not found: " + params(idx).NameReadable);
            end
        end
    end

    % Get the configurations of given parameters at given times
    % Second time derivative
    % INPUT
    %   params
    %       (string)            Vector of values from CDS_Param.Str
    %       (symbolic variable) Vector of values from CDS_Param.Sym
    %       (CDS_Param)         Vector of CDS_Param
    %   idx_time: Time coordinates, specified by index to CDS_Solution.t
    % OUTPUT
    %   (double) DIM[length(params), length(idx_time)]
    function out = qdd(this, params, idx_time)
        arguments
            this(1,1)
            params(:,1) {mustBeA(params, ["string", "sym", "CDS_Param"])} = this.SS.sys.params.q_free
            idx_time(:,1) uint64 = 1:length(this.SS.t)
        end
        out = [];
        for idx = 1:length(params)
            idxP = this.SS.sys.params.q_free.SubsetIdx(params(idx), warnMissing=false);
            if ~isempty(idxP)
                out(end+1, :) = this.SS.qf_dd(idxP, idx_time);
                continue;
            end

            idxP = this.SS.sys.params.q_input.SubsetIdx(params(idx), warnMissing=false);
            if ~isempty(idxP)
                out(end+1, :) = this.SS.qi_dd(idxP, idx_time);
                continue;
            end

            % If this is reached, then the point is not found
            % Note: acceleration for lambda is not calculated
            if any(class(params)==["string","sym"])
                warning("Param not found: " + string(params(idx)));
            else
                warning("Param not found: " + params(idx).NameReadable);
            end
        end
    end

    % Get the position of given points at given times
    % x,y,z coordinates
    % INPUT
    %   points
    %       (string)    Vector of values from CDS_Point.Name
    %       (CDS_Point) Vector of CDS_Point
    %   idx_time: Time coordinates, specified by index to CDS_Solution.t
    % OUTPUT
    %   (double) DIM[length(points), length(idx_time)]
    function out = Px(this, points, idx_time)
        arguments
            this(1,1)
            points(:,1) {mustBeA(points, ["string", "CDS_Point"])} = this.SS.sys.points.GetIfHasMass
            idx_time(:,1) uint64 = 1:length(this.SS.t)
        end
        out = this.SS.Px( this.SS.sys.points.SubsetIdx(points), idx_time);
    end
    function out = Py(this, points, idx_time)
        arguments
            this(1,1)
            points(:,1) {mustBeA(points, ["string", "CDS_Point"])} = this.SS.sys.points.GetIfHasMass
            idx_time(:,1) uint64 = 1:length(this.SS.t)
        end
        out = this.SS.Py( this.SS.sys.points.SubsetIdx(points), idx_time);
    end
    function out = Pz(this, points, idx_time)
        arguments
            this(1,1)
            points(:,1) {mustBeA(points, ["string", "CDS_Point"])} = this.SS.sys.points.GetIfHasMass
            idx_time(:,1) uint64 = 1:length(this.SS.t)
        end
        out = this.SS.Pz( this.SS.sys.points.SubsetIdx(points), idx_time);
    end

    % Get the position of 1 given point at given times
    % Position vector
    % INPUT
    %   point
    %       (string)    A value from CDS_Point.Name
    %       (CDS_Point) A CDS_Point
    %   idx_time: Time coordinates, specified by index to CDS_Solution.t
    % OUTPUT
    %   (double) DIM[3, length(idx_time)]
    function out = P(this, point, idx_time)
        arguments
            this(1,1)
            point(1,1) {mustBeA(point, ["string", "CDS_Point"])}
            idx_time(:,1) uint64 = 1:length(this.SS.t)
        end
        idxP = this.SS.sys.points.SubsetIdx(point);
        out = [...
            this.SS.Px(idxP, idx_time);
            this.SS.Py(idxP, idx_time);
            this.SS.Pz(idxP, idx_time)];
    end

    % Get the position of given points at 1 given time
    % Position vector
    % INPUT
    %   idx_time: Time coordinate, specified by index to CDS_Solution.t
    %   points
    %       (string)    Vector of values from CDS_Point.Name
    %       (CDS_Point) Vector of CDS_Point
    % OUTPUT
    %   (double) DIM[length(points), 3]
    function out = xyz(this, idx_time, points)
        arguments
            this(1,1)
            idx_time(1,1) uint64 = this.SS.t_idx(0)
            points(:,1) {mustBeA(points, ["string", "CDS_Point"])} = this.SS.sys.points
        end
        idxP = this.SS.sys.points.SubsetIdx(points);
        out = [...
            this.SS.Px(idxP,idx_time),...
            this.SS.Py(idxP,idx_time),...
            this.SS.Pz(idxP,idx_time)];
    end

    %**********************************************************************
    % Formatted data
    %***********************************
    % Same as this.xyz(), but the output is formatted as a table
    % INPUT
    %   idx_time: Time coordinate, specified by index to CDS_Solution.t
    %   points
    %       (string)    Vector of values from CDS_Point.Name
    %       (CDS_Point) Vector of CDS_Point
    % OUTPUT
    %   (table(double)) DIM[length(points), 3]
    function out = xyzTable(this, idx_time, points)
        arguments
            this(1,1)
            idx_time(1,1) uint64 = this.SS.t_idx(0)
            points(:,1) {mustBeA(points, ["string", "CDS_Point"])} = this.SS.sys.points
        end
        % Tables are not permitted duplicate row or column names
        idxP = this.SS.sys.points.SubsetIdx(points, keepDuplicates=false);
        data = [...
            this.SS.Px(idxP,idx_time),...
            this.SS.Py(idxP,idx_time),...
            this.SS.Pz(idxP,idx_time)];
        out = array2table(data, 'VariableName',["x","y","z"], 'RowNames',this.SS.sys.points(idxP).Name);
    end

    % Same as this.xyzTable(), but with the output table transposed
    % INPUT
    %   idx_time: Time coordinate, specified by index to CDS_Solution.t
    %   points
    %       (string)    Vector of values from CDS_Point.Name
    %       (CDS_Point) Vector of CDS_Point
    % OUTPUT
    %   (table(double)) DIM[3, length(points)]
    function out = xyzTable_t(this, idx_time, points)
        arguments
            this(1,1)
            idx_time(1,1) uint64 = this.SS.t_idx(0)
            points(:,1) {mustBeA(points, ["string", "CDS_Point"])} = this.SS.sys.points
        end
        out = rows2vars( this.xyzTable(idx_time, points) );
        out.Properties.RowNames = out.OriginalVariableNames;
        out.OriginalVariableNames = [];
    end

    %**********************************************************************
    % Operate on data
    %***********************************
    % Calculate norm of the task space distance between 2 points
    % NOTE
    %   For single input, point2 defaults to [0,0,0]
    % INPUT
    %   point1
    %       (string)    A value from CDS_Point.Name
    %       (CDS_Point) A CDS_Point
    %   point2
    %       (string)    A value from CDS_Point.Name
    %       (CDS_Point) A CDS_Point
    % OUTPUT
    %   (double) DIM[numSolutionTime, 1]
    function result = AbsDistance(this, point1, point2)
        arguments
            this(1,1)
            point1(1,1) {mustBeA(point1, ["string", "CDS_Point"])}
            point2(1,1) {mustBeA(point2, ["string", "CDS_Point"])} = strings(0)
        end
        IsSingleInput = isempty(point2);

        idxP1 = this.SS.sys.points.SubsetIdx(point1);
        idxP2 = this.SS.sys.points.SubsetIdx(point2);

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

        result = vecnorm([distance_x(:), distance_y(:), distance_z(:)], 2, 2);
    end

    % Calculate acute angle between the line joining the 2 points and a vertical line
    % ASSUMES
    %   y axis is up
    % INPUT
    %   point1
    %       (string)    A value from CDS_Point.Name
    %       (CDS_Point) A CDS_Point
    %   point2
    %       (string)    A value from CDS_Point.Name
    %       (CDS_Point) A CDS_Point
    % OUTPUT
    %   (double) DIM[numSolutionTime, 1]
    function result = AngleFromVertical(this, point1, point2)
        arguments
            this(1,1)
            point1(1,1) {mustBeA(point1, ["string", "CDS_Point"])}
            point2(1,1) {mustBeA(point2, ["string", "CDS_Point"])}
        end

        idxP1 = this.SS.sys.points.SubsetIdx(point1);
        idxP2 = this.SS.sys.points.SubsetIdx(point2);

        % Test points exist
        if isempty(idxP1); error("First point not found"); end
        if isempty(idxP2); error("Second point not found"); end

        distance_y = this.SS.Py(idxP1, :) - this.SS.Py(idxP2, :);
        absDistance = this.AbsDistance(point1, point2);
        result = acos( distance_y(:) ./ absDistance(:) );
    end
end
end

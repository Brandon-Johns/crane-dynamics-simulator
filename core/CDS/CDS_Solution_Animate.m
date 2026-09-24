%{
PURPOSE
    Plot or animate the solution as a line drawing of task space

DETAILS
    Lines are drawn joining the points each chain in CDS_Solution.sys.chains
    Lines are drawn to represent springs and dampers by their connections (if specified)
    Arrows are drawn to represent point forces
    Asterisks are drawn to represent points with mass
%}

classdef CDS_Solution_Animate < handle
properties (Access=private)
    SS(1,1) CDS_Solution

    view_vector(1,3) double = [0,0,1]
    view_upVector(1,3) double = [0,1,0]
    interactiveOrbitUp(1,1) string {mustBeMember(interactiveOrbitUp, ["x","y","z"])} = "y"

    % Indices into SS.Px, .Py, .Pz corresponding to
    %   The points with mass
    %   The points in SS.sys.chains
    idxMass(:,1) uint64
    idxChains(1,:) cell

    % User specified curves to plot
    userCurves_x(1,:) cell
    userCurves_y(1,:) cell
    userCurves_z(1,:) cell

    % Colour blind friendly colours
    % Source: https://sronpersonalpages.nl/~pault/#sec:qualitative
    % Colour blind safe (except greyscale)
    colourPalette = ["#ee6677","#4477aa","#228833","#aa3377","#ccbb44","#66ccee","#bbbbbb"];
end
methods
    % INPUT
    %   The solution to animate
    function this = CDS_Solution_Animate(solution)
        arguments
            solution CDS_Solution
        end
        if isempty(solution)
            this = CDS_Solution_Animate.empty(size(solution));
            return;
        end
        if isscalar(solution)
            this.SS = solution;
            this.Construct;
            return;
        end
        for idx = 1:numel(solution)
            this(idx) = CDS_Solution_Animate(solution(idx));
        end
        this = reshape(this, size(solution));
    end

    % Select a predefined plot view orientation
    % Intended for y-up coordinate systems
    % INPUT
    %   view_name
    %       "top"
    %       "side"
    %       "front"
    %       "3D-1"
    %       "3D-2"
    function Set_View_Predefined(this, view_name)
        arguments
            this(1,1)
            view_name(1,1) string {mustBeMember(view_name,["top","side","front","3D-1","3D-2"])} = "front"
        end

        if view_name=="top"
            this.view_vector = [0,1,0];
            this.view_upVector = [0,0,1];
        elseif view_name=="side"
            this.view_vector = [1,0,0];
            this.view_upVector = [0,1,0];
        elseif view_name=="front"
            this.view_vector = [0,0,1];
            this.view_upVector = [0,1,0];
        elseif view_name=="3D-1"
            this.view_vector = [1,0.5,1];
            this.view_upVector = [0,1,0];
        elseif view_name=="3D-2"
            this.view_vector = [1,0.5,-1];
            this.view_upVector = [0,1,0];
        end
    end

    % Specify additional curves to be plotted along with the other plots
    % NOTE
    %   function handles should be
    %       handle input: t: (double) DIM[1,1] The simulation time
    %       handle output: curve: (double) DIM[1,:] array of all points to plot at that time
    % INPUT
    %   x
    %       (double)          x coordinate data of the curve to plot
    %       (function_handle) function that evaluates the x coordinate data of the curve
    %   y
    %       (double)          y coordinate data of the curve to plot
    %       (function_handle) function that evaluates the y coordinate data of the curve
    %   z
    %       (double)          z coordinate data of the curve to plot
    %       (function_handle) function that evaluates the z coordinate data of the curve
    % EXAMPLE
    %   x = -3:0.1:3;
    %   y = @(t_) 3*t_*x.^2 + 2*t_*x + 1;
    %   z = zeros(size(x));
    %   SSa = CDS_Solution_Animate(CDS_Solution);
    %   SSa.Add_Curve(x, y, z)
    function Add_Curve(this, x, y, z)
        arguments
            this(1,1)
            x(:,1) {mustBeA(x, ["double","function_handle"])}
            y(:,1) {mustBeA(y, ["double","function_handle"])}
            z(:,1) {mustBeA(z, ["double","function_handle"])}
        end
        % Input normalisation
        if isa(x, "double"); x=@(t_)x; end
        if isa(y, "double"); y=@(t_)y; end
        if isa(z, "double"); z=@(t_)z; end
        % Input validation
        if nargin(x)~=1; error("Bad input: x must be a function handle of time only"); end
        if nargin(y)~=1; error("Bad input: y must be a function handle of time only"); end
        if nargin(z)~=1; error("Bad input: z must be a function handle of time only"); end
        x0 = x(0);
        y0 = y(0);
        z0 = z(0);
        if ~isa(x0, "double") || ~isvector(x0); error("Bad input: handle x must output a vector of doubles"); end
        if ~isa(y0, "double") || ~isvector(y0); error("Bad input: handle y must output a vector of doubles"); end
        if ~isa(z0, "double") || ~isvector(z0); error("Bad input: handle z must output a vector of doubles"); end
        if length(x0)~=length(y0) || length(x0)~=length(z0)
            error("Bad input: all vectors must be same length");
        end

        % Register data for plotting
        this.userCurves_x(end+1) = {x};
        this.userCurves_y(end+1) = {y};
        this.userCurves_z(end+1) = {z};
    end

    % Draw the system at given moments in time
    % INPUT
    %   frameTimes
    %       Solution times at which to draw the system. These are automatically adjusted with nearest-neighbour interpolation
    %   aspectRatioMode
    %       "data":     Force axis scale ratios 1:1:1
    %       "variable": Use matlab default axis scale
    %   ax
    %       Axes object to plot on
    function PlotFrame(this, frameTimes, aspectRatioMode, ax)
        arguments
            this(1,1)
            frameTimes(:,1) double = 0
            aspectRatioMode(1,1) string {mustBeMember(aspectRatioMode,["data","variable"])} = "data"
            ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
        end
        % Options
        % Applies to all
        paddingFactor = 0.2; % double, positive
        minAR = 0.4; % double in range [0,1]
        lineWidth = 2;

        if isempty(ax); fig=figure; ax=axes('Parent',fig); end
        fig = ancestor(ax, 'figure');
        hold(ax, 'on')

        % Each type of component gets a colour, and the remaining colours are used by chains
        colours = this.AssignColours(fig);
        ax.ColorOrder = hex2rgb(colours.chains);

        % Find closest frames to specified times
        idxTimes = this.SS.t_idx(frameTimes);

        % Evaluate symbolic expressions needed to draw the components
        componentValues = this.EvaluateComponents(idxTimes);
        LS_connections = componentValues.linearSpringConnections;
        LD_connections = componentValues.linearDamperConnections;
        PF_locs = componentValues.pointForceLocations;
        PF_vals = componentValues.pointForceValues;

        % Loop over all times to plot at
        for idxFrame = 1:length(idxTimes)
            % Draw frame
            idxTime = idxTimes(idxFrame);
            frameTime = this.SS.t(idxTime);
            for idxChain = 1:numel(this.idxChains)
                plot3(ax,...
                    this.SS.Px(this.idxChains{idxChain},idxTime),...
                    this.SS.Py(this.idxChains{idxChain},idxTime),...
                    this.SS.Pz(this.idxChains{idxChain},idxTime),...
                    'LineWidth',lineWidth);
            end
            plot3(ax,...
                this.SS.Px(this.idxMass,idxTime),...
                this.SS.Py(this.idxMass,idxTime),...
                this.SS.Pz(this.idxMass,idxTime),...
                'LineStyle','none',...
                'Marker','*',...
                'MarkerSize',15,...
                'MarkerEdgeColor',colours.markers);
            for idxCurve = 1:length(this.userCurves_x)
                plot3(ax,...
                    this.userCurves_x{idxCurve}(frameTime),...
                    this.userCurves_y{idxCurve}(frameTime),...
                    this.userCurves_z{idxCurve}(frameTime),...
                    'LineWidth',lineWidth, 'Color',colours.userCurves);
            end
            for idx = 1:length(LS_connections)
                % DIMS: {spring}(point,xyz,time)
                plot3(ax,...
                    LS_connections{idx}(:,1,idxFrame), LS_connections{idx}(:,2,idxFrame), LS_connections{idx}(:,3,idxFrame),...
                    'LineWidth',lineWidth, 'LineStyle',':', 'Color',colours.linearSprings)
            end
            for idx = 1:length(LD_connections)
                % DIMS: {damper}(point,xyz,time)
                plot3(ax,...
                    LD_connections{idx}(:,1,idxFrame), LD_connections{idx}(:,2,idxFrame), LD_connections{idx}(:,3,idxFrame),...
                    'LineWidth',lineWidth, 'LineStyle',':', 'Color',colours.linearDampers)
            end
            % DIMS: (point,xyz,time) and (force,xyz,time)
            arrowBase   = PF_locs(:,:,idxFrame); % Location
            arrowLength = PF_vals(:,:,idxFrame); % Force
            if ~isempty(arrowBase)
                quiver3(ax,...
                    arrowBase(:,1),arrowBase(:,2),arrowBase(:,3),...
                    arrowLength(:,1),arrowLength(:,2),arrowLength(:,3),...
                    'LineWidth',lineWidth, 'Color',colours.pointForces);
            end
        end

        % Set axis limits with padding
        % Clamp minimum aspect ratio
        axis(ax, "tight");
        axLim = [ax.XLim; ax.YLim; ax.ZLim];
        axCenter = (axLim(:,2) + axLim(:,1)) / 2;
        axSpan = axLim(:,2) - axLim(:,1);
        clampMinSpan = max(axSpan) * minAR;
        axSpan(axSpan < clampMinSpan) = clampMinSpan; % Apply clamp
        axSpan = axSpan * (1 + paddingFactor); % Apply padding
        axLimPadded(:,1) = axCenter - 0.5*axSpan;
        axLimPadded(:,2) = axCenter + 0.5*axSpan;
        ax.XLim = axLimPadded(1,:);
        ax.YLim = axLimPadded(2,:);
        ax.ZLim = axLimPadded(3,:);

        title(ax, "Configuration at times [ " + strjoin(compose("%g",this.SS.t(idxTimes)),", ") + " ] (s)")
        xlabel(ax, 'x (m)')
        ylabel(ax, 'y (m)')
        zlabel(ax, 'z (m)')
        box(ax, 'off');
        grid(ax, 'on');
        if aspectRatioMode=="data"
            daspect(ax, [1, 1, 1]) % Force axis scale ratios 1:1:1
        end
        this.Set_View(ax);
    end

    % Animate drawing the system at realtime speed
    % INPUT
    %   mode
    %       "play":  Create a figure and animate
    %       "gif":   Write to gif
    %       "video": Write to mp4
    %   fileName
    %       Relative filepath to output the gif/video at
    %       Specify the filename without any file extension
    % INPUT (Name=Value)
    %   frameRate
    %       Target framerate of animation
    %       Set 0 for automatic
    %       Frames are sampled by nearest-neighbour interpolation
    function Animate(this, mode, fileName, options)
        arguments
            this(1,1)
            mode(1,1) string {mustBeMember(mode,["play","gif","video"])} = "play"
            fileName(1,1) string = "tmp"
            options.frameRate(1,1) uint64 = 0
        end

        if mode=="play"
            if options.frameRate == 0
                options.frameRate = 20;
            end
            this.Animate_Setup(mode, options.frameRate);

        elseif mode=="gif"
            if options.frameRate == 0
                options.frameRate = 10;
            end
            ax = this.Animate_Setup(mode, options.frameRate);
            videoFrames = this.Animate_Play(ax, mode);
            this.Animate_SaveGif(videoFrames, fileName, options.frameRate);

        elseif mode=="video"
            if options.frameRate == 0
                options.frameRate = 60;
            end
            ax = this.Animate_Setup(mode, options.frameRate);
            videoFrames = this.Animate_Play(ax, mode);
            this.Animate_SaveVideo(videoFrames, fileName, options.frameRate);
        end
    end
end
methods (Access=private)
    % This should only be called by the constructor
    % Broken out to reduce mess from needing to use this(idx).
    function Construct(this)
        % If gravity is defined (not all zeros), then use it to set the up vectors
        % There is no need to normalise the up vector
        upVector = - this.SS.sys.params.EvaluateSymExpr_IC(this.SS.sys.g0);
        if any(upVector)
            % Set up vector, as used by the interactive orbit tool
            %   Use closest cardinal axis to the up vector
            %   This method, using max() is equivalent to taking the dot product to each axis individually,
            %   and using the most significant result
            interactiveUp_choices = ["x","y","z"];
            [~, interactiveUp_idx] = max(upVector);
            this.interactiveOrbitUp = interactiveUp_choices(interactiveUp_idx);

            this.view_upVector = upVector;

            % view_vector and view_upVector should not be parallel
            if this.view_vector(interactiveUp_idx) > 0.8*norm(this.view_vector)
                this.view_vector = this.view_vector([2,3,1]);
            end
        end

        % Ordered indices of points to plot
        this.idxMass = this.SS.sys.points.SubsetIdx(this.SS.sys.points.GetIfHasMass);
        this.idxChains = cell(size(this.SS.sys.chains));
        for idx = 1:numel(this.idxChains)
            % Closed chains (duplicates) are a normal input, no need to warn
            this.idxChains{idx} = this.SS.sys.points.SubsetIdx(this.SS.sys.chains{idx}, warnDuplicates=false);
        end
    end

    % Set plot view orientation
    function Set_View(this, ax)
        arguments
            this(1,1)
            ax matlab.graphics.axis.Axes
        end
        fig = ancestor(ax, 'figure');

        % Set up vector, as used by the interactive orbit tool
        % Set current interactive (by mouse drag on plot) camera control mode to orbit
        cameratoolbar(fig, 'SetCoordSys',this.interactiveOrbitUp);
        cameratoolbar(fig, 'setmode','orbit')

        % Set current camera view
        view(ax, this.view_vector)
        camup(ax, this.view_upVector);
    end

    %**********************************************************************
    % Animation internal functions
    %***********************************
    % Repeat button
    function Callback_Repeat(this,source,event)
        fig = source.Parent;
        ax = get(fig,'CurrentAxes');
        this.Animate_Play(ax, 'play');
    end

    function out = AssignColours(this, fig)
        arguments
            this(1,1)
            fig matlab.ui.Figure
        end
        % Each type of component gets a colour, and the remaining colours are used by chains
        colours = this.colourPalette;
        out = struct;
        out.userCurves    = "#bbbbbb"; % Placeholder
        out.linearSprings = "#bbbbbb";
        out.linearDampers = "#bbbbbb";
        out.pointForces   = "#bbbbbb";
        if ~isempty(this.userCurves_x);         out.userCurves    = colours(1); colours(1)=[]; end
        if ~isempty(this.SS.sys.linearSprings); out.linearSprings = colours(1); colours(1)=[]; end
        if ~isempty(this.SS.sys.linearDampers); out.linearDampers = colours(1); colours(1)=[]; end
        if ~isempty(this.SS.sys.pointForces);   out.pointForces   = colours(1); colours(1)=[]; end
        % Chains - remaining colours
        out.chains = colours;
        % Markers - fixed colour
        out.markers = "#000000";
        if ~isMATLABReleaseOlderThan("R2025a") && theme(fig).BaseColorStyle=="dark"
            out.markers = "#FFFFFF";
        end
    end

    % Evaluate all symbolic expressions that need to be evaluated, then output as struct
    function out = EvaluateComponents(this, idxTimes)
        arguments
            this(1,1)
            idxTimes(:,1) uint64
        end
        % And now to make a mess in the name of performance
        %   Calling SS.EvaluateSymExpr_atTimeIdx() is really slow
        %   So I put all symExprs in 1 big array and call it only once
        %   Iterating over handles is fast, so the repetition is worth it to get a preallocated sym array
        linearSprings = this.SS.sys.linearSprings;
        linearDampers = this.SS.sys.linearDampers;
        pointForces   = this.SS.sys.pointForces;
        numS = length(linearSprings);
        numD = length(linearDampers);
        numPF = length(pointForces);

        % Get the number of symbolic 3vectors in each group of symbolic 3vectors
        % For components that support Connections(), this is the number of connections (1 group per component instance)
        % For point forces, there is one big group of all locations, and another of force values
        groupLengths = zeros(numS+numD+2,1);
        for idxS=1:numS; groupLengths(idxS)      = length(linearSprings(idxS).Connections); end
        for idxD=1:numD; groupLengths(numS+idxD) = length(linearDampers(idxD).Connections); end
        groupLengths(numS+idxD+1:numS+idxD+2) = numPF;

        % Concatenate the transformation matrices for all groups, (where exists)
        numPoints = sum(groupLengths(1:numS+numD+1));
        pointsT = CDS_T.Zeros(numPoints,1);
        idxG = 1;
        for idxS = 1:numS
            pointsT(idxG:idxG+groupLengths(idxS)-1) = linearSprings(idxS).Connections;
            idxG = idxG + groupLengths(idxS);
        end
        for idxD = 1:numD
            pointsT(idxG:idxG+groupLengths(numS+idxD)-1) = linearDampers(idxD).Connections;
            idxG = idxG + groupLengths(idxD);
        end
        pointsT(idxG:idxG+numPF-1) = pointForces.Point;

        % Concatenate the symbolic vectors for all groups
        % DIM: (which vector, xyz component)
        groupsXYZ_sym = zeros(sum(groupLengths), 3, 'sym');
        for idxG = 1:numPoints
            groupsXYZ_sym(idxG,:) = pointsT(idxG).P;
        end
        for idxF = 1:numPF
            idxG = idxG+1;
            groupsXYZ_sym(idxG,1) = pointForces(idxF).Fx;
            groupsXYZ_sym(idxG,2) = pointForces(idxF).Fy;
            groupsXYZ_sym(idxG,3) = pointForces(idxF).Fz;
        end

        % Evaluate
        % Dimensions output: [which vector, xyz vector component, time]
        groupsXYZ_allTimes3D = this.SS.EvaluateSymExpr_atTimeIdx(groupsXYZ_sym, idxTimes, nDimsIn=2);

        % Split according to groups
        % Dimensions output: {which group of vectors}[which vector, xyz vector component, time]
        groupsCell = mat2cell(groupsXYZ_allTimes3D, groupLengths);

        % Split groups according to component type
        out = struct;
        out.linearSpringConnections = groupsCell(1:numS);
        out.linearDamperConnections = groupsCell(numS+1:numS+numD);
        out.pointForceLocations     = groupsCell{numS+numD+1};
        out.pointForceValues        = groupsCell{numS+numD+2};

        % Calculation not including chains or masses
        % Calculation not including tip of force arrow, because the scale of the arrow is not set
        out.axLim = [...
            min(groupsXYZ_allTimes3D(1:numPoints,1,:),[],'all'), max(groupsXYZ_allTimes3D(1:numPoints,1,:),[],'all');...
            min(groupsXYZ_allTimes3D(1:numPoints,2,:),[],'all'), max(groupsXYZ_allTimes3D(1:numPoints,2,:),[],'all');...
            min(groupsXYZ_allTimes3D(1:numPoints,3,:),[],'all'), max(groupsXYZ_allTimes3D(1:numPoints,3,:),[],'all')];

    end

    function ax = Animate_Setup(this, mode, frameRate)
        arguments
            this(1,1)
            mode(1,1) string {mustBeMember(mode,["play","gif","video"])}
            frameRate(1,1) double
        end
        % Options
        % Applies to all
        paddingFactor = 0.2; % double, positive
        minAR = 0.4; % double in range [0,1]
        lineWidth = 2;
        % Applies to exports
        resolutionV_inches = 5; % double, positive
        resolutionH_inches = 5; % double, positive
        resolutionDPI = 100; % unit64
        resolutionAutoCrop = true; % logical

        % Cut frames that won't be rendered - restrict to frame rate
        idx_include = zeros(size(this.SS.t), "uint64");
        idx_include(1) = 1; % Use first frame
        idx_include(end) = numel(idx_include); % Use last frame
        dt_ideal = 1/frameRate;
        prevFrameTime=this.SS.t(1);
        for idx = 2 : length(this.SS.t)-1
            dt = this.SS.t(idx) - prevFrameTime;
            dt_next = this.SS.t(idx+1) - prevFrameTime;
            % If next frame passes, then choose the closest of the current and next frame (rounds down or up to closest)
            if (dt_next >= dt_ideal) && (abs(dt - dt_ideal) <= abs(dt_next - dt_ideal))
                idx_include(idx) = idx;
                prevFrameTime = this.SS.t(idx);
            end
        end
        idx_AnimateIncludeTimes = nonzeros(idx_include);

        % Check framerate
        frameDiff = diff(this.SS.t(idx_AnimateIncludeTimes));
        frameRate_worst = 1/max(frameDiff);
        idealFrameRate = ""+this.SS.t(1)+":"+dt_ideal+":"+this.SS.t(end);
        if frameRate_worst*2 < frameRate
            warning("Low Framerate. For ideal framerate, solve with CDS_Solver_Options.time="+idealFrameRate+" (simulated data), or use CDS_SolutionInterpolated(..., "+idealFrameRate+") (experimental data)")
        end

        % Evaluate symbolic expressions needed to draw the components
        componentValues = this.EvaluateComponents(idx_AnimateIncludeTimes);

        % Create figure
        if mode=="play"
            fig = figure;
        else
            % Don't display figure to user
            fig = figure('Visible','off');
        end
        ax = axes('Parent',fig, 'XGrid','on', 'YGrid','on', 'ZGrid','on');
        hold(ax, "on");

        % Each type of component gets a colour, and the remaining colours are used by chains
        colours = this.AssignColours(fig);
        ax.ColorOrder = hex2rgb(colours.chains);

        % Define lines by handle and draw/clear by handle
        numChains = length(this.SS.sys.chains);
        numUC = length(this.userCurves_x);
        numLS = length(this.SS.sys.linearSprings);
        numLD = length(this.SS.sys.linearDampers);
        line_chain_h = cell(numChains, 1);
        line_mass_h = animatedline(ax, 'LineStyle','none', 'Marker','*', 'MarkerSize',15, 'MarkerEdgeColor',colours.markers);
        line_user_h = cell(numUC, 1);
        line_LS_h = cell(numLS, 1);
        line_LD_h = cell(numLD, 1);
        line_PF_h = quiver3(ax, [],[],[], [],[],[], 'LineWidth',lineWidth, 'Color',colours.pointForces);
        for idx=1:numChains;
            line_chain_h{idx}=animatedline(ax, 'LineWidth',lineWidth, 'Color',colours.chains(1+mod(idx-1,length(colours.chains))));
        end
        for idx=1:numUC; line_user_h{idx}=animatedline(ax, 'LineWidth',lineWidth, 'Color',colours.userCurves); end
        for idx=1:numLS; line_LS_h{idx}  =animatedline(ax, 'LineWidth',1.5*lineWidth, 'LineStyle',':', 'Color',colours.linearSprings); end
        for idx=1:numLD; line_LD_h{idx}  =animatedline(ax, 'LineWidth',1.5*lineWidth, 'LineStyle',':', 'Color',colours.linearDampers); end

        % Set axis limits with padding
        % Clamp minimum aspect ratio
        axLim = [...
            min(this.SS.Px,[],'all'), max(this.SS.Px,[],'all');...
            min(this.SS.Py,[],'all'), max(this.SS.Py,[],'all');...
            min(this.SS.Pz,[],'all'), max(this.SS.Pz,[],'all')];
        if ~isempty(componentValues.axLim)
            axLim = [min(axLim(:,1), componentValues.axLim(:,1)), max(axLim(:,2), componentValues.axLim(:,2))];
        end
        axCenter = (axLim(:,2) + axLim(:,1)) / 2;
        axSpan = axLim(:,2) - axLim(:,1);
        clampMinSpan = max(axSpan) * minAR;
        axSpan(axSpan < clampMinSpan) = clampMinSpan; % Apply clamp
        axSpan = axSpan * (1 + paddingFactor); % Apply padding
        axLimPadded(:,1) = axCenter - 0.5*axSpan;
        axLimPadded(:,2) = axCenter + 0.5*axSpan;

        % Figure to plot on and line object definitions
        ax.XLim = axLimPadded(1,:);
        ax.YLim = axLimPadded(2,:);
        ax.ZLim = axLimPadded(3,:);
        %ax.Title.String = 'Animation';
        ax.XLabel.String = 'x (m)';
        ax.YLabel.String = 'y (m)';
        ax.ZLabel.String = 'z (m)';
        daspect(ax, [1, 1, 1]) % Force axis scale ratios 1:1:1
        this.Set_View(ax);

        % Set export style and canvas size
        resolutionHV_px = [];
        if mode=="gif" || mode=="video"
            ax.Title.Visible = "off";
            ax.XAxis.Visible = "off";
            ax.YAxis.Visible = "off";
            ax.ZAxis.Visible = "off";

            % If view is 3D or rolled, then crop resolution exactly fit plot box
            plotBoxAspectRatio_HV = [1,1];
            cameraViewVector = ax.CameraTarget - ax.CameraPosition;
            isPlotBoxRectangular2D = nnz(cameraViewVector)==1 && nnz(ax.CameraUpVector)==1;
            if resolutionAutoCrop && isPlotBoxRectangular2D
                plotBoxAxisV = ax.CameraUpVector~=0;
                plotBoxAxisH = ~cameraViewVector & ~plotBoxAxisV;
                plotBoxAspectRatio_HV = [ax.PlotBoxAspectRatio(plotBoxAxisH), ax.PlotBoxAspectRatio(plotBoxAxisV)];
                plotBoxAspectRatio_HV = plotBoxAspectRatio_HV / max(plotBoxAspectRatio_HV);
            end

            % Crop resolution and round to exact px size
            resolutionHV_px = round([resolutionH_inches,resolutionV_inches] .* plotBoxAspectRatio_HV * resolutionDPI);
            resolutionHV_inches = resolutionHV_px / resolutionDPI;

            % These settings effect the output size of print()
            fig.PaperUnits = "inches";
            fig.PaperSize = resolutionHV_inches;
            fig.PaperPosition = [0,0,resolutionHV_inches];
            ax.Position = [0,0,1,1];
        end

        % Store animated line handles with the axis data
        userData = struct;
        userData.idx_AnimateIncludeTimes = idx_AnimateIncludeTimes;
        userData.LS_connections = componentValues.linearSpringConnections;
        userData.LD_connections = componentValues.linearDamperConnections;
        userData.PF_locs = componentValues.pointForceLocations;
        userData.PF_vals = componentValues.pointForceValues;
        userData.line_chain_h = line_chain_h;
        userData.line_mass_h = line_mass_h;
        userData.line_user_h = line_user_h;
        userData.line_LS_h = line_LS_h;
        userData.line_LD_h = line_LD_h;
        userData.line_PF_h = line_PF_h;
        userData.resolutionHV_px = resolutionHV_px;
        userData.resolutionDPI = resolutionDPI;
        ax.UserData = userData;

        if mode=="play"
            % Method to pass data to a callback function
            % https://au.mathworks.com/help/matlab/creating_plots/callback-definition.html
            % https://au.mathworks.com/help/matlab/creating_guis/share-data-among-callbacks.html
            uicontrol(fig,...
                'Style', 'pushbutton',...
                'String', 'Repeat',...
                'Position', [20 20 50 20],...
                'Callback', @this.Callback_Repeat);
        end
    end

    function videoFrames = Animate_Play(this, ax, mode)
        arguments
            this(1,1)
            ax(1,1) matlab.graphics.axis.Axes
            mode(1,1) string {mustBeMember(mode,["play","gif","video"])}
        end
        fig = ancestor(ax, 'figure');

        % Get animated line handles from the axis data
        idx_AnimateIncludeTimes = ax.UserData.idx_AnimateIncludeTimes;
        LS_connections = ax.UserData.LS_connections;
        LD_connections = ax.UserData.LD_connections;
        PF_locs = ax.UserData.PF_locs;
        PF_vals = ax.UserData.PF_vals;
        line_chain_h = ax.UserData.line_chain_h;
        line_mass_h = ax.UserData.line_mass_h;
        line_user_h = ax.UserData.line_user_h;
        line_LS_h = ax.UserData.line_LS_h;
        line_LD_h = ax.UserData.line_LD_h;
        line_PF_h = ax.UserData.line_PF_h;
        resolutionHV_px = ax.UserData.resolutionHV_px;
        resolutionDPI = ax.UserData.resolutionDPI;

        if mode=="play"
            videoFrames = []; % Not used in this mode
            pause(0.1)
        else
            % Ensure preallocated array matches the output size of print()
            videoFrames = zeros(resolutionHV_px(2), resolutionHV_px(1), 3, length(idx_AnimateIncludeTimes), "uint8");
            dpiString = "-r"+string(resolutionDPI);
        end

        % Play / record animation
        prevFrameTime = this.SS.t(1);
        tic;
        for idxFrame = 1 : length(idx_AnimateIncludeTimes)
            % Draw frame
            idxTime = idx_AnimateIncludeTimes(idxFrame);
            frameTime = this.SS.t(idxTime);
            for idxChain = 1 : length(line_chain_h)
                clearpoints(line_chain_h{idxChain});
                addpoints(line_chain_h{idxChain},...
                    this.SS.Px(this.idxChains{idxChain},idxTime),...
                    this.SS.Py(this.idxChains{idxChain},idxTime),...
                    this.SS.Pz(this.idxChains{idxChain},idxTime));
            end
            clearpoints(line_mass_h);
            addpoints(line_mass_h,...
                this.SS.Px(this.idxMass,idxTime),...
                this.SS.Py(this.idxMass,idxTime),...
                this.SS.Pz(this.idxMass,idxTime));
            for idxCurve = 1 : length(line_user_h)
                clearpoints(line_user_h{idxCurve});
                addpoints(line_user_h{idxCurve},...
                    this.userCurves_x{idxCurve}(frameTime),...
                    this.userCurves_y{idxCurve}(frameTime),...
                    this.userCurves_z{idxCurve}(frameTime));
            end
            for idxSpring = 1:length(line_LS_h)
                % DIMS: {spring}(point,xyz,time)
                clearpoints(line_LS_h{idxSpring});
                addpoints(line_LS_h{idxSpring},...
                    LS_connections{idxSpring}(:,1,idxFrame),...
                    LS_connections{idxSpring}(:,2,idxFrame),...
                    LS_connections{idxSpring}(:,3,idxFrame))
            end
            for idxDamper = 1:length(line_LD_h)
                % DIMS: {damper}(point,xyz,time)
                clearpoints(line_LD_h{idxDamper});
                addpoints(line_LD_h{idxDamper},...
                    LD_connections{idxDamper}(:,1,idxFrame),...
                    LD_connections{idxDamper}(:,2,idxFrame),...
                    LD_connections{idxDamper}(:,3,idxFrame))
            end
            % DIMS: (point,xyz,time) and (force,xyz,time)
            arrowBase   = PF_locs(:,:,idxFrame); % Location
            arrowLength = PF_vals(:,:,idxFrame); % Force
            if ~isempty(arrowBase)
                line_PF_h.XData = arrowBase(:,1);
                line_PF_h.YData = arrowBase(:,2);
                line_PF_h.ZData = arrowBase(:,3);
                line_PF_h.UData = arrowLength(:,1);
                line_PF_h.VData = arrowLength(:,2);
                line_PF_h.WData = arrowLength(:,3);
            end

            % Paint frame
            if mode=="play"
                drawnow limitrate; % limits to 20fps
                executionTime = toc;
                pause(frameTime - prevFrameTime - executionTime); % draw at specified time rate
                prevFrameTime = frameTime;
                tic;
            else % gif or video
                % Get frame for video output
                videoFrames(:,:,:,idxFrame) = print(fig, "-RGBImage", "-image", dpiString);
            end
        end
    end

    function Animate_SaveGif(this, videoFrames, fileName, videoFrameRate)
        arguments
            this(1,1)
            videoFrames(:,:,3,:) uint8
            fileName(1,1) string
            videoFrameRate(1,1) double
        end
        FileHelper = CDS_Helper_StrOut();
        fileName = FileHelper.ValidateFileExtension(fileName, ".gif");
        fileName = FileHelper.MakePathToFile(fileName);

        % Properties of new file
        NumColours = 16; % Very literally
        delayLength = 1/videoFrameRate;

        % Write to new file
        for idx = 1 : size(videoFrames,4)
            % Get raw frame and convert to range [0,1]
            % Compress colours
            frame = double(videoFrames(:,:,:,idx)) / 255;
            [A,map] = rgb2ind(frame, NumColours, 'nodither');

            % Write to file
            if idx == 1
                imwrite(A,map, fileName,'gif', 'LoopCount',Inf, 'DelayTime',delayLength);
            else
                imwrite(A,map, fileName,'gif', 'WriteMode','append', 'DelayTime',delayLength);
            end
        end
    end

    function Animate_SaveVideo(this, videoFrames, fileName, videoFrameRate)
        arguments
            this(1,1)
            videoFrames(:,:,3,:) uint8
            fileName(1,1) string
            videoFrameRate(1,1) double
        end
        FileHelper = CDS_Helper_StrOut();
        fileName = FileHelper.ValidateFileExtension(fileName, ".mp4");
        fileName = FileHelper.MakePathToFile(fileName);
        video = VideoWriter(fileName, 'MPEG-4');
        video.FrameRate = videoFrameRate;

        % Write to new file
        video.open;
        video.writeVideo(videoFrames);
        video.close;
    end
end
end

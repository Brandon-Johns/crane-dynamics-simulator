%{
PURPOSE
    Plot the solution as a function of time

LIMITATIONS
    Partial support for solutions built with CDS_SolutionExp
    In cases of non-support: either no plot will be produced, or an error will be thrown
%}

classdef CDS_Solution_Plot < handle
properties (Access=private)
    SS(1,1) CDS_Solution
end
methods
    % INPUT
    %   The solution to plot
    function this = CDS_Solution_Plot(solution)
        arguments
            solution CDS_Solution
        end
        if isempty(solution)
            this = CDS_Solution_Plot.empty(size(solution));
            return;
        end
        if isscalar(solution)
            this.SS = solution;
            return;
        end
        for idx = 1:numel(solution)
            this(idx) = CDS_Solution_Plot(solution(idx));
        end
        this = reshape(this, size(solution));
    end

    % Plot an arbitrary input symbolic expression, as evaluated at the solution by CDS_Solution.EvaluateSymExpr_atTimeIdx()
    % INPUT
    %   symExprs: (symbolic expression) Expressions to evaluate
    %   idx_time: Time coordinates by index, according the time in this.t
    % INPUT (Name=Value)
    %   ax: Axes object to plot on
    %   legendStr: Legend entries for the additional expressions
    % SIDE EFFECTS
    %   Figure with plot of time vs symExprs
    function PlotSymExpr(this, symExprs, idx_time, options)
        arguments
            this(1,1)
            symExprs sym
            idx_time(:,1) uint64 = 1:length(this.SS.t)
            options.ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
            options.legendStr string = string.empty
        end
        values = this.SS.EvaluateSymExpr_atTimeIdx(symExprs(:), idx_time);

        ax = options.ax;
        if isempty(ax)
            fig=figure;
            ax=axes('Parent',fig);
        end
        numPreExistingPlots = numel(ax.Children);

        hold(ax, 'on')
        plot(ax, this.SS.t, values, 'LineWidth',2)

        if isempty(options.ax)
            xlabel(ax, 'Time (s)')
            box(ax, 'off');
            grid(ax, 'on');
        end

        if ~isempty(options.legendStr)
            legendStr = options.legendStr(:);
            if numel(legendStr) ~= numel(symExprs)
                if isscalar(legendStr)
                    legendStr = legendStr + " (" + string(1:numel(symExprs)).' + ")";
                else
                    error("Number of legend strings does not equal number of symbolic expressions provided")
                end
            end
            if numPreExistingPlots==0
                legend(ax, legendStr, 'Location','Best')
            elseif ~isempty(ax.Legend)
                legendStrMerged = string(ax.Legend.String);
                legendStrMerged((numPreExistingPlots+1):end) = legendStr;
                ax.Legend.String = legendStrMerged;
            else
                legendStrMerged = [strings(numPreExistingPlots,1); legendStr];
                legend(ax, legendStrMerged, 'Location','Best')
            end
        end
    end

    % INPUT
    %   Axes object to plot on
    % SIDE EFFECTS
    %   Figure with plot of time vs constraint equation violation
    function PlotConstraintViolation(this, ax)
        arguments
            this(1,1)
            ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
        end
        if isempty(this.SS.sys.constraints); fprintf("No constraints\n"); return; end

        % This can error for CDS_SolutionExp if sys.points.T_0n (set NaN for experimental points) are used to build constraints
        C = this.SS.sys.constraints.C;
        constraintError = this.SS.EvaluateSymExpr_atTimeIdx(C);

        if isempty(ax); fig=figure; ax=axes('Parent',fig); end
        hold(ax, 'on')
        plot(ax, this.SS.t, constraintError, 'LineWidth',2)
        title(ax, 'Error of Constraints from C=0')
        xlabel(ax, 'Time (s)')
        ylabel(ax, 'Error (units of constraint equation)')
        legend(ax, "Constraint "+string(1:length(C)), 'Location','Best')
        box(ax, 'off');
        grid(ax, 'on');
    end

    % INPUT
    %   Axes object to plot on
    % SIDE EFFECTS
    %   Figure with plot of total system energy vs time
    %   Plot is offset to start at 0
    function PlotEnergyTotal(this, ax)
        arguments
            this(1,1)
            ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
        end
        if isempty(this.SS.E)||all(isnan(this.SS.E),'all'); fprintf("Energy not calculated\n"); return; end

        % Offset to make energy component start at 0
        E = this.SS.E;
        E = E - E(1);

        if isempty(ax); fig=figure; ax=axes('Parent',fig); end
        hold(ax, 'on')
        plot(ax, this.SS.t, E.', 'LineWidth',2)
        title(ax, 'Total System Energy')
        xlabel(ax, 'Time (s)')
        ylabel(ax, 'Energy (J)')
        legend(ax, "Total System Energy", 'Location','Best')
        box(ax, 'off');
        grid(ax, 'on');
    end

    % INPUT
    %   Axes object to plot on
    % SIDE EFFECTS
    %   Figure with overlaid plots of each energy component and total system energy vs time
    %   Plots offset to start with 0 gravitational potential energy
    function PlotEnergyAll(this, ax)
        arguments
            this(1,1)
            ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
        end
        if isempty(this.SS.E)||all(isnan(this.SS.E),'all'); fprintf("Energy not calculated\n"); return; end

        % Offset to make potential energy components start at 0
        % Don't offset kinetic or spring energies because their zero-points have meaning
        % The plot for E will be offset from PlotEnergyTotal(), but whatever
        E = this.SS.E - sum(this.SS.V_mass(:,1));
        V_mass = this.SS.V_mass - this.SS.V_mass(:,1);

        if isempty(ax); fig=figure; ax=axes('Parent',fig); end
        hold(ax, 'on')
        plot(ax, this.SS.t, E.', 'LineWidth',2)
        plot(ax, this.SS.t, this.SS.K_mass.', 'LineWidth',2)
        for idx = 1:numel(this.SS.sys.points.GetIfHasMass)
            % Match colours to kinetic component
            plot(ax, this.SS.t, V_mass(idx,:), 'LineWidth',2, "LineStyle","-.", "Color",ax.Children(end-idx).Color);
        end
        if ~isempty(this.SS.sys.linearSprings);  plot(ax, this.SS.t, this.SS.V_linearSprings.', 'LineWidth',2, 'LineStyle','--'); end
        if ~isempty(this.SS.sys.torsionSprings); plot(ax, this.SS.t, this.SS.V_torsionSprings.', 'LineWidth',2, 'LineStyle',':'); end

        legend_string = ["Total System Energy";...
            strcat("Kinetic: Mass ",this.SS.sys.points.GetIfHasMass.Name);...
            strcat("Potential: Mass ",this.SS.sys.points.GetIfHasMass.Name);...
            strcat("Potential: Linear Spring ",this.SS.sys.linearSprings.Name);...
            strcat("Potential: Torsion Spring ",this.SS.sys.torsionSprings.Name);...
        ];
        title(ax, 'System Energy')
        xlabel(ax, 'Time (s)')
        ylabel(ax, 'Energy (J)')
        legend(ax, legend_string,'Location','Best')
        box(ax, 'off');
        grid(ax, 'on');
    end

    % INPUT
    %   Axes object to plot on
    % SIDE EFFECTS
    %   Figure with plot of time vs the difference between
    %       Rate of change of total system energy
    %       Rate of work done on system
    function PlotPowerError(this, ax)
        arguments
            this(1,1)
            ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
        end
        % This will error for most user built CDS_SolutionExp
        % because sys.points.GetIfHasMass.T_0n (set NaN for experimental points) is used to calculate the power
        CE = CDS_Calc_Energy(this.SS.sys);
        energyError = this.SS.EvaluateSymExpr_atTimeIdx(CE.dEdt - CE.dWdt);

        if isempty(ax); fig=figure; ax=axes('Parent',fig); end
        hold(ax, 'on')
        plot(ax, this.SS.t, energyError, 'LineWidth',2)
        title(ax, 'Error in Time-Rate of Change of Total System Energy from Time-Rate of Work')
        xlabel(ax, 'Time (s)')
        ylabel(ax, 'Power (W)')
        legend(ax, ["dEdt - dWdt"], 'Location','Best')
        box(ax, 'off');
        grid(ax, 'on');
    end

    % INPUT
    %   Axes object to plot on
    % SIDE EFFECTS
    %   Figure with
    %       Plot of rate of change of total system energy vs time
    %       Plot of rate of work done on system vs time
    function PlotPowerTotal(this, ax)
        arguments
            this(1,1)
            ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
        end
        % This will error for most user built CDS_SolutionExp
        % because sys.points.GetIfHasMass.T_0n (set NaN for experimental points) is used to calculate the power
        CE = CDS_Calc_Energy(this.SS.sys);
        data = this.SS.EvaluateSymExpr_atTimeIdx([CE.dEdt; CE.dWdt]);
        dEdt = data(1,:);
        dWdt = data(2,:);

        % If plots are overlapping, then plot dashed
        energyError = dEdt - dWdt;
        range_energyError = max(energyError) - min(energyError);
        lineStyle = '-';
        if range_energyError==0 || range_energyError < max([max(dEdt)-min(dEdt), max(dWdt)-min(dWdt)]) * 0.01
            lineStyle = '--';
        end

        if isempty(ax); fig=figure; ax=axes('Parent',fig); end
        hold(ax, 'on')
        plot(ax, this.SS.t, dEdt, 'LineWidth',2)
        plot(ax, this.SS.t, dWdt, 'LineWidth',2, "LineStyle",lineStyle)
        title(ax, 'Time-Rate of Change of Total System Energy')
        xlabel(ax, 'Time (s)')
        ylabel(ax, 'Power (W)')
        legend(ax, ["dEdt", "dWdt"], 'Location','Best')
        box(ax, 'off');
        grid(ax, 'on');
    end

    % TODO: add missing power components
    % INPUT
    %   Axes object to plot on
    % SIDE EFFECTS
    %   Figure with each component of power and work vs time
    function PlotPowerAll(this, ax)
        arguments
            this(1,1)
            ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
        end
        % This will error for most user built CDS_SolutionExp
        % because sys.points.GetIfHasMass.T_0n (set NaN for experimental points) is used to calculate the power
        expr = [...
            this.SS.sys.points.Power_dEdt;...
            this.SS.sys.linearSprings.Power_dEdt;...
            this.SS.sys.torsionSprings.Power_dEdt;...
            this.SS.sys.constraints.Power_dWdt;...
            this.SS.sys.points.Power_dWdt;...
            this.SS.sys.linearSprings.Power_dWdt;...
            this.SS.sys.torsionSprings.Power_dWdt;...
            this.SS.sys.linearDampers.Power_dWdt;...
            this.SS.sys.pointForces.Power_dWdt;...
            this.SS.sys.generalisedForces.Power_dWdt;...
        ];
        names = [...
            strcat("(dEdt) ",this.SS.sys.points.NameReadable);...
            strcat("(dEdt) ",this.SS.sys.linearSprings.NameReadable);...
            strcat("(dEdt) ",this.SS.sys.torsionSprings.NameReadable);...
            strcat("(dWdt) ",this.SS.sys.constraints.NameReadable);...
            strcat("(dWdt) ",this.SS.sys.points.NameReadable);...
            strcat("(dWdt) ",this.SS.sys.linearSprings.NameReadable);...
            strcat("(dWdt) ",this.SS.sys.torsionSprings.NameReadable);...
            strcat("(dWdt) ",this.SS.sys.linearDampers.NameReadable);...
            strcat("(dWdt) ",this.SS.sys.pointForces.NameReadable);...
            strcat("(dWdt) ",this.SS.sys.generalisedForces.NameReadable);...
        ];
        data = this.SS.EvaluateSymExpr_atTimeIdx(expr);

        if isempty(ax); fig=figure; ax=axes('Parent',fig); end
        hold(ax, 'on')
        plot(ax, this.SS.t, data.', 'LineWidth',2);
        title(ax, 'Time-Rate of Change of Total System Energy')
        xlabel(ax, 'Time (s)')
        ylabel(ax, 'Power (W)')
        legend(ax, names, 'Location','Best')
        box(ax, 'off');
        grid(ax, 'on');
    end

    % INPUT
    %   Axes object to plot on
    % SIDE EFFECTS
    %   Figure with overlaid plots of all free generalised coordinates vs time
    function PlotConfigSpace(this, ax)
        arguments
            this(1,1)
            ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
        end
        if isempty(this.SS.qf); fprintf("Config space not calculated\n"); return; end
        if isempty(ax); fig=figure; ax=axes('Parent',fig); end
        hold(ax, 'on')
        plot(ax, this.SS.t,this.SS.qf.', 'LineWidth',2)
        legend(ax, this.SS.sys.params.q_free.Str,'Location','Best')
        title(ax, 'Solution - Configuration Space')
        xlabel(ax, 'Time (s)')
        ylabel(ax, 'Generalised Coordinate (SI unit)')
        box(ax, 'off');
        grid(ax, 'on');
    end

    % INPUT
    %   Axes object to plot on
    % SIDE EFFECTS
    %   Figure with overlaid plots of all constraint state variables (lambda) vs time
    function PlotLambda(this, ax)
        arguments
            this(1,1)
            ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
        end
        if isempty(this.SS.ql); fprintf("No Lambda OR Lambda not calculated\n"); return; end
        if isempty(ax); fig=figure; ax=axes('Parent',fig); end
        hold(ax, 'on')
        plot(ax, this.SS.t,this.SS.ql.', 'LineWidth',2)
        legend(ax, this.SS.sys.params.lambda.Str,'Location','Best')
        title(ax, 'Solution - Configuration Space - Lambda')
        xlabel(ax, 'Time (s)')
        ylabel(ax, 'Generalised Coordinate Lambda (SI unit)')
        box(ax, 'off');
        grid(ax, 'on');
    end

    % INPUT
    %   Axes object to plot on
    % SIDE EFFECTS
    %   Figure with overlaid plots of all input generalised coordinates vs time
    function PlotInput(this, ax)
        arguments
            this(1,1)
            ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
        end
        if isempty(this.SS.sys.params.q_input); fprintf("No inputs\n"); return; end
        if isempty(ax); fig=figure; ax=axes('Parent',fig); end
        hold(ax, 'on')
        plot(ax, this.SS.t,this.SS.qi.', 'LineWidth',2)
        legend(ax, this.SS.sys.params.q_input.Str,'Location','Best')
        title(ax, 'Input')
        xlabel(ax, 'Time (s)')
        ylabel(ax, 'Input')
        box(ax, 'off');
        grid(ax, 'on');
    end

    % INPUT
    %   ax: Axes object to plot on
    % INPUT (Name=Value)
    %   dim
    %       "x": plot the x coordinate data
    %       "y": plot the y coordinate data
    %       "z": plot the z coordinate data
    %   points
    %       (string)    Name of the points to plot. Values matching CDS_Point.Name
    %       (CDS_Point) The points to plot
    % SIDE EFFECTS
    %   Figure with plot of coordinates in task space
    function PlotTaskSpace(this, ax, options)
        arguments
            this(1,1)
            ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
            options.dim(1,:) string {mustBeMember(options.dim, ["x", "y", "z"])} = ["x", "y", "z"]
            options.points (:,1) {mustBeA(options.points, ["string", "CDS_Point"])} = this.SS.sys.points.GetIfHasMass
        end
        dim = options.dim;
        points = options.points;

        % Get indices of points to plot
        % Then redefine input because of removing duplicates and not-found
        idxP = this.SS.sys.points.SubsetIdx(points, keepDuplicates=false);
        points = this.SS.sys.points(idxP);
        numP = length(idxP);

        if numP==0; fprintf("No points\n"); return; end

        % Automatically skip dimensions that are all zero for every point
        if ~any(this.SS.Px); dim(dim=="x")=[]; end
        if ~any(this.SS.Py); dim(dim=="y")=[]; end
        if ~any(this.SS.Pz); dim(dim=="z")=[]; end

        if isempty(ax); fig=figure; ax=axes('Parent',fig); end
        hold(ax, 'on')
        legend_string = strings(0);
        if any(dim=="x")
            legend_string(end+1 : end+numP) = strcat(points.NameReadable, "_x");
            plot(ax, this.SS.t, this.SS.Px(idxP,:).', 'LineWidth',2)
        end
        if any(dim=="y")
            legend_string(end+1 : end+numP) = strcat(points.NameReadable, "_y");
            plot(ax, this.SS.t, this.SS.Py(idxP,:).', 'LineWidth',2)
        end
        if any(dim=="z")
            legend_string(end+1 : end+numP) = strcat(points.NameReadable, "_z");
            plot(ax, this.SS.t, this.SS.Pz(idxP,:).', 'LineWidth',2)
        end

        title(ax, "Task Space Coordinates")
        legend(ax, legend_string,'Location','Best')
        xlabel(ax, 'Time (s)')
        ylabel(ax, 'Task Space Position (m)')
        box(ax, 'off');
        grid(ax, 'on');
    end

    % INPUT
    %   ax: Axes object to plot on
    % INPUT (Name=Value)
    %   dim
    %       "x": plot the x coordinate data
    %       "y": plot the y coordinate data
    %       "z": plot the z coordinate data
    % SIDE EFFECTS
    %   Figure with plot of coordinates in task space
    %   Variant that plots only the points with mass
    function PlotTaskSpace_Mass(this, ax, options)
        arguments
            this(1,1)
            ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
            options.dim(1,:) string = ["x", "y", "z"]
        end
        PlotTaskSpace(this, ax, dim=options.dim, points=this.SS.sys.points.GetIfHasMass);
        if isempty(ax); ax=gca; end
        title(ax, "Task Space Coordinates: Mass")
    end

    % INPUT
    %   ax: Axes object to plot on
    % INPUT (Name=Value)
    %   dim
    %       "x": plot the x coordinate data
    %       "y": plot the y coordinate data
    %       "z": plot the z coordinate data
    % SIDE EFFECTS
    %   Figure with plot of coordinates in task space
    %   Variant that plots all points
    function PlotTaskSpace_All(this, ax, options)
        arguments
            this(1,1)
            ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
            options.dim(1,:) string = ["x", "y", "z"]
        end
        PlotTaskSpace(this, ax, dim=options.dim, points=this.SS.sys.points);
        if isempty(ax); ax=gca; end
        title(ax, "Task Space Coordinates: All")
    end

    % INPUT
    %   Axes object to plot on
    % SIDE EFFECTS
    %   Figure with the generalised forces that act on the system vs time
    %   Plotted
    %       Generalised forces
    %       Equivalent forces from constraints, point forces, springs, dampers, etc.
    %       Equivalent forces from input generalised coordinates
    %   TODO: Not plotted
    %       Inertial forces (F=m*a, torque=I*alpha)
    %       Reaction forces
    function PlotForces(this, ax)
        arguments
            this(1,1)
            ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
        end
        % Could convert to optional input
        q = this.SS.sys.params.q;

        % This can error for CDS_SolutionExp if sys.points.T_0n (set NaN for experimental points) are used to build components
        namesBase = [...
            this.SS.sys.constraints.NameReadable;...
            this.SS.sys.linearSprings.NameReadable;...
            this.SS.sys.torsionSprings.NameReadable;...
            this.SS.sys.linearDampers.NameReadable;...
            this.SS.sys.pointForces.NameReadable;...
            this.SS.sys.generalisedForces.NameReadable;...
            "Input Generalised Coordinates"
        ];
        objects = [...
            num2cell(this.SS.sys.constraints);...
            num2cell(this.SS.sys.linearSprings);...
            num2cell(this.SS.sys.torsionSprings);...
            num2cell(this.SS.sys.linearDampers);...
            num2cell(this.SS.sys.pointForces);...
            num2cell(this.SS.sys.generalisedForces);...
            % Defer calculation of inverse dynamics
        ];
        expr = zeros([numel(namesBase), numel(q)], 'sym');
        for idx = 1:numel(objects)
            expr(idx,:) = objects{idx}.Q;
        end
        if ~isempty(this.SS.sys.params.q_input)
            Q_input_sym = CDS_Solver_GenerateEquations().InverseDynamics(this.SS.sys);

            % Q_input_sym corresponds to q_input only
            expr(end, length(this.SS.sys.params.q_free)+1:end) = Q_input_sym;
        end

        names = (q.NameReadable.') + " : " + namesBase;

        % Flatten arrays
        %names = names.'; %% Uncomment to switch legend ordering: row-major / column-major
        %expr = expr.';   %% Uncomment to switch legend ordering: row-major / column-major
        names = names(:);
        expr = expr(:);

        data = this.SS.EvaluateSymExpr_atTimeIdx(expr);

        % Remove expressions that equal 0
        idxRemove = ~any(data, 2);
        names = names(~idxRemove);
        data = data(~idxRemove, :);

        if isempty(data); fprintf("No non-zero forces to plot\n"); return; end
        if isempty(ax); fig=figure; ax=axes('Parent',fig); end
        hold(ax, 'on')
        plot(ax, this.SS.t, data.', 'LineWidth',2);
        title(ax, 'Equivalent Generalised Forces')
        xlabel(ax, 'Time (s)')
        ylabel(ax, 'Generalised Force (SI unit)')
        legend(ax, names, 'Location','Best')
        box(ax, 'off');
        grid(ax, 'on');
    end

    % INPUT
    %   Axes object to plot on
    % SIDE EFFECTS
    %   Figure with the lengths/angles of springs/dampers vs time
    %   Lengths of dampers are only included for instances where this was specified
    function PlotComponentLengths(this, ax)
        arguments
            this(1,1)
            ax matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
        end
        % This can error for CDS_SolutionExp if sys.points.T_0n (set NaN for experimental points) are used to build components
        names = [...
            this.SS.sys.linearSprings.NameReadable;...
            this.SS.sys.torsionSprings.NameReadable;...
            this.SS.sys.linearDampers.NameReadable;...
        ];
        expr = [...
            this.SS.sys.linearSprings.Length;...
            this.SS.sys.torsionSprings.Angle;...
            this.SS.sys.linearDampers.Length;...
        ];

        % Remove expressions where the length was not set
        idxRemove = isnan(expr);
        names = names(~idxRemove);
        expr = expr(~idxRemove);

        data = this.SS.EvaluateSymExpr_atTimeIdx(expr);

        if isempty(data); fprintf("No lengths to plot\n"); return; end
        if isempty(ax); fig=figure; ax=axes('Parent',fig); end
        hold(ax, 'on')
        plot(ax, this.SS.t, data.', 'LineWidth',2);
        title(ax, 'Springs and Dampers: Lengths and Angles')
        xlabel(ax, 'Time (s)')
        ylabel(ax, 'Length or Angle (SI unit)')
        legend(ax, names, 'Location','Best')
        box(ax, 'off');
        grid(ax, 'on');
    end
end
end

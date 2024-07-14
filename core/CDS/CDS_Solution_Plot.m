%{
PURPOSE
    Plot the solution as a function of time
%}

classdef CDS_Solution_Plot < handle
properties (Access=private)
    SS(1,1) CDS_Solution
end
methods
    % INPUT
    %   CDS_Solution
    function this = CDS_Solution_Plot(solution)
        % This results that: Input array -> output array of objects
        %   (instead of assigning the input array to the property of 1 output object)
        %   https://au.mathworks.com/help/matlab/matlab_oop/creating-object-arrays.html
        if nargin==0; return; end
        for idx = length(solution):-1:1
            this(idx).SS = solution(idx);
        end
    end
    
    % OUTPUT
    %   figure with plot of total system energy vs time
    function PlotEnergyTotal(this)
        arguments
            this(1,1)
        end
        this.PlotEnergy("E", "E")
    end
    
    % OUTPUT
    %   figure with overlaid plots of each energy component and total system energy vs time
    function PlotEnergyAll(this)
        arguments
            this(1,1)
        end
        this.PlotEnergy(["E","K","V"], "V")
    end
    
    % INPUT
    %   ax: (default = create new figure) Axes object to plot on
    % OUTPUT
    %   figure with overlaid plots of all state components vs time
    function PlotConfigSpace(this, ax)
        arguments
            this(1,1)
            ax(1,1) {mustBeA(ax, ["matlab.graphics.axis.Axes","string"])} = ""
        end
        % Exception for no q_free - Do not plot
        if isempty(this.SS.q_free); fprintf("Config space not calculated\n"); return; end

        % If not input axes, generate a new figure & ax object
        if isa(ax, "string"); fig=figure; ax=axes('Parent',fig); end

        plot(ax, this.SS.t,this.SS.qf.', 'LineWidth',2)
        legend(ax, this.SS.q_free.Str,'Location','Best')
        title(ax, 'Solution - Configuration Space')
        xlabel(ax, 'Time (s)')
        ylabel(ax, 'Generalised Coordinate (SI unit)')
        box(ax, 'off');
        grid(ax, 'on');
    end
    
    % INPUT
    %   ax: (default = create new figure) Axes object to plot on
    % OUTPUT
    %   figure with overlaid plots of all constraint lambda vs time
    function PlotLambda(this, ax)
        arguments
            this(1,1)
            ax(1,1) {mustBeA(ax, ["matlab.graphics.axis.Axes","string"])} = ""
        end
        % Exception for no q_free - Do not plot
        if isempty(this.SS.q_lambda); fprintf("No Lambda\n"); return; end

        % If not input axes, generate a new figure & ax object
        if isa(ax, "string"); fig=figure; ax=axes('Parent',fig); end

        plot(ax, this.SS.t,this.SS.ql.', 'LineWidth',2)
        legend(ax, this.SS.q_lambda.Str,'Location','Best')
        title(ax, 'Solution - Configuration Space - Lambda')
        xlabel(ax, 'Time (s)')
        ylabel(ax, 'Generalised Coordinate Lambda (SI unit)')
        box(ax, 'off');
        grid(ax, 'on');
    end
    
    % OUTPUT
    %   figure with overlaid plots of all inputs vs time
    function PlotInput(this)
        arguments
            this(1,1)
        end
        % Exception for no inputs - Do not plot
        if isempty(this.SS.q_input); fprintf("No inputs\n"); return; end
        
        figure;
        plot(this.SS.t,this.SS.qi.', 'LineWidth',2)
        legend(this.SS.q_input.Str,'Location','Best')
        title('Input')
        xlabel('Time (s)')
        ylabel('Input')
        box off;
        grid on;
    end
    
    % INPUT
    %   dim: axis of coordinates to plot (e.g. "x" = plot x coordinates)
    %   points
    %       (string): Array of the values matching the output of CDS_Point.NameShort
    %       (CDS_Point): Array of CDS_Point
    %   titleString: plot title to display
    % OUTPUT
    %   figure with plot of coordinates in task space
    function PlotTaskSpace(this, dim, points, titleString)
        arguments
            this(1,1)
            dim(1,:) string {mustBeMember(dim, ["x", "y", "z"])} = ["x", "y", "z"]
            points (:,1) {mustBeA(points, ["string", "CDS_Point"])} = this.SS.p_mass
            titleString(1,1) string = ""
        end
        % Get indices of points to plot
        idxP = this.SS.p_all.PointIdx(points, "RemoveDuplicates");

        % Reinterpret because of "RemoveDuplicates" and remove not found
        points = this.SS.p_all(idxP);
        numP = length(idxP);
        
        % Plot
        figure;
        hold on
        legend_string = strings(0);
        if any(dim=="x")
            legend_string(end+1 : end+numP) = strcat(points.NameReadable, "_x");
            plot(this.SS.t, this.SS.Px(idxP,:).', 'LineWidth',2)
        end
        if any(dim=="y")
            legend_string(end+1 : end+numP) = strcat(points.NameReadable, "_y");
            plot(this.SS.t, this.SS.Py(idxP,:).', 'LineWidth',2)
        end
        if any(dim=="z")
            legend_string(end+1 : end+numP) = strcat(points.NameReadable, "_z");
            plot(this.SS.t, this.SS.Pz(idxP,:).', 'LineWidth',2)
        end
        
        title(titleString)
        legend(legend_string)
        xlabel('time (s)')
        ylabel('Task Space Position (m)')
        box off;
        grid on;
        hold off
    end
    
    % OUTPUT
    %   figure with plot of coordinates in task space
    %   variant that plots only the points with mass
    function PlotTaskSpace_Mass(this, dim, titleString)
        arguments
            this(1,1)
            dim(1,:) string = ["x", "y", "z"]
            titleString(1,1) string = "Task Space Coordinates: Mass"
        end
        PlotTaskSpace(this, dim, this.SS.p_mass, titleString);
    end
    
    % OUTPUT
    %   figure with plot of coordinates in task space
    %   variant that plots all points
    function PlotTaskSpace_All(this, dim, titleString)
        arguments
            this(1,1)
            dim(1,:) string = ["x", "y", "z"]
            titleString(1,1) string = "Task Space Coordinates: All"
        end
        PlotTaskSpace(this, dim, this.SS.p_all, titleString);
    end
end
methods (Access=private)
    function PlotEnergy(this, components, offsetComponents)
        arguments
            this(1,1)
            components(:,1) string
            offsetComponents(1,1) string = "0" % Default no offset
        end
        % Exception for energy not calculated (e.g. experimental input) - Do not plot
        if isempty(this.SS.E); fprintf("Energy not calculated\n"); return; end
        
        V = this.SS.V;
        K = this.SS.K;
        E = this.SS.E;
        
        % Offset to make energy component start at 0
        if offsetComponents=="E" || offsetComponents=="V"
            E = E - sum(V(:,1));
            V = V - V(:,1);
        end
        if offsetComponents=="E" || offsetComponents=="K"
            E = E - sum(K(:,1));
            K = K - K(:,1);
        end
        
        % Legend
        head_E = "Total";
        head_V = strcat("Potential_",this.SS.p_mass.NameShort);
        head_K = strcat("Kinetic_",this.SS.p_mass.NameShort);
        
        figure;
        hold on
        legend_string = strings(0);
        if any(components=="E")
            legend_string(end+1) = head_E;
            plot(this.SS.t, E.', 'LineWidth',2)
        end
        if any(components=="K")
            legend_string(end+1 : end+length(head_K)) = head_K;
            plot(this.SS.t, K.', 'LineWidth',2)
        end
        if any(components=="V")
            legend_string(end+1 : end+length(head_V)) = head_V;
            plot(this.SS.t, V.', 'LineWidth',2)
        end
        
        hold off
        title('System Energy')
        xlabel('Time (s)')
        ylabel('Energy (J)')
        legend(legend_string)
        box off;
        grid on;
    end
end
end

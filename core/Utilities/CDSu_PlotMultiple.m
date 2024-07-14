%{
PURPOSE
    Miscellaneous plot helpers

ASSUMES
    All use same time vector
%}

classdef CDSu_PlotMultiple < handle
properties
    % Line spec - These arrays must be longer than the number of overlapping plots
    %lineStyle = ["-","-","-",":",":",":",":",":",":",":",":",":",":",":",":",":",":",":",":",":"]
    lineStyle(1,:) string = ["-","-","-","-","-","-","-","-","-","-","-","-","-","-","-","-","-","-","-","-"]
    lineColour(1,1) string = "auto"
    lineWidth(1,1) double = 0.8
    FontName(1,1) string = "Times New Roman"
    FontSizeAll(1,1) double = 12
end
methods
    function this = CDSu_PlotMultiple()
    end
    
    % NOTES:
    %   A lagging plot occurs after the baseline => it is to far right on the time plot
    % INPUT:
    %   LagIdx =
    %       Offsets, specified by index, not time
    %       Position corresponds to the lag of each member of P (negative lag = lead)
    function P = RemoveLag(this, P, LagIdx)
        arguments
            this(1,1)
            P(:,:) {mustBeA(P,["cell","double"])} % single-input double | multi-input = cell
            LagIdx(1,:) int64
        end
        inType=class(P);
        if inType=="double"; P={P}; end
        mustBeVector(P);
        
        for idx=1:length(P)
            lagIdx = LagIdx(idx);
            if 0 < lagIdx
                % Remove Lag
                %   Pop & append elements
                P{idx}(:, 1:lagIdx) = [];
                P{idx}(:, end+1:end+lagIdx) = nan;
            elseif lagIdx < 0
                % Remove Lead
                %   Prepend & pop elements
                P{idx} = [nan(size(P{1},1), abs(lagIdx)), P{idx}(:, 1:end-abs(lagIdx))];
            end
        end

        % Output in same form as input
        if inType=="double"; P=P{1}; end
    end
    
    function P = OffsetDataToZero(this, P, ax)
        arguments
            this(1,1)
            P(:,:) {mustBeA(P,["cell","double"])} % single-input double | multi-input = cell
            ax(1,:) char {mustBeMember(ax, ['x','z','y',])} = 'xyz'
        end
        inType=class(P);
        if inType=="double"; P={P}; end
        mustBeVector(P);
        
        % Operate only on specified axes
        idxAx = [any(ax=='x'); any(ax=='y'); any(ax=='z')];

        % Subtract column@t=0 from all columns
        for idx=1:length(P)
            idxFirstRow = find( any(isfinite(P{idx}(idxAx,:))), 1);
            P{idx}(idxAx,:) = P{idx}(idxAx,:) - P{idx}(idxAx,idxFirstRow);
        end

        % Output in same form as input
        if inType=="double"; P=P{1}; end
    end

    function fig = PlotPath_OnPlane(this, P, plane)
        arguments
            this(1,1)
            P(:,:) {mustBeA(P,["cell","double"])} % single-input double | multi-input = cell
            plane(1,1) string {mustBeMember(plane,["x","y","z"])} = "z"
        end
        if isa(P,"double"); P={P}; end
        mustBeVector(P);
        
        % Choose plane
        if     plane=="x"; idxX=2; idxY=3;
        elseif plane=="y"; idxX=1; idxY=3;
        elseif plane=="z"; idxX=1; idxY=2;
        end
        
        fig=figure;
        ax=axes('Parent',fig);
        hold(ax, 'on')
        for idx=1:length(P)
            plot(P{idx}(idxX,:),P{idx}(idxY,:));
        end
        hold(ax, 'off')
    end
    
    % Plot specific axes
    function fig = PlotXYZ(this, varargin); fig = PlotXYZ_Choose(this, 'xyz', varargin{:}); end
    function fig = PlotXY(this, varargin); fig = PlotXYZ_Choose(this, 'xy', varargin{:}); end
    function fig = PlotX(this, varargin); fig = PlotXYZ_Choose(this, 'xy', varargin{:}); end
    function fig = PlotY(this, varargin); fig = PlotXYZ_Choose(this, 'xy', varargin{:}); end
    function fig = PlotZ(this, varargin); fig = PlotXYZ_Choose(this, 'xy', varargin{:}); end

    function fig = PlotXYZ_Choose(this, axToPlot, t,P, legendStr, fileNameOut,export)
        arguments
            this(1,1)
            axToPlot(1,:) char {mustBeNonempty, mustBeMember(axToPlot,'xyz')}
            t(1,:) double
            P(:,:) {mustBeA(P,["cell","double"])} % single-input double | multi-input = cell
            legendStr(:,1) string
            fileNameOut(1,1) string = "tmp"
            export(1,1) string = ""
        end
        if isa(P,"double"); P={P}; end
        mustBeVector(P);
        if length(P)~=length(legendStr); error("Mismatching inputs"); end
        if length(axToPlot)~=length(unique(axToPlot)); error("Requesting multiple copies of same axes"); end
        numPlots = length(axToPlot);

        LS = this.lineStyle;
        LC = this.LineColours(length(P));
        LW = this.lineWidth;
        fig=figure;
        TL = tiledlayout(fig, numPlots,1, 'TileSpacing','compact');
        for idx=1:numPlots; ax(idx)=nexttile(TL,idx); end
        axX = ax(axToPlot=='x');
        axY = ax(axToPlot=='y');
        axZ = ax(axToPlot=='z');
        
        hold(ax, 'on')
        for idx = 1:length(P)
            if ~isempty(axX); plot(axX, t, P{idx}(1,:), 'LineWidth',LW, "Color",LC(idx), "LineStyle",LS(idx)); end
            if ~isempty(axY); plot(axY, t, P{idx}(2,:), 'LineWidth',LW, "Color",LC(idx), "LineStyle",LS(idx)); end
            if ~isempty(axZ); plot(axZ, t, P{idx}(3,:), 'LineWidth',LW, "Color",LC(idx), "LineStyle",LS(idx)); end
        end
        hold(ax, 'off')
        xlabel(ax(end), 'time (s)')
        if ~isempty(axX); ylabel(axX, 'x (m)'); end
        if ~isempty(axY); ylabel(axY, 'y (m)'); end
        if ~isempty(axZ); ylabel(axZ, 'z (m)'); end
        lgd = legend(ax(1), legendStr, 'NumColumns',min(4, length(legendStr)));
        lgd.Layout.Tile = 'north';
        lgd.FontName = this.FontName;
        lgd.FontSize = this.FontSizeAll;
        xlim(ax, [min([ax.XLim]), max([ax.XLim])])
        if numPlots>1
            xticklabels(ax(1:end-1), {});
            xticks(ax(1:end-1), ax(end).XTick);
        end
        for idx=1:length(ax)
            ax(idx).FontName = this.FontName;
            ax(idx).FontSize = this.FontSizeAll;
            ax(idx).XLabel.FontSize = this.FontSizeAll;
            ax(idx).YLabel.FontSize = this.FontSizeAll;
            ax(idx).Title.FontSize  = this.FontSizeAll;
        end
        box(ax,'off');
        grid(ax,'on');
        % Save figure
        this.exportFig(fig, fileNameOut, export);
    end

    function fig = PlotXYZ_KM(this, t, PK,PM, legendStr,fileNameOut,export)
        arguments
            this(1,1)
            t(1,:) double
            PK(:,:) {mustBeA(PK,["cell","double"])} % single-input double | multi-input = cell
            PM(:,:) {mustBeA(PM,["cell","double"])} % single-input double | multi-input = cell
            legendStr(:,1) string
            fileNameOut(1,1) string = "tmp"
            export(1,1) string = ""
        end
        if isa(PK,"double"); PK={PK}; end
        if isa(PM,"double"); PM={PM}; end
        mustBeVector(PK);
        mustBeVector(PM);
        if length(PK)~=length(PM); error("Mismatching inputs: Points K to Points M"); end
        if length(PK)~=length(legendStr); error("Mismatching inputs: Legend string"); end
        
        LS = this.lineStyle;
        LC = this.LineColours(length(PK));
        LW = this.lineWidth;
        fig=figure;
        TL = tiledlayout(fig, 3,2, 'TileSpacing','compact');
        axK(1)=nexttile(TL,1);
        axK(2)=nexttile(TL,3);
        axK(3)=nexttile(TL,5);
        axM(1)=nexttile(TL,2);
        axM(2)=nexttile(TL,4);
        axM(3)=nexttile(TL,6);
        axAll = [axK,axM];
        hold([axK,axM], 'on')
        for idx = 1:length(PK)
            plot(axK(1), t, PK{idx}(1,:), 'LineWidth',LW, "Color",LC(idx), "LineStyle",LS(idx))
            plot(axK(2), t, PK{idx}(2,:), 'LineWidth',LW, "Color",LC(idx), "LineStyle",LS(idx))
            plot(axK(3), t, PK{idx}(3,:), 'LineWidth',LW, "Color",LC(idx), "LineStyle",LS(idx))
            plot(axM(1), t, PM{idx}(1,:), 'LineWidth',LW, "Color",LC(idx), "LineStyle",LS(idx))
            plot(axM(2), t, PM{idx}(2,:), 'LineWidth',LW, "Color",LC(idx), "LineStyle",LS(idx))
            plot(axM(3), t, PM{idx}(3,:), 'LineWidth',LW, "Color",LC(idx), "LineStyle",LS(idx))
        end
        hold([axK,axM], 'off')
        title(axK(1), "point K")
        title(axM(1), "point M")
        xlabel([axK(3),axM(3)], 'time (s)')
        ylabel(axK(1), 'x (m)')
        ylabel(axK(2), 'y (m)')
        ylabel(axK(3), 'z (m)')
        lgd = legend(axK(1), legendStr, 'NumColumns',min(4, length(legendStr)));
        lgd.Layout.Tile = 'north';
        lgd.FontName = this.FontName;
        lgd.FontSize = this.FontSizeAll;
        xticklabels([axK(1:2),axM(1:2)], {})
        xlim(axK, [min([axK.XLim]), max([axK.XLim])])
        xlim(axM, [min([axK.XLim]), max([axM.XLim])])
        xticks(axK(1:2), axK(3).XTick)
        xticks(axM(1:2), axM(3).XTick)
        for idx=1:length(axAll)
            axAll(idx).FontName = this.FontName;
            axAll(idx).FontSize = this.FontSizeAll;
            axAll(idx).XLabel.FontSize = this.FontSizeAll;
            axAll(idx).YLabel.FontSize = this.FontSizeAll;
            axAll(idx).Title.FontSize  = this.FontSizeAll;
        end
        box(axAll,'off');
        grid(axAll,'on');
        % Save figure
        this.exportFig(fig, fileNameOut, export);
    end
    
    function exportFig(this, fig, fileName, fileType)
        arguments
            this(1,1)
            fig(1,1) matlab.ui.Figure
            fileName(1,1) string = "tmp"
            fileType(1,1) string {mustBeMember(fileType,["","png","eps","pdf","svg"])} = ""
        end
        if fileType==""; return; end
        
        FH = CDS_Helper_StrOut();
        fileName = FH.ValidateFileExtension(fileName,fileType);
        fileName = FH.MakePathToFile(fileName);
        if     fileType=="png"; exportgraphics(fig, fileName, 'BackgroundColor','white', 'Resolution',600);
        elseif fileType=="eps"; exportgraphics(fig, fileName, 'BackgroundColor','none', 'ContentType','vector');
        elseif fileType=="pdf"; exportgraphics(fig, fileName, 'BackgroundColor','white', 'ContentType','vector');
        elseif fileType=="svg"
            % Options to force printing as a vector,
            % Otherwise, past a particular number of plotted points, matlab puts a png inside vector container instead...
            % Without any warnings :/
            % Note that in forcing this, the files can get quite big
            try
                print(fig, fileName, '-vector','-dsvg');
            catch
                print(fig, fileName, '-painters','-dsvg'); % Before 2021b
            end
        end
    end

    function lineColours = LineColours(this, numberOfLines)
        arguments
            this
            numberOfLines(1,1) uint64 = inf
        end
        % Check user override
        if this.lineColour~="auto"; lineColours=this.lineColour; return; end
        
        % Aims to choose colour blind friendly colours
        % Source: https://personal.sron.nl/~pault/#sec:qualitative
        switch numberOfLines
        case {1,2,3,4}
            % Colour blind safe (including greyscale safe)
            lineColours = ["#004488","#bb5566","#ddaa33","#000000"];
        case {5,6,7}
            % Colour blind safe (except greyscale)
            lineColours = ["#ee6677","#4477aa","#228833","#aa3377","#ccbb44","#66ccee","#bbbbbb"];
        otherwise
            % Not Colour blind safe
            lineColours = ["#D95319", "#000000", "#0072BD", "#77AC30",...
                "#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#00FFFF", "#FF00FF",...
                "#FF8800", "#00FF88", "#FF0088", "#88FF00", "#0088FF", "#8800FF"];
        end

        lineColours = lineColours(1:numberOfLines);
    end
end
end
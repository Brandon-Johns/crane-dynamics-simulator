%{
PURPOSE
    Plot the solution as a picture of the configuration in 3D space

NOTES
    The drawn lines join the points in CDS_Solution.chains
    On the drawings, * is used to represent a point with mass
%}

classdef CDS_Solution_Animate < handle
properties (Access=private)
    SS(1,1) CDS_Solution
    
    view_vector(1,3) double = [0,0,1]
    view_upVector(1,3) double = [0,1,0]
    
    idx_AnimateIncludeTimes(1,:) double
end
methods
    % INPUT
    %   CDS_Solution
    function this = CDS_Solution_Animate(solution)
        % This results that: Input array -> output array of objects
        %   (instead of assigning the input array to the property of 1 output object)
        %   https://au.mathworks.com/help/matlab/matlab_oop/creating-object-arrays.html
        if nargin==0; return; end
        for idx = length(solution):-1:1
            this(idx).SS = solution(idx);
        end
    end
    
    % Select a predefined plot view orientation
    % Intended for y-up coordinate systems
    % INPUT
    %   view_name = "top" | "side" | "front" | "3D-1" | "3D-2"
    function Set_View_Predefined(this, view_name)
        arguments
            this(1,1)
            view_name(1,1) string = "front"
        end
        
        if strcmp(view_name, 'top')
            this.view_vector = [0,1,0];
            this.view_upVector = [0,0,1];
        elseif strcmp(view_name, 'side')
            this.view_vector = [1,0,0];
            this.view_upVector = [0,1,0];
        elseif strcmp(view_name, '3D-1')
            this.view_vector = [1,0.5,1];
            this.view_upVector = [0,1,0];
        elseif strcmp(view_name, '3D-2')
            this.view_vector = [1,0.5,-1];
            this.view_upVector = [0,1,0];
        else % 'front', or bad input => set to 'front'
            this.view_vector = [0,0,1];
            this.view_upVector = [0,1,0];
        end
    end

    % Draw the system at given moments in time
    %   Uses nearest-neighbour interpolation
    % INPUT
    %   time: Solution times at which to draw the system
    %   aspectRatioMode
    %       "data": (default) Force axis scale ratios 1:1:1
    %       "": Use matlab default axis scale
    %   axes_h: (default = create new figure) handle to axes to plot on
    function PlotFrame(this, frameTimes, aspectRatioMode, axes_h)
        arguments
            this(1,1)
            frameTimes(:,1) double = 0
            aspectRatioMode(1,1) string = "data"
            axes_h(1,1) {mustBeA(axes_h, ["matlab.graphics.axis.Axes","string"])} = ""
        end
        % If not input axes, generate a new figure & ax object
        if isa(axes_h, "string"); fig=figure; axes_h=axes('Parent',fig); end
        isHoldOnAtStart = ishold(axes_h);
        hold(axes_h, 'on')

        % Find closest frames to specified times
        idx_times = dsearchn(this.SS.t.', frameTimes(:));
        
        % Loop over all times to plot at
        for idx_time = idx_times(:).'
            % Plot frame
            coords_chains = this.Draw(this.SS.chains, idx_time);
            coords_mass = this.Draw({this.SS.p_mass}, idx_time);
            
            % Draw frame
            for idxChain = 1:length(coords_chains)
                plot3(...
                    coords_chains{idxChain}(:,1),...
                    coords_chains{idxChain}(:,2),...
                    coords_chains{idxChain}(:,3),...
                    'LineWidth',2);
            end
            plot3(...
                coords_mass{1}(:,1),...
                coords_mass{1}(:,2),...
                coords_mass{1}(:,3),...
                'LineStyle','none',...
                'Marker','*',...
                'MarkerSize',15,...
                'MarkerEdgeColor','black');
        end
        if ~isHoldOnAtStart; hold(axes_h, 'off'); end
        
        title("Configuration at time =" + strjoin(compose(" %g",this.SS.t(idx_times))," and") + " (s)")
        xlabel('x (m)')
        ylabel('y (m)')
        zlabel('z (m)')
        box off;
        grid on;
        if strcmp(aspectRatioMode,"data")
            daspect([1, 1, 1]) % Force axis scale ratios 1:1:1
        end
        this.Set_View(axes_h);
    end
    
    % Animate drawing the system at realtime speed
    % INPUT
    %   mode
    %       "play":  Create a figure and animate
    %       "gif":   Write to gif
    %       "video": Write to mp4
    %   fileName: Filepath to output the gif/video (with the filename, but without the file extension)
    function Animate(this, mode, fileName)
        arguments
            this(1,1)
            mode(1,:) char {mustBeMember(mode,["play","gif","video"])} = "play"
            fileName(1,:) char = 'tmp'
        end
        
        if strcmp(mode, 'play')
            this.Animate_Setup(mode, 20);
            
        elseif strcmp(mode, 'gif')
            options.videoFrameRate = 10;
            fig_handle = this.Animate_Setup(mode, options.videoFrameRate);
            
            % Record
            videoFrames = this.Animate_Play(fig_handle, mode, options);
            % Save
            this.Animate_SaveGif(videoFrames, fileName, options);
            
        elseif strcmp(mode, 'video')
            options.videoFrameRate = 20;
            fig_handle = this.Animate_Setup(mode, options.videoFrameRate);
            
            % Record
            videoFrames = this.Animate_Play(fig_handle, mode, options);
            % Save
            this.Animate_SaveVideo(videoFrames, fileName, options);
        else
            warning('Bad input - Animate()')
        end
    end
    
end
methods (Access=private)
    function [P_chains_num] = Draw(this, P_chains, idx_time)
        P_chains_num = cell(size(P_chains));
        for idx_chain = 1:length(P_chains_num)
            points = P_chains{idx_chain};
            
            % Get ordered indices of points to plot
            idxP = zeros(size(points));
            for idxP_in = 1:length(points)
                idxP(idxP_in) = find(this.SS.p_all==points(idxP_in));
            end
            
            % Get ordered points
            P_chains_num{idx_chain} = [...
                this.SS.Px(idxP,idx_time),...
                this.SS.Py(idxP,idx_time),...
                this.SS.Pz(idxP,idx_time)];
        end
    end
    
    % Set plot view orientation
    function Set_View(this, axes_handle)
        arguments
            this(1,1)
            axes_handle
        end
        
        view(axes_handle, this.view_vector)
        camup(axes_handle, this.view_upVector);
    end
    
    %**********************************************************************
    % Animation internal functions
    %***********************************
    % Repeat button
    function Callback_Repeat(this,source,event)
        this.Animate_Play(source.Parent, 'play');
    end
    
    function fig_h = Animate_Setup(this, mode, frameRate)
        arguments
            this(1,1)
            mode(1,1) string
            frameRate(1,1) double = 20
        end
        
        % Cut frames that won't be rendered - restrict to frame rate
        idx_include = zeros(size(this.SS.t));
        idx_include(1) = 1; % Use first frame
        idx_include(end) = 1; % Use last frame
        prevFrameTime=this.SS.t(1);
        for idx = 2 : length(this.SS.t)-1
            if this.SS.t(idx) - prevFrameTime >= 1/frameRate
                idx_include(idx) = idx;
                prevFrameTime = this.SS.t(idx);
            end
        end
        this.idx_AnimateIncludeTimes = nonzeros(idx_include);
        
        % Create figure
        if strcmp(mode,"play")
            fig_h = figure;
        else
            % Don't display figure to user
            fig_h = figure('Visible','off');
        end
        
        % Set axis limits with 20% padding
        axLim = [...
            min(this.SS.Px,[],'all'), max(this.SS.Px,[],'all');...
            min(this.SS.Py,[],'all'), max(this.SS.Py,[],'all');...
            min(this.SS.Pz,[],'all'), max(this.SS.Pz,[],'all')];
        axSpan = axLim(:,2) - axLim(:,1);
        axLimPadded(:,1) = axLim(:,1) - 0.2*axSpan;
        axLimPadded(:,2) = axLim(:,2) + 0.2*axSpan;
        
        % Figure to plot on and line object definitions
        axes_h = axes('Parent',fig_h, 'XGrid','on', 'YGrid','on', 'ZGrid','on');
        if axSpan(1)~=0; axes_h.XLim = axLimPadded(1,:); end
        if axSpan(2)~=0; axes_h.YLim = axLimPadded(2,:); end
        if axSpan(3)~=0; axes_h.ZLim = axLimPadded(3,:); end
        %axes_h.Title.String = 'Animation';
        axes_h.XLabel.String = 'x (m)';
        axes_h.YLabel.String = 'y (m)';
        axes_h.ZLabel.String = 'z (m)';
        daspect(axes_h, [1, 1, 1]) % Force axis scale ratios 1:1:1
        this.Set_View(axes_h);
        
        % Define lines by handle and draw/clear by handle
        numChains = length(this.SS.chains);
        line_h = cell(numChains + 1, 1);
        for idxChain = 1:numChains
            line_h{idxChain} = animatedline(axes_h);
        end
        line_h{end} = animatedline(axes_h, 'LineStyle','none', 'Marker','*', 'MarkerSize',15);
        
        axes_h.UserData = line_h;
        
        if strcmp(mode,"play")
            % Method to pass data to a callback function
            % https://au.mathworks.com/help/matlab/creating_plots/callback-definition.html
            % https://au.mathworks.com/help/matlab/creating_guis/share-data-among-callbacks.html
            uicontrol('Style', 'pushbutton',...
                'String', 'Repeat',...
                'Position', [20 20 50 20],...
                'Callback', @this.Callback_Repeat);
        end
    end
    
    function videoFrames = Animate_Play(this, fig_handle, mode, options)
        % Initialise
        axes_h = get(fig_handle,'CurrentAxes');
        line_h = axes_h.UserData;
        
        if strcmp(mode,'play')
            videoFrames = nan; % Not used in this mode
            pause(0.1)
            tic;
        else % gif or video
            videoFrameRate = options.videoFrameRate;
            lastFrameTime = -inf;
            video_time = 0;
            idx_frame = 0;
        end
        
        idx_include = this.idx_AnimateIncludeTimes;
        
        % Play animation
        prevFrameTime = this.SS.t(1);
        tic;
        for idx = idx_include
            % Plot frame
            coords_chains = this.Draw(this.SS.chains, idx);
            coords_mass = this.Draw({this.SS.p_mass}, idx);
            
            % Draw frame
            for idxChain = 1 : length(line_h)-1
                clearpoints(line_h{idxChain});
                addpoints(line_h{idxChain},...
                    coords_chains{idxChain}(:,1),...
                    coords_chains{idxChain}(:,2),...
                    coords_chains{idxChain}(:,3));
            end
            clearpoints(line_h{end});
            addpoints(line_h{end},...
                coords_mass{1}(:,1),...
                coords_mass{1}(:,2),...
                coords_mass{1}(:,3));
            
            % Paint frame
            if strcmp(mode,'play')
                drawnow limitrate; % limits to 20fps
                executionTime = toc;
                pause(this.SS.t(idx) - prevFrameTime - executionTime); % draw at specified time rate
                prevFrameTime = this.SS.t(idx);
                tic;
            else % gif or video
                % Get frame for video output
                if video_time >= lastFrameTime + 1/videoFrameRate
                    lastFrameTime = video_time;
                    idx_frame = idx_frame + 1;
                    videoFrames(idx_frame) = getframe(axes_h);
                end
                video_time = this.SS.t(idx);
            end
        end
    end
    
    function Animate_SaveGif(this, videoFrames, fileName, options)
        [dimH, dimW, ~] = size(videoFrames(1).cdata);
        dimAR = dimW/dimH; % Aspect ratio

        % Properties of new file
        fileName = strcat(fileName,'.gif');
        NumColours = 3; % very literally
        delayLength = 1/options.videoFrameRate;
        dimHOut = 200;
        
        % Write to new file
        for idx = 1 : length(videoFrames)
            % Raw frame
            frame = videoFrames(idx).cdata;

            % Resize [height, width]
            frame = imresize(frame,[dimHOut round(dimHOut*dimAR)]);

            % Compress colours and dither
            [A,map] = rgb2ind(frame, NumColours, 'nodither');
            %[A,map] = rgb2ind(frame, NumColours, 'dither'); % auto colour map
            %[A,map] = rgb2ind(frame, [0,0,0;1,1,1], 'dither'); % specify colour map
            %[A,map] = rgb2ind(frame, [0.2,0.2,0.2;.8,.8,.8], 'dither'); % specify colour map

            % Write to file
            if idx == 1
                imwrite(A,map, fileName,'gif', 'LoopCount',Inf, 'DelayTime',delayLength);
            else
                imwrite(A,map, fileName,'gif', 'WriteMode','append', 'DelayTime',delayLength);
            end
        end
    end
    
    function Animate_SaveVideo(this, videoFrames, fileName, options)
        % Write video to file
        video = VideoWriter(fileName, 'MPEG-4');
        video.FrameRate = options.videoFrameRate;
        
        open(video);
        writeVideo(video,videoFrames);
        close(video);
    end
    
end
end

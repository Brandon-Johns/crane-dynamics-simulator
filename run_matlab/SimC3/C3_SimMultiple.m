%{
Simulate multiple systems

ASSUMES
    All trials use same solution time vector
    All trials use same input (The parameter 'motion' from AddTrial)

Core Capability
    Caching
    Sundials: generating code / reading in results

Utilities
    Transform solution to be relative to point I
    Generate file name (to describe all trials in one name)
    Generate legend string (to plot all trials on one plot)


%}
classdef C3_SimMultiple < handle
properties (Access=public)
    % Options for user to set directly
    Flag_refreshCached = false
    Flag_DoNotCache = false
end
properties(SetAccess=private)
    cacheBasePath(1,1) string
    sunResultsBasePath(1,1) string

    % Built by AddTrial()
    trialDescriptions(:,:) table
    
    % Created by BuildSolution()
    Values(:,1) CDSv_C3
    Solutions(:,1) CDS_Solution
    t(1,:) double % Time vector to evaluate solution at
    
    % Map options
    %   Syntax: Map(input, output)
    MAP_usePointMassName = containers.Map([0,1], ["", "_Pointmass"]); % logical -> cache filename
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    function this = C3_SimMultiple(cacheBasePath, sunResultsBasePath)
        this.cacheBasePath = cacheBasePath;
        this.sunResultsBasePath = sunResultsBasePath;
        
        % Create empty table
        vNames = ["motion","config","geometry","usePointMass","sunResultsDir","sunResultsPrepend"];
        vTypes = ["double","string","double",  "logical",     "string",       "string"];
        this.trialDescriptions = table('Size',[0,length(vNames)], 'VariableTypes',vTypes, 'VariableNames',vNames);
    end
    
    % Add simulation trial:     3-4 inputs
    % Add sun simulation trial: 6   inputs (1:4 describe the exported system)
    function AddTrial(this,motion,config,geometry,usePointMass,sunResultsDir,sunResultsPrepend)
        arguments
            this(1,1)
            motion(1,1) uint64
            config(1,1) {mustBeMember(config, ["1P","2P","3P","ZS","FC","ZJ","FJ"])}
            geometry(1,1) uint64
            usePointMass(1,1) {mustBeMember(usePointMass, ["", "usePointMass"])} = ""
            sunResultsDir(1,1) = "__NOT_SUN"
            sunResultsPrepend(1,1) = "__NOT_SUN"
        end
        MAP_usePointMass = containers.Map(["", "usePointMass"], [0,1]);
        logical_usePointMass = MAP_usePointMass(usePointMass);
        this.trialDescriptions(end+1,:) = {motion,config,geometry,logical_usePointMass,sunResultsDir,sunResultsPrepend};
    end
    
    %**********************************************************************
    % Interface: Run Simulator
    %***********************************
    function S = BuildSolution(this)
        E = this.trialDescriptions;
        
        V = CDSv_C3.empty;
        S = CDS_Solution.empty;
        for idx = 1:height(E)
            % Value builder
            VB = CDSvb_C3_Builder(E.geometry(idx), E.motion(idx));
            if E.usePointMass; VB.SetPointMass; end
            V(idx) = VB.Values_Sim;

            % Time vector to evaluate solution at
            this.t = 0 : 0.02 : V(idx).t_max;

            % Model builder
            MB = this.InitialiseModelBuilder(E.config(idx), V(idx));
            MB.Build_SystemDescription;

            if  E.sunResultsDir(idx) == "__NOT_SUN" % Simulation
                S(idx) = this.BuildSolution_Sim(E(idx,:), MB);
            else % Sun Import
                S(idx) = this.BuildSolution_Sun(E(idx,:), MB);
            end
        end
        
        % Store results
        this.Values = V;
        this.Solutions = S;
    end
    
    function ExportSun(this, sunGenBasePath)
        arguments
            this(1,1)
            sunGenBasePath(1,1) string % Required
        end
        E = this.trialDescriptions;
        if size(E,1)~=1; error("Export 1 at a time"); end
        
        % Path to export results to
        sunGenDirLeaf = this.GenSunDirLeaf(E);
        exportPath = fullfile(sunGenBasePath, sunGenDirLeaf);

        % Value builder
        VB = CDSvb_C3_Builder(E.geometry, E.motion);
        if E.usePointMass; VB.SetPointMass; end
        V = VB.Values_Sim;
        
        % Model builder
        MB = this.InitialiseModelBuilder(E.config, V);
        sys = MB.Build_SystemDescription;

        SO = CDS_Solver_Options;
        SO.exportPath = exportPath;
        SO.time = [0, V.t_max];

        fprintf("%s\n", "Exporting: "+exportPath);
        S = CDS_Solver(SO);
        S.Solve(sys, "sundials");
    end
    
    %**********************************************************************
    % Interface: Output utilities
    %***********************************
    % OUTPUT
    % results = table of data relative to "I"
    %   Access as results.I{idxRows}(valY,valX)
    function results = ChangeCoordinates(this)
        Sg = CDS_Solution_GetData(this.Solutions);
        
        R = struct("I",{},"K",{},"M",{}, "I_relImesA2",{},"K_relImesA2",{},"M_relImesA2",{});
        time = this.Solutions(1).t;

        for idx = 1:length(Sg)
            % Points in world frame (frame A1)
            R(idx).I = Sg(idx).P("I");
            R(idx).K = Sg(idx).P("K");
            R(idx).M = Sg(idx).P("M");

            % Rotation to frame between frames A1->A2
            theta_1 = CDS_Param_Input("theta_1_t").Set_Selector(this.Values(idx).theta_1_t).q(time);

            % Transformation:
            %   P_n_relI_measureA1 = P_n_relA1_measureA1 - P_I_relA1_measureA1
            %   P_n_relI_measureA2 = R_A2A1 * P_n_relI_measureA1
            R(idx).I_relImesA2 = zeros(size(R(idx).M));
            R(idx).K_relImesA2 = zeros(size(R(idx).M));
            R(idx).M_relImesA2 = zeros(size(R(idx).M));
            for idxT = 1:length(time)
                T_A1A2 = CDS_T('at', 'y', theta_1(idxT));
                R_A2A1 = T_A1A2.R.';

                R(idx).I_relImesA2(:,idxT) = R_A2A1 * ( R(idx).I(:,idxT) );
                R(idx).K_relImesA2(:,idxT) = R_A2A1 * ( R(idx).K(:,idxT) - R(idx).I(:,idxT) );
                R(idx).M_relImesA2(:,idxT) = R_A2A1 * ( R(idx).M(:,idxT) - R(idx).I(:,idxT) );
            end
        end
        results = struct2table(R);
    end
    
    function out = LegendStr(this, mode)
        arguments
            this(1,1)
            mode(1,:) = ["Config", "Geometry"]
        end
        E = this.trialDescriptions;
        out = strings(size(E.config));
        
        for idx = 1:length(mode)
            if     mode(idx)=="Geometry"
                out = out + "G"+E.geometry;
                out(E.usePointMass) = out(E.usePointMass) + "(PointMass)";
            elseif mode(idx)=="Config"
                out = out + "Sim"+E.config;
            end
            
            if idx~=length(mode); out=out+"-"; end
        end
    end
    
    function out = FigFileNameBase(this, figBasePath)
        arguments
            this(1,1)
            figBasePath(1,1) string = ""
        end
        E = this.trialDescriptions;
        pointMassStr = strings(size(E.usePointMass));
        pointMassStr(E.usePointMass) = "pm";
        
        motionStr = "Motion"+E.motion(1);
        specificsStr = strjoin(compose("%s%s%s",E.config,E.geometry,pointMassStr),"_");
        fileName = motionStr+"_"+specificsStr;
        
        out = fullfile(figBasePath, fileName);
    end

end
methods (Access=private)
    function MB = InitialiseModelBuilder(this, modelPreset, V)
        arguments
            this(1,1)
            modelPreset(1,1) string
            V(1,1) CDSv_C3
        end
        if     modelPreset=="1P"; MB = CDSm_C3_1p(V);
        elseif modelPreset=="2P"; MB = CDSm_C3_2p(V);
        elseif modelPreset=="3P"; MB = CDSm_C3_3p(V);
        elseif modelPreset=="ZS"; MB = CDSm_C3_noSheave(V);
        elseif modelPreset=="FC"; MB = CDSm_C3_sheave(V);
        elseif modelPreset=="ZJ"; MB = CDSm_C3_noSheave2P(V);
        elseif modelPreset=="FJ"; MB = CDSm_C3_sheave2P(V);
        else
            error("Bad input: model")
        end
        MB.Flag_2D = V.Flag_2DPermitted; % Run in 2D where possible
        %MB.Flag_pointI_truePosition = false; % Not implemented
    end

    function sunGenDirLeaf = GenSunDirLeaf(this, E)
        arguments
            this(1,1)
            E(1,:) table
        end
        usePointMassName = this.MAP_usePointMassName(E.usePointMass);
        sunGenDirLeaf = "Motion"+E.motion + "_"+E.config + "_G"+E.geometry + usePointMassName;
    end
    
    function sunResultsFileName = SunResultsFileName(this, E)
        arguments
            this(1,1)
            E(1,:) table
        end
        fileNamePart1 = E.sunResultsPrepend; % 'pathAppend' from the sunGen dir
        fileNamePart2 = this.GenSunDirLeaf(E);
        sunResultsFileName = fileNamePart1+"-"+fileNamePart2;
    end
    
    function SS = BuildSolution_Sun(this, E, MB)
        arguments
            this(1,1)
            E(1,:) table
            MB(1,1) CDSm_C3
        end
        % Data path
        sunResultsFileName = this.SunResultsFileName(E);
        sunResultsFullPath = fullfile(this.sunResultsBasePath,E.sunResultsDir,sunResultsFileName);
        
        % Retrieve data
        SS_import = MB.ImportSolution_Sundials(sunResultsFullPath);
        
        % Interpolate data
        SS = CDS_SolutionInterpolated(SS_import, this.t);
    end
    
    
    function SS = BuildSolution_Sim(this, E, MB)
        arguments
            this(1,1)
            E(1,:) table
            MB(1,1) CDSm_C3
        end
        % Solve / retrieve results from cache
        usePointMassName = this.MAP_usePointMassName(E.usePointMass);
        cacheFileName = "Motion"+E.motion + "_"+E.config + "_G"+E.geometry + usePointMassName + ".xlsx";
        cacheFile = fullfile(this.cacheBasePath, cacheFileName);

        if ~this.Flag_refreshCached && exist(cacheFile, "file")
            SS_import = MB.ImportSolution_Saved(cacheFile);
            % Interpolate data
            SS = CDS_SolutionInterpolated(SS_import, this.t);
        else
            fprintf("Simulator: Solving\n");
            % Evaluate at the same time coordinates
            SO = CDS_Solver_Options(); SO.time = this.t;
            %SO.EventsIsActive = 1;
            SS = MB.Solve("auto","auto", SO,"OptsSpecifyTime");
            % Cache results
            if ~this.Flag_DoNotCache
                fprintf("%s\n", "Caching: "+cacheFile);
                SSe = CDS_Solution_Export(SS);
                SSe.DataToExcel(cacheFile);
            end
        end

    end
end
end
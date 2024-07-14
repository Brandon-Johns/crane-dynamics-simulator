%{
The same as C3_SimMultiple, but based around using the data from the trials with a UR5 robot

Core Intent
    Run simulations that match the conditions of the experimental trials
    Directly compare these simulations with the experimental results


%}
classdef C3_ImportMultiple < handle
properties(SetAccess=private)
    dataBasePath(1,1) string
    cacheBasePath(1,1) string
    sunResultsBasePath(1,1) string

    % Built by AddTrial()
    trialDescriptions(:,:) table
    
    % Created by BuildSolution()
    Values(:,1) CDSv_C3
    Solutions(:,1) CDS_Solution
    
    % Map options
    %   Syntax: Map(input, output)
    MAPp = containers.Map(["PL","PH"], [3,4]); % Payload readable    -> CDSvb_C3_Builder
    MAPm = containers.Map([1,2,3], [6,7,8]);   % Motion experimental -> CDSvb_C3_Builder
    MAPm_2DPermitted = containers.Map([1,2,3], [false,true,false]);  % Motion experimental -> logical
    MAP_Sim2D_optToText = containers.Map([0,1], ["","2D"]);          % logical -> cache filename
    MAP_usePointMassName = containers.Map([0,1], ["", "Pointmass"]); % logical -> cache filename
end
methods
    function this = C3_ImportMultiple(dataBasePath, cacheBasePath, sunResultsBasePath)
        this.dataBasePath = dataBasePath;
        this.cacheBasePath = cacheBasePath;
        this.sunResultsBasePath = sunResultsBasePath;
        
        % Create empty table
        vNames = ["exDate","exPayload","exMotion","exConfig","simConfig","usePointMass","sunResultsDir","sunResultsPrepend"];
        vTypes = ["string","string",   "double",  "string",  "string",   "logical",     "string",       "string"];
        this.trialDescriptions = table('Size',[0,length(vNames)], 'VariableTypes',vTypes, 'VariableNames',vNames);
    end
    
    % Add experimental trial:   4 inputs
    % Add simulation trial:     5 inputs (1:4 describe the experiment to mimic)
    % Add sun simulation trial: 6 inputs (1:5 describe the exported system)
    function AddTrial(this,exDate,exPayload,exMotion,exConfig,simConfig,usePointMass,sunResultsDir,sunResultsPrepend)
        arguments
            this(1,1)
            exDate(1,1)
            exPayload(1,1) {mustBeMember(exPayload, ["PL","PH"])}
            exMotion(1,1) {mustBeMember(exMotion, [1,2,3])}
            exConfig(1,1) {mustBeMember(exConfig, ["1P","2P","3P","ZS","FC"])}
            simConfig(1,1) {mustBeMember(simConfig, ["__NOT_SIM", "1P","2P","3P","ZS","FC","ZJ","FJ"])} = "__NOT_SIM"
            usePointMass(1,1) {mustBeMember(usePointMass, ["", "usePointMass"])} = ""
            sunResultsDir(1,1) = "__NOT_SUN"
            sunResultsPrepend(1,1) = "__NOT_SUN"
        end
        MAP_usePointMass = containers.Map(["", "usePointMass"], [0,1]);
        logical_usePointMass = MAP_usePointMass(usePointMass);
        this.trialDescriptions(end+1,:) = {exDate,exPayload,exMotion,exConfig,simConfig,logical_usePointMass,sunResultsDir,sunResultsPrepend};
    end
    
    function S = BuildSolution(this)
        E = this.trialDescriptions;
        
        V = CDSv_C3.empty;
        S = CDS_Solution.empty;
        for idx = 1:height(E)
            % Retrieve experimental data
            [SE, V(idx)] = this.BuildSolution_Exp(E(idx,:));

            if E.simConfig(idx) == "__NOT_SIM" % Experiment
                S(idx) = SE;
            elseif  E.sunResultsDir(idx) == "__NOT_SUN" % Simulation
                S(idx) = this.BuildSolution_Sim(E(idx,:), V(idx), SE);
            else % Sun Import
                S(idx) = this.BuildSolution_Sun(E(idx,:), V(idx), SE);
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
        sunGenDir = this.GenSunDir(E);
        exportPath = fullfile(sunGenBasePath, sunGenDir);

        % Retrieve experimental data
        [SE, V] = this.BuildSolution_Exp(E);
        
        % Model builder
        MB = this.InitialiseModelBuilder(E.simConfig, V);
        MB.Flag_2D = this.MAPm_2DPermitted(E.exMotion);
        %MB.Flag_pointI_truePosition = false; % Not implemented
        sys = MB.Build_SystemDescription;

        SO = CDS_Solver_Options;
        SO.exportPath = exportPath;
        SO.time = [0, SE.t(end)];

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
            mode(1,:) = ["Payload","Config"]
        end
        E = this.trialDescriptions;
        out = strings(size(E.simConfig));
        
        for idx = 1:length(mode)
            if     mode(idx)=="Payload"
                out = out + E.exPayload;
                out(E.usePointMass) = out(E.usePointMass) + "(PointMass)";
            elseif mode(idx)=="Config"
                idxExp = E.simConfig=="__NOT_SIM";
                out(idxExp)  = out(idxExp)  + "Exp"+E.exConfig(idxExp);
                out(~idxExp) = out(~idxExp) + "Sim"+E.simConfig(~idxExp) +"(Exp"+E.exConfig(~idxExp)+")";
            elseif mode(idx)=="SimConfig"
                idxExp = E.simConfig=="__NOT_SIM";
                out(~idxExp) = out(~idxExp) + "Sim" + E.exConfig(~idxExp);
            elseif mode(idx)=="SimExp"
                idxExp = E.simConfig=="__NOT_SIM";
                out(idxExp) = out(idxExp) + "Exp";
                out(~idxExp) = out(~idxExp) + "Sim";
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
        simConfigStr = E.simConfig;
        simConfigStr(simConfigStr=="__NOT_SIM") = "";
        pointMassStr = strings(size(E.usePointMass));
        pointMassStr(E.usePointMass) ="pm";

        figDir = "Exp"+E.exDate(1);
        
        motionStr = "Motion"+E.exMotion(1);
        specificsStr = strjoin(compose("%s%s%s%s",E.exPayload,E.exConfig,simConfigStr,pointMassStr),"_");
        fileName = motionStr+"_"+specificsStr;
        
        out = fullfile(figBasePath, figDir, fileName);
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
    end

    function sunGenDir = GenSunDir(this, E)
        arguments
            this(1,1)
            E(1,:) table
        end
        sim2DName = this.MAP_Sim2D_optToText( this.MAPm_2DPermitted(E.exMotion) );
        usePointMassName = this.MAP_usePointMassName(E.usePointMass);
        sunGenDir = "Exp"+E.exDate+"_Motion"+E.exMotion+"_"+E.exPayload+"_Exp"+E.exConfig+"_Sim"+E.simConfig+sim2DName+usePointMassName;
    end
    
    function sunResultsFileName = SunResultsFileName(this, E)
        arguments
            this(1,1)
            E(1,:) table
        end
        fileNamePart1 = E.sunResultsPrepend; % 'pathAppend' from the sunGen dir
        fileNamePart2 = this.GenSunDir(E);
        sunResultsFileName = fileNamePart1+"-"+fileNamePart2;
    end
    
    function [SE, V] = BuildSolution_Exp(this, E)
        arguments
            this(1,1)
            E(1,:) table
        end
        % Data path
        dataFileName = "raw_motion"+E.exMotion+"_"+E.exPayload+"_"+E.exConfig+".csv";
        dataFullPath = fullfile(this.dataBasePath,E.exDate,dataFileName);
        
        % Retrieve parameters
        VB = CDSvb_C3_Builder( this.MAPp(E.exPayload), this.MAPm(E.exMotion) );
        if E.usePointMass; VB.SetPointMass; end
        V = VB.Values_Exp;
        
        % Retrieve experimental data
        SB = CDSm_C3_ImportExp_v1(V);
        SE = SB.Build_Solution(dataFullPath);
        
        % Check results
        SEg = CDS_Solution_GetData(SE);
        % L & L2 should be coincident
        errorL = SEg.AbsDistance("L","L2");
        if max(errorL)>0.01
            fprintf("Consistency of L/L2. Error (max,mean,std) = %.1g, %.1g, %.1g\n", max(errorL),mean(errorL),std(errorL));
            warning("Large error in L/L2");
        end
    end
    
    function [SS, V] = BuildSolution_Sun(this, E, V, SE)
        arguments
            this(1,1)
            E(1,:) table
            V(1,1) CDSv_C3
            SE(1,1) CDS_Solution
        end
        % Data path
        sunResultsFileName = this.SunResultsFileName(E);
        sunResultsFullPath = fullfile(this.sunResultsBasePath,E.sunResultsDir,sunResultsFileName);
        
        % Load preset numerical values: constants, ICs, inputs, etc.
        sim2D = this.MAPm_2DPermitted(E.exMotion);
        
        % Model builder
        MB = this.InitialiseModelBuilder(E.simConfig, V);
        MB.Flag_2D = sim2D;
        %MB.Flag_pointI_truePosition = false; % Not implemented
        MB.Build_SystemDescription;
        
        % Retrieve data
        SS_import = MB.ImportSolution_Sundials(sunResultsFullPath);
        
        % Interpolate data
        SS = CDS_SolutionInterpolated(SS_import, SE.t);
    end
    
    
    function [SS, V] = BuildSolution_Sim(this, E, V, SE)
        arguments
            this(1,1)
            E(1,:) table
            V(1,1) CDSv_C3
            SE(1,1) CDS_Solution
        end
        % Load preset numerical values: constants, ICs, inputs, etc.
        sim2D = this.MAPm_2DPermitted(E.exMotion);
        sim2DName = this.MAP_Sim2D_optToText(sim2D);
        usePointMassName = this.MAP_usePointMassName(E.usePointMass);
        
        % Model builder
        MB = this.InitialiseModelBuilder(E.simConfig, V);
        MB.Flag_2D = sim2D;
        %MB.Flag_pointI_truePosition = false; % Not implemented
        MB.Build_SystemDescription;

        % Solve / retrieve results from cache
        excelDir = "Exp"+E.exDate+"_SimResultsCache";
        excelFN = "Motion"+E.exMotion+"_Payload"+E.exPayload+"_Exp"+E.exConfig+"_Sim"+E.simConfig+sim2DName+usePointMassName+"_SS"+".xlsx";
        excelFileName_SS = fullfile(this.cacheBasePath, excelDir, excelFN);
        if exist(excelFileName_SS, "file")
            SS = MB.ImportSolution_Saved(excelFileName_SS);
        else
            fprintf("Simulator: Solving\n");
            % Evaluate at the same time coordinates
            SO = CDS_Solver_Options(); SO.time = SE.t;
            % SO.EventsIsActive = 1;
            SS = MB.Solve("auto","auto", SO,"OptsSpecifyTime");
            % Cache results
            fprintf("%s\n", "Caching: "+excelFileName_SS);
            SSe = CDS_Solution_Export(SS);
            SSe.DataToExcel(excelFileName_SS);
        end

        % Check results
        SEg = CDS_Solution_GetData(SE);
        SSg = CDS_Solution_GetData(SS);
        % Start config should closely align
        errorStart = SEg.xyz(1,["A","I","J","K","L","L2","M"]) - SSg.xyz(1,["A","I","J","K","L","L","M"]);
        if max(vecnorm(errorStart,2,2))>0.01
            fprintf("Consistency of Start Position. Max Error (norm) = %.2g\n", max(vecnorm(errorStart,2,2)) )
            %startErrorT = array2table(round(startError,1,'significant'), 'RowNames',["A","I","J","K","L","L2","M"])
            warning("Large error in Start Position");
        end
        % Point I should closely align (well... model dependent)
        errorI = SEg.P("I") - SSg.P("I");
        if max(mean(errorI,2))>0.01
            fprintf("Consistency of I. Max    error (x,y,z) = %.1g, %.1g, %.1g\n", max(errorI,[],2));
            fprintf("Consistency of I. Ave    error (x,y,z) = %.1g, %.1g, %.1g\n", mean(errorI,2));
            fprintf("Consistency of I. STDDEV error (x,y,z) = %.1g, %.1g, %.1g\n", std(errorI,0,2));
            warning("Large error in I");
        end
    end
end
end
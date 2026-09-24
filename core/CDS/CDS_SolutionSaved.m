%{
PURPOSE
    Import post-processed solution data

DETAILS
    Load the previously solved solution that was exported with CDS_Solution_Export

NOTES
    Reimporting the solution requires rebuilding the CDS_SystemDescription object.
    It is your responsibility to ensure that this object is identical to the one that created the exported solution

    Alternatively to this workflow, you may wish to simply export your solution to a .mat file.
    Then you can later import the .mat file

EXAMPLE
    % See the HowTo Reference "Export/Import the Processed Solution"
%}

classdef CDS_SolutionSaved < CDS_Solution
methods
    %**********************************************************************
    % Interface - Create & Initialise
    %***********************************
    % INPUT
    %   sys
    %       The system to corresponding to the solution data being loaded
    %       It must exactly match the system that created the exported solution
    %       It will not be strictly verified that the solution matches the system description
    %   fileName
    %       Relative path to the file that holds the exported solution
    function this = CDS_SolutionSaved(sys, fileName)
        arguments
            sys(1,1) CDS_SystemDescription
            fileName(1,1) string
        end
        % Validate file path
        FileHelper = CDS_Helper_StrOut();
        fileName = FileHelper.ValidateFileExtension(fileName, ".xlsx");
        fileName = FileHelper.ValidateFileExists(fileName);

        % Save system description
        this.sys = sys;

        % TODO: Why was lambda not imported? Set it to be imported
        % Don't import lambda
        sys.params.SetStateVectorMode("withoutLambda");

        % Read in the xlsx results
        sheetNames = sheetnames(fileName);
        this.t     = this.ImportFromExcel(fileName, sheetNames, 't');
        this.qf    = this.ImportFromExcel(fileName, sheetNames, 'qf');
        this.qf_d  = this.ImportFromExcel(fileName, sheetNames, 'qf_d');
        this.qf_dd = this.ImportFromExcel(fileName, sheetNames, 'qf_dd');
        this.qi    = this.ImportFromExcel(fileName, sheetNames, 'qi');
        this.qi_d  = this.ImportFromExcel(fileName, sheetNames, 'qi_d');
        this.qi_dd = this.ImportFromExcel(fileName, sheetNames, 'qi_dd');
        %this.ql    = this.ImportFromExcel(fileName, sheetNames, 'ql');
        %this.ql_d  = this.ImportFromExcel(fileName, sheetNames, 'ql_d');
        this.ql    = double.empty(0, numel(this.t));
        this.ql_d  = double.empty(0, numel(this.t));
        this.Px    = this.ImportFromExcel(fileName, sheetNames, 'Px');
        this.Py    = this.ImportFromExcel(fileName, sheetNames, 'Py');
        this.Pz    = this.ImportFromExcel(fileName, sheetNames, 'Pz');
        E          = this.ImportFromExcel(fileName, sheetNames, 'E');
        this.K_mass           = this.ImportFromExcel(fileName, sheetNames, 'K_mass');
        this.V_mass           = this.ImportFromExcel(fileName, sheetNames, 'V_mass');
        this.V_linearSprings  = this.ImportFromExcel(fileName, sheetNames, 'V_linearSprings');
        this.V_torsionSprings = this.ImportFromExcel(fileName, sheetNames, 'V_torsionSprings');

        if isempty(E)
            this.E = nan(1,numel(this.t)); % This causes a lot of fun (match to CDS_SolutionExp)
        else
            this.E = E;
        end

        % Compatibility with exports from previous version
        if isempty(this.K_mass) && isempty(this.V_mass)
            this.K_mass = this.ImportFromExcel(fileName, sheetNames, 'K');
            this.V_mass = this.ImportFromExcel(fileName, sheetNames, 'V');
        end
    end
end
methods (Access=private)
    function val = ImportFromExcel(this, fileName, sheetNames, sheetName)
        if ~ismember(sheetName, sheetNames)
            % Allow missing
            % Initialise empty arrays with consistent sizes
            val = double.empty(0, numel(this.t));
            return
        end

        val = readmatrix(fileName, 'sheet',sheetName, 'UseExcel',0).';
    end
end
end

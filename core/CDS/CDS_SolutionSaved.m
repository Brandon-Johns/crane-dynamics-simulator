%{
PURPOSE
    Load the previously solved solution that was exported with CDS_Solution_Export
    Hold the post processed solution data

NOTES
    Reimporting the solution requires rebuilding the CDS_SystemDescription object.
    It is your responsibility to ensure that this object is identical to the one that created the exported solution

    Alternatively to this workflow, you may wish to simply export your solution as a .mat file.
    Then you can later import the .mat file

EXAMPLE
    % See the HowTo Reference "Export/Import the post-processed solution"
%}

classdef CDS_SolutionSaved < CDS_Solution
methods
    %**********************************************************************
    % Interface - Create & Initialise
    %***********************************
    % INPUT
    %   sys: CDS_SystemDescription instance that exactly matches the one that created the exported solution
    %   fileName: path to the file that holds the exported solution
    function this = CDS_SolutionSaved(sys, fileName)
        arguments
            sys(1,1) CDS_SystemDescription
            fileName(1,1) string
        end
        % Validate file path
        FileHelper = CDS_Helper_StrOut();
        fileName = FileHelper.ValidateFileExtension(fileName, ".xlsx");
        fileName = FileHelper.ValidateFileExists(fileName);

        % Extract params & points
        this.q_free = sys.params.q_free;
        %q_lambda = [];
        this.q_input = sys.params.q_input;
        this.p_mass = sys.points.all.GetIfHasMass;
        this.p_all = sys.points.all;
        this.chains = sys.chains;

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
        this.K     = this.ImportFromExcel(fileName, sheetNames, 'K');
        this.V     = this.ImportFromExcel(fileName, sheetNames, 'V');
        this.E     = this.ImportFromExcel(fileName, sheetNames, 'E');
        this.Px    = this.ImportFromExcel(fileName, sheetNames, 'Px');
        this.Py    = this.ImportFromExcel(fileName, sheetNames, 'Py');
        this.Pz    = this.ImportFromExcel(fileName, sheetNames, 'Pz');
    end
end
methods (Access=private)
    function val = ImportFromExcel(~, fileName, sheetNames, sheetName)
        % Allow empty
        if ~ismember(sheetName, sheetNames)
            val=[];
            return
        end
        
        val = readmatrix(fileName, 'sheet',sheetName, 'UseExcel',0).';
    end
end
end

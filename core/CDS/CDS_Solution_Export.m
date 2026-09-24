%{
PURPOSE
    Export the solution to an excel file in human readable format

NOTES
    The solution can be reimported with CDS_SolutionSaved
%}

classdef CDS_Solution_Export < handle
properties (Access=protected)
    SS(1,1) CDS_Solution
end
methods
    % INPUT
    %   The solution to export
    function this = CDS_Solution_Export(solution)
        arguments
            solution CDS_Solution
        end
        if isempty(solution)
            this = CDS_Solution_Export.empty(size(solution));
            return;
        end
        if isscalar(solution)
            this.SS = solution;
            return;
        end
        for idx = 1:numel(solution)
            this(idx) = CDS_Solution_Export(solution(idx));
        end
        this = reshape(this, size(solution));
    end

    % Output solution to excel
    % DETAIL
    %   If file already exists, overwrite entire file
    %   Each sheet holds each variable from CDS_Solution
    % INPUT
    %   Relative path to the file
    function DataToExcel(this, fileName)
        arguments
            this(1,1)
            fileName(1,1) string = "tmp"
        end
        % Validate and create file path
        FileHelper = CDS_Helper_StrOut();
        fileName = FileHelper.ValidateFileExtension(fileName, ".xlsx");
        fileName = FileHelper.MakePathToFile(fileName);

        % Output
        this.ExportToExcel(this.SS.t,     "Time",                         fileName, "t", "clearFile")
        this.ExportToExcel(this.SS.qf,    this.SS.sys.params.q_free.Str,  fileName, "qf")
        this.ExportToExcel(this.SS.qf_d,  this.SS.sys.params.q_free.Str,  fileName, "qf_d")
        this.ExportToExcel(this.SS.qf_dd, this.SS.sys.params.q_free.Str,  fileName, "qf_dd")
        this.ExportToExcel(this.SS.qi,    this.SS.sys.params.q_input.Str, fileName, "qi")
        this.ExportToExcel(this.SS.qi_d,  this.SS.sys.params.q_input.Str, fileName, "qi_d")
        this.ExportToExcel(this.SS.qi_dd, this.SS.sys.params.q_input.Str, fileName, "qi_dd")
        this.ExportToExcel(this.SS.Px,    this.SS.sys.points.Name, fileName, "Px")
        this.ExportToExcel(this.SS.Py,    this.SS.sys.points.Name, fileName, "Py")
        this.ExportToExcel(this.SS.Pz,    this.SS.sys.points.Name, fileName, "Pz")
        this.ExportToExcel(this.SS.E,     "Total",                 fileName, "E")
        this.ExportToExcel(this.SS.K_mass, this.SS.sys.points.GetIfHasMass.Name,      fileName, "K_mass")
        this.ExportToExcel(this.SS.V_mass, this.SS.sys.points.GetIfHasMass.Name,      fileName, "V_mass")
        this.ExportToExcel(this.SS.V_linearSprings,  this.SS.sys.linearSprings.Name,  fileName, "V_linearSprings")
        this.ExportToExcel(this.SS.V_torsionSprings, this.SS.sys.torsionSprings.Name, fileName, "V_torsionSprings")
    end
end
methods (Access=protected)
    % INPUT
    %   values = [val_1; ...; val_n]
    function ExportToExcel(~, values, names, fileName, sheetName, clearFile)
        arguments
            ~
            values(:,:) double
            names(1,:) string
            fileName(1,1) string
            sheetName(1,1) string
            clearFile(1,1) string = ""
        end
        % Exception for no data - Do not create sheet
        if isempty(values) || all(isnan(values),'all')
            fprintf("(Export Excel) Sheet skipped: " + sheetName + "\n");
            if strcmp(clearFile, "clearFile")
                % If clearFile is set, I don't want to do programmatic deletion
                % Make the user do it
                error("(Export Excel) Please manually delete: " + fileName + "\n");
            end
            return;
        end

        if strcmp(clearFile, "clearFile")
            writeMode = "replacefile";
        else
            writeMode = "inplace";
        end
        data = array2table(values.', 'VariableNames',names);
        writetable(data, fileName,...
            'WriteMode',writeMode,...
            'Sheet',sheetName,...
            'UseExcel',0);
    end
end
end

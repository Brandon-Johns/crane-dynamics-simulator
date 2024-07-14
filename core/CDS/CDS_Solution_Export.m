%{
PURPOSE
    Export the solution to an excel file in human readable format

NOTES
    The solution can be reimported with CDS_SolutionSaved
%}

classdef CDS_Solution_Export < handle
properties (Access=private)
    SS(1,1) CDS_Solution
end
methods
    % INPUT
    %   CDS_Solution
    function this = CDS_Solution_Export(solution)
        % This results that: Input array -> output array of objects
        %   (instead of assigning the input array to the property of 1 output object)
        %   https://au.mathworks.com/help/matlab/matlab_oop/creating-object-arrays.html
        if nargin==0; return; end
        for idx = length(solution):-1:1
            this(idx).SS = solution(idx);
        end
    end
    
    % Output solution to excel
    % If file already exists, overwrite entire file
    %    Each sheet holds each variable from CDS_Solution
    % INPUT
    %   fileName: path to the file
    function DataToExcel(this, fileName)
        arguments
            this(1,1)
            fileName(1,1) string = "tmp"
        end
        % Validate and create file path
        FileHelper = CDS_Helper_StrOut();
        fileName = FileHelper.ValidateFileExtension(fileName, ".xlsx");
        fileName = FileHelper.MakePathToFile(fileName);
        
        % Output configuration space
        this.ExportToExcel(this.SS.t, "Time", fileName, "t", "clearFile")
        this.ExportToExcel(this.SS.qf, this.SS.q_free.Str, fileName, "qf")
        this.ExportToExcel(this.SS.qf_d, this.SS.q_free.Str, fileName, "qf_d")
        this.ExportToExcel(this.SS.qf_dd, this.SS.q_free.Str, fileName, "qf_dd")
        this.ExportToExcel(this.SS.qi, this.SS.q_input.Str, fileName, "qi")
        this.ExportToExcel(this.SS.qi_d, this.SS.q_input.Str, fileName, "qi_d")
        this.ExportToExcel(this.SS.qi_dd, this.SS.q_input.Str, fileName, "qi_dd")
        
        % Output Energy
        this.ExportToExcel(this.SS.E, "Total", fileName, "E")
        this.ExportToExcel(this.SS.V, this.SS.p_mass.NameShort, fileName, "V")
        this.ExportToExcel(this.SS.K, this.SS.p_mass.NameShort, fileName, "K")
        
        % Output task space - all
        this.ExportToExcel(this.SS.Px, this.SS.p_all.NameShort, fileName, "Px")
        this.ExportToExcel(this.SS.Py, this.SS.p_all.NameShort, fileName, "Py")
        this.ExportToExcel(this.SS.Pz, this.SS.p_all.NameShort, fileName, "Pz")
    end
end
methods (Access=protected)
    function ExportToExcel(~, values, names, fileName, sheetName, clearFile)
        arguments
            ~
            values(:,:) double % [val_1; ...; val_n]
            names(1,:) string
            fileName(1,1) string
            sheetName(1,1) string
            clearFile(1,1) string = ""
        end
        % Exception for no data - Do not create sheet
        if isempty(values)
            fprintf("(Export Excel) Sheet skipped: " + sheetName + "\n");
            if strcmp(clearFile, "clearFile")
                % If clearFile is set, I don't want to do programmatic deletion
                % Make the user do it
                error("(Export Excel) Please manually delete:" + fileName + "\n");
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

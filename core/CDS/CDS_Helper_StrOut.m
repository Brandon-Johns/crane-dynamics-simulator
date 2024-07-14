%{
PURPOSE
    Various functions to validate, create, and write to text files
%}

classdef CDS_Helper_StrOut < handle
properties
    %
end
methods
    function this = CDS_Helper_StrOut()
        %
    end

    %**********************************************************************
    % Interface: Create
    %***********************************
    % Create a folder tree, given a path including the filename
    % INPUT
    %    filePath: path to the file
    function filePath = MakePathToFile(this, filePath)
        arguments
            this(1,1)
            filePath(1,1) string
        end
        filePath = this.ValidatePath(filePath);
        
        % Extract directory, removing filename
        [PathDir,~,~] = fileparts(filePath);
        
        % Current working directory => No action required
        if PathDir==""; return; end
        
        % Path already exists => No action required
        if isfolder(PathDir); return; end
        
        mkdir(PathDir);
    end
    
    %**********************************************************************
    % Interface:
    %   Validate (throws errors)
    %   Check (returns valid/invalid as a boolean)
    %***********************************
    % Validate that a given file path string has the desired file extension
    % The path itself is not validated
    % INPUT
    %   filepath: The path to validate
    %   extension: The file extension that should be at the end of the path
    % OUTPUT
    %   The input path. If there was no extension, then the extension is added
    function filePath = ValidateFileExtension(this, filePath, extension)
        arguments
            this(1,1)
            filePath(1,1) string
            extension(1,1) string
        end
        [~,pathFN,pathEx] = fileparts(filePath);
        if contains(pathFN, "."); error("Path contains multiple extensions"); end
        
        % Add "." to extension
        if ~contains(extension, "."); extension="."+extension; end

        % Check extension / append extension if none
        if pathEx==""
            filePath = filePath + extension;
        elseif pathEx ~= extension
            error("Mismatching extension");
        end
    end
    
    % Check if a given file exists
    % Test the input string without altering it / without any error-correcting
    % INPUT
    %   filepath: The path to validate
    function pathExists = CheckFileExists(this, filePath)
        arguments
            this(1,1)
            filePath(1,1) string
        end
        pathExists = exist(filePath, "file");
    end

    % Validate that a given file exists
    % INPUT
    %   filepath: The path to validate
    % OUTPUT
    %   The input path. The directory separator is automatically corrected to that of the current OS
    function filePath = ValidateFileExists(this, filePath)
        arguments
            this(1,1)
            filePath(1,1) string
        end
        filePath = this.ValidatePath(filePath);
        if ~this.CheckFileExists(filePath); error("Files Does not exist"); end
    end

    % Validate a given file path string
    % Its existence is not validated
    % INPUT
    %   filepath: The path to validate
    % OUTPUT
    %   The input path. The directory separator is automatically corrected to that of the current OS
    function filePath = ValidatePath(this, filePath)
        arguments
            this(1,1)
            filePath(1,1) string
        end
        % Enforce platform correct dir separator
        %   fullfile() sets the correct separator when given a UNIX path
        %   => change window separator to UNIX, then let fullfile() finish the job
        filePath = fullfile(strrep(filePath, "\","/"));
        
        % Prevent dangerous operations
        [pathDir,~,pathEx] = fileparts(filePath);
        if pathEx==""; error("Bad input: No file extension"); end
        if any(strncmp(pathDir,["\","/"],1)); error("Bad input: Relative paths only (Path starts with '/')"); end
    end
    
    %**********************************************************************
    % Interface: Write
    %***********************************
    % Clear content of txt file
    % INPUT
    %   filePath: path to the file
    function ClearFile(this, filePath)
        arguments
            this(1,1)
            filePath(1,1) string
        end
        filePath = this.MakePathToFile(filePath);
        
        % Empty file / Create if none exists
        fileID = fopen(filePath, 'wt');
        
        % Close file
        fclose(fileID);
    end
    
    % Append string to text file
    % INPUT
    %   str: string to output
    %   filePath: path to the file
    %   mode =
    %       "format": print formatted with 'fprintf()'
    %       "exact": write exact string input with 'fwrite()'
    %       "exactN": write exact string input, then newline
    function StrToTxt(this, str, filePath, mode)
        arguments
            this(1,1)
            str(:,1) string
            filePath(1,1) string = "tmp.txt"
            mode(1,1) string {mustBeMember(mode, ["format","exact","exactN"])} = "format"
        end
        filePath = this.MakePathToFile(filePath);
        
        % Open and setup output file
        fileID = fopen(filePath, 'rt+');
        if fileID==-1 % error code for file does not exist
            fileID = fopen(filePath, 'wt+');
        else
            fseek(fileID, 0, 'eof'); % add at end of file
        end
        
        % Print / write string to file
        for idx = 1:length(str)
            if strcmp(mode,"format")
                fprintf(fileID, str(idx));
            elseif strcmp(mode,"exact")
                fwrite(fileID, str(idx));
            else %strcmp(mode,"exactN")
                fwrite(fileID, str(idx));
                fprintf(fileID, '\n');
            end
        end
        
        % Close file
        fclose(fileID);
    end
    
    % Append symbolic expression to text file
    % INPUT
    %   var: symbolic matrix or cell array of symbolic matrices
    %   filePath: path to the file
    %   mode =
    %       "bare": only print the expression (not for cell arrays)
    %       "terminate": bare, but terminate line with ';\n\n'
    %   modeWS =
    %       "normalWS": print spaces within equation
    %       "removeWS": remove spaces from equation
    function SymToTxt(this, var, filePath, mode, modeWS)
        arguments
            this(1,1)
            var
            filePath(1,1) string = "tmp.txt"
            mode(1,1) string {mustBeMember(mode, ["bare","terminate"])} = "bare"
            modeWS(1,1) string {mustBeMember(modeWS, ["normalWS","removeWS"])} = "normalWS"
        end
        filePath = this.MakePathToFile(filePath);
        
        if strcmp(modeWS, "removeWS")
            preprocessWS = @(str) strrep(str,' ','');
        else %strcmp(modeWS, 'normalWS')
            preprocessWS = @(str) str;
        end
        
        % Open and setup output file
        fileID = fopen(filePath, 'rt+');
        if fileID==-1 % error code for file does not exist
            fileID = fopen(filePath, 'wt+');
        else
            fseek(fileID, 0, 'eof'); % add at end of file
        end
        
        % Print data
        if iscell(var)
            % Reshape into 1D cell array
            var = var(:);
            
            % Print each cell
            for idx = 1:length(var)
                fprintf(fileID, '%s\n\n' ,preprocessWS(char(var{idx})));
            end
        else % Bare matrix
            fprintf(fileID, '%s' ,preprocessWS(char(var)));
            
            if strcmp(mode,'terminate')
                fprintf(fileID, ';\n\n');
            end
        end
        
        % Close file
        fclose(fileID);
    end
end
end

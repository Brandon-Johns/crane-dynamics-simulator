%{
PURPOSE
    Validate filepaths. Create and write to text files
%}

classdef CDS_Helper_StrOut < handle
methods
    % Blank constructor
    function this = CDS_Helper_StrOut()
        %
    end

    %**********************************************************************
    % Interface: Create
    %***********************************
    % Create a folder tree
    % INPUT
    %   Relative filepath, including filename & extension
    % OUTPUT
    %   (string) DIM[1,1] The input path with the directory separator normalised for the current OS
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
    %   filepath: Relative filepath, including filename and optional file extension
    %   extension: Desired file extension
    % OUTPUT
    %   (string) DIM[1,1] The input path with the extension added
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
    %   Relative filepath, including filename & extension
    % OUTPUT
    %   (logical) DIM[1,1]
    function result = CheckFileExists(this, filePath)
        arguments
            this(1,1)
            filePath(1,1) string
        end
        result = exist(filePath, "file");
    end

    % Validate that a given file exists
    % INPUT
    %   Relative filepath, including filename & extension
    % OUTPUT
    %   (string) DIM[1,1] The input path with the directory separator normalised for the current OS
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
    %   Relative filepath, including filename & extension
    % OUTPUT
    %   (string) DIM[1,1] The input path with the directory separator normalised for the current OS
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
    %   Relative filepath, including filename & extension
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
    %   str
    %       Text to output
    %   filePath
    %       Relative filepath, including filename & extension
    %   mode
    %       "format": Print formatted with 'fprintf()'
    %       "exact":  Write exact string input with 'fwrite()'
    %       "exactN": Write exact string input, then newline
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
    %   var
    %       Symbolic matrix
    %   filePath
    %       Relative filepath, including filename & extension
    %   mode
    %       "bare":      Only print the expression (not for cell arrays)
    %       "terminate": Bare, but terminate line with ';\n\n'
    %   modeWS
    %       "normalWS": Print spaces within equation
    %       "removeWS": Remove spaces from equation
    function SymToTxt(this, var, filePath, mode, modeWS)
        arguments
            this(1,1)
            var sym
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
        fprintf(fileID, '%s' ,preprocessWS(char(var)));

        if strcmp(mode,'terminate')
            fprintf(fileID, ';\n\n');
        end

        % Close file
        fclose(fileID);
    end
end
end

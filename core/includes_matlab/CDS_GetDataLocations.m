%{
PURPOSE
    Get the path to the root project directory or a data directory

% EXAMPLE
    CDS_GetDataLocations().cache()
    # Returns "C:\________\data\matlab_cache"

    CDS_GetDataLocations().cache("aaa","bbb","ccc")
    # Returns "C:\________\data\matlab_cache\aaa\bbb\ccc"
%}
classdef CDS_GetDataLocations
properties (Access=private)
    base(1,1) string
end
methods
    function this = CDS_GetDataLocations()
        % Full path to this file (no matter where it is called from)
        [pathDir,~,~] = fileparts( mfilename('fullpath') );

        % Base of path to data
        this.base = fullfile(pathDir, "..","..","data");
    end

    % INPUT
    %   varargin: [string,...] directory hierarchy. Specify one directory per string
    % OUTPUT
    %   Path to the corresponding directory
    function out = root(this,varargin);          out = this.formPath(varargin{:}); end
    
    function out = exp_results(this,varargin);   out = this.formPath("experiments_results", varargin{:}); end
    function out = cache(this,varargin);         out = this.formPath("matlab_cache", varargin{:}); end
    function out = fig(this,varargin);           out = this.formPath("matlab_fig", varargin{:}); end
    function out = sun_generated(this,varargin); out = this.formPath("sundials_generated", varargin{:}); end
    function out = sun_results(this,varargin);   out = this.formPath("sundials_results", varargin{:}); end
end
methods (Access=private)
    function out = formPath(this, append)
        arguments
            this(1,1)
        end
        arguments(Repeating)
            append(1,1) string
        end
        
        out = fullfile(this.base, append{:});
    end
end
end

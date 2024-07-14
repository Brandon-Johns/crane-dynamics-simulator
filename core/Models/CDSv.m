%{
PURPOSE
    Stores preset numerical values for use across all models
%}

classdef CDSv < handle & matlab.mixin.Copyable
properties (Access=protected)
    Build_Complete(1,1) logical = false;
end
methods
    function this = CDSv()
        %
    end

    function Set_BuildComplete(this)
        this.Build_Complete = true;
    end
end
end

%{
Abstract Class

PURPOSE
    Build a predefined crane model
    Solve this model or import the solution

NOTES
    Must call this.Build_SystemDescription before calling this.Solve or this.ImportSolution_...
%}

classdef CDSm < handle
properties (SetAccess=private, GetAccess=protected)
    % Load preset numerical values: constants, ICs, inputs, etc.
    Values(1,1) CDSv
end
properties (SetAccess=protected)
    sys CDS_SystemDescription
end
methods (Abstract)
    sys = Build_SystemDescription(this)
end
methods
    function this = CDSm(Values)
        this.Values = Values;
    end

    function SS = Solve(this, solverName, solveMode, solveOptions, overrideTimeVector)
        arguments
            this
            solverName(1,1) string = "auto"
            solveMode(1,1) string = "auto"
            solveOptions(1,1) CDS_Solver_Options = CDS_Solver_Options()
            overrideTimeVector(1,1) string {mustBeMember(overrideTimeVector, ["OptsSpecifyTime", "auto"])} = "auto"
        end
        if overrideTimeVector=="auto"
            solveOptions.time = [0, this.Values.t_max];
        end

        S = CDS_Solver(solveOptions);
        [t,x,xd] = S.Solve(this.sys, solverName, solveMode);

        SS = CDS_SolutionSim(this.sys, t,x,xd);
    end
    
    function SS = ImportSolution_Sundials(this, fileName)
        arguments
            this
            fileName(1,1) string
        end
        % Remove lagrange multipliers from state vector
        %   In case this is in error, it'll be validated by CDS_SolutionSim
        this.sys.params.SetStateVectorMode("withoutLambda");

        % Read in the CSV/txt results
        dataRaw = readmatrix(fileName);
        t_import = dataRaw(:, 1).';
        x_import = dataRaw(:, 2:end).';

        % Remove the rows of text after the data ends (solver stats)
        t = t_import(isfinite(t_import));
        x = x_import(:, isfinite(t_import));

        SS = CDS_SolutionSim(this.sys, t,x);
    end

    function SS = ImportSolution_Saved(this, fileName)
        % Validation provided in CDS_SolutionSaved
        SS = CDS_SolutionSaved(this.sys, fileName);
    end
end
end


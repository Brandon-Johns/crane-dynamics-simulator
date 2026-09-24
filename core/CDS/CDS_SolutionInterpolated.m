%{
PURPOSE
    Interpolate the post-processed solution data at different time coordinates

NOTES
    Alternatively to using this class, where possible, it is better to specify the desired solution time coordinates to the solver
    Doing so is more accurate than interpolation
    This class is mostly intended for experimental data, where specifying desired time coordinates is not possible

EXAMPLE
    % Given:
    %   SS: CDS_Solution that has already been built (for example, an experimental solution)
    %   t:  Times to interpolate the solution at

    SS_new = CDS_SolutionInterpolated(SS, t);
%}

classdef CDS_SolutionInterpolated < CDS_Solution
methods
    %**********************************************************************
    % Interface - Create & Initialise
    %***********************************
    % INPUT
    %   sol:   The solution to interpolate
    %   t_new: Times to interpolate the solution at
    function this = CDS_SolutionInterpolated(sol, t_new)
        arguments
            sol(1,1) CDS_Solution
            t_new(1,:) double
        end
        % NOTE:
        %   Different methods have different extrapolation behaviour
        %   If changing method, the NaN check may need to be changed
        interpolationMethod = "linear";

        % Save system description
        % New time vector
        this.sys = sol.sys;
        this.t = t_new;

        % Interpolate all coordinates
        %   Transpose and then back for interp1()
        this.qf    = this.interp1_allowEmpty(sol.t, sol.qf,    t_new, interpolationMethod);
        this.qf_d  = this.interp1_allowEmpty(sol.t, sol.qf_d,  t_new, interpolationMethod);
        this.qf_dd = this.interp1_allowEmpty(sol.t, sol.qf_dd, t_new, interpolationMethod);
        this.qi    = this.interp1_allowEmpty(sol.t, sol.qi,    t_new, interpolationMethod);
        this.qi_d  = this.interp1_allowEmpty(sol.t, sol.qi_d,  t_new, interpolationMethod);
        this.qi_dd = this.interp1_allowEmpty(sol.t, sol.qi_dd, t_new, interpolationMethod);
        this.ql    = this.interp1_allowEmpty(sol.t, sol.ql,    t_new, interpolationMethod);
        this.ql_d  = this.interp1_allowEmpty(sol.t, sol.ql_d,  t_new, interpolationMethod);
        this.Px    = this.interp1_allowEmpty(sol.t, sol.Px,    t_new, interpolationMethod);
        this.Py    = this.interp1_allowEmpty(sol.t, sol.Py,    t_new, interpolationMethod);
        this.Pz    = this.interp1_allowEmpty(sol.t, sol.Pz,    t_new, interpolationMethod);
        this.E     = this.interp1_allowEmpty(sol.t, sol.E,     t_new, interpolationMethod);
        this.K_mass           = this.interp1_allowEmpty(sol.t, sol.K_mass,           t_new, interpolationMethod);
        this.V_mass           = this.interp1_allowEmpty(sol.t, sol.V_mass,           t_new, interpolationMethod);
        this.V_linearSprings  = this.interp1_allowEmpty(sol.t, sol.V_linearSprings,  t_new, interpolationMethod);
        this.V_torsionSprings = this.interp1_allowEmpty(sol.t, sol.V_torsionSprings, t_new, interpolationMethod);

        % Warn for extrapolation
        if anynan(this.qf)
            warning("Solution contains NaN. This can be caused be extrapolation");
        end
    end
end
methods (Access=private)
    function valNew = interp1_allowEmpty(this, t, val, tNew, varargin)
        if isempty(val)
            % Initialise empty arrays with consistent sizes
            valNew = double.empty(0, numel(this.t));
            return
        end

        % NOTE
        %   Has weird behaviour for output size depending on input sizes - check documentation before changing
        valNew = interp1(t,val.', tNew, varargin{:}).';

        if isvector(valNew)
            valNew = valNew.';
        end
    end
end
end

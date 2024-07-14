%{
PURPOSE
    Interpolate the whole solution at different time coordinates
    Hold the post processed solution data

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
    %   SS: CDS_Solution that has already been built
    %   t:  Times to interpolate the solution at
    function this = CDS_SolutionInterpolated(sol, t_new)
        arguments
            sol(1,1) CDS_Solution
            t_new(1,:) double
        end
        interpolationMethod = "linear";

        % Extract params & points
        this.q_free   = sol.q_free;
        this.q_input  = sol.q_input;
        this.q_lambda = sol.q_lambda;
        this.p_all    = sol.p_all;
        this.p_mass   = sol.p_mass;

        % New time vector
        this.t = t_new;

        % Interpolate all coordinates
        %   Transpose and then back for interp1()
        this.qf    = this.interp1_allowEmpty(sol.t, sol.qf.',    t_new, interpolationMethod).';
        this.qf_d  = this.interp1_allowEmpty(sol.t, sol.qf_d.',  t_new, interpolationMethod).';
        this.qf_dd = this.interp1_allowEmpty(sol.t, sol.qf_dd.', t_new, interpolationMethod).';
        this.qi    = this.interp1_allowEmpty(sol.t, sol.qi.',    t_new, interpolationMethod).';
        this.qi_d  = this.interp1_allowEmpty(sol.t, sol.qi_d.',  t_new, interpolationMethod).';
        this.qi_dd = this.interp1_allowEmpty(sol.t, sol.qi_dd.', t_new, interpolationMethod).';
        this.ql    = this.interp1_allowEmpty(sol.t, sol.ql.',    t_new, interpolationMethod).';
        this.ql_d  = this.interp1_allowEmpty(sol.t, sol.ql_d.',  t_new, interpolationMethod).';
        this.K     = this.interp1_allowEmpty(sol.t, sol.K.',     t_new, interpolationMethod).';
        this.V     = this.interp1_allowEmpty(sol.t, sol.V.',     t_new, interpolationMethod).';
        this.E     = this.interp1_allowEmpty(sol.t, sol.E.',     t_new, interpolationMethod).';
        this.Px    = this.interp1_allowEmpty(sol.t, sol.Px.',    t_new, interpolationMethod).';
        this.Py    = this.interp1_allowEmpty(sol.t, sol.Py.',    t_new, interpolationMethod).';
        this.Pz    = this.interp1_allowEmpty(sol.t, sol.Pz.',    t_new, interpolationMethod).';
    end
end
methods (Access=private)
    function valNew = interp1_allowEmpty(~, t,val, tNew, varargin)
        if isempty(val)
            valNew=[];
            return
        end
        
        valNew = interp1(t,val, tNew, varargin{:});
    end
end
end

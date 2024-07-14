%{
PURPOSE
    Evaluate the analytic solution to a single point mass pendulum

NOTES
    Analytic solution
    https://en.wikipedia.org/wiki/Pendulum_(mathematics)
    https://people.brandeis.edu/~kuntawu/advanced_physics_laboratory/chaos_Neipp.pdf
        title={Exact solution for the nonlinear pendulum}
        author={Bel{\'e}ndez, Augusto and Pascual, Carolina and M{\'e}ndez, DI and Bel{\'e}ndez, Tarsicio and Neipp, Cristian}
%}

classdef CDSu_Analytic_1P
properties (Access=public)
    % Values added to satisfy mustBePositive (overwritten by constructor)
    LinkLength(1,1) double {mustBePositive} = 1
    gravity(1,1) double {mustBePositive} = 9.8

    % Initial angle (stable equilibrium at theta=0)
    theta_IC(1,1) double
end
methods
    function this = CDSu_Analytic_1P(l, g, t0)
        this.LinkLength = l;
        this.gravity = g;
        this.theta_IC = t0;
    end

    % Period: Small angle approx
    function period = Evaluate_Period_SmallAngleApprox(this)
        l = this.LinkLength;
        g = this.gravity;
        period = 2*pi*sqrt(l/g);
    end

    % Period: Exact solution
    function period = Evaluate_Period(this)
        l = this.LinkLength;
        g = this.gravity;
        t0 = this.theta_IC;
        period = 4*sqrt(l/g)*ellipticK((sin(t0/2))^2);
    end

    % Full signal: Exact solution
    function theta = Evaluate_Signal(this, time)
        arguments
            this(1,1)
            time double {mustBeVector}
        end
        l = this.LinkLength;
        g = this.gravity;
        t0 = this.theta_IC;
        w0 = sqrt(g/l); % NOTE: different definition across literature
        k = sin(t0/2);
        m = k^2;
        [sn,~,~] = ellipj(ellipticK(m)-w0*time, m);
        theta = 2*asin(k*sn);
    end
end
end

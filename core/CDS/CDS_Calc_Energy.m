%{
PURPOSE
    Generate expressions of total system energy/power

EXAMPLE
    % Given:
    %   params: CDS_Params
    %   theta_1: CDS_Param
    %   theta_2: CDS_Param
    %   theta_3: CDS_Param
    %   sys: CDS_SystemDescription
    % Find the total energy in a triple pendulum system as the difference between the
    %   Energy at the initial conditions
    %   Energy at the equilibrium configuration
    CE = CDS_Calc_Energy(sys);
    e_IC = CE.E0;
    e_equilibrium_vars = params.Subset(["theta_1"; "theta_2"; "theta_3"]).Sym;
    e_equilibrium_vals = [0;0;0];
    e_equilibrium = params.EvaluateSymExpr_StaticCondition(CE.E, 0, e_equilibrium_vars, e_equilibrium_vals);
    e_total = e_IC - e_equilibrium;
%}

classdef CDS_Calc_Energy < handle
properties (Access=private)
    sys CDS_SystemDescription
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % INPUT
    %   The system to calculate the energies of
    function this = CDS_Calc_Energy(sys)
        arguments
            sys(1,1) CDS_SystemDescription
        end
        this.sys = sys;
    end

    %**********************************************************************
    % Interface: Get
    %***********************************
    % Total potential energy
    % OUTPUT
    %   (symbolic expression) DIM[1,1]
    function out = V(this)
        arguments
            this(1,1)
        end
        out = sum(this.sys.points.Energy_V);
        out = out + sum(this.sys.linearSprings.Energy_V);
        out = out + sum(this.sys.torsionSprings.Energy_V);
    end

    % Total kinetic energy
    % OUTPUT
    %   (symbolic expression) DIM[1,1]
    function out = K(this)
        arguments
            this(1,1)
        end
        out = sum(this.sys.points.Energy_K);
    end

    % Total Rayleigh dissipation function
    % OUTPUT
    %   (symbolic expression) DIM[1,1]
    function out = D(this)
        arguments
            this(1,1)
        end
        out = sum(this.sys.linearDampers.Energy_D);
    end

    % Total system energy (E=K+V)
    % NOTE
    %   The mechanical energy, not the Hamiltonian
    % OUTPUT
    %   (symbolic expression) DIM[1,1]
    function out = E(this)
        arguments
            this(1,1)
        end
        out = this.K + this.V;
    end

    % Energy at initial conditions
    % OUTPUT
    %   (double) DIM[1,1]
    function out = V0(this)
        arguments
            this(1,1)
        end
        out=this.sys.params.EvaluateSymExpr_IC(this.V);
    end
    function out = K0(this)
        arguments
            this(1,1)
        end
        out=this.sys.params.EvaluateSymExpr_IC(this.K);
    end
    function out = E0(this)
        arguments
            this(1,1)
        end
        out=this.sys.params.EvaluateSymExpr_IC(this.E);
    end

    % Total time-rate of change of total system energy ( dE/dt = d[K+V]/dt )
    % OUTPUT
    %   (symbolic expression) DIM[1,1]
    function out = dEdt(this)
        arguments
            this(1,1)
        end
        out = this.sys.params.TotalDiff(this.E);
    end

    % Total time-rate of work done on the system
    % OUTPUT
    %   (symbolic expression) DIM[1,1]
    function out = dWdt(this)
        arguments
            this(1,1)
        end
        out = sum(this.sys.points.Power_dWdt);
        out = out + sum(this.sys.constraints.Power_dWdt);
        out = out + sum(this.sys.linearSprings.Power_dWdt);
        out = out + sum(this.sys.torsionSprings.Power_dWdt);
        out = out + sum(this.sys.linearDampers.Power_dWdt);
        out = out + sum(this.sys.pointForces.Power_dWdt);
        out = out + sum(this.sys.generalisedForces.Power_dWdt);
        out = out + this.dWdt_input;
    end

    % Total time-rate of work done on the system by the input generalised coordinates (by sys.params.q_input)
    % OUTPUT
    %   (symbolic expression) DIM[1,1]
    function out = dWdt_input(this)
        arguments
            this(1,1)
        end
        Q_input_sym = CDS_Solver_GenerateEquations().InverseDynamics(this.sys);
        out = Q_input_sym.' * this.sys.params.q_input.Sym(1);
    end
end
end

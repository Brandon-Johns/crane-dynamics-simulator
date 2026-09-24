%{
Intended for internal use only

PURPOSE
    Generate the equation of motion
%}

classdef CDS_Solver_GenerateEquations < handle
properties
    %
end
methods
    function this = CDS_Solver_GenerateEquations()
        %
    end

    %**********************************************************************
    % Interface
    %***********************************
    % Form: Euler-Lagrange equations from Lagrangian (2nd order ODEs)
    %   DAEs_EL = 0
    function DAEs_EL = EulerLagrange(this, sys)
        arguments
            this(1,1)
            sys(1,1) CDS_SystemDescription
        end
        q_free = sys.params.q_free.Sym;
        q_free_d = sys.params.q_free.Sym(1);
        q_swap = sys.params.q_SymSwap;
        q_swap_t = sys.params.q_SymSwap('t');
        lambda = sys.params.lambda.Sym;

        % Lagrangian (scalar)
        K = sum(sys.points.Energy_K);
        V = sum(sys.points.Energy_V);
        V = V + sum(sys.linearSprings.Energy_V);
        V = V + sum(sys.torsionSprings.Energy_V);
        L = K - V;

        % Rayleigh Dissipation function (scalar)
        D = sum(sys.linearDampers.Energy_D);

        % Generalised forces
        Qf = sum(sys.generalisedForces.Qf(sys), 2);

        % Point forces (array of vectors -> arrays of scalars)
        PF = sys.pointForces(:);
        Fx = PF.Fx;
        Fy = PF.Fy;
        Fz = PF.Fz;
        rx_force = PF.Point.x;
        ry_force = PF.Point.y;
        rz_force = PF.Point.z;

        % Constraints (array of scalars)
        C = sys.constraints.C;

        % System equations from Euler-Lagrange
        % Note: no equations for inputs, only generalised coordinates
        DAEs_EL = sym(zeros(length(q_free),1));
        for idx = 1:length(q_free)
            % dL/dq
            dLdq = diff(L, q_free(idx));

            % dL/d(q_d)
            dLdq_d = diff(L, q_free_d(idx));

            % d(dL/d(q_d))/dt
            dLdq_d = subs(dLdq_d, q_swap, q_swap_t);
            ddLdq_d_dt = diff(dLdq_d, sym('t','real'));
            ddLdq_d_dt = subs(ddLdq_d_dt, q_swap_t, q_swap);
            % TODO: rigorously test the following replacement code
            %ddLdq_d_dt = sys.params.TotalDiff(dLdq_d);

            % Dissipation
            % dD/d(q_d)
            dDdq_d = diff(D, q_free_d(idx));

            % Generalised forces
            Q = Qf(idx);

            % Point forces
            % Note: matrix multiplication here
            %   sum_j{F_j . d[r_j]/d[q]}
            Q = Q + (Fx.') * diff(rx_force, q_free(idx));
            Q = Q + (Fy.') * diff(ry_force, q_free(idx));
            Q = Q + (Fz.') * diff(rz_force, q_free(idx));

            % Lagrange multipliers
            % Note: matrix multiplication here
            %   sum_j{lambda_j*d(C_j)/dq}
            lambda_dCdq = (lambda.') * diff(C, q_free(idx));

            % System equations
            % Form: 0 = DAEs_EL
            DAEs_EL(idx) = ddLdq_d_dt - dLdq + dDdq_d + lambda_dCdq - Q;
        end
    end

    % Form: Constraint equations
    %   DEAs_C = 0
    function DAEs_C = Constraint(this, sys, mode)
        arguments
            this(1,1)
            sys(1,1) CDS_SystemDescription
            mode(1,1) string {mustBeMember(mode,["C_d","C_dd"])} = "C_d"
        end
        q = sys.params.q.Sym;
        q_swap = sys.params.q_SymSwap;
        q_swap_t = sys.params.q_SymSwap('t');

        % Constraint equations
        C = sys.constraints.C;
        C_t = subs(C, q_swap, q_swap_t);

        % dC/dt (matrix)
        C_dt = diff(C_t, sym('t','real'));
        C_d = subs(C_dt, q_swap_t, q_swap);
        % TODO: rigorously test the following replacement code
        %C_d = sys.params.TotalDiff(C);

        % Differentiate constraint equations
        if strcmp(mode, "C_d")
            DAEs_C = C_d;
        elseif strcmp(mode, "C_dd")
            % d^2C/dt^2 (matrix)
            C_ddt = diff(C_t, sym('t','real'), 2);
            C_dd = subs(C_ddt, q_swap_t, q_swap);
            % TODO: rigorously test the following replacement code
            % NOTE:
            %   It seems to produce a more verbose equation
            %   Perhaps double diff can be improved to collect terms better
            %C_dd = sys.params.TotalDiff(C_d);

            % Applying Baumgarte Stabilisation
            alpha = sys.BaumgarteStabilisation_alpha;
            beta = sys.BaumgarteStabilisation_beta;
            DAEs_C = C_dd + 2*alpha.*C_d + (beta.^2).*C;
        else
            error("Bad input: mode")
        end

        % When using Baumgarte Stabilisation, the condition C=0 is actually required
        % Only validating for the initial conditions. Any other state could potentially be inconsistent or out of bounds of validity
        % The method to normalise the constraint equation and the error threshold are somewhat arbitrary
        if ~isempty(C) && sys.BaumgarteStabilisation_beta~=0
            constraint_error = abs(sys.params.EvaluateSymExpr_IC( C ));
            constraint_scale = abs(sys.params.EvaluateSymExpr_IC( jacobian(C, q)*q ));
            for idxC = 1:length(C)
                if constraint_scale(idxC)==0; constraint_scale(idxC)=1; end
                if constraint_error(idxC) > 1e-10 * constraint_scale(idxC)
                    error("Generate Equations: Constraint equation at index %d does not satisfy the requirement C=0\nAt initial conditions: C = %g", idxC, constraint_error(idxC));
                end
            end
        end
    end

    % Euler-Lagrange formulation, directly rearranged to solve for q_free_dd
    % Form: x_d = f(t, x, u)
    function ODEs = EulerLagrangeReformed(this, sys)
        arguments
            this(1,1)
            sys(1,1) CDS_SystemDescription
        end
        % Remove lambda from state vector
        sys.params.SetStateVectorMode("withoutLambda")

        syms t real
        q = sys.params.q.Sym;
        q_d = sys.params.q.Sym(1);
        q_free = sys.params.q_free.Sym;
        q_free_d = sys.params.q_free.Sym(1);
        q_input = sys.params.q_input.Sym;
        q_input_d = sys.params.q_input.Sym(1);
        q_input_dd = sys.params.q_input.Sym(2);

        % Lagrangian (scalar)
        % Form: L(q, q_d, t)
        K = sum(sys.points.Energy_K);
        V = sum(sys.points.Energy_V);
        V = V + sum(sys.linearSprings.Energy_V);
        V = V + sum(sys.torsionSprings.Energy_V);
        L = K - V;

        % Rayleigh Dissipation function (scalar)
        % Form: D(q, q_d, t)
        D = sum(sys.linearDampers.Energy_D);

        % Generalised forces
        Qf = sum(sys.generalisedForces.Qf(sys), 2);

        % Point forces (array of vectors -> arrays of scalars)
        % Form: F(q, q_d, t)
        % Form: r(q, t)
        PF = sys.pointForces(:);
        Fx = PF.Fx;
        Fy = PF.Fy;
        Fz = PF.Fz;
        rx_force = PF.Point.x;
        ry_force = PF.Point.y;
        rz_force = PF.Point.z;

        % Constraints (array of scalars)
        % Form: C(q, t)
        C = sys.constraints.C;

        % Verify the assumptions on the arguments of each term
        % See mathematical notes on the method to form and solve the equations
        sys.params.isLessThanMaxDifferentialOrder(L, "ErrorOnFalse");
        sys.params.isLessThanMaxDifferentialOrder(Qf, "ErrorOnFalse");
        sys.params.isLessThanMaxDifferentialOrder(D, "ErrorOnFalse");
        sys.params.isLessThanMaxDifferentialOrder(Fx, "ErrorOnFalse");
        sys.params.isLessThanMaxDifferentialOrder(Fy, "ErrorOnFalse");
        sys.params.isLessThanMaxDifferentialOrder(Fz, "ErrorOnFalse");
        sys.params.isZeroDifferentialOrder(C, "ErrorOnFalse");
        sys.params.isZeroDifferentialOrder(rx_force, "ErrorOnFalse");
        sys.params.isZeroDifferentialOrder(ry_force, "ErrorOnFalse");
        sys.params.isZeroDifferentialOrder(rz_force, "ErrorOnFalse");

        % When using Baumgarte Stabilisation, the condition C=0 is actually required
        % Only validating for the initial conditions. Any other state could potentially be inconsistent or out of bounds of validity
        % The method to normalise the constraint equation and the error threshold are somewhat arbitrary
        if ~isempty(C) && sys.BaumgarteStabilisation_beta~=0
            constraint_error = abs(sys.params.EvaluateSymExpr_IC( C ));
            constraint_scale = abs(sys.params.EvaluateSymExpr_IC( jacobian(C, q)*q ));
            for idxC = 1:length(C)
                if constraint_scale(idxC)==0; constraint_scale(idxC)=1; end
                if constraint_error(idxC) > 1e-10 * constraint_scale(idxC)
                    error("Generate Equations: Constraint equation at index %d does not satisfy the requirement C=0\nAt initial conditions: C = %g", idxC, constraint_error(idxC));
                end
            end
        end

        % Matrices to use at solve-time
        % NOTES:
        %   jacobian(f,x) =
        %   d[f1]/d[x1] ... d[f1]/d[xn]
        %        .               .
        %   d[fm]/d[x1] ... d[fm]/d[xn]

        % DIM: [qf,qf]
        M = hessian(L, q_free_d);

        % DIM: [qf,C]
        A = jacobian(C, q_free).';

        % DIM: [qf,1]
        b_L =       jacobian(jacobian(L, q_free_d), q_input_d)*q_input_dd;
        b_L = b_L + jacobian(jacobian(L, q_free_d), q)*q_d;
        b_L = b_L + jacobian(jacobian(L, t), q_free_d).';
        b_L = b_L - jacobian(L, q_free).';
        b_D =       jacobian(D, q_free_d).';
        b_F =     - Qf;
        b_F = b_F - (jacobian(rx_force, q_free).')*Fx;
        b_F = b_F - (jacobian(ry_force, q_free).')*Fy;
        b_F = b_F - (jacobian(rz_force, q_free).')*Fz;
        b = b_L + b_D + b_F;

        % DIM: [C,1]
        %   Applying Baumgarte Stabilisation
        %   0 = C_dd + 2*alpha.*C_d + (beta.^2).*C;
        % Acceleration terms (excluding A)
        alpha = sys.BaumgarteStabilisation_alpha;
        beta = sys.BaumgarteStabilisation_beta;
        h =     jacobian(C, q_input)*q_input_dd;
        h = h + jacobian(jacobian(C, q)*q_d, q)*q_d;
        h = h + 2*jacobian(jacobian(C, t), q)*q_d;
        h = h + jacobian(jacobian(C, t), t);
        % Velocity terms
        h = h + 2*alpha.*( jacobian(C, q)*q_d + jacobian(C, t) );
        % Position terms
        h = h + (beta.^2).*C;

        ODEs = CDS_Solver_ODEs2;
        ODEs.M = M;
        ODEs.A = A;
        ODEs.b = b;
        ODEs.h = h;
    end

    % Euler-Lagrange formulation, directly arranged to solve for Q_input
    % Clarification
    %   Q_input is the equivalent force that acts on the system, as was caused by q_input
    %   This does not include any other forces (constraints, dampers, point forces, explicit time, etc)
    %   It is simply:
    %       Change all q_input to q_free
    %       Add force Q_input to compensate such that the same motion occurs
    % Form
    %   Q_input = f(t, x, u, lambda, q_free_dd)
    function Q_input = InverseDynamics(this, sys)
        arguments
            this(1,1)
            sys(1,1) CDS_SystemDescription
        end
        % First part identical to this.EulerLagrangeReformed()
        syms t real
        q = sys.params.q.Sym;
        q_d = sys.params.q.Sym(1);
        q_free = sys.params.q_free.Sym;
        q_free_d = sys.params.q_free.Sym(1);
        q_free_dd = sys.params.q_free.Sym(2); % Added for InverseDynamics
        lambda = sys.params.lambda.Sym;       % Added for InverseDynamics
        q_input = sys.params.q_input.Sym;
        q_input_d = sys.params.q_input.Sym(1);
        q_input_dd = sys.params.q_input.Sym(2);

        K = sum(sys.points.Energy_K);
        V = sum(sys.points.Energy_V) + sum(sys.linearSprings.Energy_V) + sum(sys.torsionSprings.Energy_V);
        L = K - V;
        D = sum(sys.linearDampers.Energy_D);
        PF = sys.pointForces(:);
        Fx = PF.Fx;
        Fy = PF.Fy;
        Fz = PF.Fz;
        rx_force = PF.Point.x;
        ry_force = PF.Point.y;
        rz_force = PF.Point.z;
        C = sys.constraints.C;

        sys.params.isLessThanMaxDifferentialOrder(L, "ErrorOnFalse");
        sys.params.isLessThanMaxDifferentialOrder(D, "ErrorOnFalse");
        sys.params.isLessThanMaxDifferentialOrder(Fx, "ErrorOnFalse");
        sys.params.isLessThanMaxDifferentialOrder(Fy, "ErrorOnFalse");
        sys.params.isLessThanMaxDifferentialOrder(Fz, "ErrorOnFalse");
        sys.params.isZeroDifferentialOrder(C, "ErrorOnFalse");
        sys.params.isZeroDifferentialOrder(rx_force, "ErrorOnFalse");
        sys.params.isZeroDifferentialOrder(ry_force, "ErrorOnFalse");
        sys.params.isZeroDifferentialOrder(rz_force, "ErrorOnFalse");

        % Inverse dynamics
        Q_input = hessian(L, q_input_d)*q_input_dd ...
            + jacobian(jacobian(L, q_input_d), q_free_d)*q_free_dd ...
            + jacobian(jacobian(L, q_input_d), q)*q_d ...
            + jacobian(jacobian(L, t), q_input_d).' ...
            - jacobian(L, q_input).' ...
            + jacobian(D, q_input_d).' ...
            + (jacobian(C, q_input).') * lambda;
            - (jacobian(rx_force, q_input).') * Fx ...
            - (jacobian(ry_force, q_input).') * Fy ...
            - (jacobian(rz_force, q_input).') * Fz;
    end
end
end

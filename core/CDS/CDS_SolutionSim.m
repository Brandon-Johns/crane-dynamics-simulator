%{
PURPOSE
    Post-process simulation solution data

EXAMPLE
    % Given
    %   sys: CDS_SystemDescription

    S = CDS_Solver;
    [t,x,xd] = S.Solve(sys);
    SS = CDS_SolutionSim(sys, t, x, xd);
%}

classdef CDS_SolutionSim < CDS_Solution
methods
    %**********************************************************************
    % Interface - Create & Initialise
    %***********************************
    % INPUT
    %   sys: The system that was solved
    %   t_sol:  Output 1 of CDS_Solver.Solve(sys)
    %   x_sol:  Output 2 of CDS_Solver.Solve(sys)
    %   xd_sol: Output 3 of CDS_Solver.Solve(sys)
    function this = CDS_SolutionSim(sys, t_sol,x_sol,xd_sol)
        arguments
            sys(1,1) CDS_SystemDescription
            t_sol(1,:) double
            x_sol(:,:) double
            xd_sol(:,:) double = nan(size(x_sol))
        end
        % Validate input: x_sol & xd_sol must be same size
        if ~all(size(x_sol)==size(xd_sol))
            error("Mismatching input sizes: x_sol and xd_sol should have the same size");
        end

        % Validate input: x_sol & xd_sol must match length of t_sol
        if length(t_sol)~=size(x_sol,2)
            if length(t_sol)==size(x_sol,1)
                x_sol = x_sol.';
                xd_sol = xd_sol.';
                warning("Mismatching input sizes => Automatically corrected with transpose");
            else
                error("Mismatching input sizes: x_sol and xd_sol are inconsistent with t_sol");
            end
        end

        % Validate input: state vector mode
        % Validate input: x_sol & xd_sol must match length of state vector
        if sys.params.StateVectorMode_differential_order_of_q_free==2
            error("State vector differential order of 2 is not supported. See setting: params.StateVectorMode_differential_order_of_q_free")
        end
        if length(sys.params.x)~=size(xd_sol,1)
            % Toggle lagrange multipliers
            xMode = sys.params.x_mode;
            if xMode=="withLambda"; try_xMode="withoutLambda"; else; try_xMode="withLambda"; end
            sys.params.SetStateVectorMode(try_xMode);
            if length(sys.params.x)==size(xd_sol,1)
                warning("Mismatching inputs => Automatically corrected with by setting state vector mode to: " + try_xMode);
            else
                sys.params.SetStateVectorMode(xMode);
                error("Mismatching inputs: x_sol is inconsistent with the length of the state vector");
            end
        end

        q_free = sys.params.q_free;
        q_input = sys.params.q_input;
        lambda = sys.params.lambda;
        numQF = numel(q_free);
        numLam = numel(lambda);
        numX = numel(sys.params.x); % According to current setting of xMode

        % Save system description
        % Save solution time
        this.sys = sys;
        this.t = t_sol;

        % Decompose state vector
        % IMPORTANT: MUST MATCH ORDER IN SOLVER, which uses x to determine order e.g. x0 = sys.params.x.x0;
        this.qf =     x_sol(numQF+1:2*numQF, :);
        this.qf_d =   x_sol(1:numQF, :);
        this.qf_dd = xd_sol(1:numQF,:);
        this.ql    =  x_sol(2*numQF+1:numX, :);
        this.ql_d  = xd_sol(2*numQF+1:numX, :);

        % Generate input
        this.qi    = zeros(numel(q_input), numel(this.t));
        this.qi_d  = zeros(numel(q_input), numel(this.t));
        this.qi_dd = zeros(numel(q_input), numel(this.t));
        for idxU = 1:length(q_input)
            this.qi(idxU,:) = q_input(idxU).q(t_sol);
            this.qi_d(idxU,:) = q_input(idxU).q_d(t_sol);
            this.qi_dd(idxU,:) = q_input(idxU).q_dd(t_sol);
        end

        xu = [q_free.Sym; q_free.Sym(1); q_input.Sym; q_input.Sym(1); q_input.Sym(2)];
        xu_sol = [this.qf; this.qf_d; this.qi; this.qi_d; this.qi_dd];

        % Evaluate lambda, if not found during solving
        if numLam~=0 && sys.params.x_mode=="withoutLambda"
            xMode = sys.params.x_mode;
            ODEs2_obj = CDS_Solver_GenerateEquations().EulerLagrangeReformed(sys); % This changes xMode
            sys.params.SetStateVectorMode(xMode);                                  % Restore xMode
            [q_free_dd, this.ql] = ODEs2_obj.BatchEvaluate_qdd_lambda(sys, t_sol, xu,xu_sol);

            % RE: lambda_d
            %   Has no current use
            %   Requires qe_ddd
            %   So for now, this.ql_d shall stay empty!
            %   If ever add it is added, then the integration test function OutputMayContainLambdaD() should be removed

            % Sanity check
            error_qfdd = max(abs(this.qf_dd - q_free_dd), [],'all');
            if error_qfdd > 1e-10 * max(abs(this.qf_dd), [],'all');
                error("Internal error. Inconsistent calculation of qf_dd. Absolute error = %g", error_qfdd)
            end
        end

        % Evaluate positions
        T_0n = sys.points.T_0n;
        this.Px = sys.params.EvaluateSymExpr(T_0n.x, t_sol, xu,xu_sol);
        this.Py = sys.params.EvaluateSymExpr(T_0n.y, t_sol, xu,xu_sol);
        this.Pz = sys.params.EvaluateSymExpr(T_0n.z, t_sol, xu,xu_sol);

        % Evaluate energies
        this.K_mass = sys.params.EvaluateSymExpr(this.sys.points.GetIfHasMass.Energy_K, t_sol, xu,xu_sol);
        this.V_mass = sys.params.EvaluateSymExpr(this.sys.points.GetIfHasMass.Energy_V, t_sol, xu,xu_sol);
        this.V_linearSprings  = sys.params.EvaluateSymExpr(sys.linearSprings.Energy_V,  t_sol, xu,xu_sol);
        this.V_torsionSprings = sys.params.EvaluateSymExpr(sys.torsionSprings.Energy_V, t_sol, xu,xu_sol);
        this.E = sum(this.K_mass, 1) + sum(this.V_mass, 1) + sum(this.V_linearSprings, 1) + sum(this.V_torsionSprings, 1);
    end
end
end

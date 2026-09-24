%{
Intended for internal use only

PURPOSE
    Used by CDS_Solver.Solve() with solveMode=["solveTime3"]
    Holds the partially formed ODEs
%}

classdef CDS_Solver_ODEs2 < handle
properties
    M(:,:) sym
    A(:,:) sym
    b(:,1) sym
    h(:,1) sym
end
methods
    function this = CDS_Solver_ODEs2()
        %
    end

    % Vectorised version of CDS_Solver_ODEs2_Eval.Evaluate()
    % INPUT
    %   t_sol
    %       (double) Array of times to evaluate the solution at
    %   xu:
    %       (symbolic variable) Defines order of variables in ux_sol
    %       Must contain at least [q_free.Sym; q_free.Sym(1); q_input.Sym; q_input.Sym(1); q_input.Sym(2)];
    %   xu_sol
    %       (double) [qf; qf_d; qi; qi_d; qi_dd];
    % OUTPUT
    %   qfdd
    %       (double) DIM[length(sys.params.q_free), length(t_sol)], where DIM1 order corresponds to sys.params.q_free.Sym(2)
    %   lambda
    %       (double) DIM[length(sys.params.lambda), length(t_sol)], where DIM1 order corresponds to sys.params.lambda
    function [qfdd, lambda] = BatchEvaluate_qdd_lambda(this, sys, t_sol, xu,xu_sol)
        num_t = numel(t_sol);
        num_qf = numel(sys.params.q_free);
        num_lam = numel(sys.params.lambda);

        M_3D = sys.params.EvaluateSymExpr(this.M, t_sol, xu,xu_sol, nDimsIn=2);
        A_3D = sys.params.EvaluateSymExpr(this.A, t_sol, xu,xu_sol, nDimsIn=2);
        b_3D = sys.params.EvaluateSymExpr(this.b, t_sol, xu,xu_sol, nDimsIn=2);
        h_3D = sys.params.EvaluateSymExpr(this.h, t_sol, xu,xu_sol, nDimsIn=2);
        M_inv_A_3D = pagemldivide(M_3D, A_3D); % This is M\A
        M_inv_b_3D = pagemldivide(M_3D, b_3D); % This is M\b
        A_tr_3D = pagetranspose(A_3D);         % This is A.'
        lambda_3D = pagemldivide( pagemtimes(A_tr_3D,M_inv_A_3D), (h_3D - pagemtimes(A_tr_3D,M_inv_b_3D)) );
        qfdd_3D = -pagemtimes(M_inv_A_3D,lambda_3D) - M_inv_b_3D;

        lambda = reshape(lambda_3D, [num_lam,num_t]);
        qfdd = reshape(qfdd_3D, [num_qf,num_t]);
    end
end
end

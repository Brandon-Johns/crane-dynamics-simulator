%{
Intended for internal use only

PURPOSE
    Used by CDS_Solver.Solve() with solveMode="solveTime3"
    Evaluates the equations of motion during solving
    this.Evaluate() is the function passed to the ODE solver
%}

classdef CDS_Solver_ODEs2_Eval < handle
properties (SetAccess=immutable)
    M_h(1,1) function_handle = @() "ERROR"
    A_h(1,1) function_handle = @() "ERROR"
    b_h(1,1) function_handle = @() "ERROR"
    h_h(1,1) function_handle = @() "ERROR"

    u_h(1,1) function_handle = @() "ERROR"
end
methods
    %**********************************************************************
    % Interface - Create & Initialise
    %***********************************
    function this = CDS_Solver_ODEs2_Eval(sys, ODEs)
        arguments
            sys(1,1) CDS_SystemDescription
            ODEs(1,1) CDS_Solver_ODEs2
        end
        x = sys.params.x.Sym;
        u = sys.params.u.Sym;
        c = sys.params.const.Sym;
        cNum = sys.params.const.Num;

        % Sub in constants
        M_semiNum = subs(ODEs.M, c, cNum);
        A_semiNum = subs(ODEs.A, c, cNum);
        b_semiNum = subs(ODEs.b, c, cNum);
        h_semiNum = subs(ODEs.h, c, cNum);

        % Save as anon functions
        this.u_h = sys.params.u.q_h;
        this.M_h = matlabFunction(M_semiNum,'Vars',{sym('t','real'), x, u});
        this.A_h = matlabFunction(A_semiNum,'Vars',{sym('t','real'), x, u});
        this.b_h = matlabFunction(b_semiNum,'Vars',{sym('t','real'), x, u});
        this.h_h = matlabFunction(h_semiNum,'Vars',{sym('t','real'), x, u});
    end

    %**********************************************************************
    % Interface - Called by Solver
    %***********************************
    function x_d = Evaluate(this, t, x)
        u = this.u_h(t);
        M = this.M_h(t, x, u);
        A = this.A_h(t, x, u);
        b = this.b_h(t, x, u);
        h = this.h_h(t, x, u);

        % Solve-time operations
        M_inv_A = M\A;
        M_inv_b = M\b;
        A_tr = A.';
        lambda = ( A_tr*M_inv_A ) \ ( h - A_tr*M_inv_b );
        q_free_dd = -M_inv_A*lambda - M_inv_b;

        % Form into 1st order ODE
        %   x_d = f(t, x, u)
        x_d = [q_free_dd; x(1:length(x)/2)];
    end
end
end

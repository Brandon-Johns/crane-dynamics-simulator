%{
Intended for internal use only

PURPOSE
    Used by CDS_Solver.Solve() with solveMode="solveTime2"
    Evaluates the equations of motion during solving
    this.Evaluate() is the function passed to the ODE solver
%}

classdef CDS_Solver_ODEs_Eval < handle
properties (SetAccess=immutable, GetAccess=private)
    % Set value in constructor
    Flag_withConstraint(1,1) logical = true
    
    M_order2_h(1,1) function_handle = @() "ERROR"
    fb_h(1,1) function_handle = @() "ERROR"
    fc_h(1,1) function_handle = @() "ERROR"
    fdT_h(1,1) function_handle = @() "ERROR"
    fe_h(1,1) function_handle = @() "ERROR"
    
    u_h(1,1) function_handle = @() "ERROR"
end
methods
    %**********************************************************************
    % Interface - Create & Initialise
    %***********************************
    function this = CDS_Solver_ODEs_Eval(sys, ODEs)
        arguments
            sys(1,1) CDS_SystemDescription
            ODEs(1,1) CDS_Solver_ODEs
        end
        x = sys.params.x.Sym;
        u = sys.params.u.Sym;
        c = sys.params.const.Sym;
        cNum = sys.params.const.Num;
        
        % Sub in constants
        M_order2_semiNum = subs(ODEs.M_order2, c, cNum);
        f_b_semiNum = subs(ODEs.f_b, c, cNum);
        f_c_semiNum = subs(ODEs.f_c, c, cNum);
        f_dT_semiNum = subs(ODEs.f_dT, c, cNum);
        f_e_semiNum = subs(ODEs.f_e, c, cNum);
        
        % Save as anon functions
        this.u_h = sys.params.u.q;
        this.M_order2_h = matlabFunction(M_order2_semiNum,'Vars',{sym('t'), x, u});
        this.fb_h = matlabFunction(f_b_semiNum,'Vars',{sym('t'), x, u});
        this.fc_h = matlabFunction(f_c_semiNum,'Vars',{sym('t'), x, u});
        this.fdT_h = matlabFunction(f_dT_semiNum,'Vars',{sym('t'), x, u});
        this.fe_h = matlabFunction(f_e_semiNum,'Vars',{sym('t'), x, u});
        
        % Set constraint mode
        this.Flag_withConstraint = strcmp(ODEs.modeConstraint, "withConstraint");
        
    end
    
    %**********************************************************************
    % Interface - Called by Solver
    %***********************************
    function x_d = Evaluate(this, t, x)
        u = this.u_h(t, x);
        
        M_order2 = this.M_order2_h(t, x, u);
        f_b = this.fb_h(t, x, u);
        f_c = this.fc_h(t, x, u);
        f_dT = this.fdT_h(t, x, u);
        f_e = this.fe_h(t, x, u);
        
        if this.Flag_withConstraint
            % Solve for lambda
            f_mb = M_order2\f_b;
            f_mc = M_order2\f_c;
            f_lambda = (f_e - f_dT*f_mc)/(f_dT*f_mb);

            % Form into 2nd order ODE
            %   q_dd = f(t, [q; q_d], u)
            q_free_dd = -f_mc - f_lambda*f_mb;
            
        else % No constraint
            q_free_dd = -M_order2\f_c;
        end
        
        % Form into 1st order ODE
        %   x_d = f(t, x, u)
        x_d = [q_free_dd; x(1:length(x)/2)];
    end
end
end

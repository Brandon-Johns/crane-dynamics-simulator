%{
Intended for internal use only

PURPOSE
    Rearrange the equation of motion into a form that is compatible with ODE solvers
%}

classdef CDS_Solver_ReformEquations < handle
properties
    %
end
methods
    function this = CDS_Solver_ReformEquations()
        %
    end
    
    %**********************************************************************
    % Interface
    %***********************************
    % Reform into: 0=f(t,x,x_d)
    % Make function of 't' and reduce differential order
    function DAEs_t = Implicit(this, sys, DAEs_EL, DAEs_C)
        q_free = sys.params.q_free;
        x_swap = sys.params.x_SymSwap();
        x_swap_t = sys.params.x_SymSwap('t');
        
        DAEs_EL_t = subs(DAEs_EL, x_swap, x_swap_t);
        DAEs_C_t = subs(DAEs_C, x_swap, x_swap_t);
        
        % Extra equations from reduction of order
        DAEs_OrderReducing_t = (q_free.Sym(0,'t',1) - q_free.Sym(1,'t'));
        
        % Form system of equation into matrix equation
        DAEs_LHS_t = [DAEs_EL_t; DAEs_OrderReducing_t; DAEs_C_t];
        DAEs_RHS_t = zeros(size(DAEs_LHS_t));
        DAEs_t = DAEs_LHS_t == DAEs_RHS_t;
    end
    
    % Reform into: M(t,x)*x_d=f(t,x)
    function [M, f] = MassMatrix(this, sys, DAEs_EL, DAEs_C)
        q_free_dd = sys.params.q_free.Sym(2);
        x = sys.params.x.Sym;
        numQF = length(q_free_dd);
        numX = length(x);
        
        M = zeros(numX,numX, 'sym');
        f = zeros(numX,1, 'sym');
        
        % EL equations
        [M(1:numQF,1:numQF), f(1:numQF)] = this.FormMatrixEquation(DAEs_EL, q_free_dd);
        
        % Extra equations from reduction of order
        M(numQF+1:2*numQF, numQF+1:2*numQF) = eye(numQF,numQF);
        f(numQF+1:2*numQF) = x(1:numQF);
        
        % Constraint equations
        %   I've double and triple checked this one. Should be good
        %   Wish I had a test case sufficiently complex to really test it though
        [M(2*numQF+1:numX,1:numQF), f(2*numQF+1:numX)] = this.FormMatrixEquation(DAEs_C, q_free_dd);
    end
    
    % Reform into: x_d=f(t,x)
    function ODEs = Solve(this, sys, DAEs_EL, DAEs_C, mode)
        if isempty(sys.params.lambda.Sym)...
                || isempty(DAEs_C)...
                || DAEs_C==0
            ODEs = Solve_NoConstraint(this, sys, DAEs_EL, mode);
        else
            ODEs = Solve_WithConstraint(this, sys, DAEs_EL, DAEs_C, mode);
        end
    end
end
methods (Access=private)
    % Reform into: x_d=f(t,x)
    % Assumes there is a constraint
    % Constraint must be double differentiated
    function ODEs = Solve_WithConstraint(this, sys, DAEs_EL, DAEs_C, mode)
        arguments
            this(1,1)
            sys(1,1)
            DAEs_EL(:,1)
            DAEs_C(1,1)
            mode(1,1) string {mustBeMember(mode,["setuptime","solvetime_anonfun","solvetime_object"])}
        end
        lambda = sys.params.lambda.Sym;
        q_free_d = sys.params.q_free.Sym(1);
        q_free_dd = sys.params.q_free.Sym(2);
        
        % EL equations
        [f_b, f_a] = this.FormMatrixFunction(DAEs_EL, lambda);
        [M_order2, f_c] = this.FormMatrixFunction(f_a, q_free_dd);
        
        % Constraint equations
        [f_dT, f_e] = this.FormMatrixFunction(DAEs_C, q_free_dd);
        
        % Remove lambda from state vector
        sys.params.SetStateVectorMode("withoutLambda")
        x = sys.params.x.Sym;
        u = sys.params.u.Sym;
        
        if strcmp(mode, "setuptime")
            % Solve for lambda
            f_mb = M_order2\f_b;
            f_mc = M_order2\f_c;
            f_lambda = (f_e - f_dT*f_mc)/(f_dT*f_mb);

            % Form into 2nd order ODE
            %   q_dd = f(t, [q; q_d], u)
            f_q_free_dd = -f_mc - f_lambda*f_mb;
            
            % Form into 1st order ODE
            %   x_d = f(t, x, u)
            x_d = [f_q_free_dd; q_free_d];
            
            % Sub in constants
            x_d_semiNum = subs(x_d, sys.params.const.Sym, sys.params.const.Num);
            
            % Create function handle for solver
            x_d_h = matlabFunction(x_d_semiNum,'Vars',{sym('t'), x, u});
            ODEs = x_d_h;
            
        elseif strcmp(mode, "solvetime_anonfun")
            % Sub in constants
            M_order2_semiNum = subs(M_order2, sys.params.const.Sym, sys.params.const.Num);
            f_b_semiNum = subs(f_b, sys.params.const.Sym, sys.params.const.Num);
            f_c_semiNum = subs(f_c, sys.params.const.Sym, sys.params.const.Num);
            f_dT_semiNum = subs(f_dT, sys.params.const.Sym, sys.params.const.Num);
            f_e_semiNum = subs(f_e, sys.params.const.Sym, sys.params.const.Num);
            
            % To compare: Anon functions or just call a function
            M_order2_h = matlabFunction(M_order2_semiNum,'Vars',{sym('t'), x, u});
            fb_h = matlabFunction(f_b_semiNum,'Vars',{sym('t'), x, u});
            fc_h = matlabFunction(f_c_semiNum,'Vars',{sym('t'), x, u});
            fdT_h = matlabFunction(f_dT_semiNum,'Vars',{sym('t'), x, u});
            fe_h = matlabFunction(f_e_semiNum,'Vars',{sym('t'), x, u});
            
            % Solve for lambda
            f_mb_h = @(t_,x_,u_) M_order2_h(t_,x_,u_) \ fb_h(t_,x_,u_);
            f_mc_h = @(t_,x_,u_) M_order2_h(t_,x_,u_) \ fc_h(t_,x_,u_);
            f_lambda_h = @(t_,x_,u_) ( fe_h(t_,x_,u_) - fdT_h(t_,x_,u_) * f_mc_h(t_,x_,u_) )/( fdT_h(t_,x_,u_) * f_mb_h(t_,x_,u_) );
            
            % Form into 2nd order ODE
            %   q_dd = f(t, [q; q_d], u)
            f_q_free_dd_h = @(t_,x_,u_) -f_mc_h(t_,x_,u_) - f_lambda_h(t_,x_,u_) * f_mb_h(t_,x_,u_);
            
            % Form into 1st order ODE
            %   x_d = f(t, x, u)
            x_d_h = @(t_,x_,u_) [f_q_free_dd_h(t_,x_,u_); x_(1:length(x_)/2)];
            ODEs = x_d_h;
            
        elseif strcmp(mode, "solvetime_object")
            % Create object for holding and evaluating the system equations
            ODEs = CDS_Solver_ODEs();
            ODEs.modeConstraint = "withConstraint";
            ODEs.M_order2 = M_order2;
            ODEs.f_b = f_b;
            ODEs.f_c = f_c;
            ODEs.f_dT = f_dT;
            ODEs.f_e = f_e;
            
        else
            error("Bad input: mode")
        end
    end
    
    % Reform into: x_d=f(t,x)
    % Assumes there is no constraint
    function ODEs = Solve_NoConstraint(this, sys, DAEs_EL, mode)
        arguments
            this(1,1)
            sys(1,1)
            DAEs_EL(:,1)
            mode(1,1) string {mustBeMember(mode,["setuptime","solvetime_anonfun","solvetime_object"])}
        end
        q_free_d = sys.params.q_free.Sym(1);
        q_free_dd = sys.params.q_free.Sym(2);
        
        % EL equations
        f_a = DAEs_EL;
        [M_order2, f_c] = this.FormMatrixFunction(f_a, q_free_dd);
        
        % Remove lambda from state vector (not that there should be any there)
        sys.params.SetStateVectorMode("withoutLambda")
        x = sys.params.x.Sym;
        u = sys.params.u.Sym;
        
        if strcmp(mode, "setuptime")
            % Form into 2nd order ODE
            %   q_dd = f(t, [q; q_d], u)
            f_q_free_dd = -M_order2\f_c;
            
            % Form into 1st order ODE
            %   x_d = f(t, x, u)
            x_d = [f_q_free_dd; q_free_d];
            
            % Sub in constants
            x_d_semiNum = subs(x_d, sys.params.const.Sym, sys.params.const.Num);
            
            % Create function handle for solver
            x_d_h = matlabFunction(x_d_semiNum,'Vars',{sym('t'), x, u});
            ODEs = x_d_h;
            
        elseif strcmp(mode, "solvetime_anonfun")
            % Sub in constants
            M_order2_semiNum = subs(M_order2, sys.params.const.Sym, sys.params.const.Num);
            f_c_semiNum = subs(f_c, sys.params.const.Sym, sys.params.const.Num);
            
            % To compare: Anon functions or just call a function
            M_order2_h = matlabFunction(M_order2_semiNum,'Vars',{sym('t'), x, u});
            fc_h = matlabFunction(f_c_semiNum,'Vars',{sym('t'), x, u});
            
            % Form into 2nd order ODE
            %   q_dd = f(t, [q; q_d], u)
            f_q_free_dd_h = @(t_,x_,u_) -M_order2_h(t_,x_,u_) \ fc_h(t_,x_,u_);
            
            % Form into 1st order ODE
            %   x_d = f(t, x, u)
            x_d_h = @(t_,x_,u_) [f_q_free_dd_h(t_,x_,u_); x_(1:length(x_)/2)];
            ODEs = x_d_h;
            
        elseif strcmp(mode, "solvetime_object")
            % Create object for holding and evaluating the system equations
            ODEs = CDS_Solver_ODEs();
            ODEs.modeConstraint = "noConstraint";
            ODEs.M_order2 = M_order2;
            ODEs.f_c = f_c;
            
        else
            error("Bad input: mode")
        end
    end
    
    %{
    For a set of 'm' number of functions f(x) = [f_1(x); ...; f_m(x)]
    which are linear of 'n' number of variables x = [x_1; ...; x_n]
        i.e. can be split into form: f_i(x) = b_j + a_j1*x_1 + a_j2*x_2 + ... + a_jn*x_n
             where a_ji and b_j are not functions of x_j for all i=[1,n], j=[1,m]
    Reform f(x) as
        f(x) = A*x + b             , DIMENSIONS: (m,n)*(n,1) + (m,1)
    where
        A = [a_11 ..., a_1n; ...; a_m1 ..., a_mn]
        b = [b_1 ...; b_m]
    %}
    function [A, b] = FormMatrixFunction(this, f, x)
        arguments
            this(1,1)
            f(:,1)
            x(:,1)
        end
        n = length(x);
        m = length(f);
        A = zeros(m,n, 'sym');
        b = zeros(m,1, 'sym');
        for idx_j = 1:m
            remainder = f(idx_j);
            
            for idx_i = 1:n
                % coeffs returns coefficients ordered by degree [0th, ..., highest]
                % In this case: [0th, 1st] or [0th] if not in equation
                split = coeffs(remainder, x(idx_i), 'All');

                if length(split)==2
                    A(idx_j,idx_i) = split(1); % Coefficient of the q_dd
                    remainder = split(2); % Remainder of equation
                elseif length(split)==1
                    remainder = split; % Remainder of equation
                else % length(split)==0
                    remainder = 0; % Remainder of equation
                end
            end

            % Remainder of equation that are not coefficients of any b_j
            b(idx_j) = remainder;
        end

        % This isn't a catch-all, but will help to prevent accidentally running stiff ODEs
        %   If this warning triggers, check the model's inertial resistance to wiggling around
        %   E.g. Swinging a massless pendulum
        %   E.g. A double pendulum, where only link 2 has mass (It's ok for link 1 to be massless if link 2 has moment of inertia though)
        %   These systems will make any ODE solver very unhappy
        %   Maybe also check for unused q_free
        % Test method
        %   https://en.wikipedia.org/wiki/Rank_(linear_algebra)#Properties
        %   Because we're doing symbolic calculations, many cases will get through unfortunately
        %   My first improvement would be to sub in all numeric values @ initial conditions, then check both rank and condition number
        %   ode45 does that during solving anyway though. Just have to run in a .m file (not mlx) so the warnings actually show
        rank_A = rank(A);
        if rank_A < min(size((A)))
            warningMsg = "Check your model's inertial resistance to wiggling around. Singular matrix in calculation";
            
            rank_Ab = rank([A,b]);
            if rank_A == rank_Ab
                warningMsg = warningMsg + " (Many solutions)";
            elseif rank_A == rank_Ab+1
                warningMsg = warningMsg + " (No solutions)";
            end
            warning(warningMsg);
        end
    end
    
    %{
    Similar to FormMatrixFunction(), but where
        f(x) represents the LHS of the equation f(x)=0
    Returns the matrix equation
        A*x = b             , DIMENSIONS: (m,n)*(n,1) = (m,1)
    %}
    function [A, b] = FormMatrixEquation(this, f, x)
        [A, b] = this.FormMatrixFunction(f, x);
        
        % Flip sign of remainder for move to other side of equation
        b = -b;
    end
end
end

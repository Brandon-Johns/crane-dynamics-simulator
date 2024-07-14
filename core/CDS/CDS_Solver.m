%{
PURPOSE
    Generate and solve the equations of motion
%}

classdef CDS_Solver < handle
properties (Access=private)
    options(1,1) CDS_Solver_Options
end
methods
    % INPUT
    %   options: (CDS_Solver_Options) Specify additional solver options
    function this = CDS_Solver(options)
        arguments
            options(1,1) CDS_Solver_Options = CDS_Solver_Options()
        end
        this.options = options;
    end
    
    %**********************************************************************
    % Interface - Solve
    %***********************************
    % INPUT
    %   sys:
    %       CDS_SystemDescription
    %   solverName:
    %       auto: ode45
    %       drawIC:   Skips solving, just passes through the ICs. For this mode, the output "xd_sol" is not correct
    %       sundials: (Requires "solveMode"="export") Export ODEs as C++ code for solving with the SUNDIALS CVODE solver
    %       (any standard Matlab solver): Solve with the Matlab solver
    %   solveMode:
    %       auto: Recommended. Choses the best available mode for the input system and chosen solver
    %       fullyImplicit: (Must be used by ode15i)                    Solve   0 = f(t,x,x_d)
    %       massMatrix: (0 constraints / 0 or 1 if solver allows DAEs) Solve   M(t,x) * x_d = f(t,x)
    %       setupTime:  (0 or 1 constraints) Solve   x_d = f(t,x)   where f is formed symbolically before solving
    %       solveTime:  (0 or 1 constraints) Solve   x_d = f(t,x)   where f is formed numerically during solving (via anonymous functions)
    %       solveTime2: (0 or 1 constraints) Solve   x_d = f(t,x)   where f is formed numerically during solving (via CDS_Solver_ODEs_Eval)
    %       export:     (0 or 1 constraints) Export .m or .cpp files to externally solve
    function [t_sol, x_sol, xd_sol] = Solve(this, sys, solverName, solveMode)
        arguments
            this(1,1)
            sys(1,1) CDS_SystemDescription
            solverName(1,1) string {mustBeMember(solverName, ["auto","drawIC","sundials", "ode45","ode23","ode113","ode78","ode89","ode15s","ode23t","ode23s","ode23tb","ode15i"])} = "auto"
            solveMode(1,1) string {mustBeMember(solveMode, ["auto","fullyImplicit","massMatrix","setupTime","solveTime","solveTime2","export"])} = "auto"
        end
        % Not intended to set solverName auto without also setting solveMode auto
        %   I could remove auto and set the default, but then functions calling this can't pass auto without pain
        if solverName=="auto" && solveMode~="auto"; solveMode="auto"; warning("Setting solveMode to auto"); end
        if solverName=="auto"
            if length(sys.params.lambda) <= 1
                solverName="ode45";
            else
                solverName="ode15i";
            end
        end
        
        % Override bad input & resolve "auto" for special solvers
        if solverName=="sundials"; solveMode="export"; end
        if solverName=="drawIC"; solveMode="drawIC"; end % User should specify "solveMode"="auto"
        if solverName=="ode15i"; solveMode="fullyImplicit"; end

        % Resolve "auto" for standard solvers
        if solveMode=="auto"
            if isempty(sys.params.lambda)
                solveMode = "massMatrix";
            else
                solveMode = "solveTime2";
            end
        end

        % Validate solveMode for standard solvers
        if solveMode=="fullyImplicit"; mustBeMember(solverName, "ode15i"); end
        if any(solveMode==["massMatrix", "setupTime", "solveTime", "solveTime2"])
            mustBeMember(solverName, ["ode45","ode23","ode113","ode78","ode89","ode15s","ode23t","ode23s","ode23tb"]);
        end
        if solveMode=="export"
            mustBeMember(solverName, ["sundials", "ode45","ode23","ode113","ode78","ode89","ode15s","ode23t","ode23s","ode23tb"]);
        end
        if     solveMode=="massMatrix"...
            && ~any(solverName == ["ode15s","ode23t"])...
            && ~isempty(sys.params.lambda)
            error("Mode 'massMatrix' may only be used with constraint equations for solver 'ode15s' or 'ode23t'. Input: " + solverName)
        end
        if solveMode=="massMatrix" && solverName=="ode23s"
            warning("Mode 'massMatrix' for solver 'ode23s' requires the mass matrix to be constant. This will not be checked for 'input' type parameters i.e. any instance of CDS_Params.Create('input', NAME)");
        end

        % Check version
        if any(solverName==["ode78","ode89"]) && isMATLABReleaseOlderThan("R2021b")
            error("Solvers 'ode78' and 'ode89' require Matlab R2021b or later")
        end

        % Set solve time span
        %   Because I'm using the ode output = solution struct,
        %   the ODE solvers will treat t_span as the 2 input version, effectively forcing
        %       t_span=[t_span(1), t_span(end)]
        %   => must use deval to change solution coordinates
        t_span = this.options.time;
        
        % Set solve options
        opt = odeset('RelTol',this.options.RelTol, 'AbsTol',this.options.AbsTol);
        opt = odeset(opt, 'Stats','on');
        if this.options.EventsIsActive
            opt = odeset(opt, 'Events',this.options.Events);
        end
        
        GenEquations = CDS_Solver_GenerateEquations;
        ReformEquations = CDS_Solver_ReformEquations;
        
        % Switch solveMode
        if solveMode=="fullyImplicit"
            % FORM:   0 = f(t, x, x_d)
            %         0 = g(t, x)
            % INPUT:  [f, g]
            % OUTPUT: x
            
            % Generate and form system equations
            [K, V] = GenEquations.Energy(sys);
            DAEs_EL = GenEquations.EulerLagrange(sys, K, V);
            DAEs_C = GenEquations.Constraint(sys, "C_d");
            DAEs_f_t = ReformEquations.Implicit(sys, DAEs_EL, DAEs_C);
            
            % Sub in constants
            DAEs_f_semiNum_t = subs(DAEs_f_t, sys.params.const.Sym, sys.params.const.Num);
            
            % Create function handle for ode solver
            DAEs_h1 = daeFunction(DAEs_f_semiNum_t, sys.params.x.Sym(0,"t"), sys.params.u.Sym);
            
            % Inject inputs into DAE
            u_h = sys.params.u.q;
            DAEs_h = @(t_,x_,x_d_) DAEs_h1(t_,x_,x_d_, u_h(t_,x_));
            
            % Create consistent set of ICs
            [x0,x_d0] = decic(DAEs_h, 0,...
                sys.params.x.x0, sys.params.x.x0_fixed,...
                sys.params.x.x_d0, sys.params.x.x_d0_fixed,...
                opt);
            sys.params.x.SetIC(x0, x_d0);
            
            fprintf('Modified initial conditions:\n')
            disp(table(sys.params.x.Str, x0, x_d0, 'VariableNames',["x","x(0)","x_d(0)"]));
            
            % Solve
            sol = ode15i(DAEs_h,t_span,x0,x_d0,opt);
            
        elseif solveMode=="massMatrix"
            % FORM:   M(t, x) * x_d = f(t, x)
            %         ode15s, ode23t: M can be singular
            %         ode23s:         M must be full rank and constant
            %         other solvers:  M must be full rank
            % INPUT:  M, f
            % OUTPUT: x
            
            % Generate and form system equations
            [K, V] = GenEquations.Energy(sys);
            DAEs_EL = GenEquations.EulerLagrange(sys, K, V);
            DAEs_C = GenEquations.Constraint(sys, "C_d");
            [DAEs_M, DAEs_f] = ReformEquations.MassMatrix(sys, DAEs_EL, DAEs_C);

            if solverName=="ode23s" && any(ismember(symvar(DAEs_M), sys.params.x.Sym))
                error("Mode 'massMatrix' for solver 'ode23s' requires the mass matrix to be constant.");
            end
            
            % Sub in constants
            DAEs_M_semiNum = subs(DAEs_M, sys.params.const.Sym, sys.params.const.Num);
            DAEs_f_semiNum = subs(DAEs_f, sys.params.const.Sym, sys.params.const.Num);
            
            % Create function handle for ode solver
            DAEs_M_h1 = matlabFunction(DAEs_M_semiNum, 'Vars',{sym('t'), sys.params.x.Sym, sys.params.u.Sym});
            DAEs_f_h1 = matlabFunction(DAEs_f_semiNum, 'Vars',{sym('t'), sys.params.x.Sym, sys.params.u.Sym});
            
            % Inject inputs into DAE
            u_h = sys.params.u.q;
            DAEs_M_h = @(t_,x_) DAEs_M_h1(t_, x_, u_h(t_,x_));
            DAEs_f_h = @(t_,x_) DAEs_f_h1(t_, x_, u_h(t_,x_));
            
            % Pass mass matrix to solver
            opt = odeset(opt, 'Mass',DAEs_M_h);
            
            % Solve
            x0 = sys.params.x.x0;
            sol = this.RunSolver(solverName, DAEs_f_h, t_span, x0, opt);
            
        elseif any(solveMode==["setupTime", "solveTime"])
            % FORM:   x_d = f(t, x)
            % INPUT:  f
            % OUTPUT: x
            
            % Generate and form system equations
            [K, V] = GenEquations.Energy(sys);
            DAEs_EL = GenEquations.EulerLagrange(sys, K, V);
            DAEs_C = GenEquations.Constraint(sys, "C_dd");
            if solveMode=="setupTime"
                DAEs_f_h1 = ReformEquations.Solve(sys, DAEs_EL, DAEs_C, "setuptime");
            else % solveMode=="solveTime"
                DAEs_f_h1 = ReformEquations.Solve(sys, DAEs_EL, DAEs_C, "solvetime_anonfun");
            end
            
            % Inject inputs into DAE
            u_h = sys.params.u.q;
            DAEs_f_h = @(t_,x_) DAEs_f_h1(t_, x_, u_h(t_,x_));
            
            % Solve
            x0 = sys.params.x.x0;
            sol = this.RunSolver(solverName, DAEs_f_h, t_span, x0, opt);
            
        elseif solveMode=="solveTime2"
            % FORM:   x_d = f(t, x)
            % INPUT:  f
            % OUTPUT: x
            
            % Generate and form system equations
            [K, V] = GenEquations.Energy(sys);
            DAEs_EL = GenEquations.EulerLagrange(sys, K, V);
            DAEs_C = GenEquations.Constraint(sys, "C_dd");
            ODEs_obj = ReformEquations.Solve(sys, DAEs_EL, DAEs_C, "solvetime_object");
            
            % Create handle to solver
            ODEs_f_obj = CDS_Solver_ODEs_Eval(sys, ODEs_obj);
            DAEs_f_h = @(t_,x_) ODEs_f_obj.Evaluate(t_,x_);
            
            % Solve
            x0 = sys.params.x.x0;
            sol = this.RunSolver(solverName, DAEs_f_h, t_span, x0, opt);
            
        elseif solveMode=="export"
            % FORM:   x_d = f(t, x)
            % INPUT:  f
            % OUTPUT: x
            
            % Generate and form system equations
            [K, V] = GenEquations.Energy(sys);
            DAEs_EL = GenEquations.EulerLagrange(sys, K, V);
            DAEs_C = GenEquations.Constraint(sys, "C_dd");
            ODEs_obj = ReformEquations.Solve(sys, DAEs_EL, DAEs_C, "solvetime_object");
            
            % Export Equations
            Exporter = CDS_Solver_ODEs_Export(sys, ODEs_obj, this.options);
            if solverName=="sundials"
                Exporter.Export_Sundials;
            else
                Exporter.Export_Matlab(solverName);
            end
            return
            
        elseif solveMode=="drawIC"
            % Skip solver, just pass through ICs
            % deval doesn't like me => create dummy sol struct
            sol = ode45(@(t,x)x, [0,eps], sys.params.x.x0, odeset('InitialStep',eps, 'maxstep',eps));
            
        else
            error('Bad input: solveMode')
        end
        
        % Interpolate solution to desired time coordinates
        %   Cut user specified time if solver exited early
        %   A warning is already issued by the solver, so no need to reissue
        if length(t_span)==2
            % Use the solution time coords generated by solver
            t_sol = sol.x; % Why they have to call it x, RIP
            
            % Limit against too many coords
            %   Because deval is quite slow
            if length(t_sol)>10000
                t_sol = linspace(t_sol(1), t_sol(end), 10000);
            end
        else
            % Use the user specified solution time coords
            t_sol = t_span;

            % Cut time if solver exited early
            if sol.x(end)<t_sol(end)
                t_sol = t_sol(t_sol<=sol.x(end));
            end
        end
        [x_sol, xd_sol] = deval(sol,t_sol);
    end
end
methods (Access=private)
    function sol = RunSolver(this, solverName, varargin)
        arguments
            this(1,1)
            solverName(1,1) string
        end
        arguments (Repeating)
            varargin
        end
        if     solverName=="ode45";   sol = ode45(varargin{:});
        elseif solverName=="ode23";   sol = ode23(varargin{:});
        elseif solverName=="ode113";  sol = ode113(varargin{:});
        elseif solverName=="ode78";   sol = ode78(varargin{:});
        elseif solverName=="ode89";   sol = ode89(varargin{:});
        elseif solverName=="ode15s";  sol = ode15s(varargin{:});
        elseif solverName=="ode23t";  sol = ode23t(varargin{:});
        elseif solverName=="ode23s";  sol = ode23s(varargin{:});
        elseif solverName=="ode23tb"; sol = ode23tb(varargin{:});
        else
            error('Bad input: solver')
        end
    end
end
end

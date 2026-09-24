%{
PURPOSE
    Generate and solve equations of motion from system descriptions
%}

classdef CDS_Solver < handle
properties (Access=private)
    options(1,1) CDS_Solver_Options
end
methods
    % INPUT
    %   Additional solver options
    function this = CDS_Solver(options)
        arguments
            options(1,1) CDS_Solver_Options = CDS_Solver_Options()
        end
        this.options = options;
    end

    %**********************************************************************
    % Interface - Solve
    %***********************************
    % NOTES
    %   Constraints and initial conditions (Relevant for solving DAEs only)
    %       These solver/mode pairs solve the equations as DAEs:
    %           "ode15i","fullyImplicit"
    %           "ode15s","massMatrix"
    %           "ode23t","massMatrix"
    %           "idas","massMatrix"
    %       Theory
    %           DAEs pair redundant degrees of freedom with additionally specified constraints that they must adhere to
    %           Users can specify any ICs, and these are not necessarily consistent with the constraints
    %           decic() is used to adjust the user specified ICs to enforce consistency
    %           This includes the ICs for lambda and q_free_dd
    %       In practice
    %           It's pretty good
    %           If any errors, try changing the 'fixed' ICs when using .SetIC()
    % INPUT
    %   sys
    %       The system to solve
    %   solverName
    %       "auto": ode45
    %       "drawIC":   Skips solving, just passes through the ICs. For this mode, the output "xd_sol" is not correct
    %       "sundials": (Requires "solveMode"="export") Export ODEs as C++ code for solving with the SUNDIALS CVODE solver
    %       (any standard Matlab solver): Solve with the Matlab solver
    %   solveMode
    %       "auto": Recommended. Choses the best available mode for the input system and chosen solver
    %       "fullyImplicit"
    %           (For ode15i) Solve   0 = f(t,x,x_d)
    %       "massMatrix"
    %           Solve   M(t,x) * x_d = f(t,x)
    %           (ode15s, ode23t, idas): Any number of constraints
    %           ode23s:                 0 constraints and M must be constant
    %           other solvers:          0 constraints
    %       "setupTime":  (0 or 1 constraints) Solve   x_d = f(t,x)   where f is formed symbolically before solving
    %       "solveTime":  (0 or 1 constraints) Solve   x_d = f(t,x)   where f is formed numerically during solving (via anonymous functions)
    %       "solveTime2": (0 or 1 constraints) Solve   x_d = f(t,x)   where f is formed numerically during solving (via CDS_Solver_ODEs_Eval)
    %       "solveTime3": (any constraints)    Solve   x_d = f(t,x)   where f is formed numerically during solving (via CDS_Solver_ODEs2_Eval)
    %       "export":     (0 or 1 constraints) Export .m or .cpp files to externally solve
    % OUTPUT
    %   t_sol  (double) DIM[1, numSolutionTime]
    %   x_sol  (double) DIM[length(sys.params.x), numSolutionTime]
    %   xd_sol (double) DIM[length(sys.params.x), numSolutionTime]
    function [t_sol, x_sol, xd_sol] = Solve(this, sys, solverName, solveMode)
        arguments
            this(1,1)
            sys(1,1) CDS_SystemDescription
            solverName(1,1) string {mustBeMember(solverName, ["auto","drawIC","sundials", "ode45","ode23","ode113","ode78","ode89","ode15s","ode23t","ode23s","ode23tb","ode15i","cvodesnonstiff","cvodesstiff","idas"])} = "auto"
            solveMode(1,1) string {mustBeMember(solveMode, ["auto","fullyImplicit","massMatrix","setupTime","solveTime","solveTime2","solveTime3","export"])} = "auto"
        end
        % Not intended to set solverName auto without also setting solveMode auto
        if solverName=="auto" && solveMode~="auto"
            solveMode="auto";
            warning("Setting solveMode to auto");
        end

        % Special solvers: Override bad input & resolve solveMode="auto"
        if solverName=="sundials"; solveMode="export"; end
        if solverName=="drawIC"; solveMode="drawIC"; end % User should specify "solveMode"="auto"
        if solverName=="ode15i"; solveMode="fullyImplicit"; end

        % Standard solvers: Resolve "auto"
        if solverName=="auto"; solverName="ode45"; end
        if solveMode=="auto"; solveMode = "solveTime3"; end

        % Standard solvers: Validate solveMode
        if solveMode=="fullyImplicit"; mustBeMember(solverName, "ode15i"); end
        if any(solveMode==["massMatrix", "setupTime", "solveTime", "solveTime2", "solveTime3"])
            mustBeMember(solverName, ["ode45","ode23","ode113","ode78","ode89","ode15s","ode23t","ode23s","ode23tb","cvodesnonstiff","cvodesstiff","idas"]);
        end
        if solveMode=="export"
            mustBeMember(solverName, ["sundials", "ode45","ode23","ode113","ode78","ode89","ode15s","ode23t","ode23s","ode23tb"]);
        end
        if solveMode=="massMatrix" && ~any(solverName == ["ode15s","ode23t","idas"]) && ~isempty(sys.params.lambda)
            error("Mode 'massMatrix' may only be used with constraint equations for solvers 'ode15s', 'ode23t', 'idas'. Input: " + solverName)
        end
        if solveMode=="massMatrix" && solverName=="ode23s"
            warning("Mode 'massMatrix' for solver 'ode23s' requires the mass matrix to be constant. This will not be checked for 'input' type parameters i.e. any instance of CDS_Params.Create('input', NAME)");
        end
        if any(solveMode==["setupTime", "solveTime", "solveTime2", "export"]) && numel(sys.params.lambda)>1
            error("The following modes permit a maximum of 1 constraint equation: setupTime, solveTime, solveTime2, export")
        end

        % Check version
        if any(solverName==["ode78","ode89"]) && isMATLABReleaseOlderThan("R2021b")
            error("Solvers 'ode78' and 'ode89' require Matlab R2021b or later")
        end
        if any(solverName==["cvodesnonstiff","cvodesstiff","idas"]) && isMATLABReleaseOlderThan("R2024b")
            error("Matlab interfaces to the SUNDIALS solvers requires Matlab R2024b or later")
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

            % Disable Baumgarte stabilisation
            %   This mode uses "C_d", which does not use Baumgarte stabilisation
            %   However, this.FindConsistentICs_WithIndex1DAE() uses "C_dd", which uses Baumgarte stabilisation
            %   So I turn it off to keep the ICs consistent with the solve method
            sys.SetConstraint_StabilisationFactors(0,0);

            % Generate and form system equations
            DAEs_EL = GenEquations.EulerLagrange(sys);
            DAEs_C = GenEquations.Constraint(sys, "C_d");
            [DAEs_h, Jacobians_h] = ReformEquations.Implicit(sys, DAEs_EL, DAEs_C);

            % Create consistent set of ICs
            [x0, x_d0] = this.FindConsistentICs_WithIndex1DAE(sys, opt);
            sys.params.x.SetIC(x0, x_d0);

            % Jacobian
            %   It doesn't seem to have a significant impact on solving
            %   Not that I investigated too thoroughly
            opt = odeset(opt, 'Jacobian',Jacobians_h);

            % Solve
            sol = this.RunSolver(solverName, DAEs_h,t_span,x0,x_d0,opt);

        elseif solveMode=="massMatrix"
            % FORM:   M(t, x) * x_d = f(t, x)
            %         ode15s, ode23t, idas: M can be singular
            %         ode23s:               M must be full rank and constant
            %         other solvers:        M must be full rank
            % INPUT:  M, f
            % OUTPUT: x

            % Disable Baumgarte stabilisation
            %   This mode uses "C_d", which does not use Baumgarte stabilisation
            %   However, this.FindConsistentICs_WithIndex1DAE() uses "C_dd", which uses Baumgarte stabilisation
            %   So I turn it off to keep the ICs consistent with the solve method
            sys.SetConstraint_StabilisationFactors(0,0);

            % Generate and form system equations
            DAEs_EL = GenEquations.EulerLagrange(sys);
            DAEs_C = GenEquations.Constraint(sys, "C_d");
            [DAEs_M, DAEs_f, ~] = ReformEquations.MassMatrix(sys, DAEs_EL, DAEs_C);

            if solverName=="ode23s" && any(ismember(symvar(DAEs_M), [sys.params.x.Sym; sym('t','real')]))
                error("Mode 'massMatrix' for solver 'ode23s' requires the mass matrix to be constant.");
            end

            % Sub in constants
            DAEs_M_semiNum = subs(DAEs_M, sys.params.const.Sym, sys.params.const.Num);
            DAEs_f_semiNum = subs(DAEs_f, sys.params.const.Sym, sys.params.const.Num);

            % Create function handle for ode solver
            DAEs_M_h1 = matlabFunction(DAEs_M_semiNum, 'Vars',{sym('t','real'), sys.params.x.Sym, sys.params.u.Sym});
            DAEs_f_h1 = matlabFunction(DAEs_f_semiNum, 'Vars',{sym('t','real'), sys.params.x.Sym, sys.params.u.Sym});

            % Inject inputs into DAE
            u_h = sys.params.u.q_h;
            DAEs_M_h = @(t_,x_) DAEs_M_h1(t_, x_, u_h(t_));
            DAEs_f_h = @(t_,x_) DAEs_f_h1(t_, x_, u_h(t_));

            % Pass mass matrix to solver
            opt = odeset(opt, 'Mass',DAEs_M_h);
            opt = odeset(opt, "MStateDependence","strong");

            % Jacobian:
            %   Disabled because the DAE test cases perform slightly worse when it is specified...
            %   Though I haven't tested it with index-1 DAEs yet
            %Jacobian_semiNum = subs(Jacobian, sys.params.const.Sym, sys.params.const.Num);
            %Jacobian_h1 = matlabFunction(Jacobian_semiNum, 'Vars',{sym('t','real'), sys.params.x.Sym, sys.params.u.Sym});
            %Jacobian_h = @(t_,x_) Jacobian_h1(t_, x_, u_h(t_));
            %opt = odeset(opt, 'Jacobian',Jacobian_h);

            % DAEs only: Find set of consistent set initial conditions
            if ~isempty(sys.params.lambda)
                [x0, x_d0] = this.FindConsistentICs_WithIndex1DAE(sys, opt);
                sys.params.x.SetIC(x0, x_d0);
                opt = odeset(opt, "InitialSlope",x_d0);
            end

            % Solve
            x0 = sys.params.x.x0;
            sol = this.RunSolver(solverName, DAEs_f_h, t_span, x0, opt);

        elseif any(solveMode==["setupTime", "solveTime"])
            % FORM:   x_d = f(t, x)
            % INPUT:  f
            % OUTPUT: x

            % Generate and form system equations
            DAEs_EL = GenEquations.EulerLagrange(sys);
            DAEs_C = GenEquations.Constraint(sys, "C_dd");
            if solveMode=="setupTime"
                ODEs_f_h1 = ReformEquations.Solve(sys, DAEs_EL, DAEs_C, "setuptime");
            else % solveMode=="solveTime"
                ODEs_f_h1 = ReformEquations.Solve(sys, DAEs_EL, DAEs_C, "solvetime_anonfun");
            end

            % Inject inputs into ODE
            u_h = sys.params.u.q_h;
            ODEs_f_h = @(t_,x_) ODEs_f_h1(t_, x_, u_h(t_));

            % Solve
            x0 = sys.params.x.x0;
            sol = this.RunSolver(solverName, ODEs_f_h, t_span, x0, opt);

        elseif solveMode=="solveTime2"
            % FORM:   x_d = f(t, x)
            % INPUT:  f
            % OUTPUT: x

            % Generate and form system equations
            DAEs_EL = GenEquations.EulerLagrange(sys);
            DAEs_C = GenEquations.Constraint(sys, "C_dd");
            ODEs_obj = ReformEquations.Solve(sys, DAEs_EL, DAEs_C, "solvetime_object");

            % Create handle to solver
            ODEs_f_obj = CDS_Solver_ODEs_Eval(sys, ODEs_obj);
            ODEs_f_h = @(t_,x_) ODEs_f_obj.Evaluate(t_,x_);

            % Solve
            x0 = sys.params.x.x0;
            sol = this.RunSolver(solverName, ODEs_f_h, t_span, x0, opt);

        elseif solveMode=="solveTime3"
            % FORM:   x_d = f(t, x)
            % INPUT:  f
            % OUTPUT: x

            % Generate and form system equations
            ODEs2_obj = GenEquations.EulerLagrangeReformed(sys);

            % Create handle to solver
            ODEs2_f_obj = CDS_Solver_ODEs2_Eval(sys, ODEs2_obj);
            ODEs_f_h = @(t_,x_) ODEs2_f_obj.Evaluate(t_,x_);

            % Solve
            x0 = sys.params.x.x0;
            sol = this.RunSolver(solverName, ODEs_f_h, t_span, x0, opt);

        elseif solveMode=="export"
            % FORM:   x_d = f(t, x)
            % INPUT:  f
            % OUTPUT: x

            % Generate and form system equations
            DAEs_EL = GenEquations.EulerLagrange(sys);
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

        if isfield(sol, "deval_shim")
            % Shim for new solver
            % As tempted as I am to abuse dot notation to override deval, this is a little safer
            [x_sol, xd_sol] = sol.deval_shim(t_sol);
        else
            [x_sol, xd_sol] = deval(sol,t_sol);

            % Address problems with deval
            %   For the case of time coordinates being specified (not just [start,end] times)
            %   The output of deval does not satisfy the ODE. There is large Numerical error between
            %       1) xd as output by deval
            %       2) xd as calculated by xd = ODEs2_f_h(t, x);
            %   Checking against analytic solutions shows that (2) is more accurate
            %       "CompareAnalytic_DampedHarmonic.m"
            %       "CompareAnalytic_InclinedPlane_1C"
            %   The Matlab documentation says that xd "indicates the slope of the interpolating function used by sol"
            %       I think this is good enough justification to override the output with the more accurate version
            %   For now, I only do this for ODEs
            if any(solveMode==["setupTime", "solveTime", "solveTime2", "solveTime3"])
                for idx = 1:length(t_sol)
                    xd_sol(:,idx) = ODEs_f_h(t_sol(idx), x_sol(:,idx));
                end
            end
        end
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
        elseif solverName=="ode15i";  sol = ode15i(varargin{:});
        elseif any(solverName==["cvodesnonstiff","cvodesstiff","idas"])
            % Shim for new solver interface
            ODEs_h = varargin{1};
            t_span = varargin{2};
            x0 =  varargin{3};
            opt =  varargin{4};
            solver = ode();
            solver.Solver = solverName;
            solver.ODEFcn = ODEs_h;
            solver.InitialTime = 0;
            solver.InitialValue = x0;
            if ~isempty(opt.InitialSlope); solver.InitialSlope = opt.InitialSlope; end
            solver.AbsoluteTolerance = opt.AbsTol;
            solver.RelativeTolerance = opt.RelTol;
            if ~isempty(opt.Mass)
                solver.MassMatrix = odeMassMatrix(MassMatrix=opt.Mass, StateDependence="strong");
            end
            if this.options.EventsIsActive
                solver.EventDefinition = odeEvent(EventFcn=opt.Events);
            end
            [interpolate_h, ODEResults] = solver.solutionFcn(t_span(1), t_span(end));
            % The output time is given as though t_span specifies start and end times only
            % If this is not true, then it is corrected by the use of deval later
            sol = struct;
            sol.x = ODEResults.Time;
            sol.deval_shim = @(t_) this.CreateShim_deval(interpolate_h, ODEs_h, t_);
        else
            error('Bad input: solver')
        end
    end

    % Shim for new solver interface
    % To use, create an anonymous function that binds all arguments expect t
    % NOTE
    %   Not compatible with fully implicit solvers
    function [x_sol, xd_sol] = CreateShim_deval(~, interpolate_h, ODEs_h, t)
        arguments
            ~
            interpolate_h(1,1) function_handle
            ODEs_h(1,1) function_handle
            t double {mustBeVector}
        end
        x_sol = interpolate_h(t);
        xd_sol = zeros(size(x_sol));
        for idx = 1:length(t)
            xd_sol(:,idx) = ODEs_h(t(idx), x_sol(:,idx));
        end
    end

    % Find a consistent set of ICs
    % Create and use ideal inputs in decic()
    %   Ideal inputs are index-1 DAEs with the Jacobian also specified
    %       Matlab requires this, but doesn't strictly enforce it
    %       Regardless, the underlying algorithm seems to require it
    %           Based on what I read about the sundials implementation
    %           Otherwise the solution to f(t,x,xd)=0 may not be unique
    %           And based on my testing, it would otherwise often converge on the wrong values
    %   To form index-1 DAEs:
    %       Use DAEs_C=C_dd
    %       Append more order reducing equations: 0 = qf_dd - d[qf_d]/dt
    %       Update state vector accordingly (make a mess of the codebase)
    % OUTPUT
    %   [x0, x_d0] are the found set of consistent ICs
    %   This function does not have any side effects
    function [x0, x_d0] = FindConsistentICs_WithIndex1DAE(this, sys, opt)
        arguments
            this(1,1)
            sys(1,1) CDS_SystemDescription
            opt(1,1) struct
        end
        GenEquations = CDS_Solver_GenerateEquations;
        ReformEquations = CDS_Solver_ReformEquations;

        % Generate and form system equations
        DAEs_EL = GenEquations.EulerLagrange(sys);
        DAEs_C = GenEquations.Constraint(sys, "C_dd"); % Must use C_dd, not C_d

        % Save old settings
        x_order_old = sys.params.StateVectorMode_differential_order_of_q_free;

        % Form index-1 DAEs
        sys.params.SetStateVectorMode_differential_order_of_q_free(2);
        [DAEs_h, Jacobians_h] = ReformEquations.Implicit(sys, DAEs_EL, DAEs_C);

        % Create consistent set of ICs
        %   The Jacobian seems to have a big impact here
        opt = odeset(opt, 'Jacobian',Jacobians_h);
        [x0, x_d0] = this.FindConsistentICs(sys, DAEs_h, opt);

        % Restore old settings and match output to original mode of the state vector
        %   The use of intersect matches the order even if I mess with the order of the x between modes
        x_sym_index1 = sys.params.x.Sym;
        sys.params.SetStateVectorMode_differential_order_of_q_free(x_order_old);
        x_sym = sys.params.x.Sym;
        [~, ~, idx_index1] = intersect(x_sym, x_sym_index1, 'stable');
        x0 = x0(idx_index1);
        x_d0 = x_d0(idx_index1);
    end

    % Find a consistent set of ICs
    % Wrapper for decic()
    % INPUT
    %   DAEs_h: Fully-implicit DAEs. Ideally they should be index-1
    %   opt:    ode options struct. The Jacobian will be used if set
    % OUTPUT
    %   [x0, x_d0] are the found set of consistent ICs
    %   This function does not have any side effects
    function [x0, x_d0] = FindConsistentICs(this, sys, DAEs_h, opt)
        arguments
            this(1,1)
            sys(1,1) CDS_SystemDescription
            DAEs_h(1,1) function_handle
            opt(1,1) struct
        end
        x = sys.params.x;

        % First try
        out = this.decic_NoError(DAEs_h, 0, x.x0, x.x0_fixed, x.x_d0, x.x_d0_fixed, opt);

        % If the Jacobians were specified, then try again without them
        if ~out.success && ~isempty(opt.Jacobian)
            warning("Unable to find a consistent set of initial conditions (1): Now trying without Jacobians")
            opt = odeset(opt, 'Jacobian',[]);
            out = this.decic_NoError(DAEs_h, 0, x.x0, x.x0_fixed, x.x_d0, x.x_d0_fixed, opt);
        end

        if out.success
            x0 = out.x0;
            x_d0 = out.x_d0;
            fprintf('Modified initial conditions:\n')
            disp(table(x.Str, x0, x_d0, 'VariableNames',["x","x(0)","x_d(0)"]));
        else
            % Pass through the unchanged ICs
            warning("Unable to find a consistent set of initial conditions (2): Now trying to solve anyway")
            x0 = x.x0;
            x_d0 = x.x_d0;
        end
    end

    function out = decic_NoError(~, varargin)
        out = struct;
        out.success = false;
        out.x0 = [];
        out.x_d0 = [];
        try
            [out.x0, out.x_d0] = decic(varargin{:});
            out.success = true;
        catch ME
            if ~strcmp(ME.identifier, 'MATLAB:decic:ConvergenceFail')
                ME.rethrow;
            end
        end
    end
end
end

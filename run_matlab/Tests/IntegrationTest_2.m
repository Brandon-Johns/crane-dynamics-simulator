%{
Written By: Brandon Johns
Date Version Created: 2024-03-31
Date Last Edited: 2024-03-31
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Integration test
    Validate using 1 constraint

Points
    O: the stationary origin
    A: the particle

%}
classdef IntegrationTest_2 < IntegrationTest
methods(Static)
    function out = Description()
        out = "Particle sliding down a frictionless inclined plane";
    end

    function Run(solverArgs, solverTol, validateTol)
        arguments
            solverArgs = {}
            solverTol = 1e-8
            validateTol = 1e-12
        end
        %**********************************************************************
        % Define System
        %***********************************
        mass = 4.59; % A somewhat random number
        gravity = 9.8;
        duration = 2.2;
        gradient = -3/4; % Slope is a 3:4:5 triangle because I can

        params = CDS_Params();
        points = CDS_Points(params);
        params.Create('free', 'Lx').SetIC(0); % Initial conditions should be consistent with the constraint
        params.Create('free', 'Ly').SetIC(0);
        params.Create('const', 'g').SetNum(gravity);

        constraint = Ly - gradient*Lx;

        T_OA = CDS_T('P', [Lx;Ly;0]);
        A = points.Create('A', mass).SetT_0n(T_OA);

        chains = {};
        g0 = [0; -g; 0];
        sys = CDS_SystemDescription(params, points, chains, g0);
        sys.SetConstraint(constraint);

        %**********************************************************************
        % Solve
        %***********************************
        SO = CDS_Solver_Options();
        SO.time = 0 : 0.2 : duration;
        SO.RelTol = solverTol;
        SO.AbsTol = solverTol;

        S = CDS_Solver(SO);
        [t,x,xd] = S.Solve(sys, solverArgs{:});

        SS = CDS_SolutionSim(sys, t, x, xd);
        SSg = CDS_Solution_GetData(SS);

        %**********************************************************************
        % Validate output
        %***********************************
        AssertTol_default = @(val_, val_true_) IntegrationTest.AssertTol(val_, val_true_, validateTol);
        AssertTol_relaxed = @(val_, val_true_) IntegrationTest.AssertTol(val_, val_true_, validateTol*1e2);
        AssertTol_zeros = @(val_) IntegrationTest.AssertTol_zeros(val_, validateTol);

        % Calculate known dynamics
        % x = x0 + v0*t + 0.5*a*t^2
        % v = v0 + a*t
        % E = 0.5*m*v^2
        slope_dx = 1;
        slope_dy = gradient;
        slope_ds = sqrt(1 + gradient^2);

        t_true = SO.time;
        xdd_true = (-gravity*(slope_dx*slope_dy/slope_ds^2))*ones(size(t_true));
        xd_true = xdd_true.*t_true;
        x_true = 0.5*xdd_true.*t_true.^2;
        ydd_true = (-gravity*(slope_dy^2/slope_ds^2))*ones(size(t_true));
        yd_true = ydd_true.*t_true;
        y_true = 0.5*ydd_true.*t_true.^2;
        Ek_true = 0.5*mass*(xd_true.^2 + yd_true.^2);
        Ev_true = gravity*mass*y_true;

        % Test solver output
        IntegrationTest.AssertEqual(t(end), duration)
        AssertTol_default(x(1,:), xd_true)
        AssertTol_default(x(2,:), yd_true)
        AssertTol_default(x(3,:), x_true)
        AssertTol_default(x(4,:), y_true)
        AssertTol_default(xd(1,:), xdd_true)
        AssertTol_default(xd(2,:), ydd_true)
        AssertTol_default(xd(3,:), xd_true)
        AssertTol_default(xd(4,:), yd_true)

        % Test solution structure
        IntegrationTest.AssertEqual(t, SS.t)
        IntegrationTest.AssertEqual_unordered(SS.q_free.Str, ["Lx","Ly"])
        AssertTol_default(SSg.q("Lx"), x_true)
        AssertTol_default(SSg.q("Ly"), y_true)
        AssertTol_default(SSg.qd("Lx"), xd_true)
        AssertTol_default(SSg.qd("Ly"), yd_true)
        AssertTol_default(SSg.qdd("Lx"), xdd_true)
        AssertTol_default(SSg.qdd("Ly"), ydd_true)
        assert(isempty(SS.q_input))
        assert(isempty(SS.qi))
        assert(isempty(SS.qi_d))
        assert(isempty(SS.qi_dd))
        if(IntegrationTest.OutputMayContainLambda(solverArgs))
            assert(numel(SS.q_lambda)==1)
            % The solver messes up the first element too much due to not being given good initial conditions
            % Just verify the size
            assert(all(size(SS.ql)==size(SS.t)))
            assert(all(size(SS.ql_d)==size(SS.t)))
        else
            assert(isempty(SS.q_lambda))
            assert(isempty(SS.ql))
            assert(isempty(SS.ql_d))
        end
        IntegrationTest.AssertEqual_unordered(SS.p_mass.NameShort, "A")
        AssertTol_relaxed(SS.K, Ek_true)
        AssertTol_relaxed(SS.V, Ev_true)
        AssertTol_zeros(SS.E)
        IntegrationTest.AssertEqual_unordered(SS.p_all.NameShort, SS.p_mass.NameShort)
        AssertTol_default(SS.Px, x_true)
        AssertTol_default(SS.Py, y_true)
        IntegrationTest.AssertZeros(SS.Pz)
    end
end
end

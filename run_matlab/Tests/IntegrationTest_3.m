%{
Written By: Brandon Johns
Date Version Created: 2024-03-31
Date Last Edited: 2024-03-31
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Integration test
    Validate using initial conditions (position and velocity)

Points
    O: the stationary origin
    A: the particle

%}
classdef IntegrationTest_3 < IntegrationTest
methods(Static)
    function out = Description()
        out = "Free-falling particle with initial velocity";
    end

    function Run(solverArgs, solverTol, validateTol)
        arguments
            solverArgs = {}
            solverTol = 1e-10
            validateTol = 1e-12
        end
        %**********************************************************************
        % Define System
        %***********************************
        mass = 4.59; % A somewhat random number
        gravity = 9.8;
        duration = 2.2;
        Lx_IC = -0.53;
        Ly_IC = 1.7;
        Lx_d_IC = 4.53;
        Ly_d_IC = 6.95;

        params = CDS_Params();
        points = CDS_Points(params);
        params.Create('free', 'Lx').SetIC(Lx_IC, Lx_d_IC); % Initial velocity conditions
        params.Create('free', 'Ly').SetIC(Ly_IC, Ly_d_IC);
        params.Create('const', 'g').SetNum(gravity);

        T_OA = CDS_T('P', [Lx;Ly;0]);
        A = points.Create('A', mass).SetT_0n(T_OA);

        chains = {};
        g0 = [0; -g; 0];
        sys = CDS_SystemDescription(params, points, chains, g0);

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
        AssertTol_zeros = @(val_) IntegrationTest.AssertTol_zeros(val_, validateTol);

        % Calculate known dynamics
        % x = x0 + v0*t + 0.5*a*t^2
        % v = v0 + a*t
        % E = 0.5*m*v^2
        t_true = SO.time;
        xdd_true = zeros(size(t_true));
        xd_true = Lx_d_IC*ones(size(t_true));
        x_true = Lx_IC + Lx_d_IC.*t_true;
        ydd_true = (-gravity)*ones(size(t_true));
        yd_true = Ly_d_IC + ydd_true.*t_true;
        y_true = Ly_IC + Ly_d_IC.*t_true + 0.5*ydd_true.*t_true.^2;
        Ek_true = 0.5*mass*(xd_true.^2 + yd_true.^2);
        Ev_true = gravity*mass*y_true;
        E_true = (Ek_true(1) + Ev_true(1))*ones(size(t_true));

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
        assert(isempty(SS.q_lambda))
        assert(isempty(SS.ql))
        assert(isempty(SS.ql_d))
        IntegrationTest.AssertEqual_unordered(SS.p_mass.NameShort, "A")
        AssertTol_default(SS.K, Ek_true)
        AssertTol_default(SS.V, Ev_true)
        AssertTol_default(SS.E, E_true)
        IntegrationTest.AssertEqual_unordered(SS.p_all.NameShort, SS.p_mass.NameShort)
        AssertTol_default(SS.Px, x_true)
        AssertTol_default(SS.Py, y_true)
        IntegrationTest.AssertZeros(SS.Pz)
    end
end
end

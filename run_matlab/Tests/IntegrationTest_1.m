%{
Written By: Brandon Johns
Date Version Created: 2024-03-31
Date Last Edited: 2024-03-31
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Integration test
    Validate core functionality

Points
    O: the stationary origin
    A: the particle

%}
classdef IntegrationTest_1 < IntegrationTest
methods(Static)
    function out = Description()
        out = "Free-falling particle";
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

        params = CDS_Params();
        points = CDS_Points(params);
        params.Create('free', 'Ly').SetIC(0);
        params.Create('const', 'g').SetNum(gravity);

        T_OA = CDS_T('P', [0;Ly;0]);
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
        xdd_true = (-gravity)*ones(size(t_true));
        xd_true = xdd_true.*t_true;
        x_true = 0.5*xdd_true.*t_true.^2;
        Ek_true = 0.5*mass*xd_true.^2;
        Ev_true = gravity*mass*x_true;

        % Test solver output
        IntegrationTest.AssertEqual(t(end), duration)
        AssertTol_default(x(2,:), x_true)
        AssertTol_default(x(1,:), xd_true)
        AssertTol_default(xd(2,:), xd_true)
        AssertTol_default(xd(1,:), xdd_true)

        % Test solution structure
        IntegrationTest.AssertEqual(t, SS.t)
        IntegrationTest.AssertEqual_unordered(SS.q_free.Str, "Ly")
        AssertTol_default(SS.qf, x_true)
        AssertTol_default(SS.qf_d, xd_true)
        AssertTol_default(SS.qf_dd, xdd_true)
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
        AssertTol_zeros(SS.E)
        IntegrationTest.AssertEqual_unordered(SS.p_all.NameShort, SS.p_mass.NameShort)
        IntegrationTest.AssertZeros(SS.Px)
        AssertTol_default(SS.Py, x_true)
        IntegrationTest.AssertZeros(SS.Pz)
    end
end
end

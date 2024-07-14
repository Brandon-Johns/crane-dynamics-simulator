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
    A: the point mass pendulum bob

%}
classdef IntegrationTest_4 < IntegrationTest
methods(Static)
    function out = Description()
        out = "Single point-mass pendulum";
    end

    function Run(solverArgs, solverTol, validateTol)
        arguments
            solverArgs = {}
            solverTol = 1e-10
            validateTol = 1e-6
        end
        %**********************************************************************
        % Define System
        %***********************************
        mass = 4.59; % A somewhat random number
        gravity = 9.8;
        duration = 10.2;
        theta_IC = 0.9*pi;
        L_OA_num = 1.5;

        params = CDS_Params();
        points = CDS_Points(params);
        params.Create('free', 'theta_1').SetIC(theta_IC);
        params.Create('const', 'L_OA').SetNum(L_OA_num);
        params.Create('const', 'g').SetNum(gravity);

        T_OO2 = CDS_T('atP', 'z', theta_1-sym(pi)/2, [0;0;0]);
        T_O2A = CDS_T('atP', 'z', 0, [L_OA;0;0]);

        T_OA = T_OO2*T_O2A;

        O = points.Create('O');
        A = points.Create('A', mass).SetT_0n(T_OA);

        chains = {[O,A]};
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
        % Analytic solution to a single point mass pendulum
        % E = 0.5*m*v^2
        t_true = SO.time;
        AS = CDSu_Analytic_1P(L_OA_num, gravity, theta_IC);
        theta_true = AS.Evaluate_Signal(t);
        x_true = L_OA_num*sin(theta_true);
        y_true = -L_OA_num*cos(theta_true);
        Ev_true = gravity*mass*y_true;
        Ek_true = Ev_true(1) - Ev_true;
        E_true = Ev_true(1) * ones(size(t_true));
        theta_d_true_abs = sqrt(abs(2*Ek_true/mass))/L_OA_num; % Will have more error due to sqrt

        % Test solver output
        IntegrationTest.AssertEqual(t(end), duration)
        AssertTol_default(abs(x(1,:)), theta_d_true_abs)
        AssertTol_default(x(2,:), theta_true)
        %AssertTol_default(xd(1,:), theta_dd_true) % Not analytically found
        AssertTol_default(abs(xd(2,:)), theta_d_true_abs)

        % Test solution structure
        IntegrationTest.AssertEqual(t, SS.t)
        IntegrationTest.AssertEqual_unordered(SS.q_free.Str, "theta_1")
        AssertTol_default(SSg.q("theta_1"), theta_true)
        AssertTol_default(abs(SSg.qd("theta_1")), theta_d_true_abs)
        %AssertTol_default(SSg.qdd("theta_1"), theta_dd_true) % Not analytically found
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
        IntegrationTest.AssertEqual_unordered(SS.p_all.NameShort, ["O", "A"])
        AssertTol_zeros(SSg.Px("O"))
        AssertTol_zeros(SSg.Py("O"))
        AssertTol_default(SSg.Px("A"), x_true)
        AssertTol_default(SSg.Py("A"), y_true)
        IntegrationTest.AssertZeros(SS.Pz)
    end
end
end

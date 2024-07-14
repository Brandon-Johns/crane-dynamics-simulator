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
    A: the point mass pendulum bob

%}
classdef IntegrationTest_5 < IntegrationTest
methods(Static)
    function out = Description()
        out = "4-parallel-Bar linkage with point-mass";
    end

    function Run(solverArgs, solverTol, validateTol)
        arguments
            solverArgs = {}
            solverTol = 1e-10
            validateTol = 1e-8
        end
        %**********************************************************************
        % Define System
        %***********************************
        mass = 4.59; % A somewhat random number
        gravity = 9.8;
        duration = 10.2;
        theta_IC = 0.4*pi;
        L_AB_num = 1.5;
        L_BC_num = 2.63;
        L_AD_num = L_BC_num;

        params = CDS_Params();
        points = CDS_Points(params);
        params.Create('free', 'theta_1').SetIC(theta_IC);
        params.Create('free', 'theta_2').SetIC(theta_IC);
        params.Create('const', 'L_AB').SetNum(L_AB_num);
        params.Create('const', 'L_BC').SetNum(L_BC_num);
        params.Create('const', 'L_AD').SetNum(L_AD_num);
        params.Create('const', 'g').SetNum(gravity);

        T_AA2 = CDS_T('atP', 'z', -(sym(pi/2) - theta_1), [0;0;0]);
        T_A2B = CDS_T('atP', 'z', sym(pi/2) - theta_2, [L_AB;0;0]);
        T_BG = CDS_T('atP', 'z', 0, [L_BC/2;0;0]);
        T_BC = CDS_T('atP', 'z', 0, [L_BC;0;0]);
        T_AD = CDS_T('atP', 'z', 0, [L_AD;0;0]);

        T_AC = T_AA2*T_A2B*T_BC;
        T_DA = T_AD.Inv;
        T_DC = T_DA*T_AC;

        % Invert T_DC for P_CD in terms of independent vars
        T_CD = T_DC.Inv;
        P_CD = T_CD.P;

        % Solve dependent transformations - Solved by hand
        se = @(x) simplify(expand(x));
        psi_1 = atan2(P_CD(2),P_CD(1));
        a_CD = se(sqrt(P_CD(2)^2 + P_CD(1)^2));

        % Forward transforms in terms of independent variables
        T_CC2 = CDS_T('atP', 'z', psi_1, [0;0;0]);
        T_C2D = CDS_T('atP', 'z', 0, [a_CD;0;0]);

        T_AB = T_AA2*T_A2B;
        T_AC = T_AB*T_BC;
        T_AD = T_AC*T_CC2*T_C2D;
        T_AG = T_AB*T_BG;
        A = points.Create('A');
        B = points.Create('B').SetT_0n(T_AB);
        C = points.Create('C').SetT_0n(T_AC);
        D = points.Create('D').SetT_0n(T_AD);
        G = points.Create('G', mass).SetT_0n(T_AG);

        chains = {[A, B, C, D]};
        g0 = [0; -g; 0];
        sys = CDS_SystemDescription(params, points, chains, g0);

        % Using this as a constraint allows the bars to invert when passing through singularity (@theta1 = 0.5*pi)
        %   Technically feasible, but not what I'm after
        %   Safe to enable for: theta_IC < 0.5*pi
        sys.SetConstraint(a_CD);

        % Simpler constraint, but prevents the linkage from inverting and still tests the formulation fine
        %sys.SetConstraint(theta_1-theta_2);

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

        % Calculate known dynamics
        % Analytic solution to a single point mass pendulum
        % E = 0.5*m*v^2
        AS = CDSu_Analytic_1P(L_AB_num, gravity, theta_IC);
        theta_true = AS.Evaluate_Signal(t);

        % Test solver output
        IntegrationTest.AssertEqual(t(end), duration)

        % Test solution structure
        IntegrationTest.AssertEqual(t, SS.t)
        AssertTol_default(SSg.q("theta_1"), theta_true)
        AssertTol_default(SSg.q("theta_1"), SSg.q("theta_2"))
    end
end
end

%{
Written By: Brandon Johns
Date Version Created: 2024-09-02
Status: Complete
Date Last Edited: 2026-03-21
Simulator: CDS

%%% PURPOSE %%%
Integration test
    Validate using 1 torsion spring
    Validate with moment of inertia, and with centre of mass not at centre of rotation

Locations
    O: stationary origin (pin joint)
    A: centre of mass of the rigid body

Components
    OA: The spring at O, joining to the link OA

%}
classdef IntegrationTest_7 < IntegrationTest
methods(Static)
    function out = Description()
        out = "1D Rotary Spring-Inertia System";
    end

    function Run(solverArgs, solverTol, validateTol, thetaNNum, theta_IC, theta_d_IC)
        arguments
            solverArgs = {}
            solverTol = 1e-10
            validateTol = 1e-7
            thetaNNum = 0
            theta_IC = 5
            theta_d_IC = 0
        end
        %**********************************************************************
        % Define System
        %***********************************
        mass = 0.459; % A somewhat random number
        Izz = 4.27;
        gravity = 9.8;
        duration = 3.2;
        kNum = 3.54;
        L1Num = 4.32;
        %thetaNNum = 5;
        %theta_IC = 0;
        %theta_d_IC = 0;

        % Moment of inertia: (given) + (particle)
        Izz_total = Izz + mass*L1Num^2;

        sys = CDS_SystemDescription();
        params = sys.params;
        params.Create('free', 'theta').SetIC(theta_IC, theta_d_IC);
        params.Create('const', 'L_1').SetNum(L1Num);
        params.Create('const', 'g').SetNum(gravity);
        params.Create('const', 'k').SetNum(kNum);
        params.Create('const', 'thetaN').SetNum(thetaNNum);

        T_OO2 = CDS_T('at', 'z', theta);
        T_O2A = CDS_T('P', [L_1;0;0]);
        T_OA = T_OO2 * T_O2A;
        momentOfInertia = [9999,9999,Izz];
        A = sys.CreatePoint('A', mass, momentOfInertia).SetT_0n(T_OA);

        sys.SetChains();
        sys.SetGravity([0; 0; -g]);

        sys.CreateTorsionSpring("OA").SetAngle(theta).SetSpringConstant(k).SetNaturalAngle(thetaN);

        %**********************************************************************
        % Solve
        %***********************************
        SO = CDS_Solver_Options();
        SO.time = 0 : 0.05 : duration;
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
        %   EOM:
        %       0 = m*x_dd + k*(x-thetaN)
        %   Standard form:
        %       m*x_dd + k*x = k*thetaN
        %   Solution
        %       Homogeneous solution is of a harmonic oscillator
        %       Particular solution is for a zero degree polynomial (a constant)
        %   Energy
        %       Ek = 0.5*m*v^2
        %       Ev = Es
        %       Es = 0.5*k*(theta-thetaN).^2;
        w = sqrt(kNum/Izz_total);
        theta_true = (theta_IC - thetaNNum)*cos(w*t) + (theta_d_IC/w)*sin(w*t) + thetaNNum;
        theta_d_true = -w*(theta_IC - thetaNNum)*sin(w*t) + theta_d_IC*cos(w*t);
        theta_dd_true = -w*w*(theta_IC - thetaNNum)*cos(w*t) - w*theta_d_IC*sin(w*t);
        Ek_true = 0.5*Izz_total*(theta_d_true.^2);
        Eg_true = zeros(size(Ek_true));
        Es_true = 0.5*kNum*(theta_true-thetaNNum).^2;
        E_true = Ek_true + Eg_true + Es_true;

        % Test solver output
        IntegrationTest.AssertEqual(t(end), duration)
        AssertTol_default(x(2,:), theta_true)
        AssertTol_default(x(1,:), theta_d_true)
        AssertTol_default(xd(2,:), theta_d_true)
        AssertTol_default(xd(1,:), theta_dd_true)

        % Test system structure
        IntegrationTest.AssertEqual_unordered(SS.sys.params.q_free.Str, "theta")
        assert(isempty(SS.sys.params.q_input))
        assert(isempty(SS.sys.params.lambda))
        IntegrationTest.AssertEqual_unordered(SS.sys.points.Name, "A")
        IntegrationTest.AssertEqual_unordered(SS.sys.points.GetIfHasMass.Name, "A")
        assert(isempty(SS.sys.linearSprings))
        IntegrationTest.AssertEqual_unordered(SS.sys.torsionSprings.Name, "OA")

        % Test solution structure
        IntegrationTest.AssertEqual(t, SS.t)
        AssertTol_default(SS.qf, theta_true)
        AssertTol_default(SS.qf_d, theta_d_true)
        AssertTol_default(SS.qf_dd, theta_dd_true)
        assert(isempty(SS.qi))
        assert(isempty(SS.qi_d))
        assert(isempty(SS.qi_dd))
        assert(isempty(SS.ql))
        assert(isempty(SS.ql_d))
        AssertTol_default(SS.K_mass, Ek_true)
        AssertTol_default(SS.V_mass, Eg_true)
        assert(isempty(SS.V_linearSprings))
        AssertTol_default(SS.V_torsionSprings, Es_true)
        AssertTol_default(SS.E, E_true)
        AssertTol_default(SS.Px, L1Num*cos(theta_true))
        AssertTol_default(SS.Py, L1Num*sin(theta_true))
        IntegrationTest.AssertZeros(SS.Pz)
    end
end
end

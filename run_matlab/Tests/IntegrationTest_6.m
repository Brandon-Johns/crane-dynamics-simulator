%{
Written By: Brandon Johns
Date Version Created: 2024-08-30
Status: Complete
Date Last Edited: 2026-03-21
Simulator: CDS

%%% PURPOSE %%%
Integration test
    Validate using 1 spring

Points
    O: the stationary origin
    A: the particle

Components
    OA: The spring joining O and A

%}
classdef IntegrationTest_6 < IntegrationTest
methods(Static)
    function out = Description()
        out = "1D Spring-Mass System";
    end

    function Run(solverArgs, solverTol, validateTol, LnNum, Ly_IC, Ly_d_IC)
        arguments
            solverArgs = {}
            solverTol = 1e-10
            validateTol = 1e-7
            LnNum = 0
            Ly_IC = 5
            Ly_d_IC = 0
        end
        %**********************************************************************
        % Define System
        %***********************************
        mass = 0.459; % A somewhat random number
        gravity = 9.8;
        duration = 3.2;
        kNum = 3.54;
        %LnNum = 5;
        %Ly_IC = 0;
        %Ly_d_IC = 0;

        sys = CDS_SystemDescription();
        params = sys.params;
        params.Create('free', 'Ly').SetIC(Ly_IC, Ly_d_IC);
        params.Create('const', 'g').SetNum(gravity);
        params.Create('const', 'k').SetNum(kNum);
        params.Create('const', 'Ln').SetNum(LnNum);

        T_OA = CDS_T('P', [0;Ly;0]);
        A = sys.CreatePoint('A', mass).SetT_0n(T_OA);

        sys.SetChains();
        sys.SetGravity([0; -g; 0]);

        sys.CreateLinearSpring("OA").SetLength(Ly).SetSpringConstant(k).SetNaturalLength(Ln);

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
        %       0 = m*x_dd + k*(x-Ln) + m*g
        %   Standard form:
        %       m*x_dd + k*x = k*Ln - m*g
        %   Solution
        %       Homogeneous solution is of a harmonic oscillator
        %       Particular solution is for a zero degree polynomial (a constant)
        %   Energy
        %       Ek = 0.5*m*v^2
        %       Ev = Eg + Es
        %       Eg = m*g*h
        %       Es = 0.5*k*(L-Ln).^2;
        w = sqrt(kNum/mass);
        y_true = (Ly_IC - LnNum + mass*gravity/kNum)*cos(w*t) + (Ly_d_IC/w)*sin(w*t) + LnNum - mass*gravity/kNum;
        yd_true = -w*(Ly_IC - LnNum + mass*gravity/kNum)*sin(w*t) + Ly_d_IC*cos(w*t);
        ydd_true = -w*w*(Ly_IC - LnNum + mass*gravity/kNum)*cos(w*t) - w*Ly_d_IC*sin(w*t);
        Ek_true = 0.5*mass*(yd_true.^2);
        Eg_true = gravity*mass*y_true;
        Es_true = 0.5*kNum*(y_true-LnNum).^2;
        E_true = Ek_true + Eg_true + Es_true;

        % Test solver output
        IntegrationTest.AssertEqual(t(end), duration)
        AssertTol_default(x(2,:), y_true)
        AssertTol_default(x(1,:), yd_true)
        AssertTol_default(xd(2,:), yd_true)
        AssertTol_default(xd(1,:), ydd_true)

        % Test system structure
        IntegrationTest.AssertEqual_unordered(SS.sys.params.q_free.Str, "Ly")
        assert(isempty(SS.sys.params.q_input))
        assert(isempty(SS.sys.params.lambda))
        IntegrationTest.AssertEqual_unordered(SS.sys.points.Name, "A")
        IntegrationTest.AssertEqual_unordered(SS.sys.points.GetIfHasMass.Name, "A")
        IntegrationTest.AssertEqual_unordered(SS.sys.linearSprings.Name, "OA")
        assert(isempty(SS.sys.torsionSprings))

        % Test solution structure
        IntegrationTest.AssertEqual(t, SS.t)
        AssertTol_default(SS.qf, y_true)
        AssertTol_default(SS.qf_d, yd_true)
        AssertTol_default(SS.qf_dd, ydd_true)
        assert(isempty(SS.qi))
        assert(isempty(SS.qi_d))
        assert(isempty(SS.qi_dd))
        assert(isempty(SS.ql))
        assert(isempty(SS.ql_d))
        AssertTol_default(SS.K_mass, Ek_true)
        AssertTol_default(SS.V_mass, Eg_true)
        AssertTol_default(SS.V_linearSprings, Es_true)
        assert(isempty(SS.V_torsionSprings))
        AssertTol_default(SS.E, E_true)
        IntegrationTest.AssertZeros(SS.Px)
        AssertTol_default(SS.Py, y_true)
        IntegrationTest.AssertZeros(SS.Pz)
    end
end
end

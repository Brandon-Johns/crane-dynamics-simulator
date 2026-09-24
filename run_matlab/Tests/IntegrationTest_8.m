%{
Written By: Brandon Johns
Date Version Created: 2024-09-11
Status: Complete
Date Last Edited: 2026-03-21
Simulator: CDS

%%% PURPOSE %%%
Integration test
    Validate using 1 spring and 1 damper

Points
    O: the stationary origin
    A: the particle

Components
    OA: The spring joining O and A
    OA: The damper joining O and A

%}
classdef IntegrationTest_8 < IntegrationTest
methods(Static)
    function out = Description()
        out = "1D Spring-Mass-Damper System";
    end

    function Run(solverArgs, solverTol, validateTol, Ly_IC, Ly_d_IC, wn, d)
        arguments
            solverArgs = {}
            solverTol = 1e-10
            validateTol = 1e-7
            Ly_IC = 5
            Ly_d_IC = 0
            wn {mustBePositive} = 1
            d {mustBeNonnegative} = .5
        end
        if d==1
            error("Analytic solution not valid for d=1");
        end

        %**********************************************************************
        % Define System
        %***********************************
        mass = 0.459; % A somewhat random number
        gravity = 9.8;
        duration = 3.2;
        LnNum = 5.95;
        %Ly_IC = 0;
        %Ly_d_IC = 0;
        %wn = 1; % Natural frequency
        %d = .5; % Damping ratio
        F1 = 0.123; % Constant force acting upwards on the mass

        bNum = 2*d*mass*wn;    % Damping constant
        kNum = mass*wn^2;      % Spring constant

        sys = CDS_SystemDescription();
        params = sys.params;
        params.Create('free', 'Ly').SetIC(Ly_IC, Ly_d_IC);
        params.Create('const', 'g').SetNum(gravity);
        params.Create('const', 'k').SetNum(kNum);
        params.Create('const', 'Ln').SetNum(LnNum);
        params.Create('const', 'b').SetNum(bNum);

        T_OA = CDS_T('P', [0;Ly;0]);
        A = sys.CreatePoint('A', mass).SetT_0n(T_OA);

        sys.SetChains();
        sys.SetGravity([0; -g; 0]);

        sys.CreateLinearSpring("OA").SetLength(Ly).SetSpringConstant(k).SetNaturalLength(Ln);
        sys.CreateLinearDamper("OA").SetLength(Ly).SetDampingConstant(b);
        % Split the force into parts to test both formulations
        sys.CreateGeneralisedForce("A").SetLocation(Ly).SetQ(F1/3);
        sys.CreatePointForce("A").SetLocation(A).SetF([0; 2*F1/3; 0]);

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
        %       0 = m*x_dd + b*x_d + k*(x-Ln) + m*g - F1
        %   Standard form:
        %       m*x_dd + b*x_d + k*x = k*Ln - m*g + F1
        %   Solution
        %       Homogeneous solution is of a harmonic oscillator
        %       Particular solution is for a zero degree polynomial (a constant)
        %           assumes F1 is a constant
        %   Analytic Solution valid for d=/=1 (all but the critically damped solution)
        %   Energy
        %       Ek = 0.5*m*v^2
        %       Ev = Eg + Es
        %       Eg = m*g*h
        %       Es = 0.5*k*(L-Ln).^2;
        w1 = -d*wn + wn*sqrt(d^2-1);
        w2 = -d*wn - wn*sqrt(d^2-1);
        C1 = (1/kNum)*(kNum*LnNum - mass*gravity + F1);
        A1 = (Ly_d_IC - w2*Ly_IC + w2*C1)/(w1-w2);
        B1 = Ly_IC - A1 - C1;
        y_true = real( A1*exp(w1*t) + B1*exp(w2*t) + C1 );
        yd_true = real( w1*A1*exp(w1*t) + w2*B1*exp(w2*t) );
        ydd_true = real( w1*w1*A1*exp(w1*t) + w2*w2*B1*exp(w2*t) );
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

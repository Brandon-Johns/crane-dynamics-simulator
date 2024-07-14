%{
'C3' models series

PURPOSE
    Build a predefined crane model:
        'Full Complexity' with pulley, where the hook and payload are rigidly fixed together
        (like a double pendulum)
%}

classdef CDSm_C3_sheave2P < CDSm_C3
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    function this = CDSm_C3_sheave2P(varargin)
        % Call superclass constructor
        this@CDSm_C3(varargin{:});
    end
    
    function sys = Build_SystemDescription(this)
        %**********************************************************************
        % User input
        %***********************************
        % Load preset numerical values: constants, ICs, inputs, etc.
        V = this.Values;

        % Reduce to 2D (true or false)
        Flag_2D = this.Flag_2D;

        % Point I: True or equilibrium
        %Flag_pointI_truePosition = this.Flag_pointI_truePosition;
        
        %**********************************************************************
        % Check input
        %***********************************
        mustNotBeZero = [V.mass_K; V.mass_M; V.inertia_K(:); V.inertia_M(:)];
        if any(mustNotBeZero==0); error("Some mass & inertia values are zero, but for this model they must be set"); end
        
        %**********************************************************************
        % Define Geometry - Parameters
        %***********************************
        params = CDS_Params();
        points = CDS_Points(params);

        params.Create('const', 'phi_1').SetNum(V.phi_1);
        params.Create('const', 'L_AB').SetNum(V.L_AB);
        params.Create('const', 'L_BC').SetNum(V.L_BC);
        params.Create('const', 'L_CD').SetNum(V.L_CD);
        params.Create('const', 'L_EF').SetNum(V.L_EF);
        params.Create('const', 'L_FG').SetNum(V.L_FG);
        params.Create('const', 'L_GH').SetNum(V.L_GH);
        params.Create('const', 'L_FJ').SetNum(V.L_FJ);
        params.Create('const', 'L_JK').SetNum(V.L_JK);
        params.Create('const', 'L_KL').SetNum(V.L_KL);
        params.Create('const', 'L_LM').SetNum(V.L_LM);
        params.Create('const', 'theta_3_eq').SetNum(V.theta_3_eq);
        params.Create('const', 'a_DE_eq').SetNum(V.a_DE_eq);
        params.Create('const', 'g').SetNum(V.g);

        params.Create('free', 'theta_3').SetIC(V.theta_3_IC);
        params.Create('free', 'theta_7').SetIC(V.theta_7_IC);

        % START: Simplification to lock together the payload & Hook block
        theta_11 = V.theta_11_IC;
        % END: Simplification

        params.Create('free', 'a_DE').SetIC(V.a_DE_IC);
        params.Create('input', 'theta_2').Set_Selector(V.theta_2_t);

        if Flag_2D
            theta_4 = V.theta_4_IC;
            theta_5 = V.theta_5_IC;
            theta_6 = V.theta_6_IC;
            % Hold initial position
            theta_1 = CDS_Param_Input('tmp').Set_Selector(V.theta_1_t).q(0);
            theta_10 = CDS_Param_Input('tmp').Set_Selector(V.theta_10_t).q(0);
        else % 3D
            params.Create('free', 'theta_4').SetIC(V.theta_4_IC);
            params.Create('free', 'theta_5').SetIC(V.theta_5_IC);
            params.Create('free', 'theta_6').SetIC(V.theta_6_IC);
            params.Create('input', 'theta_1').Set_Selector(V.theta_1_t);
            params.Create('input', 'theta_10').Set_Selector(V.theta_10_t);
        end

        %**********************************************************************
        % Define Geometry - Transformations
        %***********************************
        % Forward transformations - independent
        T_A1A2 = CDS_T('atP', 'y', theta_1, [0;0;0]);
        T_A2A3 = CDS_T('atP', 'z', theta_2, [0;0;0]);
        T_A3B  = CDS_T('atP', 'z', -phi_1, [L_AB;0;0]);
        T_BC   = CDS_T('atP', 'z', theta_3, [L_BC;0;0]);
        T_CD1  = CDS_T('atP', 'z', -sym(pi/2), [L_CD;0;0]);
        T_D1D2 = CDS_T('atP', 'y', theta_4, [0;0;0]);
        T_D2E1 = CDS_T('atP', 'z', 0, [a_DE;0;0]);
        T_E1E2 = CDS_T('atP', 'x', -theta_5, [0;0;0]);
        T_E2E3 = CDS_T('atP', 'z', -sym(pi/2), [0;0;0]);
        T_E3E4 = CDS_T('atP', 'x', theta_6, [0;0;0]);
        T_E4F  = CDS_T('atP', 'z', -theta_7, [L_EF;0;0]);
        T_FG1  = CDS_T('atP', 'z', 0, [L_FG;0;0]);

        T_FJ1  = CDS_T('atP', 'z', 0, [L_FJ; 0; 0]);
        T_J1J2 = CDS_T('atP', 'z', sym(pi/2), [0; 0; 0]);
        T_J2K1 = CDS_T('atP', 'z', 0, [L_JK; 0; 0]);
        T_K1K2 = CDS_T('atP', 'x', theta_10, [0; 0; 0]);
        T_K2L  = CDS_T('atP', 'y', -theta_11, [L_KL; 0; 0]);
        T_LM   = CDS_T('atP', 'z', 0, [L_LM; 0; 0]);

        %***********************************
        % Solve dependent transformations to close chain
        % Forward transform B->G1
        T_BG1 = T_BC*T_CD1*T_D1D2*T_D2E1*T_E1E2*T_E2E3*T_E3E4*T_E4F*T_FG1;

        % Invert T_BG1 for P_G1B in terms of independent vars
        P_G1B_known = T_BG1.Inv.P;
        x_G1B = P_G1B_known(1);
        y_G1B = P_G1B_known(2);
        z_G1B = P_G1B_known(3);

        % Solve dependent transformations: hand calcs, matlab solver, wolfram alpha
        % No assumptions
        a_HB = sqrt(x_G1B^2 + y_G1B^2 + z_G1B^2 - L_GH^2);

        % Assumes psi_12 in range [-pi,pi]
        theta_9 = asin(z_G1B/a_HB);

        % Unknown validity range (from wolfram alpha)
        theta_8 = 2*atan((y_G1B + sqrt(x_G1B^2 + y_G1B^2 - L_GH^2))/(x_G1B + L_GH));

        % Remaining forward transforms in terms of independent variables
        T_G1G2 = CDS_T('atP', 'z', theta_8, [0;0;0]);
        T_G2H1 = CDS_T('atP', 'z', -sym(pi/2), [L_GH;0;0]);
        T_H1H2 = CDS_T('atP', 'y', theta_9, [0;0;0]);

        %***********************************
        % Point I: Imaginary rope leaves main sheave
        %   Prep to solve
        T_AB = T_A1A2*T_A2A3*T_A3B;

        % True mid point
        T_BD = T_BC*T_CD1;
        P_BD = T_BD.P;
        P_BI = P_BD./2;
        P_BIh = [P_BI; 1];

        % Forward transformation
        P_AIh = T_AB*P_BIh;
        R_AI = T_A1A2.R; % Set vertical, regardless of luffing angle
        T_AI = CDS_T('RP', R_AI, P_AIh);

        %***********************************
        % Combine transformations
        T_AB = T_A1A2*T_A2A3*T_A3B;
        T_AC = T_AB*T_BC;
        T_AD = T_AC*T_CD1;
        T_AE = T_AD*T_D1D2*T_D2E1;
        T_AF = T_AE*T_E1E2*T_E2E3*T_E3E4*T_E4F;
        T_AG = T_AF*T_FG1;
        T_AH = T_AG*T_G1G2*T_G2H1;
        %T_AI = defined above
        T_AJ = T_AF*T_FJ1;
        T_AK = T_AJ*T_J1J2*T_J2K1;
        T_AL = T_AK*T_K1K2*T_K2L;
        T_AM = T_AL*T_LM;

        % Rope length
        %L_rope = a_HB + L_GH*(sym(pi/2)-theta_8) + L_FG + L_EF*(sym(pi/2)+theta_5) + a_DE + L_CD*(sym(pi)-theta_3);
        L_rope = a_HB + a_DE; % approximated version

        %**********************************************************************
        % Define Geometry - Other
        %***********************************
        % Points and chains
        A = points.Create('A');
        B = points.Create('B').SetT_0n(T_AB);
        C = points.Create('C').SetT_0n(T_AC);
        D = points.Create('D').SetT_0n(T_AD);
        E = points.Create('E').SetT_0n(T_AE);
        F = points.Create('F').SetT_0n(T_AF);
        G = points.Create('G').SetT_0n(T_AG);
        H = points.Create('H').SetT_0n(T_AH);
        I = points.Create('I').SetT_0n(T_AI);
        J = points.Create('J').SetT_0n(T_AJ);
        K = points.Create('K', V.mass_K, V.inertia_K).SetT_0n(T_AK);
        L = points.Create('L').SetT_0n(T_AL);
        M = points.Create('M', V.mass_M, V.inertia_M).SetT_0n(T_AM);

        chains = {[A,B,C,D,E,F,G,H,B], [I,J,K,L,M]};

        %***********************************
        % Direction of gravity in base frame
        g0 = [0; -g; 0];

        %***********************************
        sys = CDS_SystemDescription(params, points, chains, g0);

        % Constraints
        %   Specify as 0=C
        %   Note: all uses of C differentiate => no need to specify const
        L_rope = simplify(expand(L_rope));
        sys.SetConstraint(L_rope);
        
        %**********************************************************************
        % Save output
        %***********************************
        this.sys=sys;
    end
end
end
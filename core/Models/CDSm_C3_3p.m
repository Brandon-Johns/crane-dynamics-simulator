%{
'C3' models series

PURPOSE
    Build a predefined crane model: Triple pendulum
%}

classdef CDSm_C3_3p < CDSm_C3
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    function this = CDSm_C3_3p(varargin)
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

        % Full complexity system ICs
        % For finding length of imag_rope
        theta_3 = V.theta_3_IC;
        theta_4 = V.theta_4_IC;
        theta_5 = V.theta_5_IC;
        theta_6 = V.theta_6_IC;
        theta_7 = V.theta_7_IC;
        params.Create('free', 'theta_11').SetIC(V.theta_11_IC);
        a_DE = V.a_DE_IC;

        % Triple pendulum simplification
        params.Create('free', 'theta_p1i').SetIC(V.theta_p1i_IC);
        params.Create('free', 'theta_p2i').SetIC(V.theta_p2i_IC);
        params.Create('input', 'theta_2').Set_Selector(V.theta_2_t);

        if Flag_2D
            theta_p1o=0;
            theta_p2o=0;
            theta_p1s=0;
            % Hold initial position
            theta_1 = CDS_Param_Input('tmp').Set_Selector(V.theta_1_t).q(0);
            theta_10 = CDS_Param_Input('tmp').Set_Selector(V.theta_10_t).q(0);
        else % 3D
            params.Create('free', 'theta_p1o').SetIC(V.theta_p1o_IC);
            params.Create('free', 'theta_p2o').SetIC(V.theta_p2o_IC);
            params.Create('free', 'theta_p1s').SetIC(V.theta_p1s_IC);
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
        T_FJ1  = CDS_T('atP', 'z', 0, [L_FJ; 0; 0]);

        %***********************************
        % Point I: Imaginary rope leaves main sheave
        %   Prep to solve
        T_AB = T_A1A2*T_A2A3*T_A3B;

        % Equilibrium configuration (roughly)
        T_BC_eq = CDS_T('atP', 'z', theta_3_eq, [L_BC;0;0]);
        T_BD_eq = T_BC_eq*T_CD1;
        P_BD_eq = T_BD_eq.P;
        P_BI = P_BD_eq./2;
        P_BIh = [P_BI; 1];

        % Forward transformation
        P_AIh = T_AB*P_BIh;
        R_AI = T_A1A2.R; % Set vertical, regardless of luffing angle
        T_AI = CDS_T('RP', R_AI, P_AIh);

        %***********************************
        % Point J: Imaginary rope joins hook block
        T_AJ_eq = T_AB*T_BC*T_CD1*T_D1D2*T_D2E1*T_E1E2*T_E2E3*T_E3E4*T_E4F*T_FJ1;
        P_AI = T_AI.P;
        P_AJ_eq = T_AJ_eq.P;
        imagRope_sym = norm(P_AJ_eq - P_AI);

        % Evaluate at time=0, x=x(t=0)
        u_handle = params.u.q;
        u0 = u_handle(0, params.x.x0);
        imagRope = double(subs(imagRope_sym,...
            [params.const.Sym; params.u.Sym], ...
            [params.const.Num; u0]));

        %fprintf(ccode(imagRope_sym));
        %fprintf('%.15E\n', imagRope);

        % Forward Transformations
        T_II2 = CDS_T('atP', 'z', -sym(pi/2)+theta_p1i, [0;0;0]);
        T_I2I3 = CDS_T('atP', 'y', theta_p1o, [0;0;0]);
        T_I3I4 = CDS_T('atP', 'x', theta_p1s, [0;0;0]);
        T_I4J1 = CDS_T('atP', 'z', 0, [imagRope;0;0]);
        T_J1J2 = CDS_T('atP', 'y', theta_p2o, [0;0;0]);
        T_J2J3 = CDS_T('atP', 'z', theta_p2i, [0;0;0]);

        %***********************************
        % Rest of linkage
        % Forward transformation
        T_J3K1 = CDS_T('atP', 'z', 0, [L_JK; 0; 0]);
        T_K1K2 = CDS_T('atP', 'x', theta_10, [0; 0; 0]);
        T_K2L = CDS_T('atP', 'y', -theta_11, [L_KL; 0; 0]);
        T_LM = CDS_T('atP', 'z', 0, [L_LM; 0; 0]);

        %***********************************
        % Combine transformations
        %T_AB = defined above
        %T_AI = defined above
        T_AJ = T_AI*T_II2*T_I2I3*T_I3I4*T_I4J1;
        T_AK = T_AJ*T_J1J2*T_J2J3*T_J3K1;
        T_AL = T_AK*T_K1K2*T_K2L;
        T_AM = T_AL*T_LM;

        %**********************************************************************
        % Define Geometry - Other
        %***********************************
        % Points and chains
        A = points.Create('A');
        I = points.Create('I').SetT_0n(T_AI);
        J = points.Create('J').SetT_0n(T_AJ);
        K = points.Create('K', V.mass_K, V.inertia_K).SetT_0n(T_AK);
        L = points.Create('L').SetT_0n(T_AL);
        M = points.Create('M', V.mass_M, V.inertia_M).SetT_0n(T_AM);

        chains = {[A,I,J,K,L,M]};

        %***********************************
        % Direction of gravity in base frame
        g0 = [0; -g; 0];

        %***********************************
        sys = CDS_SystemDescription(params, points, chains, g0);

        % Constraints
        %   Specify as 0=C
        %   Note: all uses of C differentiate => no need to specify const
        %(none)
        
        %**********************************************************************
        % Save output
        %***********************************
        this.sys=sys;
    end
end
end
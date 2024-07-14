%{
'C3' models series

PURPOSE
    Build CDS_SolutionExp using the results from real-world experimental trials
    Trials with a UR5 robot and motion capture
%}

classdef CDSm_C3_ImportExp_v1 < handle
properties (Access=private)
    Values(1,1) CDSv_C3
end
methods
    function this = CDSm_C3_ImportExp_v1(Values)
        this.Values = Values;
    end
    
    function SS = Build_Solution(this, FileName)
        %**********************************************************************
        % User input
        %***********************************
        V = this.Values;
        
        % Read in the CSV
        ExpDataRaw = readmatrix(FileName);
        t = ExpDataRaw(:, 1);
        idxStartT = 2;
        % Boom head
        raw_BH_R = ExpDataRaw(:, idxStartT:idxStartT+8);
        raw_BH_P = ExpDataRaw(:, idxStartT+9:idxStartT+11);
        idxStartT=idxStartT+12;
        % Hook block
        raw_HB_R = ExpDataRaw(:, idxStartT:idxStartT+8);
        raw_HB_P = ExpDataRaw(:, idxStartT+9:idxStartT+11);
        idxStartT=idxStartT+12;
        % Payload
        raw_PP_R = ExpDataRaw(:, idxStartT:idxStartT+8);
        raw_PP_P = ExpDataRaw(:, idxStartT+9:idxStartT+11);

        % Convert to mm -> m
        raw_BH_P = raw_BH_P * 1e-3;
        raw_HB_P = raw_HB_P * 1e-3;
        raw_PP_P = raw_PP_P * 1e-3;

        %**********************************************************************
        % Define Geometry - Parameters
        %***********************************
        params = CDS_Params();
        points = CDS_Points(params);

        params.Create('input', 'theta_1').Set_Selector(V.theta_1_t);
        params.Create('input', 'theta_2').Set_Selector(V.theta_2_t);
        params.Create('input', 'theta_10').Set_Selector(V.theta_10_t);

        %**********************************************************************
        % Define Geometry - Other
        %***********************************
        % Points and chains
        A = points.Create('A');
        I = points.Create('I');
        J = points.Create('J');
        K = points.Create('K', V.mass_K, V.inertia_K);
        L = points.Create('L');
        L2 = points.Create('L2');
        M = points.Create('M', V.mass_M, V.inertia_M);

        chains = {[A,I,J,K,L,M], [L,L2]};

        %**********************************************************************
        % Build Solution Object
        %***********************************
        SS = CDS_SolutionExp(params, t);

        SS.AddPoint_Analytic(A);
        SS.AddPoint_Exp(I, V.T_w0, raw_BH_R, raw_BH_P, V.T_BH_I);
        SS.AddPoint_Exp(J, V.T_w0, raw_HB_R, raw_HB_P, V.T_HB_J);
        SS.AddPoint_Exp(K, V.T_w0, raw_HB_R, raw_HB_P, V.T_HB_K);
        SS.AddPoint_Exp(L, V.T_w0, raw_HB_R, raw_HB_P, V.T_HB_L);
        SS.AddPoint_Exp(L2, V.T_w0, raw_PP_R, raw_PP_P, V.T_PP_L);
        SS.AddPoint_Exp(M, V.T_w0, raw_PP_R, raw_PP_P, V.T_PP_M);

        SS.SetChains(chains);

        %**********************************************************************
        % Evaluate Missing Parameters - Setup
        %***********************************
        tmpParams = CDS_Params();
        tmpPoints = CDS_Points(tmpParams);
        B = tmpPoints.Create('B');
        C = tmpPoints.Create('C');
        F = tmpPoints.Create('F');
        %G = tmpPoints.Create('G');
        tmpSS = CDS_SolutionExp(tmpParams, t);
        tmpSS.AddPoint_Exp(B, V.T_w0, raw_BH_R, raw_BH_P, V.T_BH_B);
        tmpSS.AddPoint_Exp(C, V.T_w0, raw_BH_R, raw_BH_P, V.T_BH_C);
        tmpSS.AddPoint_Exp(F, V.T_w0, raw_HB_R, raw_HB_P, V.T_HB_F);
        %tmpSS.AddPoint_Exp(G, V.T_w0, raw_HB_R, raw_HB_P, V.T_HB_G);
        idxB = tmpSS.p_all==B;
        idxC = tmpSS.p_all==C;
        idxF = tmpSS.p_all==F;
        %idxG = tmpSS.p_all==G;

        %**********************************************************************
        % Evaluate Missing Parameters: L_AB
        %***********************************
        P_Bx = tmpSS.Px(idxB,:);
        P_By = tmpSS.Py(idxB,:);
        P_Bz = tmpSS.Pz(idxB,:);

        L_AB_vec = vecnorm([P_Bx(:), P_By(:), P_Bz(:)], 2, 2);
        V.L_AB = mean(L_AB_vec);

        %**********************************************************************
        %  Evaluate Missing Parameters: a_DE_IC, theta_(3, 4, 5, 6, 7)_IC
        %***********************************
        % Time to solve the system at
        idx_time = 1;

        % Solve 2D case for a_DE
        %   To use as initial guess for IK solver to find actual value
        P_CF_measureWorld = [...
            tmpSS.Px(idxF, idx_time) - tmpSS.Px(idxC, idx_time);
            tmpSS.Py(idxF, idx_time) - tmpSS.Py(idxC, idx_time);
            tmpSS.Pz(idxF, idx_time) - tmpSS.Pz(idxC, idx_time)];
        a_DE_assuming2D = sqrt(norm(P_CF_measureWorld)^2 - (V.L_CD - V.L_EF)^2);
        
        % Reference zero angle/length joint configuration
        a_DE_zero = 0;
        theta_3_zero = 0;
        theta_4_zero = 0;
        theta_5_zero = 0;
        theta_6_zero = 0;
        theta_7_zero = 0;
        a_DE_initialGuess = a_DE_assuming2D;
        
        % Start of chain in world frame
        R_0_BH = reshape(raw_BH_R(idx_time,:), 3,3).';
        P_0_BH = raw_BH_P(idx_time,:);
        T_0_BH = CDS_T('RP', R_0_BH, P_0_BH);
        T_w_frameB = V.T_w0 * T_0_BH * V.T_BH_frameB;

        % End of chain in world frame (EE target for IK solver)
        R_0_HB = reshape(raw_HB_R(idx_time,:), 3,3).';
        P_0_HB = raw_HB_P(idx_time,:);
        T_0_HB = CDS_T('RP', R_0_HB, P_0_HB);
        T_w_frameJ1 = V.T_w0 * T_0_HB * V.T_HB_frameJ1;

        % Usual forward transformations, but at home positions
        T_BC   = CDS_T('atP', 'z', theta_3_zero, [V.L_BC;0;0]);
        T_CD1  = CDS_T('atP', 'z', -sym(pi/2), [V.L_CD;0;0]);
        T_D1D2 = CDS_T('atP', 'y', theta_4_zero, [0;0;0]);
        T_D2E1 = CDS_T('atP', 'z', 0, [a_DE_zero;0;0]);
        T_E1E2 = CDS_T('atP', 'x', -theta_5_zero, [0;0;0]);
        T_E2E3 = CDS_T('atP', 'z', -sym(pi/2), [0;0;0]);
        T_E3E4 = CDS_T('atP', 'x', theta_6_zero, [0;0;0]);
        T_E4F  = CDS_T('atP', 'z', -theta_7_zero, [V.L_EF;0;0]);
        T_FJ1  = CDS_T('atP', 'z', 0, [V.L_FJ; 0; 0]);

        % 'Robotics System Toolbox' Kinematic Description
        robot = rigidBodyTree;
        jointAxis_x = [1,0,0];
        jointAxis_y = [0,1,0];
        jointAxis_z = [0,0,1];
        joint_B  = rigidBodyJoint('B','fixed');      joint_B.setFixedTransform(double( T_w_frameB.T));
        joint_C  = rigidBodyJoint('C','revolute');   joint_C.setFixedTransform(double( T_BC.T));   joint_C.JointAxis  = jointAxis_z;
        joint_D1 = rigidBodyJoint('D1','fixed');     joint_D1.setFixedTransform(double(T_CD1.T));
        joint_D2 = rigidBodyJoint('D2','revolute');  joint_D2.setFixedTransform(double(T_D1D2.T)); joint_D2.JointAxis = jointAxis_y;
        joint_E1 = rigidBodyJoint('E1','prismatic'); joint_E1.setFixedTransform(double(T_D2E1.T)); joint_E1.JointAxis = jointAxis_x; joint_E1.PositionLimits = [0,2*a_DE_initialGuess];
        joint_E2 = rigidBodyJoint('E2','revolute');  joint_E2.setFixedTransform(double(T_E1E2.T)); joint_E2.JointAxis = -jointAxis_x;
        joint_E3 = rigidBodyJoint('E3','fixed');     joint_E3.setFixedTransform(double(T_E2E3.T));
        joint_E4 = rigidBodyJoint('E4','revolute');  joint_E4.setFixedTransform(double(T_E3E4.T)); joint_E4.JointAxis = jointAxis_x;
        joint_F  = rigidBodyJoint('F','revolute');   joint_F.setFixedTransform(double( T_E4F.T));  joint_F.JointAxis  = -jointAxis_z;
        joint_J1 = rigidBodyJoint('J1','fixed');     joint_J1.setFixedTransform(double(T_FJ1.T));
        body_wB   = rigidBody("wB");   body_wB.Joint   = joint_B;  robot.addBody(body_wB,'base');
        body_BC   = rigidBody("BC");   body_BC.Joint   = joint_C;  robot.addBody(body_BC,'wB');
        body_CD1  = rigidBody("CD1");  body_CD1.Joint  = joint_D1; robot.addBody(body_CD1,'BC');
        body_D1D2 = rigidBody("D1D2"); body_D1D2.Joint = joint_D2; robot.addBody(body_D1D2,'CD1');
        body_D2E1 = rigidBody("D2E1"); body_D2E1.Joint = joint_E1; robot.addBody(body_D2E1,'D1D2');
        body_E1E2 = rigidBody("E1E2"); body_E1E2.Joint = joint_E2; robot.addBody(body_E1E2,'D2E1');
        body_E2E3 = rigidBody("E2E3"); body_E2E3.Joint = joint_E3; robot.addBody(body_E2E3,'E1E2');
        body_E3E4 = rigidBody("E3E4"); body_E3E4.Joint = joint_E4; robot.addBody(body_E3E4,'E2E3');
        body_E4F  = rigidBody("E4F");  body_E4F.Joint  = joint_F;  robot.addBody(body_E4F,'E3E4');
        body_FJ1  = rigidBody("FJ1");  body_FJ1.Joint  = joint_J1; robot.addBody(body_FJ1,'E4F');
        
        % Solve IK
        ik = inverseKinematics('RigidBodyTree',robot);
        weights = [1,1,1, 1,1,1]; % Estimated pose error weights [orientation, position]
        configGuess = robot.homeConfiguration;
        configGuess(string({configGuess.JointName})=="E1").JointPosition = a_DE_initialGuess;
        
        [configSol,ikSolInfo] = ik('FJ1',double(T_w_frameJ1.T),weights,configGuess);

        % Check IK solver output info
        if ~strcmp(ikSolInfo.Status, "success") || ikSolInfo.PoseErrorNorm > 1e-5
            error("IK Solver failed. Status=" + ikSolInfo.Status + " Error=" + ikSolInfo.PoseErrorNorm);
        end

        V.a_DE_IC = configSol(string({configSol.JointName})=="E1").JointPosition;
        V.theta_3_IC = configSol(string({configSol.JointName})=="C").JointPosition;
        V.theta_4_IC = configSol(string({configSol.JointName})=="D2").JointPosition;
        V.theta_5_IC = configSol(string({configSol.JointName})=="E2").JointPosition;
        V.theta_6_IC = configSol(string({configSol.JointName})=="E4").JointPosition;
        V.theta_7_IC = configSol(string({configSol.JointName})=="F").JointPosition;
        
        % Assume starting in equilibrium
        V.a_DE_eq = V.a_DE_IC;
        V.theta_3_eq = V.theta_3_IC;

        %**********************************************************************
        % Evaluate Missing Parameters: imagRope
        %***********************************
        idxI = SS.p_all==I;
        idxJ = SS.p_all==J;
        P_IJ_measureWorld = [...
            SS.Px(idxJ, idx_time) - SS.Px(idxI, idx_time);
            SS.Py(idxJ, idx_time) - SS.Py(idxI, idx_time);
            SS.Pz(idxJ, idx_time) - SS.Pz(idxI, idx_time)];
        V.imagRope = norm(P_IJ_measureWorld);

        %**********************************************************************
        % Print info
        %***********************************
        %fprintf("L_AB = %f (stddev: %g) (m)\n", V.L_AB, std(L_AB_vec));
        %fprintf("imagRope = %f (m)\n", V.imagRope);
        %fprintf("a_DE_IC = %f (m)\n", V.a_DE_IC);
        %fprintf("theta_3_IC = %f (deg)\n", rad2deg(V.theta_3_IC));
        %fprintf("theta_4_IC = %f (deg)\n", rad2deg(V.theta_4_IC));
        %fprintf("theta_5_IC = %f (deg)\n", rad2deg(V.theta_5_IC));
        %fprintf("theta_6_IC = %f (deg)\n", rad2deg(V.theta_6_IC));
        %fprintf("theta_7_IC = %f (deg)\n", rad2deg(V.theta_7_IC));
        
        %robot.showdetails;
        %configSol
        %robot.show;
        %robot.show(configSol);

    end
end
end


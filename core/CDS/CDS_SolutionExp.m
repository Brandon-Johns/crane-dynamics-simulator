%{
PURPOSE
    Post-process experimental solution data; results from real-world experimental trials

IMPORTANT NOTE
    The method this.CalculatePointTrajectory_Exp(MyPoint, ...) ignores the value of MyPoint.T_0n
    Because the point is not analytic, T_0n cannot be set
    Hence, the value of MyPoint.T_0n will be set to CDS_T.NaN(1)

NOTES
    Allows mixed coordinates
        Analytic     e.g. Known trajectory of a servo controlled robot
        Experimental e.g. As measured by sensors (I used motion capture)

CONSIDERATIONS
    For experimental points, sys.points.T_0n is not known symbolically, which inhibits calculating many values
    Not implemented:
    - Calculating configuration space requires custom inverse kinematics
    - Kinetic and potential energies/powers can be automatically calculated
    - Some component properties can be automatically calculated, depending on how they are defined
    --- If defined with connections, use the points arrays directly
    --- If defined with generalised coordinates, first find configuration space with inverse kinematics
    A way to do some of these calculations could be to set MyPoint.T_0n to read values from the solution arrays
    For each experimental point
        sys.params.Create("input", "Px_"+idx).SetSpline(spline(this.t, this.Px(idx,:)));
        % Repeat this for all components of the transformation matrix
        % The method to calculate the rotation is in this.CalculatePointTrajectory_Exp()
        % For rotation, alternatively, only define syms for the quaternions [qx,qy,qz,qw], and set R with the symExpr to convert
        P_w_idx = str2sym(["Px","Py","Pz"]+"_"+idx);
        R_w_idx = str2sym(["Rxx","Rxy","Rxz"; "Ryx","Ryy","Ryz"; "Rzx","Rzy","Rzz"]+"_"+idx);
        T_w_idx = CDS_T("RP",R_w_idx,P_w_idx)
        sys.points(idx).SetT_0n(T_w_idx);
    This would allow pretty seamless use of the codebase, which strongly focusses on evaluating symbolic expressions
    Otherwise, equations could be directly reimplemented to operate on numeric arrays, but that'd be a lot of mess

EXAMPLE
    % Given:
    %   sys: CDS_SystemDescription
    %   A: (CDS_Point) with all properties appropriately set (T_0A is analytic)
    %   B: (CDS_Point) with all properties appropriately set (T_0B is analytic)
    %   C: (CDS_Point) with all properties except T_0n appropriately set (T_0C was experimentally measured)
    %   D: (CDS_Point) with all properties except T_0n appropriately set (T_0D was experimentally measured)
    %   T_w0: (CDS_T) Transformation between the simulator and experimental world frames
    %   t:    (array of doubles) Sample times of the experimental data
    %   R_wC: (2D array of doubles) Experimentally measured rotations of frame C for each time in t
    %   P_wC: (2D array of doubles) Experimentally measured translations of frame C for each time in t
    %   R_wD: (2D array of doubles) Experimentally measured rotations of frame D for each time in t
    %   P_wD: (2D array of doubles) Experimentally measured translations of frame D for each time in t

    SS = CDS_SolutionExp(sys, t);
    SS.CalculatePointTrajectory_Analytic(A);
    SS.CalculatePointTrajectory_Analytic(B);
    SS.CalculatePointTrajectory_Exp(C, T_w0, R_wC, P_wC);
    SS.CalculatePointTrajectory_Exp(D, T_w0, R_wD, P_wD);
%}

classdef CDS_SolutionExp < CDS_Solution
properties (SetAccess=private)
    % Track how points have been calculated
    points_calculationMethod(:,1) {mustBeMember(points_calculationMethod, ["NotCalculated","Analytic","Experimental"])} = "NotCalculated"
end
methods
    %**********************************************************************
    % Interface - Create & Initialise
    %***********************************
    % REQUIRES
    %   In the provided sys
    %       All sys.params.q_input must be already created and fully configured
    %       All sys.points must be already created. They do not yet need to be configured
    % NOTE
    %   Additionally in the provided sys
    %       Any sys.params.const that are set will be used
    %   All other system properties will be ignored, and their solution arrays will be set as empty
    %   This class focusses only on calculating the solution trajectories
    % INPUT
    %   sys: The system to corresponding to the experimental data being loaded
    %   t_sol: The sample times of the experimental data
    function this = CDS_SolutionExp(sys, t_sol)
        arguments
            sys(1,1) CDS_SystemDescription
            t_sol(:,1) double
        end
        this.t = t_sol;
        this.sys = sys;

        % Initialise empty arrays with consistent sizes
        this.qf    = double.empty(0, numel(this.t));
        this.qf_d  = double.empty(0, numel(this.t));
        this.qf_dd = double.empty(0, numel(this.t));
        this.ql    = double.empty(0, numel(this.t));
        this.ql_d  = double.empty(0, numel(this.t));
        this.E     = nan(1,numel(this.t)); % This causes a lot of fun (match to CDS_SolutionSaved)
        this.K_mass           = double.empty(0, numel(this.t));
        this.V_mass           = double.empty(0, numel(this.t));
        this.V_linearSprings  = double.empty(0, numel(this.t));
        this.V_torsionSprings = double.empty(0, numel(this.t));

        % Generate input
        q_input = this.sys.params.q_input;
        this.qi    = zeros(numel(q_input), numel(this.t));
        this.qi_d  = zeros(numel(q_input), numel(this.t));
        this.qi_dd = zeros(numel(q_input), numel(this.t));
        for idxU = 1:length(q_input)
            this.qi(idxU,:) = q_input(idxU).q(t_sol);
            this.qi_d(idxU,:) = q_input(idxU).q_d(t_sol);
            this.qi_dd(idxU,:) = q_input(idxU).q_dd(t_sol);
        end

        % Initialise solution points arrays
        this.points_calculationMethod = repmat("NotCalculated", size(sys.points));
        this.Px = nan(length(sys.points), length(this.t));
        this.Py = nan(length(sys.points), length(this.t));
        this.Pz = nan(length(sys.points), length(this.t));
    end

    % Specify a system point as analytic and trigger calculation of it's solution array
    % INPUT
    %   A point registered in sys with all properties set
    %   The symbolic expression contained in point.T_0n permits values from [CDS_Params.const.Sym; CDS_Params.q_input.Sym; sym('t','real')]
    function CalculatePointTrajectory_Analytic(this, point)
        arguments
            this(1,1)
            point(1,1) CDS_Point
        end
        idxPoint = this.PointIdx(point);
        this.points_calculationMethod(idxPoint) = "Analytic";

        q_input = this.sys.params.q_input;
        u = [q_input.Sym; q_input.Sym(1); q_input.Sym(2)];
        uSol = [this.qi; this.qi_d; this.qi_dd];

        P_sol = this.sys.params.EvaluateSymExpr(point.T_0n.P, this.t, u,uSol);
        this.Px(idxPoint,:) = P_sol(1,:);
        this.Py(idxPoint,:) = P_sol(2,:);
        this.Pz(idxPoint,:) = P_sol(3,:);
    end

    % Specify a system point as experimentally measured and trigger calculation of it's solution array
    % NOTATION
    %   T_AB means the transformation matrix that satisfies the relation P_A = T_AB * P_B, where
    %       P_A is a point as measured in frame A
    %       P_B is the same point as measured in frame B
    %   Frames
    %       w: The world frame of the simulator (must be the same for all points in a system)
    %       0: The world frame of the experimental data (e.g. Motion capture world frame)
    %       d: The moving frame in which the data was measured (e.g. Motion capture object frame)
    %       n: This point, where
    %           The origin is at the centre of mass
    %           The orientation is the orientation of the body (mostly only relevant for rigid bodies)
    % INPUT
    %   point: A point registered in sys with all properties set, except T_0n which will be overridden to NaN
    %   T_w0: Static transformation
    %   R_wd: Rotation component of T_wd.    DIM: (time, Rotation matrix in row-major order)
    %   P_wd: Translation component of T_wd. DIM: (time, [x,y,z])
    %   T_dn: Static transformation
    function CalculatePointTrajectory_Exp(this, point, T_w0, R_wd, P_wd, T_dn)
        arguments
            this(1,1)
            point(1,1) CDS_Point
            T_w0(1,1) CDS_T
            R_wd(:,9) double
            P_wd(:,3) double
            T_dn(1,1) CDS_T = CDS_T(eye(4))
        end
        idxPoint = this.PointIdx(point);
        this.points_calculationMethod(idxPoint) = "Experimental";

        % The point is not analytic, therefore T_0n cannot be set
        % => To help catch any erroneous usage, set it to NaN
        point.SetT_0n( CDS_T.NaN(1) );

        % Evaluate any symbolic variables e.g. 'pi'
        T_w0 = CDS_T(double(T_w0.T));

        % Evaluate and save positions
        %   Precalculated for vectorisation (speed up of like a million times, no joke)
        %       T_w0 = str2sym("[w011, w012, w013, w0x; w021, w022, w023, w0y; w031, w032, w033, w0z; 0,0,0,1]");
        %       T_0d = str2sym("[R_0d1, R_0d2, R_0d3, P_0d1; R_0d4, R_0d5, R_0d6, P_0d2; R_0d7, R_0d8, R_0d9, P_0d3; 0,0,0,1]");
        %       T_dn = str2sym("[dn11, dn12, dn13, dnx; dn21, dn22, dn23, dny; dn31, dn32, dn33, dnz; 0,0,0,1]");
        %       T_wn = T_w0 * T_0d * T_dn;
        %       P_wn = T_wn(1:3,4)
        R_w0=T_w0.R;
        this.Px(idxPoint,:) = T_w0.x + P_wd(:,1)*R_w0(1,1)+P_wd(:,2)*R_w0(1,2)+P_wd(:,3)*R_w0(1,3)+...
            T_dn.x*(R_wd(:,1)*R_w0(1,1)+R_wd(:,4)*R_w0(1,2)+R_wd(:,7)*R_w0(1,3))+...
            T_dn.y*(R_wd(:,2)*R_w0(1,1)+R_wd(:,5)*R_w0(1,2)+R_wd(:,8)*R_w0(1,3))+...
            T_dn.z*(R_wd(:,3)*R_w0(1,1)+R_wd(:,6)*R_w0(1,2)+R_wd(:,9)*R_w0(1,3));
        this.Py(idxPoint,:) = T_w0.y + P_wd(:,1)*R_w0(2,1)+P_wd(:,2)*R_w0(2,2)+P_wd(:,3)*R_w0(2,3)+...
            T_dn.x*(R_wd(:,1)*R_w0(2,1)+R_wd(:,4)*R_w0(2,2)+R_wd(:,7)*R_w0(2,3))+...
            T_dn.y*(R_wd(:,2)*R_w0(2,1)+R_wd(:,5)*R_w0(2,2)+R_wd(:,8)*R_w0(2,3))+...
            T_dn.z*(R_wd(:,3)*R_w0(2,1)+R_wd(:,6)*R_w0(2,2)+R_wd(:,9)*R_w0(2,3));
        this.Pz(idxPoint,:) = T_w0.z + P_wd(:,1)*R_w0(3,1)+P_wd(:,2)*R_w0(3,2)+P_wd(:,3)*R_w0(3,3)+...
            T_dn.x*(R_wd(:,1)*R_w0(3,1)+R_wd(:,4)*R_w0(3,2)+R_wd(:,7)*R_w0(3,3))+...
            T_dn.y*(R_wd(:,2)*R_w0(3,1)+R_wd(:,5)*R_w0(3,2)+R_wd(:,8)*R_w0(3,3))+...
            T_dn.z*(R_wd(:,3)*R_w0(3,1)+R_wd(:,6)*R_w0(3,2)+R_wd(:,9)*R_w0(3,3));
    end
end
methods (Static)
    % Helper to format input for this.CalculatePointTrajectory_Exp()
    % NOTES
    %   Conversion directly from Vicon DataStream SDK Documentation
    % INPUT
    %   Euler coordinates as output by the Vicon DataStream SDK
    % OUTPUT
    %   (double) DIM[size(eulerXYZ,1), 9] Rotation matrix in row-major order
    function result = eulerXYZ_to_R_rowMajor(eulerXYZ)
        arguments
            eulerXYZ(:,3) double
        end
        % Conversion directly from Vicon DataStream SDK Documentation
        %   because there are so many ways euler angles can be specified wrong
        x = eulerXYZ(:,1);
        y = eulerXYZ(:,2);
        z = eulerXYZ(:,3);
        result = [...
            cos(y).*cos(z), -cos(y).*sin(z), sin(y),...
            cos(x).*sin(z)+sin(x).*sin(y).*cos(z), cos(x).*cos(z)-sin(x).*sin(y).*sin(z), -sin(x).*cos(y),...
            sin(x).*sin(z)-cos(x).*sin(y).*cos(z), sin(x).*cos(z)+cos(x).*sin(y).*sin(z), cos(x).*cos(y)];

        %R = eul2rotm(eulerXYZ,"XYZ");
        %R_rowMajor = reshape(permute(R,[3,2,1]), size(R,3), 9);
    end
end
methods (Access=private)
    % Retrieve idx of point in solution arrays
    % Validate existence
    % Validate number of registered points has not changed
    function idx = PointIdx(this, point)
        arguments
            this(1,1)
            point(1,1) CDS_Point
        end
        idx = this.sys.points.SubsetIdx(point, warnMissing=false);
        if isempty(idx)
            error("Point not registered");
        end
        if numel(this.sys.points) ~= numel(this.points_calculationMethod)
            error("Number of registered points has changed. It should not have been changed from after this CDS_SolutionExp instance was created")
        end
    end
end
end

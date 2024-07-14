%{
PURPOSE
    Post-process the results from real-world experimental trials
    Hold the post processed solution data

IMPORTANT NOTE
    The method this.AddPoint_Exp(MyPoint, ...) ignores the value of MyPoint.T_0n
    Because the point is not analytic, T_0n cannot be set
    Hence, the value of MyPoint.T_0n will not be correct and should not be used

NOTES
    Allows mixed coordinates
        Analytic     e.g. Known trajectory of a servo controlled robot
        Experimental e.g. As measured by sensors (I used motion capture)

EXAMPLE
    % Given:
    %   params: CDS_Params
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

    SS = CDS_SolutionExp(params, t);
    SS.AddPoint_Analytic(A);
    SS.AddPoint_Analytic(B);
    SS.AddPoint_Exp(C, T_w0, R_wC, P_wC);
    SS.AddPoint_Exp(D, T_w0, R_wD, P_wD);
    SS.SetChains( {[A,B,C,D]} );
%}

classdef CDS_SolutionExp < CDS_Solution
properties (Access=private)
    % These properties are only for use in building this object
    % Public properties defined in CDS_Solution
    params(1,1) CDS_Params
    
end
methods
    %**********************************************************************
    % Interface - Create & Initialise
    %***********************************
    % INPUT
    %   params: CDS_Params
    %   t_sol: Sample times of the experimental data
    function this = CDS_SolutionExp(params, t_sol)
        arguments
            params(1,1) CDS_Params
            t_sol(:,1) double
        end
        this.t = t_sol;
        this.params = params;
        
        % Generate input
        %   Non-vectorised version (see notes in CDS_SolutionSim)
        this.q_input = params.q_input;
        for idxU = 1:length(this.q_input)
            for idxT = 1:length(t_sol)
                UNUSED = 0;
                this.qi(idxU,idxT) = this.q_input(idxU).q(t_sol(idxT), UNUSED);
                this.qi_d(idxU,idxT) = this.q_input(idxU).q_d(t_sol(idxT), UNUSED);
                this.qi_dd(idxU,idxT) = this.q_input(idxU).q_dd(t_sol(idxT), UNUSED);
            end
        end
    end
    
    % INPUT
    %   point: CDS_Point with all properties appropriately set
    function AddPoint_Analytic(this, point)
        arguments
            this(1,1)
            point(1,1) CDS_Point
        end
        this.CalcTransforms_Analytic(this.params.const, point);
    end
    
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
    % INPUT:
    %   point: CDS_Point with all properties except T_0n appropriately set (T_0n is ignored)
    %   T_w0: Static transformation
    %   R_wd: Rotation component of T_wd.    DIM: (time, Rotation matrix in row-major order)
    %   P_wd: Translation component of T_wd. DIM: (time, [x,y,z])
    %   T_dn: Static transformation
    function AddPoint_Exp(this, point, T_w0, R_wd, P_wd, T_dn)
        arguments
            this(1,1)
            point(1,1) CDS_Point
            T_w0(1,1) CDS_T
            R_wd(:,9) double % Rotation matrix in row-major order
            P_wd(:,3) double
            T_dn(1,1) CDS_T = CDS_T(eye(4))
        end
        % Save point object
        this.p_all(end+1) = point;
        if(point.HasMass); this.p_mass(end+1) = point; end
        
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
        this.Px(end+1,:) = T_w0.x + P_wd(:,1)*R_w0(1,1)+P_wd(:,2)*R_w0(1,2)+P_wd(:,3)*R_w0(1,3)+...
            T_dn.x*(R_wd(:,1)*R_w0(1,1)+R_wd(:,4)*R_w0(1,2)+R_wd(:,7)*R_w0(1,3))+...
            T_dn.y*(R_wd(:,2)*R_w0(1,1)+R_wd(:,5)*R_w0(1,2)+R_wd(:,8)*R_w0(1,3))+...
            T_dn.z*(R_wd(:,3)*R_w0(1,1)+R_wd(:,6)*R_w0(1,2)+R_wd(:,9)*R_w0(1,3));
        this.Py(end+1,:) = T_w0.y + P_wd(:,1)*R_w0(2,1)+P_wd(:,2)*R_w0(2,2)+P_wd(:,3)*R_w0(2,3)+...
            T_dn.x*(R_wd(:,1)*R_w0(2,1)+R_wd(:,4)*R_w0(2,2)+R_wd(:,7)*R_w0(2,3))+...
            T_dn.y*(R_wd(:,2)*R_w0(2,1)+R_wd(:,5)*R_w0(2,2)+R_wd(:,8)*R_w0(2,3))+...
            T_dn.z*(R_wd(:,3)*R_w0(2,1)+R_wd(:,6)*R_w0(2,2)+R_wd(:,9)*R_w0(2,3));
        this.Pz(end+1,:) = T_w0.z + P_wd(:,1)*R_w0(3,1)+P_wd(:,2)*R_w0(3,2)+P_wd(:,3)*R_w0(3,3)+...
            T_dn.x*(R_wd(:,1)*R_w0(3,1)+R_wd(:,4)*R_w0(3,2)+R_wd(:,7)*R_w0(3,3))+...
            T_dn.y*(R_wd(:,2)*R_w0(3,1)+R_wd(:,5)*R_w0(3,2)+R_wd(:,8)*R_w0(3,3))+...
            T_dn.z*(R_wd(:,3)*R_w0(3,1)+R_wd(:,6)*R_w0(3,2)+R_wd(:,9)*R_w0(3,3));
    end
    
    % Kinematic chains (used only for plotting the animation)
    % INPUT
    %   % Cell array of linear arrays of CDS_Point instances, where each array is a chain
    function SetChains(this, chains)
        arguments
            this(1,1)
            chains(1,:) cell
        end
        % Validate all points in the chains are correct type and have been set
        for idxChain = 1:length(chains)
            chain = chains{idxChain}; % Because matlab tries to be clever in edge cases
            if ~isa(chain, "CDS_Point"); error("Bad input: Chains must be point objects"); end
            
            for point = chain
                if ~any(this.p_all == point)
                    error("Bad input: First call AddPoint_...() for: " + point.NameReadable);
                end
            end
        end
        
        % Valid => save
        this.chains = chains;
    end
end
methods (Static)
    %**********************************************************************
    % Interface - Helpers to format input
    %***********************************
    function R_rowMajor = eulerXYZ_to_R_rowMajor(eulerXYZ)
        arguments
            eulerXYZ(:,3) double
        end
        % Conversion directly from Vicon DataStream SDK Documentation
        %   because there are so many ways euler angles can be specified wrong
        x = eulerXYZ(:,1);
        y = eulerXYZ(:,2);
        z = eulerXYZ(:,3);
        R_rowMajor = [...
            cos(y).*cos(z), -cos(y).*sin(z), sin(y),...
            cos(x).*sin(z)+sin(x).*sin(y).*cos(z), cos(x).*cos(z)-sin(x).*sin(y).*sin(z), -sin(x).*cos(y),...
            sin(x).*sin(z)-cos(x).*sin(y).*cos(z), sin(x).*cos(z)+cos(x).*sin(y).*sin(z), cos(x).*cos(y)];
        
        %R = eul2rotm(eulerXYZ,"XYZ");
        %R_rowMajor = reshape(permute(R,[3,2,1]), size(R,3), 9);
    end
end
methods (Access=private)
    % Different to version in CDS_SolutionSym
    %   Removed use of q_free
    %   Adds only 1 point at a time, appending to previously saved points
    function CalcTransforms_Analytic(this, params_const, point)
        arguments
            this(1,1)
            params_const(:,1) CDS_Param_Const
            point(1,1) CDS_Point
        end
        u = [this.q_input.Sym; this.q_input.Sym(1); this.q_input.Sym(2)];
        c = params_const.Sym;
        uSol = [this.qi; this.qi_d; this.qi_dd];
        cNum = params_const.Num;
        numT = length(this.t);
        
        % Save point object
        this.p_all(end+1) = point;
        if(point.HasMass); this.p_mass(end+1) = point; end
        
        % Evaluate and save positions
        %   Preallocation to avoid errors if matlabFunction outputs a constant
        P_semiNum = subs(point.T_0n.P, c,cNum);
        Px_h = matlabFunction(P_semiNum(1),'Vars',{[sym('t'); u]});
        Py_h = matlabFunction(P_semiNum(2),'Vars',{[sym('t'); u]});
        Pz_h = matlabFunction(P_semiNum(3),'Vars',{[sym('t'); u]});
        Px=zeros(1,numT);   Px(:)=Px_h([this.t; uSol]);   this.Px(end+1,:)=Px;
        Py=zeros(1,numT);   Py(:)=Py_h([this.t; uSol]);   this.Py(end+1,:)=Py;
        Pz=zeros(1,numT);   Pz(:)=Pz_h([this.t; uSol]);   this.Pz(end+1,:)=Pz;
    end
end
end

%{
Creation should be done through CDS_Points.m

PURPOSE
    Instances of this class represent particles, rigid bodies, and massless locations of interest
    The location is defined by a transformation matrix (it has both position and orientation)

NOTATION
    T_AB means the transformation matrix that satisfies the relation P_A = T_AB * P_B, where
        P_A is a point as measured in frame A
        P_B is the same point as measured in frame B
    Frames
        0: The world frame (must be the same for all points in a system)
        n: This point, where
            The origin is at the centre of mass
            The orientation is the orientation of the body (mostly only relevant for rigid bodies)
        p: This point, where
            The origin is the same as for frame n
            The orientation is that about which the moment of inertia was measured
    The transformation T_np is intended to be a constant
%}

classdef CDS_Point < handle
properties (SetAccess=private)
    T_0n(1,1) CDS_T = CDS_T(eye(4))
    
    m(1,1) sym = 0 % Default no mass at point
    I_pn(3,3) sym = zeros(3) % Default point mass assumption
    R_np(3,3) sym = eye(3) % Default aligned
end
properties (Access=private)
    name_short(1,1) string = "_"
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    function this = CDS_Point()
        % Initialise as work around for a MATLAB memory corruption bug in live scripts
        %   related to using IfHasMass with unsuppressed output
        this.m = 0;
        this.I_pn = zeros(3);
    end
    
    %**********************************************************************
    % Interface: Set
    %***********************************
    % Pose of the point in the world frame
    % INPUT
    %   T: CDS_T, where T.T() is a symbolic expression of the parameters registered with CDS_Params
    function this = SetT_0n(this, T)
        this.T_0n = T;
    end
    
    % Mass of the point
    % INPUT
    %   m: Symbolic expression of the CDS_Param_Const parameters registered with CDS_Params
    function this = SetMass(this, m)
        this.m = m;
    end
    
    % Mass moment of inertia of the point (3x3 matrix)
    % INPUT
    %   I: Symbolic expression of the CDS_Param_Const parameters registered with CDS_Params
    function this = SetInertia(this, I)
        this.I_pn = I;
    end
    
    % Orientation at which the moment of inertia was measured, with respect to that of the point (3x3 matrix)
    % INPUT
    %   I: Symbolic expression of the CDS_Param_Const parameters registered with CDS_Params
    function this = SetInertiaR(this, R_np)
        this.R_np = R_np;
    end
    
    % Friendly name to identify the parameter by
    % Used in in outputs, error messages, generated code
    function this = SetNameShort(this, nameIn)
        this.name_short = nameIn;
    end
    
    %**********************************************************************
    % Interface: Get
    %***********************************
    % Get properties
    function nameOut = NameShort(this)
        name = this.PropArray(this.name_short);
        nameOut = string(name);
    end
    
    function name = NameReadable(this)
        nameShort = this.PropArray(this.name_short);
        name = strcat("Point ", nameShort);
    end
    
    % Test properties of the point
    function logicalOut = HasLinearInertia(this)
        mass = this.PropArray(this.m);
        logicalOut = logical(mass~=0);
    end
    function logicalOut = HasRotationalInertia(this)
        logicalOut = false(size(this));
        for idx = 1:length(this)
            logicalOut(idx) = ~isequal(this(idx).I_pn, sym(zeros(3)));
        end
    end
    function logicalOut = HasMass(this)
        logicalOut = this.HasLinearInertia | this.HasRotationalInertia;
    end
    function logicalOut = IsPointMass(this)
        logicalOut = this.HasLinearInertia & ~this.HasRotationalInertia;
    end
    function logicalOut = IsRigidBody(this)
        logicalOut = this.HasLinearInertia & this.HasRotationalInertia;
    end

    % Get specific point objects from an array of point objects
    % INPUT
    %   Same as this.PointIdx
    function pointObject = Point(this, varargin)
        pointObject = this( this.PointIdx(varargin{:}) );
    end

    % From an array of point objects, get all the point objects that have mass
    function obj = GetIfHasMass(this)
        obj = this(this.HasMass);
    end

    % Get positions of params in array of param objects
    %   The order of the output corresponds to the order of the input
    %   If a param is not found, then that element is dropped
    % INPUT:
    %   paramsIn
    %       (string): Array of the values matching the output of CDS_Point.NameShort
    %       (CDS_Point): Array of CDS_Point
    %   optDuplicates
    %       KeepDuplicates: strictly follow to the input
    %       RemoveDuplicates: Drop duplicate CDS_Point from the output
    %   optWarn
    %       EnableWarn: Warn if for one of the inputs, not matching CDS_Point is found
    %       NoWarn: Disable warnings
    % OUTPUT:
    %   Array of indices to the array calling this method
    function idxMatch = PointIdx(this, pointsIn, optDuplicates, optWarn)
        arguments
            this
            pointsIn(1,:) {mustBeA(pointsIn, ["string", "CDS_Point"])}
            optDuplicates(1,1) string {mustBeMember(optDuplicates,["KeepDuplicates","RemoveDuplicates"])} = "KeepDuplicates"
            optWarn(1,1) string {mustBeMember(optWarn,["EnableWarn","NoWarn"])} = "EnableWarn"
        end
        % Interpret input type (effectively implements input overloading)
        if isa(pointsIn, "CDS_Point")
            NameShortIn=pointsIn.NameShort;
        else
            NameShortIn=pointsIn;
        end

        % This method will match the order in the input, removing not found, but keeping duplicate points
        idxMatch=[];
        for idxIn = 1:length(NameShortIn)
            idxMatch = [idxMatch , find(NameShortIn(idxIn)==this.NameShort)];
        end
        
        if strcmp(optWarn,"EnableWarn") && length(idxMatch)~=length(NameShortIn)
            warning("Some points not found");
        end
        
        if strcmp(optDuplicates,"RemoveDuplicates")
            idxMatch=unique(idxMatch);
        end
    end
end
methods (Access=private)
    %**********************************************************************
    % Internal
    %***********************************
    % Helper to allow using functions with an array of objects
    % NOTE: Only intended for 1D arrays
    % Input: List of properties
    % OUTPUT: Array of properties corresponding to the object
    % EXAMPLE: PropArray(this.prop)
    function propArray = PropArray(this, varargin)
        propArray = reshape([varargin{:}],size(this));
    end
end
end

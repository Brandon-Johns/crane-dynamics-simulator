%{
PURPOSE
    A 4x4 homogeneous transformation matrix

THEORY
    Transformation matrices can be interpreted in may ways, leading to ambiguities
    See the How-To Reference "Transformation Matrices" for the interpretation and conventions used in this software

NOTATION
    T:     transformation matrix
    x,y,z: position vector components
    P:     [x,y,z]   position vector
    Ph:    [x,y,z,1] homogeneous position vector
    R:     rotation matrix
    at:    rotation by theta about either the x, y, or z axis
    wxyz:  [w,qx,qy,qz] quaternion
    xyzw:  [qx,qy,qz,w] quaternion

NOTES
    The properties are hidden because quat() errors for symbolic rotations
    InferiorClasses is used to make the multiplication * operator choose CDS_T.mtimes() instead of sym.mtimes()

EXAMPLE
    % See the How-To Reference "Transformation Matrices"
%}

classdef (InferiorClasses = {?sym}) CDS_T < handle
properties (SetAccess=immutable)
    % The transformation matrix
    T(4,4)    % (symbolic expression | double)
end
properties (Dependent, Hidden)
    % Deconstruct the transformation matrix into position and rotation
    P         % (symbolic expression | double) DIM[3,1] Position vector
    Ph        % (symbolic expression | double) DIM[4,1] Homogeneous position vector
    R         % (symbolic expression | double) DIM[3,3] Rotation matrix
    quat_wxyz % (double)                       DIM[1,4] Quaternion as [w,x,y,z] (for numeric T only)
    quat_xyzw % (double)                       DIM[1,4] Quaternion as [x,y,z,w] (for numeric T only)
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % Create new transformation matrix
    % INPUT
    %   See the HowTo Reference "Use the transformation matrix class CDS_T"
    function this = CDS_T(varargin)
        % Empty
        if nargin == 0
            this.T = diag([1,1,1,1]);
            return;
        end

        % Shortcut: Input T
        if nargin == 1
            this.ValidateT(varargin{1});
            this.T = varargin{1};
            return;
        end

        % Normal: Switch over inputType
        inputType = varargin{1};
        if strcmp(inputType, "T")
            this.ValidateT(varargin{2});
            this.T = varargin{2};
            return;

        elseif strcmp(inputType, "RP")
            R = varargin{2};
            P = varargin{3};

        elseif strcmp(inputType, "R")
            R = varargin{2};
            P = [0;0;0];

        elseif strcmp(inputType, "P")
            R = eye(3);
            P = varargin{2};

        elseif strcmp(inputType, "atP")
            axis = varargin{2};
            theta = varargin{3};
            R = this.R_Construct(axis, theta);
            P = varargin{4};

        elseif strcmp(inputType, "at")
            axis = varargin{2};
            theta = varargin{3};
            R = this.R_Construct(axis, theta);
            P = [0;0;0];

        elseif strcmp(inputType, "wxyzP")
            R = quat2rotm(varargin{2}(:).');
            P = varargin{3};

        elseif strcmp(inputType, "xyzwP")
            R = quat2rotm(varargin{2}([4,1,2,3])); % Convert xyzw to wxyz
            P = varargin{3};

        elseif strcmp(inputType, "wxyz")
            R = quat2rotm(varargin{2}(:).');
            P = [0;0;0];

        elseif strcmp(inputType, "xyzw")
            R = quat2rotm(varargin{2}([4,1,2,3])); % Convert xyzw to wxyz
            P = [0;0;0];

        else
            error('Invalid input: paramType')
        end

        CDS_T.ValidateR(R);
        CDS_T.ValidateP(P);
        this.T = this.RPtoT(R, P);
    end

    %**********************************************************************
    % Interface: Get (scalar properties)
    %***********************************
    % Position coordinate
    % OUTPUT
    %   (symbolic expression | double) DIM[size(this)]
    function out = x(this)
        out = zeros(size(this), class([this.T]));
        for idx = 1:numel(this)
            out(idx) = this(idx).T(1,4);
        end
    end
    function out = y(this)
        out = zeros(size(this), class([this.T]));
        for idx = 1:numel(this)
            out(idx) = this(idx).T(2,4);
        end
    end
    function out = z(this)
        out = zeros(size(this), class([this.T]));
        for idx = 1:numel(this)
            out(idx) = this(idx).T(3,4);
        end
    end

    % Inverse transformation
    % NOTE
    %   Uses mathematical properties of T => more efficient than T^-1
    % OUTPUT
    %   (CDS_T) DIM[size(this)]
    function out = Inv(this)
        out = CDS_T.Zeros(size(this));
        for idx = 1:numel(this)
            R_inv = this(idx).R.';
            out(idx) = CDS_T([[R_inv, -R_inv*this(idx).P];[0,0,0,1]]);
        end
    end

    %**********************************************************************
    % Interface: Get (vector and matrix properties)
    %***********************************
    % OUTPUT
    %   (symbolic expression | double) DIM[1,1] Comma separated array of properties
    function out = get.P(this);  out = this.T(1:3,4); end
    function out = get.Ph(this); out = this.T(:,4); end
    function out = get.R(this);  out = this.T(1:3,1:3); end
    function out = get.quat_wxyz(this); out = rotm2quat( this.T(1:3,1:3) ); end
    function out = get.quat_xyzw(this); out = this.quat_wxyz([2,3,4,1]); end

    % OUTPUT
    %   (symbolic expression | double) DIM[size(property), size(this)] Using convention (tensor dims, batch dims)
    function out = batch_T(this);  out = reshape([this.T],  [4,4, size(this)]); end
    function out = batch_P(this);  out = reshape([this.P],  [3,   size(this)]); end
    function out = batch_Ph(this); out = reshape([this.Ph], [4,   size(this)]); end
    function out = batch_R(this);  out = reshape([this.R],  [3,3, size(this)]); end
    function out = batch_quat_wxyz(this); out = reshape([this.quat_wxyz], [4, size(this)]); end
    function out = batch_quat_xyzw(this); out = reshape([this.quat_xyzw], [4, size(this)]); end

    % Batch properties, but treating the property as a 2D matrix instead of a vector
    % NOTE
    %   For use with pagemtimes()
    % OUTPUT
    %   (symbolic expression | double) DIM[size(property), 1, size(this)] Using convention (tensor dims, batch dims)
    function out = page_P(this);  out = reshape([this.P],  [3,1, size(this)]); end
    function out = page_Ph(this); out = reshape([this.Ph], [4,1, size(this)]); end

    %**********************************************************************
    % Interface: Calculate properties of the array
    %***********************************
    % Mean transformation, and standard deviation, of an array of transformations
    % OUTPUT
    %   T_mean:   (CDS_T)  DIM[1,1] Mean transformation
    %   P_std:    (double) DIM[3,1] Standard deviations of position [position units]
    %   quat_std: (double) DIM[1,1] Standard deviation by angular distance between the quaternion representations [rad]
    function [T_mean, P_std, quat_std] = Mean(this)
        if isempty(this)
            % Mean of an empty set is undefined
            T_mean = CDS_T.NaN(1,1);
            P_std = [nan; nan; nan];
            quat_std = nan;
            return
        end
        for idx = 1:numel(this)
            if isa(this(idx).T, "sym")
                error("Bad input: Mean only accepts input type 'double'")
            end
        end

        % Convert to the 'Robotics System Toolbox' quaternion object
        % Choice of 'frame' or 'point' shouldn't matter as long as it is converted back with the same
        quat = zeros(numel(this),1, 'quaternion');
        for idx = 1:numel(this)
            quat(idx) = quaternion(this(idx).R,'rotmat','frame');
        end

        % Mean rotation
        quat_mean = meanrot(quat(:));

        % Mean transformation
        %   Convert mean rotation back to rotation matrix
        R_mean = quat_mean.rotmat('frame');
        x_mean = mean(this(:).x);
        y_mean = mean(this(:).y);
        z_mean = mean(this(:).z);
        T_mean = CDS_T('RP', R_mean, [x_mean; y_mean; z_mean]);
        if nargout<2; return; end

        % Unbiased standard deviation of translation
        x_std = std(this(:).x);
        y_std = std(this(:).y);
        z_std = std(this(:).z);
        P_std = [x_std; y_std; z_std];
        if nargout<3; return; end

        % Unbiased standard deviation of rotation
        %   Couldn't find any references for how this should be defined
        %   I shall just apply the standard deviation formula on the distance from the mean
        if isscalar(this)
            % For scalar input, used biased standard deviation to avoid DivBy0 error
            quat_std=0;
        else
            quat_distFromMean = dist(quat_mean, quat);
            quat_std = sqrt(sum(quat_distFromMean.^2)/(numel(quat_distFromMean)-1));
        end
    end

    %**********************************************************************
    % Interface: Operator Overloads
    %***********************************
    % Matrix multiplication with the * operator
    % CALL MODES
    %   matrix correspondence (not necessarily input sizes)
    %       c(n,m) = a(n,m)*b(n,m)    Multiply corresponding matrices
    %       c(n,m) = a(1,1)*b(n,m)    Multiply a by (each of b)
    %       c(n,m) = a(n,m)*b(1,1)    Multiply (each of a) by b
    %   Type & size
    %       a(n,m) CDS_T
    %       a(4,4) sym|double
    %       b(n,m) CDS_T
    %       b(4,4) sym|double
    %       b(1,4) sym|double    This case requires a(1,1) CDS_T, and return is c(4,1) sym|double
    % INPUT
    %   a: (CDS_T | symbolic expression | double) Left operand.  Transformation matrices
    %   b: (CDS_T | symbolic expression | double) Right operand. Transformation matrices or homogeneous position vector
    % OUTPUT
    %   (CDS_T | symbolic expression | double) DIM[size(a) | size(b) | [1,4]]
    %       Composed transformation matrices or transformed homogeneous position vector
    % EXAMPLE
    %   a=CDS_T; b=CDS_T; c=a*b
    %   a=CDS_T; b=[1;2;3,1]; c=a*b
    function c = mtimes(a,b)
        % Format input
        is_b_Ph = false;
        if ~isa(a, "CDS_T")
            if isequal(size(a), [4,4])
                a = CDS_T(a);
            else
                error("Bad input: Left argument");
            end
        end
        if ~isa(b, "CDS_T")
            if isequal(size(b), [4,4])
                b = CDS_T(b);
            elseif isequal(size(b), [4,1])
                % Special case
                is_b_Ph = true;
                b = CDS_T("P", b);
            else
                error("Bad input: Right argument");
            end
        end

        % Multiply
        if isequal(size(a), size(b))
            c = CDS_T.Zeros(size(a));
            for idx = 1:numel(a)
                c(idx) = CDS_T(a(idx).T * b(idx).T);
            end
        elseif isscalar(a)
            c = CDS_T.Zeros(size(b));
            for idx = 1:numel(c)
                c(idx) = CDS_T(a.T * b(idx).T);
            end
        elseif isscalar(b)
            c = CDS_T.Zeros(size(a));
            for idx = 1:numel(c)
                c(idx) = CDS_T(a(idx).T * b.T);
            end
        else
            error("Bad input: Matrix correspondence must be a(n,m)*b(n,m) | a(1,1)*b(n,m) | a(n,m)*b(1,1)");
        end

        % Special case
        if is_b_Ph
            if isscalar(a) && isscalar(b)
                c=c.Ph;
            else
                error("Bad input: When the right input is a position vector, the left input must be scalar");
            end
        end
    end
end
methods (Static)
    % Create an array of identity transformations
    % INPUT
    %   The size of the array to create. As an array or a comma separated list
    % OUTPUT
    %   (CDS_T) DIM[size] Array of identity transformation matrices
    % EXAMPLE
    %   objectArray = CDS_T.Zeros([4,5]);
    %   objectArray = CDS_T.Zeros(4,5);
    function builtObjects = Zeros(size)
        arguments (Repeating)
            size(1,:) uint64
        end
        sizeArray = [size{:}];
        if nargin==0  || isempty(sizeArray) || any(sizeArray==0)
            builtObjects = CDS_T.empty(sizeArray);
            return;
        end
        sizeAsCell = num2cell(sizeArray);
        builtObjects(sizeAsCell{:}) = CDS_T();
    end

    % Create an array of NaN transformations
    % INPUT
    %   The size of the array to create. As an array or a comma separated list
    % OUTPUT
    %   (CDS_T) DIM[size] Array of transformation matrices filled with NaN
    % EXAMPLE
    %   objectArray = CDS_T.NaN([4,5]);
    %   objectArray = CDS_T.NaN(4,5);
    function builtObjects = NaN(size)
        arguments (Repeating)
            size(1,:) uint64
        end
        builtObjects = CDS_T.Zeros(size{:});
        for idx = 1 : numel(builtObjects)
            builtObjects(idx) = [nan(3,4);[0,0,0,1]];
        end
    end
end
methods (Static, Access=private)
    %{
    Construct R
    INPUT
        [axis, theta] = rotation of theta about 'x','y',z'
    OUTPUT
        R
    %}
    function R = R_Construct(axis, theta)
        if axis == 'x'
            R = [1,0,0; 0,cos(theta),-sin(theta); 0,sin(theta),cos(theta)];
        elseif axis == 'y'
            R = [cos(theta),0,sin(theta); 0,1,0; -sin(theta),0,cos(theta)];
        elseif axis == 'z'
            R = [cos(theta),-sin(theta),0; sin(theta),cos(theta),0; 0,0,1];
        else
            error('Bad input: Axis must be one of x,y,z')
        end

        if isa(theta, 'sym')...
                && length(symvar(theta)) <= 1 % Catch complex sym expressions
            R = simplify(expand(R));
        end
    end

    % Swap between T, R, P
    function T = RPtoT(R, P)
        P = P(:); % Force vertical vector
        P = P(1:3); % remove P(4) if homogeneous position
        T = [[R,P];[0,0,0,1]];
    end
    function P = PhtoP(Ph)
        Ph = Ph(:); % Force vertical vector
        P = Ph(1:3);
    end
    function Ph = PtoPh(P)
        P = P(:); % Force vertical vector
        Ph = [P(1:3); 1];
    end

    function ValidateT(in)
        if ~any(class(in)==["double","sym"])
            error("Bad input: Transformation matrix must be of type the 'double' or 'sym'");
        end
        if ~(ismatrix(in) && all(size(in)==[4,4]))
            error("Bad input: Transformation matrix must be size 4x4");
        end
        if ~all(in(4,:)==[0,0,0,1])
            error("Bad input: Transformation matrix is malformed");
        end
    end

    function ValidateR(in)
        if ~any(class(in)==["double","sym"])
            error("Bad input: Rotation matrix must be of type the 'double' or 'sym'");
        end
        if ~(ismatrix(in) && all(size(in)==[3,3]))
            error("Bad input: Rotation matrix must be size 3x3");
        end
    end

    function ValidateP(in)
        if ~any(class(in)==["double","sym"])
            error("Bad input: Position vector must be of type the 'double' or 'sym'");
        end
        if ~(isvector(in) && (length(in)==3 || length(in)==4))
            error("Bad input: Position vector must be size 3x1 or 4x1");
        end
        if length(in)==4 && ~logical(in(4)==1)
            error("Bad input: Homogeneous position vector is malformed");
        end
    end
end
end

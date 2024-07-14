%{
PURPOSE
    Hold a 4x4 homogeneous transformation matrix

NOTES
    Object is immutable
    => Create new instead of editing

EXAMPLE
    % See the HowTo Reference "Use the transformation matrix class CDS_T"
%}

classdef CDS_T < handle
properties (SetAccess=immutable)
    T(4,4)
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    function this = CDS_T(varargin)
        % Empty
        if nargin == 0
            this.T = diag([1,1,1,1]);
            return;
        end
        
        % Shortcut: Input T
        if nargin == 1
            this.T = varargin{1};
            return;
        end
        
        % Normal: Switch over inputType
        inputType = varargin{1};
        if strcmp(inputType, "T")
            this.T = varargin{2};
            
        elseif strcmp(inputType, "RP")
            R = varargin{2};
            P = varargin{3};
            this.T = this.RPtoT(R, P);
            
        elseif strcmp(inputType, "R")
            R = varargin{2};
            P = [0;0;0];
            this.T = this.RPtoT(R, P);
            
        elseif strcmp(inputType, "P")
            R = eye(3);
            P = varargin{2};
            this.T = this.RPtoT(R, P);
            
        elseif strcmp(inputType, "atP")
            axis = varargin{2};
            theta = varargin{3};
            P = varargin{4};
            this.T = this.T_ConstructPR(axis, theta, P);
            
        elseif strcmp(inputType, "at")
            axis = varargin{2};
            theta = varargin{3};
            P = [0;0;0];
            this.T = this.T_ConstructPR(axis, theta, P);
            
        else
            error('Invalid input: paramType')
        end
    end
    
    %**********************************************************************
    % Interface: Get
    %***********************************
    % x, y, z
    function out = x(this); out = this.T(1,4); end
    function out = y(this); out = this.T(2,4); end
    function out = z(this); out = this.T(3,4); end
    
    % R, P, Ph
    function out = R(this); out = this.T(1:3,1:3); end
    function out = P(this); out = this.T(1:3,4); end
    function out = Ph(this); out = this.T(1:4,4); end
    
    % Return inverse of T (this object remains unchanged)
    %   Uses mathematical properties of T => cleaner & more efficient than T^-1
    function T_inverted = Inv(this)
        R_transpose = (this.R).';
        T_inverted =  CDS_T("RP", R_transpose, -R_transpose*this.P);
    end
    
    %**********************************************************************
    % Interface: Operator Overloads
    %***********************************
    function c = mtimes(a,b)
        if isa(a, "CDS_T"); a=a.T; end
        if isa(b, "CDS_T"); b=b.T; end
        c = a*b;
        % If result is a T, return as a CDS_T object
        if all(size(c)==[4,4]); c=CDS_T(c); end
    end
end
methods (Access=private)
    %{
    Construct T as: move, then rotate
        User to call
    INPUT
        P = position
        [axis, theta] = rotation of theta about 'x','y',z'
    OUTPUT
        T
    %}
    function T = T_ConstructPR(this, axis, theta, P)
        T = this.RPtoT(this.R_Construct(axis, theta), P);
    end
    
    %{
    Construct R
    INPUT
        [axis, theta] = rotation of theta about 'x','y',z'
    OUTPUT
        R
    %}
    function R = R_Construct(~, axis, theta)
        if axis == 'x'
            R = [1,0,0; 0,cos(theta),-sin(theta); 0,sin(theta),cos(theta)];
        elseif axis == 'y'
            R = [cos(theta),0,sin(theta); 0,1,0; -sin(theta),0,cos(theta)];
        elseif axis == 'z'
            R = [cos(theta),-sin(theta),0; sin(theta),cos(theta),0; 0,0,1];
        else
            error('Bad input')
        end
        
        if isa(theta, 'sym')...
                && length(symvar(theta)) <= 1 % Catch complex sym expressions
            R = simplify(expand(R));
        end
    end
    
    % Swap between T, R, P
    function T = RPtoT(~, R, P)
        P = P(:); % Force vertical vector
        P = P(1:3); % remove P(4) if homogeneous position
        T = [[R,P];[0,0,0,1]];
    end
    function P = PhtoP(~, Ph)
        Ph = Ph(:); % Force vertical vector
        P = Ph(1:3);
    end
    function Ph = PtoPh(~, P)
        P = P(:); % Force vertical vector
        Ph = [P(1:3); 1];
    end
end
end

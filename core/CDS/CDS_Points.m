%{
PURPOSE
    Build instances of CDS_Point
    Track every instance that it creates
    Automatically create and register associated CDS_Param instances for mass and inertia

NOTES
    Using builder and factory patterns
%}

classdef CDS_Points < handle
properties (SetAccess=private)
    % The points created by this instance
    all(:,1) CDS_Point
end
properties (Access=private)
    params(1,1) CDS_Params
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    % INPUT
    %   params: CDS_Params
    function this = CDS_Points(params)
        % Register the parameter tracking object for creation of new parameters
        this.params = params;
    end
    
    % Build instances of CDS_Point
    % INPUT
    %   sym_append: String to represent the point (each point must have a unique name)
    %   mass_num:
    %       (default=0) Mass of the point.
    %       If non-zero, then a CDS_Param_Const is automatically created with sym="m"+sym_append
    %   inertia_num
    %       (default = 0 matrix) (3x3 matrix) Mass moment of inertia of the point.
    %       If non-zero, then a set of CDS_Param_Const are automatically created with sym="I_xx"+sym_append, etc.
    %       The associated orientation should be configured with CDS_Point.SetInertiaR
    %       An input 3x1 matrix is automatically expanded into a diagonal 3x3 matrix
    % OUTPUT
    %   The created point
    %   The remaining properties are default zero. Change these by calling the set methods on the output
    function pointObject = Create(this, sym_append, mass_num, inertia_num)
        arguments
            this
            sym_append(1,1) string % Required input
            mass_num(1,1) double {mustBeFinite(mass_num)} = 0
            inertia_num(:,:) double {mustBeFinite(inertia_num)} = [0;0;0]
        end
        % Check Moment of inertia input
        if isvector(inertia_num); inertia_num=inertia_num(:); end
        if ( isvector(inertia_num) && length(inertia_num)~=3 ) || ( ~isvector(inertia_num) && any(size(inertia_num,1)~=3) )
            error("Moment of inertia must be size: 3x1 or 3x3");
        end
        
        % Check if duplicate
        if ~isempty(this.Point(sym_append,"KeepDuplicates","NoWarn"))
            error('Point already exists and registered: %s', sym_append)
        end
        
        % Create and register
        pointObject = CDS_Point();
        this.all(end+1) = pointObject;
        
        % Name
        pointObject.SetNameShort(sym_append);
        
        % Mass
        if mass_num == 0
            %
        else
            % Create new parameters & set num
            m = this.params.Create('const', strcat('m',sym_append));
            m.SetNum(mass_num);
            
            pointObject.SetMass(m.Sym);
        end
        
        % Inertia
        % Create new parameters & set num
        if isequal(inertia_num, [0;0;0]) || isequal(inertia_num, zeros(3,3))
            % No Moment of inertia (No mass or Point mass)
        elseif isvector(inertia_num)
            % Moment of inertia aligned with principle axis
            Ixx = this.params.Create('const', strcat('I_xx',sym_append));
            Iyy = this.params.Create('const', strcat('I_yy',sym_append));
            Izz = this.params.Create('const', strcat('I_zz',sym_append));
            Ixx.SetNum(inertia_num(1));
            Iyy.SetNum(inertia_num(2));
            Izz.SetNum(inertia_num(3));
            
            pointObject.SetInertia(diag([Ixx.Sym, Iyy.Sym, Izz.Sym]));
        else
            % General moment of inertia tensor
            Ixx = this.params.Create('const', strcat('I_xx',sym_append)).SetNum(inertia_num(1,1));
            Ixy = this.params.Create('const', strcat('I_xy',sym_append)).SetNum(inertia_num(1,2));
            Ixz = this.params.Create('const', strcat('I_xz',sym_append)).SetNum(inertia_num(1,3));
            Iyx = this.params.Create('const', strcat('I_yx',sym_append)).SetNum(inertia_num(2,1));
            Iyy = this.params.Create('const', strcat('I_yy',sym_append)).SetNum(inertia_num(2,2));
            Iyz = this.params.Create('const', strcat('I_yz',sym_append)).SetNum(inertia_num(2,3));
            Izx = this.params.Create('const', strcat('I_zx',sym_append)).SetNum(inertia_num(3,1));
            Izy = this.params.Create('const', strcat('I_zy',sym_append)).SetNum(inertia_num(3,2));
            Izz = this.params.Create('const', strcat('I_zz',sym_append)).SetNum(inertia_num(3,3));
            
            inertia_sym = [Ixx.Sym,Ixy.Sym,Ixz.Sym; Iyx.Sym,Iyy.Sym,Iyz.Sym; Izx.Sym,Izy.Sym,Izz.Sym];
            pointObject.SetInertia(inertia_sym);
        end
    end
    
    %**********************************************************************
    % Interface: Get
    %***********************************
    % Get specific point objects
    % INPUT
    %   Same as CDS_Point.PointIdx
    function pointObject = Point(this, varargin)
        pointObject = this.all.Point(varargin{:});
    end
    
end
end
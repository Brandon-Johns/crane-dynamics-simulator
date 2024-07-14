%{
'C3' models series

PURPOSE
    Stores preset numerical values for use across all models
%}

classdef CDSv_C3 < CDSv
properties (Access=public)
    %**********************************************************************
    % Geometry Preset
    %***********************************
    % Geometry
    phi_1(1,1) double = nan
    L_AB(1,1) double = nan
    L_BC(1,1) double = nan
    L_CD(1,1) double = nan
    L_EF(1,1) double = nan
    L_FG(1,1) double = nan
    L_GH(1,1) double = nan
    L_FJ(1,1) double = nan
    L_JK(1,1) double = nan
    L_KL(1,1) double = nan
    L_LM(1,1) double = nan
    
    theta_3_eq(1,1) double = nan
    a_DE_eq(1,1) double = nan
    
    % Mass
    g(1,1) double = nan
    mass_K(1,1) double = nan
    mass_M(1,1) double = nan
    inertia_K(:,:) double {ValidateInertia} = [nan,nan,nan]
    inertia_M(:,:) double {ValidateInertia} = [nan,nan,nan]
    
    %**********************************************************************
    % Input Preset
    %***********************************
    % Input
    % theta_1 (slew), theta_2 (luff), theta_10 (skew)
    t_max(1,1) double = nan
    theta_1_t(1,:) {mustBeA(theta_1_t, ["sym", "double", "cell"])} = nan
    theta_2_t(1,:) {mustBeA(theta_2_t, ["sym", "double", "cell"])} = nan
    theta_10_t(1,:) {mustBeA(theta_10_t, ["sym", "double", "cell"])} = nan

    Flag_2DPermitted(1,1) {ValidateFlag} = nan
    
    %**********************************************************************
    % ICs: Dependent on Geometry & Input
    %***********************************
    % ICs
    theta_3_IC(1,1) double = nan
    theta_4_IC(1,1) double = nan
    theta_5_IC(1,1) double = nan
    theta_6_IC(1,1) double = nan
    theta_7_IC(1,1) double = nan
    theta_11_IC(1,1) double = nan
    a_DE_IC(1,1) double = nan
    theta_p1i_IC(1,1) double = nan
    theta_p2i_IC(1,1) double = nan
    theta_p1o_IC(1,1) double = nan
    theta_p2o_IC(1,1) double = nan
    theta_p1s_IC(1,1) double = nan
    
    %**********************************************************************
    % Dependent - Calculated During Build
    %***********************************
    % Geometry
    imagRope(1,1) double = nan

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Experimental Parameters
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %**********************************************************************
    % Geometry Preset - to Frame
    %***********************************
    % Data World frame (Z-UP) to Simulator world frame (Y-UP)
    T_w0(1,1) CDS_T

    % VDS Object -> specific frame
    T_BH_frameB(1,1) CDS_T
    T_HB_frameF(1,1) CDS_T
    T_HB_frameG1(1,1) CDS_T
    T_HB_frameJ1(1,1) CDS_T
    T_HB_frameJ2(1,1) CDS_T

    %**********************************************************************
    % Geometry Preset - to Position
    %***********************************
    % Ending at the given position, but no specific ending orientation enforced
    % => Must be last transformation in sequence

    % VDS Object -> point of interest
    T_BH_I(1,1) CDS_T % 1p joint: BH-rope (I_fixed per the physical pendulum model)
    T_HB_J(1,1) CDS_T % 1p joint: rope-HB
    T_HB_K(1,1) CDS_T % COM: HB
    T_HB_L(1,1) CDS_T % Joint: HB-P (measured with respect to HB)
    T_PP_L(1,1) CDS_T % Joint: HB-P (measured with respect to P)
    T_PP_M(1,1) CDS_T % COM: P
    T_BH_B(1,1) CDS_T
    T_BH_C(1,1) CDS_T
    T_HB_F(1,1) CDS_T % HB, axis of front sheave
    T_HB_G(1,1) CDS_T % HB, axis of back sheave
    
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    function this = CDSv_C3(varargin)
        % Call superclass constructor
        this@CDSv(varargin{:});
    end

    %**********************************************************************
    % Interface: Get
    %***********************************
    function ValidateIsSet(this, value)
        if iscell(value); return; end
        if this.Build_Complete && any(isnan(value)); warning("Property is nan. It may not have been set"); end
    end

    % Catch any variables that were missed
    function out = get.phi_1(this); out=this.phi_1; this.ValidateIsSet(out); end
    function out = get.L_AB(this); out=this.L_AB; this.ValidateIsSet(out); end
    function out = get.L_BC(this); out=this.L_BC; this.ValidateIsSet(out); end
    function out = get.L_CD(this); out=this.L_CD; this.ValidateIsSet(out); end
    function out = get.L_EF(this); out=this.L_EF; this.ValidateIsSet(out); end
    function out = get.L_FG(this); out=this.L_FG; this.ValidateIsSet(out); end
    function out = get.L_GH(this); out=this.L_GH; this.ValidateIsSet(out); end
    function out = get.L_FJ(this); out=this.L_FJ; this.ValidateIsSet(out); end
    function out = get.L_JK(this); out=this.L_JK; this.ValidateIsSet(out); end
    function out = get.L_KL(this); out=this.L_KL; this.ValidateIsSet(out); end
    function out = get.L_LM(this); out=this.L_LM; this.ValidateIsSet(out); end
    function out = get.theta_3_eq(this); out=this.theta_3_eq; this.ValidateIsSet(out); end
    function out = get.a_DE_eq(this); out=this.a_DE_eq; this.ValidateIsSet(out); end

    function out = get.g(this); out=this.g; this.ValidateIsSet(out); end
    function out = get.mass_K(this); out=this.mass_K; this.ValidateIsSet(out); end
    function out = get.mass_M(this); out=this.mass_M; this.ValidateIsSet(out); end
    function out = get.inertia_K(this); out=this.inertia_K; this.ValidateIsSet(out); end
    function out = get.inertia_M(this); out=this.inertia_M; this.ValidateIsSet(out); end

    function out = get.t_max(this); out=this.t_max; this.ValidateIsSet(out); end
    function out = get.theta_1_t(this); out=this.theta_1_t; this.ValidateIsSet(out); end
    function out = get.theta_2_t(this); out=this.theta_2_t; this.ValidateIsSet(out); end
    function out = get.theta_10_t(this); out=this.theta_10_t; this.ValidateIsSet(out); end
    function out = get.Flag_2DPermitted(this); out=this.Flag_2DPermitted; this.ValidateIsSet(out); end
    
    function out = get.theta_3_IC(this); out=this.theta_3_IC; this.ValidateIsSet(out); end
    function out = get.theta_4_IC(this); out=this.theta_4_IC; this.ValidateIsSet(out); end
    function out = get.theta_5_IC(this); out=this.theta_5_IC; this.ValidateIsSet(out); end
    function out = get.theta_6_IC(this); out=this.theta_6_IC; this.ValidateIsSet(out); end
    function out = get.theta_7_IC(this); out=this.theta_7_IC; this.ValidateIsSet(out); end
    function out = get.theta_11_IC(this); out=this.theta_11_IC; this.ValidateIsSet(out); end
    function out = get.a_DE_IC(this); out=this.a_DE_IC; this.ValidateIsSet(out); end
    function out = get.theta_p1i_IC(this); out=this.theta_p1i_IC; this.ValidateIsSet(out); end
    function out = get.theta_p2i_IC(this); out=this.theta_p2i_IC; this.ValidateIsSet(out); end
    function out = get.theta_p1o_IC(this); out=this.theta_p1o_IC; this.ValidateIsSet(out); end
    function out = get.theta_p2o_IC(this); out=this.theta_p2o_IC; this.ValidateIsSet(out); end
    function out = get.theta_p1s_IC(this); out=this.theta_p1s_IC; this.ValidateIsSet(out); end

    function out = get.imagRope(this); out=this.imagRope; this.ValidateIsSet(out); end

end
end

function ValidateInertia(in)
    if ( isvector(in) && length(in)~=3 ) || ( ~isvector(in) && any(size(in)~=3) )
        error("Moment of inertia must be size: 3x1 or 3x3");
    end
end

function ValidateFlag(in)
    % Only allow these to be implicitly converted
    if in==1; in=true; end
    if in==0; in=false; end
    
    if ~( islogical(in) || isnan(in) )
        error("Value must be a logical or NaN (unset)")
    end
end

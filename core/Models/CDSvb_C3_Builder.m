%{
'C3' models series

PURPOSE
    Build CDSv_C3 from predefined sets of values
%}

classdef CDSvb_C3_Builder < handle
properties (Access=protected)
    % Object to build
    Values(1,1) CDSv_C3

    % Check build progress
    Build_Geometry_called(1,1) logical = 0;
    Build_Input_called(1,1) logical = 0;
    Build_ICs_called(1,1) logical = 0;
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    function this = CDSvb_C3_Builder(geometryPreset, inputPreset)
        this.Values.g = 9.8;
        this.Build_Geometry(geometryPreset);
        this.Build_Input(inputPreset);
        this.Build_ICs;
    end
    
    %**********************************************************************
    % Interface: Set option
    %***********************************
    function this = SetPointMass(this)
        if ~( this.Build_Geometry_called )
            error("Must build Geometry first")
        end
        this.Values.inertia_K = [0,0,0];
        this.Values.inertia_M = [0,0,0];
    end

    %**********************************************************************
    % Interface: Retrieve copy of built object
    %***********************************
    function V = Values_Sim(this)
        V = copy(this.Values);

        % Enable warnings on any unset properties
        V.Set_BuildComplete;
    end

    function V = Values_Exp(this)
        V = copy(this.Values);

        % Enable warnings on any unset properties
        V.Set_BuildComplete;
    end
end
methods (Access=protected)
    %**********************************************************************
    % Interface: Build
    %***********************************
    function Build_Geometry(this, geometryPreset)
        this.Build_Geometry_called = 1;
        V = this.Values;
        
        fprintf('Geometry Preset: ')
        switch geometryPreset
        case 1
            fprintf('All lengths roughly similar to each other')
            % Define position of I
            %   Base roughly on equilibrium conditions for theta_2=45deg
            %   Assume ropes parallel (otherwise dependent on hoist length... not fun)
            %   => rope leaves pulley vertically
            theta_2_eq = sym(pi/4);
            V.phi_1 = deg2rad(60);
            V.theta_3_eq = V.phi_1 - theta_2_eq;
            V.a_DE_eq = 3;

            % Adjust L_FG to make ropes parallel @ t2=45deg, equilibrium
            V.L_AB = 2;
            V.L_BC = 1;
            V.L_CD = 0.25;
            V.L_EF = 0.25;
            V.L_GH = V.L_EF;
            V.L_FG = V.L_CD + V.L_BC*cos(V.theta_3_eq) - 2*V.L_EF;
            V.L_FJ = V.L_FG/2;
            V.L_JK = 1;
            V.L_KL = 0.25;
            V.L_LM = 1;

            V.mass_K = 1;
            V.mass_M = 1;
            V.inertia_K = [1,1,1];
            V.inertia_M = [1,1,1];
        case 2
            fprintf('Approx~ Liebherr 710 HC-L 32/64\n')
            fprintf('Approx~ glass body of a CW 3700*1600*(8*3) (*3 for Triple glazed)')
            theta_2_eq = sym(pi/4);
            % theta_2_eq = deg2rad(13.56); % measured roughly: minimum angle
            V.phi_1 = deg2rad(28); % measured roughly
            V.theta_3_eq = V.phi_1 - theta_2_eq;
            V.a_DE_eq = 50; % random

            V.L_AB = 60.22; % measured roughly
            V.L_BC = 1.13; % measured roughly
            V.L_CD = 0.56; % measured roughly
            V.L_EF = 0.51; % measured roughly
            V.L_GH = V.L_EF;
            V.L_FG = V.L_CD + V.L_BC*cos(V.theta_3_eq) - 2*V.L_EF; % unfortunate requirement
            V.L_FJ = V.L_FG/2;
            V.L_JK = 0.7; % from rough model
            V.L_KL = 1.5; % from rough model
            V.L_LM = 1.85; % random CW
            
            V.mass_K = 2580; % from rough model
            V.mass_M = 350; % random CW
            V.inertia_K = [541,1938,2153]; % from rough model
            V.inertia_M = [75,398,473]; % random CW
        case {3, 4, 5, 6}
            fprintf('Experiment')
            if geometryPreset==3 || geometryPreset==5
                fprintf(' with CWM')
                payload="PL";
            else
                fprintf(' with Concrete')
                payload="PH";
            end
            
            cableThickness = ( 2 )*1e-3; % Very Roughly
        
            V.phi_1 = 0; % (SolidWorks)
            V.L_BC = ( 40 )*1e-3; % (SolidWorks)
            V.L_CD = ( 20 )*1e-3 + cableThickness; % (SolidWorks)
            V.L_EF = ( 7.5 )*1e-3 + cableThickness; % (SolidWorks)
            V.L_GH = V.L_EF; % (Checked)
            V.L_FG = ( 45 )*1e-3; % (SolidWorks)
            V.L_FJ = V.L_FG/2; % (Checked)
            
            % Boom head
            L_BI = ( 30 )*1e-3; % (SolidWorks)

            % Hook Block
            V.L_JK = ( 36.6 )*1e-3; % (SolidWorks)
            L_JL = ( 120 )*1e-3; % (SolidWorks)
            V.L_KL = L_JL - V.L_JK; % (Checked)
            V.mass_K = ( 480 - (48+23) )*1e-3; % (Measured)
            V.inertia_K = [422027, 560155, 718679]*1e-9; % (SolidWorks) MOI @COM, aligned to Frame K1

            V.T_w0 = CDS_T("at", "x", -sym(pi/2)); % (Checked)
            V.T_BH_I = CDS_T("P", [(15-7.5); 40; -65.55]*1e-3 ); % (SolidWorks)
            V.T_HB_J = CDS_T("P", [42.5; -(30.5+6.4); 0]*1e-3 ); % (SolidWorks)
            V.T_HB_K = V.T_HB_J * CDS_T("P", [0; 0; -V.L_JK]); % (Checked)
            V.T_HB_L = V.T_HB_J * CDS_T("P", [0; 0; -L_JL]); % (Checked)
            
            V.T_BH_B = V.T_BH_I * CDS_T("P", [-L_BI; 0; 0]); % (Checked)
            V.T_BH_C = V.T_BH_I * CDS_T("P", [-L_BI+V.L_BC; 0; 0]); % (Checked)
            V.T_HB_F = V.T_HB_J * CDS_T("P", [V.L_FJ; 0; 0]); % (Checked)
            V.T_HB_G = V.T_HB_J * CDS_T("P", [-V.L_FJ; 0; 0]); % (Checked)

            V.T_BH_frameB  = V.T_BH_B * CDS_T('at','x',sym(pi/2));
            V.T_HB_frameF  = V.T_HB_F * CDS_T('at','y',sym(pi)) * CDS_T('at','x',sym(pi/2)); % Same rotation between F,G1,J1
            V.T_HB_frameG1 = V.T_HB_G * CDS_T('at','y',sym(pi)) * CDS_T('at','x',sym(pi/2));
            V.T_HB_frameJ1 = V.T_HB_J * CDS_T('at','y',sym(pi)) * CDS_T('at','x',sym(pi/2));
            V.T_HB_frameJ2 = V.T_HB_frameJ1 * CDS_T('at', 'z', sym(pi/2));

            % Mass properties - Payload
            if payload=="PL"
                V.L_LM = ( 57 )*1e-3; % (SolidWorks)
                V.T_PP_L = CDS_T("P", [-(6.8+2-2.5); 50; 125]*1e-3 ); % (SolidWorks)
                V.T_PP_M = V.T_PP_L * CDS_T("P", [0; 0; -V.L_LM] ); % (Checked)
                V.mass_M = ( 48+23 )*1e-3; % (Measured)
                V.inertia_M = [57723, 129136, 183568]*1e-9; % (SolidWorks) MOI @COM, aligned to Frame L
            elseif payload =="PH"
                V.L_LM = ( 73 )*1e-3; % (SolidWorks)
                V.T_PP_L = CDS_T("P", [-(7.0+5-2.5); 50; 125]*1e-3 ); % (SolidWorks)
                V.T_PP_M = V.T_PP_L * CDS_T("P", [0; 0; -V.L_LM] ); % (Checked)
                V.mass_M = ( 563+23 )*1e-3; % (Measured)
                V.inertia_M = [681284, 768408, 1443496]*1e-9; % (SolidWorks) MOI @COM, aligned to Frame L
            end

            % These values should be filled out when importing the experiment, but here's some dummy values for planning experiments
            if any(geometryPreset==[5,6])
                fprintf(' - with rough values to fill in [L_AB, theta_3_eq, a_DE_eq]')
                % theta_3_eq: See notes in case 1
                theta_2_eq = sym(pi/4);
                V.theta_3_eq = V.phi_1 - theta_2_eq;

                V.L_AB = 1.108; % Based off a trial from Exp2021-11-29
                V.a_DE_eq = 0.6; % Based off a trial from Exp2021-11-29
            else
                warning("Use with CDSm_C3_ImportExp_v1.m to set [L_AB, theta_3_eq, a_DE_eq]")
            end
        case 7
            fprintf('Variation of Experiment with Concrete - Resized to parallel cable')
            cableThickness = ( 2 )*1e-3;
            % theta_3_eq: See notes in case 1
            theta_2_eq = sym(pi/4); % Rough values
            V.phi_1 = sym(pi/4); % Rough values
            V.theta_3_eq = V.phi_1 - theta_2_eq; % Rough values
            V.a_DE_eq = 0.6; % Rough values
            V.L_AB = 1.108;
            V.L_BC = ( 40 )*1e-3;
            V.L_CD = ( 20 )*1e-3 + cableThickness;
            V.L_EF = ( 7.5 )*1e-3 + cableThickness;
            V.L_GH = V.L_EF;
            V.L_FG = V.L_CD + V.L_BC*cos(V.theta_3_eq) - 2*V.L_EF; % Modified: Parallel cable
            V.L_FJ = V.L_FG/2;
            V.L_JK = ( 36.6 )*1e-3;
            L_JL = ( 120 )*1e-3;
            V.L_KL = L_JL - V.L_JK;
            V.L_LM = ( 73 )*1e-3; % Version: PH
            V.mass_K = ( 480 - (48+23) )*1e-3;
            V.inertia_K = [422027, 560155, 718679]*1e-9;
            V.mass_M = ( 563+23 )*1e-3; % Version: PH
            V.inertia_M = [681284, 768408, 1443496]*1e-9; % Version: PH

        otherwise
            error("Bad input: Geometry Preset")
        end
        fprintf('\n')
    end
    
    function Build_Input(this, inputPreset)
        this.Build_Input_called = 1;
        V = this.Values;
        M_PI = pi; % C/C++ notation for pi

        fprintf('Input Preset: ')
        syms t
        switch inputPreset
        case 0
            fprintf('Stationary with skew=pi/2)')
            V.Flag_2DPermitted = true;

            tm = 5;
            V.t_max = tm;
            V.theta_1_t = 0;
            V.theta_2_t = pi/4;
            V.theta_10_t = pi/2;
        case 1
            fprintf('Luffing & Slewing: ramped sin')
            V.Flag_2DPermitted = false;

            tm = 10;
            V.t_max = tm;
            V.theta_1_t = (t/tm)*0.4*(pi/4)*sin(2*t);
            V.theta_2_t = (t/tm)*0.4*(pi/4)*sin(3*t) + pi/4;
            V.theta_10_t = 0;
        case 2
            fprintf('Luffing & Slewing: ramped sin (Mod case 1 with skew=pi/2)')
            V.Flag_2DPermitted = false;
            
            tm = 10;
            V.t_max = tm;
            V.theta_1_t = (t/tm)*0.4*(pi/4)*sin(2*t);
            V.theta_2_t = (t/tm)*0.4*(pi/4)*sin(3*t) + pi/4;
            V.theta_10_t = pi/2; % mod from case 1
        case 3
            fprintf('Luffing only')
            V.Flag_2DPermitted = true;
            
            tm = 10;
            V.t_max = tm;
            V.theta_1_t = 0;
            V.theta_2_t = (t/tm)*0.4*(pi/4)*sin(3*t) + pi/4;
            V.theta_10_t = pi/2;
        case 4
            fprintf('Slewing only')
            V.Flag_2DPermitted = false;
            
            tm = 10;
            V.t_max = tm;
            V.theta_1_t = (t/tm)*0.4*(pi/4)*sin(2*t);
            V.theta_2_t = pi/4;
            V.theta_10_t = pi/2;
        case 5
            fprintf('For large crane')
            V.Flag_2DPermitted = false;
            
            w_slew = 0.6*(2*pi/60); % rpm to rad/s
            w_luff_ = 1.4; % min/(cycle of ~pi/2 rad)
            w_luff = (1/w_luff_)*((pi/2)/60); % min/(cycle of ~pi/2 rad) to rad/s
            
            tm = 120;
            V.t_max = tm;
            V.theta_1_t = (t/tm)*0.8*(pi/4)*sin(w_slew*t);
            V.theta_2_t = (t/tm)*0.8*(pi/4)*sin(w_luff*t) + pi/4;
            V.theta_10_t = pi/2;
        case 6
            fprintf("Luffing & Slewing (Exp: 2021-11-29 'motion1')")
            V.Flag_2DPermitted = false;
            
            tm = 15;
            amplitudeB = 35; % deg
            periodB = 5; % seconds
            amplitudeS = 22.5; % deg
            periodS = 15/4; % seconds
            q_startS = deg2rad(45); % rad
            V.t_max = tm;
            V.theta_1_t = (t/tm) * (amplitudeB * M_PI/180) * sin((2*M_PI/periodB)*t);
            V.theta_2_t = q_startS + ((t)/tm) * (amplitudeS * M_PI/180) * ( cos((2*M_PI/periodS)*t) - 1 );
            V.theta_10_t = pi/2;
        case 7
            fprintf("Luffing (Exp: 2021-11-29 'motion2')")
            V.Flag_2DPermitted = true;
            
            tm = 15;
            amplitudeS = 22.5; % deg
            periodS = 15/4; % seconds
            q_startS = deg2rad(45); % rad
            V.t_max = tm;
            V.theta_1_t = 0;
            V.theta_2_t = q_startS + ((t)/tm) * (amplitudeS * M_PI/180) * ( cos((2*M_PI/periodS)*t) - 1 );
            V.theta_10_t = pi/2;
        case 8
            fprintf("Slewing (Exp: 2021-11-29 'motion3')")
            V.Flag_2DPermitted = false;
            
            tm = 15;
            amplitudeB = 35; % deg
            periodB = 2.5; % seconds
            q_startS = deg2rad(45); % rad
            V.t_max = tm;
            V.theta_1_t = (t/tm) * (amplitudeB * M_PI/180) * sin((2*M_PI/periodB)*t);
            V.theta_2_t = q_startS;
            V.theta_10_t = pi/2;
        case 9
            fprintf("Luffing up - cubic spline")
            V.Flag_2DPermitted = true;

            tm = 5;
            tS = 2; % (seconds) Time to switch piecewise function
            q_startS = deg2rad(45); % rad
            amplitudeS = deg2rad(70) - q_startS; % rad
            V.t_max = tm;
            V.theta_1_t = 0;
            V.theta_2_t = {[q_startS + amplitudeS*(-2*(t/tS).^3 + 3*(t/tS).^2), amplitudeS+q_startS], tS};
            V.theta_10_t = pi/2;
        otherwise
            error("Bad input: Input Preset")
        end
        fprintf('\n')
    end
    
    function Build_ICs(this)
        if ~( this.Build_Geometry_called && this.Build_Input_called )
            error("Must build Geometry and Inputs before ICs")
        end
        this.Build_ICs_called = 1;
        V = this.Values;
        
        % Same for all models to start in static equilibrium
        V.theta_3_IC = V.theta_3_eq;
        V.theta_4_IC = 0;
        V.theta_5_IC = 0;
        V.theta_6_IC = 0;
        V.theta_7_IC = 0;
        V.theta_11_IC = 0;
        V.a_DE_IC = V.a_DE_eq;
        V.theta_p1i_IC = 0;
        V.theta_p2i_IC = 0;
        V.theta_p1o_IC = 0;
        V.theta_p2o_IC = 0;
        V.theta_p1s_IC = 0;
    end
end
end

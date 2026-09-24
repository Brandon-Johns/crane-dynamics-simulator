%{
Written By: Brandon Johns
Date Version Created: 2024-09-16
Date Last Edited: 2026-04-11
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Example Simulation:
    Contrived pulley system to test out most of the capabilities of this simulator in 1 go


%%% SYSTEM DESCRIPTION %%%

%}
close all
clear all
clc
sympref('AbbreviateOutput',false);
sympref('MatrixWithSquareBrackets',true);
CDS_FindIncludes;
CDS_IncludeSimulator;

%**********************************************************************
% Define System
%***********************************
sys = CDS_SystemDescription();
params = sys.params;

% Generalised coordinates and system parameters
syms t real
params.Create('free', 'LA').SetIC(4);
params.Create('free', 'LB').SetIC(3);
params.Create('free', 'LC').SetIC(1);
params.Create('free', 'LD').SetIC(3);
params.Create('input', 'LE').SetAnalytic(3 + sin(3*t));
params.Create('input', 'LF').SetAnalytic(2 + sin(2*t));
params.Create('const', 'L0').SetNum(6);
params.Create('const', 'g').SetNum(9.8);
params.Create('const', 'k1').SetNum(7);
params.Create('const', 'k2').SetNum(15);
params.Create('const', 'k3').SetNum(1);
params.Create('const', 'k4').SetNum(1);
params.Create('const', 'Ln1').SetNum(0);
params.Create('const', 'Ln2').SetNum(0);
params.Create('const', 'Ln3').SetNum(0);
params.Create('const', 'Ln4').SetNum(0);
params.Create('const', 'b1').SetNum(1);
params.Create('const', 'b2').SetNum(3);
L1 = L0 - LA;
L2 = LC;
L3 = LE;
L4 = LF;
F1 = -2;
F2 = -1;

% Forward transformations as homogeneous transformation matrices
T_OA = CDS_T('P', [1;-LA;0]);
T_OB = CDS_T('P', [2;-LB;0]);
T_OC = CDS_T('P', [4;-LC;0]);
T_OD = CDS_T('P', [5;-LD;0]);
T_OE = CDS_T('P', [5;-LE-LD;0]);
T_OF = CDS_T('P', [5;-LF-LD;0]);
T_OA_gnd = CDS_T('P', [1;-L0;0]);
T_OB_gnd = CDS_T('P', [1;0;0]);
T_OC_gnd = CDS_T('P', [4;0;0]);
T_shiftL = CDS_T('P', [-0.5;0;0]);
T_shiftR = CDS_T('P', [0.5;0;0]);
T_shiftLL = CDS_T('P', [-1;0;0]);
T_shiftRR = CDS_T('P', [1;0;0]);

% Points are locations defined by a transformation matrix (they have both position and orientation)
%   Particles are points that have mass
%   Rigid bodies are points that have mass and moment of inertia
O = sys.CreatePoint('O');
A = sys.CreatePoint('A', 1).SetT_0n(T_OA);
B = sys.CreatePoint('B', 1).SetT_0n(T_OB);
C = sys.CreatePoint('C', 1).SetT_0n(T_OC);
D = sys.CreatePoint('D', 1).SetT_0n(T_OD);
Bg = sys.CreatePoint('Bg').SetT_0n(T_OB_gnd);
A1 = sys.CreatePoint('A1').SetT_0n(T_OA*T_shiftLL);
A2 = sys.CreatePoint('A2').SetT_0n(T_OA*T_shiftRR);
B1 = sys.CreatePoint('B1').SetT_0n(T_OB*T_shiftLL);
B2 = sys.CreatePoint('B2').SetT_0n(T_OB*T_shiftRR);
C1 = sys.CreatePoint('C1').SetT_0n(T_OC*T_shiftLL);
C2 = sys.CreatePoint('C2').SetT_0n(T_OC*T_shiftRR);
D1 = sys.CreatePoint('D1').SetT_0n(T_OD*T_shiftLL);
D2 = sys.CreatePoint('D2').SetT_0n(T_OD*T_shiftRR);

% Kinematic chains (used only for plotting the animation)
sys.SetChains([O,A1,A2,B], [Bg,B1,B2,C1,C2,D], [D1,D2]);

% Direction of gravity in base frame
sys.SetGravity([0; -g; 0]);

% Constraints imposed by pulley system with 2 ropes
% Using "offsetToIC" to automatically determine the constant to offset the equations such that C=0
const1 = 2*LA - LB;
const2 = 2*LB - 2*LC + LD;
sys.CreateConstraint("rope1").SetConstraint(const1, "offsetToIC");
sys.CreateConstraint("rope2").SetConstraint(const2, "offsetToIC");
sys.SetConstraint_StabilisationFactors();

% Components
sys.CreateLinearSpring("S1").SetLength(L1, T_OA_gnd*T_shiftL, T_OA*T_shiftL).SetSpringConstant(k1).SetNaturalLength(Ln1);
sys.CreateLinearSpring("S2").SetLength(L2, T_OC_gnd*T_shiftL, T_OC*T_shiftL).SetSpringConstant(k2).SetNaturalLength(Ln2);
sys.CreateLinearSpring("S3").SetLength(L3, T_OD*T_shiftL, T_OE*T_shiftL).SetSpringConstant(k3).SetNaturalLength(Ln3);
sys.CreateLinearSpring("S4").SetLength(L4, T_OD*T_shiftR, T_OF*T_shiftR).SetSpringConstant(k4).SetNaturalLength(Ln4);

sys.CreateLinearDamper("D1").SetLength(L1, T_OA_gnd*T_shiftR, T_OA*T_shiftR).SetDampingConstant(b1);
sys.CreateLinearDamper("D2").SetLength(L2, T_OC_gnd*T_shiftR, T_OC*T_shiftR).SetDampingConstant(b2);

sys.CreatePointForce("F1").SetLocation(A).SetF([0;F1;0]);
sys.CreatePointForce("F2").SetLocation(D).SetF([0;F2;0]);


%**********************************************************************
% Solve
%***********************************
SO = CDS_Solver_Options();
SO.time = 0 : 0.02 : 10;
SO.RelTol = 1e-8;
SO.AbsTol = 1e-8;

% Generate and solve equation of motion
S = CDS_Solver(SO);
[t,x,xd] = S.Solve(sys);


%**********************************************************************
% Output
%***********************************
SS = CDS_SolutionSim(sys, t, x, xd);
SSp = CDS_Solution_Plot(SS);
SSe = CDS_Solution_Export(SS);
SSa = CDS_Solution_Animate(SS);
SSg = CDS_Solution_GetData(SS);

SSp.PlotConfigSpace
SSp.PlotConstraintViolation
SSp.PlotEnergyTotal
SSp.PlotEnergyAll
SSp.PlotTaskSpace_All(dim="y")
SSa.PlotFrame(0);
SSa.Animate



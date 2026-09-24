%{
Written By: Brandon Johns
Date Version Created: 2024-09-02
Date Last Edited: 2024-10-17
Status: Complete
Simulator: CDS

%%% PURPOSE %%%

Compare
    Analytic damped harmonic oscillator
    Simulator damped harmonic oscillator

Equation of motion
    m*x_dd + b*x_d + k*x = k*Ln - m*g + F1, where F1 is a constant

Diagram
    ^ F
    |
  -----
  | m |
  -----
  |   |
  b   k
  |   |
  -----
  /////

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
mass = 1; % [kg]
gravity = 9.8; % [m/s^2]
wn = 1;     % Natural frequency [rad/s] (must be greater than 0)
d = 0.5;    % Damping ratio (must be greater than or equal to 0)
LnNum = 10; % Spring natural length [m]
F1Num = 1;  % Constant force acting upwards on the mass [N]

Ly_IC = 0;   % Initial spring length [m]
Ly_d_IC = 0; % Initial rate of change of spring length [m/s]


% Derived parameters
bNum = 2*d*mass*wn;    % Damping constant
kNum = mass*wn^2;      % Spring constant
wd = wn*sqrt(1 - d^2); % Damped natural frequency


sys = CDS_SystemDescription();
params = sys.params;

params.Create('free', 'Ly').SetIC(Ly_IC, Ly_d_IC);
params.Create('const', 'g').SetNum(gravity);
params.Create('const', 'k').SetNum(kNum);
params.Create('const', 'Ln').SetNum(LnNum);
params.Create('const', 'b').SetNum(bNum);
params.Create('const', 'F1').SetNum(F1Num);

% Forward transformations as homogeneous transformation matrices
T_OA = CDS_T('P', [0;Ly;0]);
O = sys.CreatePoint('O');
A = sys.CreatePoint('A', mass).SetT_0n(T_OA);

sys.SetChains([O,A]);
sys.SetGravity([0; -g; 0]);

sys.CreateLinearSpring("OA").SetLength(Ly).SetSpringConstant(k).SetNaturalLength(Ln);
sys.CreateLinearDamper("OA").SetLength(Ly).SetDampingConstant(b);
sys.CreatePointForce("A").SetLocation(A).SetF([0;F1;0]);


%**********************************************************************
% Solve
%***********************************
SO = CDS_Solver_Options();
SO.time = 0 : 0.01 : 20;
SO.RelTol = 1e-10;
SO.AbsTol = 1e-10;

S = CDS_Solver(SO);
tic;
[t,x,xd] = S.Solve(sys);
timeToSolve = toc;

%**********************************************************************
% Output
%***********************************
SS = CDS_SolutionSim(sys, t,x,xd);
SSp = CDS_Solution_Plot(SS);
SSe = CDS_Solution_Export(SS);
SSa = CDS_Solution_Animate(SS);
SSg = CDS_Solution_GetData(SS);

SSp.PlotConfigSpace
%SSp.PlotEnergyTotal
%SSp.PlotEnergyAll

%SSa.Set_View_Predefined("front")
%SSa.PlotFrame
%SSa.Animate


%**********************************************************************
% Compare to Analytic
%***********************************
% Analytic Solution valid for d=/=1 (all but the critically damped solution)
w1 = -d*wn + wn*sqrt(d^2-1);
w2 = -d*wn - wn*sqrt(d^2-1);
C1 = (1/kNum)*(kNum*LnNum - mass*gravity + F1Num);
A1 = (Ly_d_IC - w2*Ly_IC + w2*C1)/(w1-w2);
B1 = Ly_IC - A1 - C1;
Ly_true = real( A1*exp(w1*t) + B1*exp(w2*t) + C1 );
Lyd_true = real( w1*A1*exp(w1*t) + w2*B1*exp(w2*t) );
Lydd_true = real( w1*w1*A1*exp(w1*t) + w2*w2*B1*exp(w2*t) );
Ek_true = 0.5*mass*(Lyd_true.^2);
Eg_true = gravity*mass*Ly_true;
Es_true = 0.5*kNum*(Ly_true-LnNum).^2;
Ev_true = Eg_true + Es_true;

% Error of full signal
RMSE = @(simulated_, analytic_) sqrt(mean((simulated_ - analytic_).^2));
fprintf("RMSE (y): %g\n", RMSE(SSg.q("Ly"), Ly_true))
fprintf("RMSE (yd): %g\n", RMSE(SSg.qd("Ly"), Lyd_true))
fprintf("RMSE (ydd): %g\n", RMSE(SSg.qdd("Ly"), Lydd_true))
fprintf("Max Error (Energy K): %g\n", max(abs(SS.K_mass - Ek_true)))
fprintf("Max Error (Energy V): %g\n", max(abs(SS.V_mass - Ev_true)))
fprintf("Max Error (Energy):   %g\n", max(abs(SS.E)))
fprintf("Time to Form and Solve (s): %g\n", timeToSolve)

% Root mean square error, normalised by range of displacement
Ly_simulated = SSg.q("Ly");
RMSE_normalised = RMSE(Ly_simulated, Ly_true)/(max(Ly_simulated)-min(Ly_simulated));
fprintf("RMSE (Normalised by Range of Displacement): %g\n", RMSE_normalised)

figure;
plot(t,Ly_true-SSg.q("Ly"), t,Lyd_true-SSg.qd("Ly"), t,Lydd_true-SSg.qdd("Ly"))
grid on
xlabel("Time (s)")
ylabel("Error in position, velocity, acceleration")


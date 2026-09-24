%{
Written By: Brandon Johns
Date Version Created: 2026-09-21
Date Last Edited: 2026-09-21
Status: Ever growing as the more methods are added (Complete as at 2026-08-10)
Simulator: CDS

%%% PURPOSE %%%
Unit tests
    Validate methods that are permitted to be called from arrays
    Test that the methods at least run without erroring

Coverage
    core/CDS/

To use
    Call this after running an example file or such
%}


sys.points.T_0n.x
sys.points.T_0n.y
sys.points.T_0n.z
sys.points.T_0n.Inv
sys.points.T_0n.batch_T
sys.points.T_0n.batch_P
sys.points.T_0n.batch_Ph
sys.points.T_0n.batch_R
sys.points.T_0n.page_P
sys.points.T_0n.page_Ph

% Numeric only
%sys.points.T_0n.batch_quat_wxyz
%sys.points.T_0n.batch_quat_xyzw
%[tmp_T_mean, tmp_P_std, tmp_quat_std] = sys.points.T_0n.Mean;

sys.constraints.NameReadable
sys.constraints.C
sys.constraints.Lambda
sys.constraints.Power_dWdt
sys.constraints.Q(sys)
sys.generalisedForces.NameReadable
sys.generalisedForces.Q_scalar
sys.generalisedForces.q
sys.generalisedForces.Power_dWdt
sys.generalisedForces.Q(sys)
sys.generalisedForces.Qf(sys)
sys.linearDampers.NameReadable
sys.linearDampers.Length
sys.linearDampers.Velocity
sys.linearDampers.DampingConstant
sys.linearDampers.Energy_D
sys.linearDampers.Power_dWdt
sys.linearDampers.Q(sys)
sys.linearSprings.NameReadable
sys.linearSprings.Length
sys.linearSprings.SpringConstant
sys.linearSprings.NaturalLength
sys.linearSprings.Energy_V
sys.linearSprings.Energy_E
sys.linearSprings.Hamiltonian_H
sys.linearSprings.Hamiltonian_Hf
sys.linearSprings.Hamiltonian_H_velocityDependentV
sys.linearSprings.Hamiltonian_Hf_velocityDependentV
sys.linearSprings.Power_dEdt
sys.linearSprings.Power_dVdt
sys.linearSprings.Power_dWdt
sys.linearSprings.Power_dWdt_timeDependentV
sys.linearSprings.Power_dWdt_velocityDependentV
sys.linearSprings.Q(sys)
sys.linearSprings.Q_potential(sys)
sys.linearSprings.Q_velocityDependentV(sys)
sys.pointForces.NameReadable
sys.pointForces.Point
sys.pointForces.Fx
sys.pointForces.Fy
sys.pointForces.Fz
sys.pointForces.F
sys.pointForces.Power_dWdt
sys.pointForces.Q(sys)
sys.torsionSprings.NameReadable
sys.torsionSprings.Angle
sys.torsionSprings.SpringConstant
sys.torsionSprings.NaturalAngle
sys.torsionSprings.Energy_V
sys.torsionSprings.Energy_E
sys.torsionSprings.Hamiltonian_H
sys.torsionSprings.Hamiltonian_Hf
sys.torsionSprings.Hamiltonian_H_velocityDependentV
sys.torsionSprings.Hamiltonian_Hf_velocityDependentV
sys.torsionSprings.Power_dEdt
sys.torsionSprings.Power_dVdt
sys.torsionSprings.Power_dWdt
sys.torsionSprings.Power_dWdt_timeDependentV
sys.torsionSprings.Power_dWdt_velocityDependentV
sys.torsionSprings.Q(sys)
sys.torsionSprings.Q_potential(sys)
sys.torsionSprings.Q_velocityDependentV(sys)

% (Abstract) CDS_NamedItem => using CDS_Point as a concrete subclass
sys.points.Name
sys.points.Contains(strings(1,0))
sys.points.Contains(strings(0,1))
sys.points.Contains(strings(0,1,7))
sys.points.Contains("A")
sys.points.Contains("tmp1")
sys.points.Contains(["A","B"])
sys.points.Contains(["A";"tmp2"])
sys.points.Contains(["A","tmp2";"B","tmp2"])
% Varying output size
sys.points.Subset("A", warnMissing=false)
sys.points.Subset("tmp1", warnMissing=false)
sys.points.SubsetIdx("A", warnMissing=false)
sys.points.SubsetIdx("tmp1", warnMissing=false)
sys.points.SubsetIdx(["A","B"], warnMissing=false)
sys.points.SubsetIdx(["A";"tmp2"], warnMissing=false)
sys.points.SubsetIdx(["tmp1";"tmp2"], warnMissing=false)
sys.points.SubsetIdx(strings(1,0), warnMissing=false)
sys.points.SubsetIdx(strings(0,1), warnMissing=false)
% Always col with same length as input
sys.points.SubsetIdx(["A","B"], warnMissing=false, matchQuery=true)
sys.points.SubsetIdx(["A";"tmp2"], warnMissing=false, matchQuery=true)
sys.points.SubsetIdx(["tmp1";"tmp2"], warnMissing=false, matchQuery=true)
sys.points.SubsetIdx(strings(1,0), warnMissing=false, matchQuery=true)
sys.points.SubsetIdx(strings(0,1), warnMissing=false, matchQuery=true)

sys.params.const.Num
sys.params.q_free.q0
sys.params.q_free.q_d0
sys.params.q_free.q_dd0
sys.params.q_free.q0_fixed
sys.params.q_free.q_d0_fixed
sys.params.q_free.q_dd0_fixed
sys.params.q_free.q_ddd0
sys.params.q_free.q_ddd0_fixed
sys.params.lambda.q0
sys.params.lambda.q_d0
sys.params.lambda.q0_fixed
sys.params.lambda.q_d0_fixed

%CDS_Param_x.SetIC() % Yes, a set method
sys.params.x.x0
sys.params.x.x_d0
sys.params.x.x0_fixed
sys.params.x.x_d0_fixed
[tmp_param, tmp_d_offset] = sys.params.x.ParamUnderlying

d = 1;
sys.params.All.Sym()
sys.params.All.Sym(d, '0')
sys.params.All.Sym(d, 't', 0)
sys.params.All.Sym(d, 't', 1)
sys.params.All.Str(d)
sys.params.All.SymShort(d)
sys.params.All.StrShort(d)
sys.params.All.NameReadable(d)
sys.params.All.SymShortPtr

sys.points.NameReadable
sys.points.T_0n
sys.points.m
sys.points.I_p
sys.points.I_n
sys.points.R_np
sys.points.HasLinearInertia
sys.points.HasRotationalInertia
sys.points.HasMass
sys.points.IsPointMass
sys.points.IsRigidBody
sys.points.Energy_V
sys.points.Energy_K
sys.points.Energy_E
sys.points.Power_dVdt
sys.points.Power_dKdt
sys.points.Power_dEdt
sys.points.Hamiltonian_H
sys.points.Hamiltonian_Hf
sys.points.Hamiltonian_H_nonQuadraticK
sys.points.Hamiltonian_Hf_nonQuadraticK
sys.points.Hamiltonian_H_velocityDependentV
sys.points.Hamiltonian_Hf_velocityDependentV
sys.points.Power_dWdt
sys.points.Power_dWdt_timeDependent
sys.points.Power_dWdt_timeDependentK
sys.points.Power_dWdt_timeDependentV
sys.points.Power_dWdt_nonQuadraticK
sys.points.Power_dWdt_velocityDependentV
sys.points.Q(sys)
sys.points.Q_inertial(sys)
sys.points.Q_CentrifugalAndCoriolis(sys)
sys.points.Q_timeDependentK(sys)
sys.points.Q_potential(sys)
sys.points.Q_velocityDependentV(sys)


% Methods limited to vector object arrays
tmp_handle = sys.params.u.q_h;
tmp_handle(2.2)
tmp_handle([2.2, 3.4, 7.5])
tmp_handle([22; 34; 75])
sys.params.u.q(2.2)
sys.params.u.q([2.2, 3.4, 7.5])
sys.params.u.q([22; 34; 75])
sys.points.GetIfHasMass


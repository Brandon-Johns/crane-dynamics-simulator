%{
Written By: Brandon Johns
Date Version Created: 2026-03-07
Date Last Edited: 2026-09-21
Status: Ever growing as the more methods are added (Complete as at 2026-09-21)
Simulator: CDS

%%% PURPOSE %%%
Unit tests
    Validate methods that are permitted to be called from empty arrays

Coverage
    core/CDS/


%%% NOTES %%%
In testing if empty arrays are the identical, compare size and type, not content

Weird case
Calls to properties output nothing (no size, no type, just nothing)


%}
close all
clear all
clc
sympref('AbbreviateOutput',false);
sympref('MatrixWithSquareBrackets',true);
CDS_FindIncludes;
CDS_IncludeSimulator;

% Mock inputs
sys = CDS_SystemDescription();
params = sys.params;
params.Create("free", "param1");
params.Create("free", "param2");
params.Create("free", "param3");
params.Create("free", "param4");
d=1;
t=2.2;
tRow = [2.2, 3.4, 7.5];
tCol = [22; 34; 75];

assertEmpty_equal = @(a,b) assert(all(size(a)==size(b)) && string(class(a))==string(class(b)));
assertEmpty03_sym    = @(a) assertEmpty_equal(a, sym.empty(0,3));
assertEmpty03_sym_q  = @(a) assertEmpty_equal(a, sym.empty(length(params.q),0,3));
assertEmpty03_sym_qf = @(a) assertEmpty_equal(a, sym.empty(length(params.q_free),0,3));
assertEmpty03_str    = @(a) assertEmpty_equal(a, string.empty(0,3));
assertEmpty03_double = @(a) assertEmpty_equal(a, double.empty(0,3));
assertEmpty03_bool   = @(a) assertEmpty_equal(a, logical.empty(0,3));

assertEmptySZ_sym    = @(sz,a) assertEmpty_equal(a, sym.empty(sz));
assertEmptySZ_sym_q  = @(sz,a) assertEmpty_equal(a, sym.empty([ length(params.q), sz ]));
assertEmptySZ_sym_qf = @(sz,a) assertEmpty_equal(a, sym.empty([ length(params.q_free), sz ]));
assertEmptySZ_str    = @(sz,a) assertEmpty_equal(a, string.empty(sz));
assertEmptySZ_double = @(sz,a) assertEmpty_equal(a, double.empty(sz));
assertEmptySZ_bool   = @(sz,a) assertEmpty_equal(a, logical.empty(sz));
assertEmptySZ_CDS_T  = @(sz,a) assertEmpty_equal(a, CDS_T.empty(sz));


assertEmpty03_double( CDS_T.empty(0,3).x );
assertEmpty03_double( CDS_T.empty(0,3).y );
assertEmpty03_double( CDS_T.empty(0,3).z );
assertEmpty03_double( CDS_T.empty(0,3).Inv.x );
assertEmpty_equal(    CDS_T.empty(0,3).Inv, CDS_T.empty(0,3));
% 2D
assertEmpty_equal(    CDS_T.empty(0,3).batch_T,  double.empty(4,4, 0,3));
assertEmpty_equal(    CDS_T.empty(0,3).batch_P,  double.empty(3,   0,3));
assertEmpty_equal(    CDS_T.empty(0,3).batch_Ph, double.empty(4,   0,3));
assertEmpty_equal(    CDS_T.empty(0,3).batch_R,  double.empty(3,3, 0,3));
assertEmpty_equal(    CDS_T.empty(0,3).batch_quat_wxyz, double.empty(4, 0,3));
assertEmpty_equal(    CDS_T.empty(0,3).batch_quat_xyzw, double.empty(4, 0,3));
assertEmpty_equal(    CDS_T.empty(0,3).page_P,   double.empty(3,1, 0,3));
assertEmpty_equal(    CDS_T.empty(0,3).page_Ph,  double.empty(4,1, 0,3));
% 1D row or column => Leave singleton dimensions alone (row is treated as 2D)
assertEmpty_equal(    CDS_T.empty(1,0).batch_T,  double.empty(4,4, 1,0));
assertEmpty_equal(    CDS_T.empty(1,0).batch_P,  double.empty(3,   1,0));
assertEmpty_equal(    CDS_T.empty(1,0).batch_Ph, double.empty(4,   1,0));
assertEmpty_equal(    CDS_T.empty(1,0).batch_R,  double.empty(3,3, 1,0));
assertEmpty_equal(    CDS_T.empty(1,0).batch_quat_wxyz, double.empty(4, 1,0));
assertEmpty_equal(    CDS_T.empty(1,0).batch_quat_xyzw, double.empty(4, 1,0));
assertEmpty_equal(    CDS_T.empty(1,0).page_P,   double.empty(3,1, 1,0));
assertEmpty_equal(    CDS_T.empty(1,0).page_Ph,  double.empty(4,1, 1,0));
assertEmpty_equal(    CDS_T.empty(0,1).batch_T,  double.empty(4,4, 0));
assertEmpty_equal(    CDS_T.empty(0,1).batch_P,  double.empty(3,   0));
assertEmpty_equal(    CDS_T.empty(0,1).batch_Ph, double.empty(4,   0));
assertEmpty_equal(    CDS_T.empty(0,1).batch_R,  double.empty(3,3, 0));
assertEmpty_equal(    CDS_T.empty(0,1).batch_quat_wxyz, double.empty(4, 0));
assertEmpty_equal(    CDS_T.empty(0,1).batch_quat_xyzw, double.empty(4, 0));
assertEmpty_equal(    CDS_T.empty(0,1).page_P,   double.empty(3,1, 0));
assertEmpty_equal(    CDS_T.empty(0,1).page_Ph,  double.empty(4,1, 0));
% Same result for any empty set
[tmp_T_mean, tmp_P_std, tmp_quat_std] = CDS_T.empty(0,3).Mean;
assertEmpty_equal(tmp_T_mean.T, CDS_T.NaN(1,1).T);
assertEmpty_equal(tmp_P_std, [nan;nan;nan]);
assertEmpty_equal(tmp_quat_std, nan);

objectArraySizes = {[0,3], [0,1], [1,0], [0,0], [3,0,4]};
for idxS = 1:length(objectArraySizes)
    sz = objectArraySizes{idxS}

    assertEmptySZ_str(    sz, CDS_Component_Constraint.empty(sz).NameReadable );
    assertEmptySZ_sym(    sz, CDS_Component_Constraint.empty(sz).C );
    assertEmptySZ_sym(    sz, CDS_Component_Constraint.empty(sz).Lambda );
    assertEmptySZ_sym(    sz, CDS_Component_Constraint.empty(sz).Power_dWdt );
    assertEmptySZ_sym_q(  sz, CDS_Component_Constraint.empty(sz).Q(sys) );
    assertEmptySZ_str(    sz, CDS_Component_GeneralisedForce.empty(sz).NameReadable );
    assertEmptySZ_sym(    sz, CDS_Component_GeneralisedForce.empty(sz).Q_scalar );
    assertEmptySZ_sym(    sz, CDS_Component_GeneralisedForce.empty(sz).q );
    assertEmptySZ_sym(    sz, CDS_Component_GeneralisedForce.empty(sz).Power_dWdt );
    assertEmptySZ_sym_q(  sz, CDS_Component_GeneralisedForce.empty(sz).Q(sys) );
    assertEmptySZ_sym_qf( sz, CDS_Component_GeneralisedForce.empty(sz).Qf(sys) );
    assertEmptySZ_str(    sz, CDS_Component_LinearDamper.empty(sz).NameReadable );
    assertEmptySZ_sym(    sz, CDS_Component_LinearDamper.empty(sz).Length );
    assertEmptySZ_sym(    sz, CDS_Component_LinearDamper.empty(sz).Velocity );
    assertEmptySZ_sym(    sz, CDS_Component_LinearDamper.empty(sz).DampingConstant );
    assertEmptySZ_sym(    sz, CDS_Component_LinearDamper.empty(sz).Energy_D );
    assertEmptySZ_sym(    sz, CDS_Component_LinearDamper.empty(sz).Power_dWdt );
    assertEmptySZ_sym_q(  sz, CDS_Component_LinearDamper.empty(sz).Q(sys) );
    assertEmptySZ_str(    sz, CDS_Component_LinearSpring.empty(sz).NameReadable );
    assertEmptySZ_sym(    sz, CDS_Component_LinearSpring.empty(sz).Length );
    assertEmptySZ_sym(    sz, CDS_Component_LinearSpring.empty(sz).SpringConstant );
    assertEmptySZ_sym(    sz, CDS_Component_LinearSpring.empty(sz).NaturalLength );
    assertEmptySZ_sym(    sz, CDS_Component_LinearSpring.empty(sz).Energy_V );
    assertEmptySZ_sym(    sz, CDS_Component_LinearSpring.empty(sz).Energy_E );
    assertEmptySZ_sym(    sz, CDS_Component_LinearSpring.empty(sz).Hamiltonian_H );
    assertEmptySZ_sym(    sz, CDS_Component_LinearSpring.empty(sz).Hamiltonian_Hf );
    assertEmptySZ_sym(    sz, CDS_Component_LinearSpring.empty(sz).Hamiltonian_H_velocityDependentV );
    assertEmptySZ_sym(    sz, CDS_Component_LinearSpring.empty(sz).Hamiltonian_Hf_velocityDependentV );
    assertEmptySZ_sym(    sz, CDS_Component_LinearSpring.empty(sz).Power_dEdt );
    assertEmptySZ_sym(    sz, CDS_Component_LinearSpring.empty(sz).Power_dVdt );
    assertEmptySZ_sym(    sz, CDS_Component_LinearSpring.empty(sz).Power_dWdt );
    assertEmptySZ_sym(    sz, CDS_Component_LinearSpring.empty(sz).Power_dWdt_timeDependentV );
    assertEmptySZ_sym(    sz, CDS_Component_LinearSpring.empty(sz).Power_dWdt_velocityDependentV );
    assertEmptySZ_sym_q(  sz, CDS_Component_LinearSpring.empty(sz).Q(sys) );
    assertEmptySZ_sym_q(  sz, CDS_Component_LinearSpring.empty(sz).Q_potential(sys) );
    assertEmptySZ_sym_q(  sz, CDS_Component_LinearSpring.empty(sz).Q_velocityDependentV(sys) );
    assertEmptySZ_str(    sz, CDS_Component_PointForce.empty(sz).NameReadable );
    assertEmptySZ_CDS_T(  sz, CDS_Component_PointForce.empty(sz).Point );
    assertEmptySZ_sym(    sz, CDS_Component_PointForce.empty(sz).Fx );
    assertEmptySZ_sym(    sz, CDS_Component_PointForce.empty(sz).Fy );
    assertEmptySZ_sym(    sz, CDS_Component_PointForce.empty(sz).Fz );
    assertEmpty_equal(        CDS_Component_PointForce.empty(sz).F, sym.empty([3,sz]) );
    assertEmptySZ_sym(    sz, CDS_Component_PointForce.empty(sz).Power_dWdt );
    assertEmptySZ_sym_q(  sz, CDS_Component_PointForce.empty(sz).Q(sys) );
    assertEmptySZ_str(    sz, CDS_Component_TorsionSpring.empty(sz).NameReadable );
    assertEmptySZ_sym(    sz, CDS_Component_TorsionSpring.empty(sz).Angle );
    assertEmptySZ_sym(    sz, CDS_Component_TorsionSpring.empty(sz).SpringConstant );
    assertEmptySZ_sym(    sz, CDS_Component_TorsionSpring.empty(sz).NaturalAngle );
    assertEmptySZ_sym(    sz, CDS_Component_TorsionSpring.empty(sz).Energy_V );
    assertEmptySZ_sym(    sz, CDS_Component_TorsionSpring.empty(sz).Energy_E );
    assertEmptySZ_sym(    sz, CDS_Component_TorsionSpring.empty(sz).Hamiltonian_H );
    assertEmptySZ_sym(    sz, CDS_Component_TorsionSpring.empty(sz).Hamiltonian_Hf );
    assertEmptySZ_sym(    sz, CDS_Component_TorsionSpring.empty(sz).Hamiltonian_H_velocityDependentV );
    assertEmptySZ_sym(    sz, CDS_Component_TorsionSpring.empty(sz).Hamiltonian_Hf_velocityDependentV );
    assertEmptySZ_sym(    sz, CDS_Component_TorsionSpring.empty(sz).Power_dEdt );
    assertEmptySZ_sym(    sz, CDS_Component_TorsionSpring.empty(sz).Power_dVdt );
    assertEmptySZ_sym(    sz, CDS_Component_TorsionSpring.empty(sz).Power_dWdt );
    assertEmptySZ_sym(    sz, CDS_Component_TorsionSpring.empty(sz).Power_dWdt_timeDependentV );
    assertEmptySZ_sym(    sz, CDS_Component_TorsionSpring.empty(sz).Power_dWdt_velocityDependentV );
    assertEmptySZ_sym_q(  sz, CDS_Component_TorsionSpring.empty(sz).Q(sys) );
    assertEmptySZ_sym_q(  sz, CDS_Component_TorsionSpring.empty(sz).Q_potential(sys) );
    assertEmptySZ_sym_q(  sz, CDS_Component_TorsionSpring.empty(sz).Q_velocityDependentV(sys) );

    % (Abstract) CDS_NamedItem => using CDS_Point as a concrete subclass
    assertEmptySZ_str(    sz, CDS_Point.empty(sz).Name );
    % Always false with same size as input when empty
    assertEmpty_equal(        CDS_Point.empty(sz).Contains(strings(1,0)), false(1,0) );
    assertEmpty_equal(        CDS_Point.empty(sz).Contains(strings(0,1)), false(0,1) );
    assertEmpty_equal(        CDS_Point.empty(sz).Contains(strings(0,1,7)), false(0,1,7) );
    assertEmpty_equal(        CDS_Point.empty(sz).Contains("tmp1"), false );
    assertEmpty_equal(        CDS_Point.empty(sz).Contains(["tmp1","tmp2"]), [false,false] );
    assertEmpty_equal(        CDS_Point.empty(sz).Contains(["tmp1";"tmp2"]), [false;false] );
    assertEmpty_equal(        CDS_Point.empty(sz).Contains(["tmp1","tmp2";"tmp1","tmp2"]), [false,false;false,false] );
    % Always [0,1] when empty
    assertEmpty_equal(        CDS_Point.empty(sz).Subset("tmp1", warnMissing=false), CDS_Point.empty(0,1) );
    assertEmpty_equal(        CDS_Point.empty(sz).SubsetIdx("tmp1", warnMissing=false), double.empty(0,1) );
    assertEmpty_equal(        CDS_Point.empty(sz).SubsetIdx(["tmp1","tmp2"], warnMissing=false), double.empty(0,1) );
    assertEmpty_equal(        CDS_Point.empty(sz).SubsetIdx(["tmp1";"tmp2"], warnMissing=false), double.empty(0,1) );
    assertEmpty_equal(        CDS_Point.empty(sz).SubsetIdx(strings(1,0), warnMissing=false), double.empty(0,1) );
    assertEmpty_equal(        CDS_Point.empty(sz).SubsetIdx(strings(0,1), warnMissing=false), double.empty(0,1) );
    % Always col with same length as input
    assertEmpty_equal(        CDS_Point.empty(sz).SubsetIdx(["tmp1","tmp2"], warnMissing=false, matchQuery=true), nan(2,1) );
    assertEmpty_equal(        CDS_Point.empty(sz).SubsetIdx(["tmp1";"tmp2"], warnMissing=false, matchQuery=true), nan(2,1) );
    assertEmpty_equal(        CDS_Point.empty(sz).SubsetIdx(strings(1,0), warnMissing=false, matchQuery=true), double.empty(0,1) );
    assertEmpty_equal(        CDS_Point.empty(sz).SubsetIdx(strings(0,1), warnMissing=false, matchQuery=true), double.empty(0,1) );

    assertEmptySZ_double( sz, CDS_Param_Const.empty(sz).Num );
    assertEmptySZ_double( sz, CDS_Param_Free.empty(sz).q0 );
    assertEmptySZ_double( sz, CDS_Param_Free.empty(sz).q_d0 );
    assertEmptySZ_double( sz, CDS_Param_Free.empty(sz).q_dd0 );
    assertEmptySZ_bool(   sz, CDS_Param_Free.empty(sz).q0_fixed );
    assertEmptySZ_bool(   sz, CDS_Param_Free.empty(sz).q_d0_fixed );
    assertEmptySZ_bool(   sz, CDS_Param_Free.empty(sz).q_dd0_fixed );
    assertEmptySZ_double( sz, CDS_Param_Free.empty(sz).q_ddd0 );
    assertEmptySZ_bool(   sz, CDS_Param_Free.empty(sz).q_ddd0_fixed );
    assertEmptySZ_double( sz, CDS_Param_Lambda.empty(sz).q0 );
    assertEmptySZ_double( sz, CDS_Param_Lambda.empty(sz).q_d0 );
    assertEmptySZ_bool(   sz, CDS_Param_Lambda.empty(sz).q0_fixed );
    assertEmptySZ_bool(   sz, CDS_Param_Lambda.empty(sz).q_d0_fixed );

    assertEmpty_equal(        CDS_Param_x.empty(sz).SetIC(), CDS_Param_x.empty(sz) ); % Yes, a set method
    assertEmptySZ_double( sz, CDS_Param_x.empty(sz).x0 );
    assertEmptySZ_double( sz, CDS_Param_x.empty(sz).x_d0 );
    assertEmptySZ_bool(   sz, CDS_Param_x.empty(sz).x0_fixed );
    assertEmptySZ_bool(   sz, CDS_Param_x.empty(sz).x_d0_fixed );

    [tmp_param, tmp_d_offset] = CDS_Param_x.empty(sz).ParamUnderlying;
    assertEmpty_equal(        tmp_param, CDS_Param_Free.empty(sz) );
    assertEmptySZ_double( sz, tmp_d_offset );

    assertEmptySZ_sym(    sz, CDS_Param.empty(sz).Sym() );
    assertEmptySZ_sym(    sz, CDS_Param.empty(sz).Sym(d, '0') );
    assertEmptySZ_sym(    sz, CDS_Param.empty(sz).Sym(d, 't', 0) );
    assertEmptySZ_sym(    sz, CDS_Param.empty(sz).Sym(d, 't', 1) );
    assertEmptySZ_str(    sz, CDS_Param.empty(sz).Str(d) );
    assertEmptySZ_sym(    sz, CDS_Param.empty(sz).SymShort(d) );
    assertEmptySZ_str(    sz, CDS_Param.empty(sz).StrShort(d) );
    assertEmptySZ_str(    sz, CDS_Param.empty(sz).NameReadable(d) );
    assertEmpty_equal(        CDS_Param.empty(sz).SymShortPtr, CDS_Helper_PropPointer.empty(sz) );

    assertEmptySZ_str(    sz, CDS_Point.empty(sz).NameReadable );
    assertEmptySZ_CDS_T(  sz, CDS_Point.empty(sz).T_0n );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).m );
    assertEmpty_equal(        CDS_Point.empty(sz).I_p, sym.empty([3,3,sz]) );
    assertEmpty_equal(        CDS_Point.empty(sz).I_n, sym.empty([3,3,sz]) );
    assertEmpty_equal(        CDS_Point.empty(sz).R_np, sym.empty([3,3,sz]) );
    assertEmptySZ_bool(   sz, CDS_Point.empty(sz).HasLinearInertia );
    assertEmptySZ_bool(   sz, CDS_Point.empty(sz).HasRotationalInertia );
    assertEmptySZ_bool(   sz, CDS_Point.empty(sz).HasMass );
    assertEmptySZ_bool(   sz, CDS_Point.empty(sz).IsPointMass );
    assertEmptySZ_bool(   sz, CDS_Point.empty(sz).IsRigidBody );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Energy_V );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Energy_K );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Energy_E );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Power_dVdt );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Power_dKdt );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Power_dEdt );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Hamiltonian_H );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Hamiltonian_Hf );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Hamiltonian_H_nonQuadraticK );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Hamiltonian_Hf_nonQuadraticK );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Hamiltonian_H_velocityDependentV );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Hamiltonian_Hf_velocityDependentV );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Power_dWdt );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Power_dWdt_timeDependent );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Power_dWdt_timeDependentK );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Power_dWdt_timeDependentV );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Power_dWdt_nonQuadraticK );
    assertEmptySZ_sym(    sz, CDS_Point.empty(sz).Power_dWdt_velocityDependentV );
    assertEmptySZ_sym_q(  sz, CDS_Point.empty(sz).Q(sys) );
    assertEmptySZ_sym_q(  sz, CDS_Point.empty(sz).Q_inertial(sys) );
    assertEmptySZ_sym_q(  sz, CDS_Point.empty(sz).Q_CentrifugalAndCoriolis(sys) );
    assertEmptySZ_sym_q(  sz, CDS_Point.empty(sz).Q_timeDependentK(sys) );
    assertEmptySZ_sym_q(  sz, CDS_Point.empty(sz).Q_potential(sys) );
    assertEmptySZ_sym_q(  sz, CDS_Point.empty(sz).Q_velocityDependentV(sys) );
end

% Methods limited to vector object arrays
objectArraySizes = {[0,1], [1,0]};
for idxS = 1:length(objectArraySizes)
    sz = objectArraySizes{idxS}

    % Always [0,length(t)] when empty (Limited to vector input of t)
    tmp_handle = CDS_Param_u.empty(sz).q_h;
    assertEmpty_equal(CDS_Param_u.empty(sz).q(t), double.empty(0,length(t)) );
    assertEmpty_equal(CDS_Param_u.empty(sz).q(tRow), double.empty(0,3) );
    assertEmpty_equal(CDS_Param_u.empty(sz).q(tCol), double.empty(0,3) );
    assertEmpty_equal(tmp_handle(t), double.empty(0,1) );
    assertEmpty_equal(tmp_handle(tRow), double.empty(0,3) );
    assertEmpty_equal(tmp_handle(tCol), double.empty(0,3) );

    % Normal behaviour (Always same size as the object array when empty)
    assertEmpty_equal(CDS_Point.empty(sz).GetIfHasMass, CDS_Point.empty(sz) );
end


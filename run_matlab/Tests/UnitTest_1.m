%{
Written By: Brandon Johns
Date Version Created: 2024-12-27
Date Last Edited: 2026-04-09
Status: Complete
Simulator: CDS

%%% PURPOSE %%%
Unit tests
    Validate CDS_Params.EvaluateSymExpr()

I want very strong test coverage because
    The function is rather complicated
    The function is used in fairly critical code


%}
close all
clear all
clc
sympref('AbbreviateOutput',false);
sympref('MatrixWithSquareBrackets',true);
CDS_FindIncludes;
CDS_IncludeSimulator;

% Variable names
% T = (symExpr) of 't'
% N = (double) scalar
% S = (double) vector

syms t real
tN0 = 0;
tN1 = 2.346;
tS1 = [5,6,7];

f1N = .3457;
f2N = .8654;
e1T = .3457 + abs(t-4);
e1N0 = .3457 + abs(tN0-4);
e1N1 = .3457 + abs(tN1-4);
e1S1 = .3457 + abs(tS1-4);
e2T = .8654 + 3*t^3;
e2N0 = .8654 + 3*tN0.^3;
e2N1 = .8654 + 3*tN1.^3;
e2S1 = .8654 + 3*tS1.^3;
c1N = .1346;
c2N = .9876;
a1N = .5612;
a2N = .1893;

params = CDS_Params();
params.Create('free', 'f1').SetIC(f1N);
params.Create('free', 'f2').SetIC(f2N);
params.Create('input', 'e1').SetAnalytic(e1T);
params.Create('input', 'e2').SetAnalytic(e2T);
params.Create('const', 'c1').SetNum(c1N);
params.Create('const', 'c2').SetNum(c2N);

% Unregistered syms
syms a1 a2 real

validateTol = 1e-14;
AssertTol = @(a,b) IntegrationTest.AssertTol(a,b, validateTol);
AssertEqual = @(a,b) IntegrationTest.AssertEqual(a,b);


%**********************************************************************
% Empty output
%***********************************
% Empty, scalar
AssertEqual(params.EvaluateSymExpr_IC(double.empty(0,0)), double.empty(0,0))
AssertEqual(params.EvaluateSymExpr_IC(double.empty(0,3)), double.empty(0,3)) % IC version: Should keep DIMS
AssertEqual(params.EvaluateSymExpr_IC(double.empty(3,0)), double.empty(3,0)) % IC version: Should keep DIMS
AssertEqual(params.EvaluateSymExpr_IC(double.empty(3,0,5)), double.empty(3,0,5))
AssertEqual(params.EvaluateSymExpr_IC(double.empty(3,5,0)), double.empty(3,5,0))
AssertEqual(params.EvaluateSymExpr(double.empty(0,1)), double.empty(0,1)) % Should normalise DIMS
AssertEqual(params.EvaluateSymExpr(double.empty(1,0)), double.empty(0,1)) % Should normalise DIMS
AssertEqual(params.EvaluateSymExpr(double.empty(0,0), nDimsIn=2), double.empty(0,0))
AssertEqual(params.EvaluateSymExpr(double.empty(0,1), nDimsIn=2), double.empty(0,1))
AssertEqual(params.EvaluateSymExpr(double.empty(1,0), nDimsIn=2), double.empty(1,0))
AssertEqual(params.EvaluateSymExpr(double.empty(3,0,5), nDimsIn=3), double.empty(3,0,5))
AssertEqual(params.EvaluateSymExpr(double.empty(3,5,0), nDimsIn=3), double.empty(3,5,0))

% Empty, series
AssertEqual(params.EvaluateSymExpr(double.empty(0,1), [1,2,3,4]), double.empty(0,4)) % Should normalise DIMS
AssertEqual(params.EvaluateSymExpr(double.empty(1,0), [1,2,3,4]), double.empty(0,4)) % Should normalise DIMS
AssertEqual(params.EvaluateSymExpr(double.empty(0,0), [1,2,3,4], nDimsIn=2), double.empty(0,0,4))
AssertEqual(params.EvaluateSymExpr(double.empty(0,1), [1,2,3,4], nDimsIn=2), double.empty(0,1,4))
AssertEqual(params.EvaluateSymExpr(double.empty(1,0), [1,2,3,4], nDimsIn=2), double.empty(1,0,4))
AssertEqual(params.EvaluateSymExpr(double.empty(3,0,5), [1,2,3,4], nDimsIn=3), double.empty(3,0,5,4))
AssertEqual(params.EvaluateSymExpr(double.empty(3,5,0), [1,2,3,4], nDimsIn=3), double.empty(3,5,0,4))

% Empty, mixed with empty series
AssertEqual(params.EvaluateSymExpr(double.empty(1,0), []), double.empty(0,0))
AssertEqual(params.EvaluateSymExpr(double.empty(1,0), [], nDimsIn=2), double.empty(1,0,0))
AssertEqual(params.EvaluateSymExpr(double.empty(0,1), [], nDimsIn=2), double.empty(0,1,0))

% Various, mixed with empty series
AssertEqual(params.EvaluateSymExpr(c1, []), double.empty(1,0)) % Should normalise DIMS
AssertEqual(params.EvaluateSymExpr([c1,c1], []), double.empty(2,0)) % Should normalise DIMS
AssertEqual(params.EvaluateSymExpr(c1*ones(3,5), [], nDimsIn=2), double.empty(3,5,0))
AssertEqual(params.EvaluateSymExpr(c1*ones(3,5), [], c1,c1N, nDimsIn=2), double.empty(3,5,0))
AssertEqual(params.EvaluateSymExpr(c1*ones(3,5), [], c1,c1N, e1,double.empty(1,0), nDimsIn=2), double.empty(3,5,0))
AssertEqual(params.EvaluateSymExpr(c1*ones(3,5), [], c1,c1N, [e1,a2],double.empty(2,0), nDimsIn=2), double.empty(3,5,0))


%**********************************************************************
% Test errors that should occur
%***********************************
err=1;
% nDimIn
try params.EvaluateSymExpr([c1,c1;c1,c1]); err=0; catch; end; assert(err==1)
try params.EvaluateSymExpr(ones(1,2,0), nDimsIn=2); err=0; catch; end; assert(err==1)
% Mismatching number of arguments
try params.EvaluateSymExpr(c1, [1,2], c1,c1N, [e1,e2]); err=0; catch; end; assert(err==1)
% Mismatching series size
try params.EvaluateSymExpr(c1, [1,2], c1,c1N, e1,[1;2]); err=0; catch; end; assert(err==1)
try params.EvaluateSymExpr(c1, [1,2], c1,c1N, [e1,e2],[1,2,;1,2;1,2]); err=0; catch; end; assert(err==1)
%try params.EvaluateSymExpr(c1, [], c1,c1N, [e1,a2],double.empty(1,0)); err=0; catch; end; assert(err==1) % NOT ENFORCED BECAUSE EMPTY
% Mismatching series length
%try params.EvaluateSymExpr(c1, [], c1,c1N, e1,e1S1); err=0; catch; end; assert(err==1) % NOT ENFORCED BECAUSE EMPTY
try params.EvaluateSymExpr(c1, [1,2], c1,c1N, e1,[1,2,3]); err=0; catch; end; assert(err==1)
try params.EvaluateSymExpr(c1, [1,2,3], c1,c1N, e1,[1,2,3], e2,[1,2]); err=0; catch; end; assert(err==1)
try params.EvaluateSymExpr(c1, [1,2], c1,c1N, [e1,e2],[1,2,3;1,2,3]); err=0; catch; end; assert(err==1)
% Duplicate sym
try params.EvaluateSymExpr(f1, 0, [f1,t],[1,2]); err=0; catch; end; assert(err==1)
try params.EvaluateSymExpr(f1, 0, [f1,f1],[1,2]); err=0; catch; end; assert(err==1)
try params.EvaluateSymExpr(f1, tS1, [f1,e1],[1,2], e1,e1S1); err=0; catch; end; assert(err==1)
% Missing sym
try params.EvaluateSymExpr(f1); err=0; catch; end; assert(err==1)
try params.EvaluateSymExpr(a1); err=0; catch; end; assert(err==1)
try params.EvaluateSymExpr(e1+c2+3+a2); err=0; catch; end; assert(err==1)


%**********************************************************************
% Scalar values to substitute in
%***********************************
% Scalar, scalar
% (default substitution of registered syms)
AssertTol(params.EvaluateSymExpr_IC(c1), c1N)
AssertTol(params.EvaluateSymExpr_IC(f1+e1+c2+3), f1N+e1N0+c2N+3)
AssertTol(params.EvaluateSymExpr(c1), c1N)
AssertTol(params.EvaluateSymExpr(e1+c2+3), e1N0+c2N+3)
% (override registered syms)
AssertTol(params.EvaluateSymExpr(f1, 0, f1,5), 5)
AssertTol(params.EvaluateSymExpr(e1, 0, e1,5), 5)
AssertTol(params.EvaluateSymExpr(c1, 0, c1,5), 5)
% (with unregistered syms, with non-zero time)
AssertTol(params.EvaluateSymExpr(a1, tN0, a1,a1N), a1N)
AssertTol(params.EvaluateSymExpr(a1, tN1, a1,a1N), a1N)
AssertTol(params.EvaluateSymExpr(e1+c2+3+a2, tN0, a2,a2N), e1N0+c2N+3+a2N)
AssertTol(params.EvaluateSymExpr(e1+c2+3+a2, tN1, a2,a2N), e1N1+c2N+3+a2N)
% (with arrays of scalars, and combining: default substitution, overriding, unregistered, and non-zero time)
AssertTol(params.EvaluateSymExpr(e1+c2+3+a2, tN1, [c2,a2],[3.473,8.152]), e1N1+3.473+3+8.152)
AssertTol(params.EvaluateSymExpr(f1+f2+c1+c2+a1+a2+e1, tN1, [c2,a2],[3.473,a2N], [f1,f2,a1],[f1N,f2N,a1N]), f1N+f2N+c1N+3.473+a1N+a2N+e1N1)
AssertTol(params.EvaluateSymExpr(f1+f2+c1+c2+a1+a2+e1, tN1, a2,a2N, [f1,f2,a1],[f1N,f2N,a1N]), f1N+f2N+c1N+c2N+a1N+a2N+e1N1)

% Vector, scalar
AssertTol(params.EvaluateSymExpr_IC([f1,e1,c2,3]), [f1N,e1N0,c2N,3]) % IC version: Should keep DIMS
AssertTol(params.EvaluateSymExpr_IC([f1;e1;c2;3]), [f1N;e1N0;c2N;3]) % IC version: Should keep DIMS
AssertTol(params.EvaluateSymExpr([f1,e1,c2,3], tN1, f1,f1N), [f1N;e1N1;c2N;3])
AssertTol(params.EvaluateSymExpr([f1,e1,c2,3+a2], tN1, f1,f1N, a2,a2N), [f1N;e1N1;c2N;3+a2N]) % Should normalise DIMS
AssertTol(params.EvaluateSymExpr([f1;e1;c2;3+a2], tN1, f1,f1N, a2,a2N), [f1N;e1N1;c2N;3+a2N]) % Should normalise DIMS

% Matrix, scalar
AssertTol(params.EvaluateSymExpr_IC([f1,e1;c2,3]), [f1N,e1N0;c2N,3])
AssertTol(params.EvaluateSymExpr([f1,e1,c2,3+a2], tN1, f1,f1N, a2,a2N, nDimsIn=2), [f1N,e1N1,c2N,3+a2N]) % Should keep DIMS
AssertTol(params.EvaluateSymExpr([f1;e1;c2;3+a2], tN1, f1,f1N, a2,a2N, nDimsIn=2), [f1N;e1N1;c2N;3+a2N]) % Should keep DIMS
AssertTol(params.EvaluateSymExpr([f1,e1;c2,3], 0, f1,f1N, nDimsIn=2), [f1N,e1N0;c2N,3])
AssertTol(params.EvaluateSymExpr([f1,e1;c2,3;8,c1], tN1, f1,f1N, nDimsIn=2), [f1N,e1N1;c2N,3;8,c1N])
AssertTol(params.EvaluateSymExpr(cat(3,[f1,e1;c2,3],[c1,5;e2,9]), tN1, f1,f1N, nDimsIn=3), cat(3,[f1N,e1N1;c2N,3],[c1N,5;e2N1,9]))


%**********************************************************************
% Series values to substitute in
%***********************************
z3 = [0,0,0];

% Scalar, series
% (override registered syms)
AssertTol(params.EvaluateSymExpr(f1+2, z3, f1,[3,4,5]), [5,6,7])
AssertTol(params.EvaluateSymExpr(e1+2, z3, e1,[3,4,5]), [5,6,7])
AssertTol(params.EvaluateSymExpr(c1+2, z3, c1,[3,4,5]), [5,6,7])
% (other)
AssertTol(params.EvaluateSymExpr(f1+f2, z3, f2,[2,1,0], f1,[3,5,7]), [5,6,7])
AssertTol(params.EvaluateSymExpr(f1+f2, z3, [f2,f1],[2,1,0;3,5,7]), [5,6,7])
AssertTol(params.EvaluateSymExpr(e1, tS1), e1S1)

% Scalar, mixed
AssertTol(params.EvaluateSymExpr(f1+f2+2, z3, f1,[3,4,5], f2,f2N), [5,6,7]+f2N)
AssertTol(params.EvaluateSymExpr(f1+f2+2, z3, f2,f2N, f1,[3,4,5]), [5,6,7]+f2N)
AssertTol(params.EvaluateSymExpr(f1+f2+a1+a2, z3, [f2,f1],[2,1,0;3,5,7], a2,a2N, a1,[.1,.2,.3]), [5.1,6.2,7.3]+a2N)
AssertTol(params.EvaluateSymExpr(f1+f2+a1+a2, z3, [f2;f1],[2,1,0;3,5,7], a2,a2N, a1,[.1,.2,.3]), [5.1,6.2,7.3]+a2N)
AssertTol(params.EvaluateSymExpr(f1+f2+c1+a2, z3, [f2,f1],[2,1,0;3,5,7], a2,a2N, c1,[.1,.2,.3]), [5.1,6.2,7.3]+a2N)
AssertTol(params.EvaluateSymExpr(f1+f2+a1+a2+c1, z3, [f2,f1],[2,1,0;3,5,7], a2,a2N, a1,[.1,.2,.3]), [5.1,6.2,7.3]+a2N+c1N)

% Vector, mixed
AssertTol(params.EvaluateSymExpr([f1+c2; f1-c2], z3, f1,[3,4,5], c2,2), [5,6,7; 1,2,3]) % Should normalise DIMS
AssertTol(params.EvaluateSymExpr([f1+c2, f1-c2], z3, f1,[3,4,5], c2,2), [5,6,7; 1,2,3]) % Should normalise DIMS

% Vector, mixed - where expr contains scalars and time-varying values
AssertTol(params.EvaluateSymExpr([7; 9], z3, f1,[3,4,5], c2,2), [7,7,7; 9,9,9])
AssertTol(params.EvaluateSymExpr([c1; 9], z3, f1,[3,4,5], c2,2), [c1N,c1N,c1N; 9,9,9])
AssertTol(params.EvaluateSymExpr([c1; c2], z3, f1,[3,4,5], c2,2), [c1N,c1N,c1N; 2,2,2])
AssertTol(params.EvaluateSymExpr([f1+c2; c2], z3, f1,[3,4,5], c2,2), [5,6,7; 2,2,2])

% Matrix, mixed
AssertTol(params.EvaluateSymExpr(f1+f2+a1+a2+c1, z3, [f2,f1],[2,1,0;3,5,7], a2,a2N, a1,[.1,.2,.3], nDimsIn=2), cat(3, 5.1,6.2,7.3)+a2N+c1N)
AssertTol(params.EvaluateSymExpr([f1+c2; f1-c2], z3, f1,[3,4,5], c2,2, nDimsIn=2), cat(3, [5;1],[6;2],[7;3])) % Should keep DIMS
AssertTol(params.EvaluateSymExpr([f1+c2, f1-c2], z3, f1,[3,4,5], c2,2, nDimsIn=2), cat(3, [5,1],[6,2],[7,3])) % Should keep DIMS

% Matrix, mixed - where expr contains scalars and time-varying values
AssertTol(params.EvaluateSymExpr(f1+f2+a1+a2+c1, tS1, [f2,f1],[2,1,0;3,5,7], a2,a2N, a1,[.1,.2,.3], nDimsIn=2), cat(3, 5.1,6.2,7.3)+a2N+c1N)
AssertTol(params.EvaluateSymExpr([f1+c2;  9], tS1, f1,[3,4,5], c2,2, nDimsIn=2), cat(3, [5;9],[6;9],[7;9])) % Should keep DIMS
AssertTol(params.EvaluateSymExpr([f1+c2, c2], z3, f1,[3,4,5], c2,2, nDimsIn=2), cat(3, [5,2],[6,2],[7,2])) % Should keep DIMS
AssertTol(params.EvaluateSymExpr([f1+c2, c2], tS1, f1,[3,4,5], nDimsIn=2), cat(3, [3,0],[4,0],[5,0])+c2N) % Should keep DIMS
AssertTol(params.EvaluateSymExpr([f1+c2+a1+e1;  9], tS1, [f1,a1],[3,4,5;.1,.2,.3], c2,2, nDimsIn=2), cat(3, [5.1+e1S1(1);9],[6.2+e1S1(2);9],[7.3+e1S1(3);9])) % Should keep DIMS
AssertTol(params.EvaluateSymExpr([f1,a1;c2,3;8,c1;a1,a2], tS1, f1,f1N, [a1,a2],[a1N,a2N], nDimsIn=2), repmat([f1N,a1N;c2N,3;8,c1N;a1N,a2N],1,1,3))

out = repmat([f1N,nan;c2N,3;8,c1N;a1N,a2N],1,1,3);
out(1,2,:) = e1S1;
AssertTol(params.EvaluateSymExpr([f1,e1;c2,3;8,c1;a1,a2], tS1, f1,f1N, [a1,a2],[a1N,a2N], nDimsIn=2), out)


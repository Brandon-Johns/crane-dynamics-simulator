%{
PURPOSE
    Hold post processed solution data

NOTATION
    _d:  1st time derivative
    _dd: 2nd time derivative

NOTES
    Subclasses are used to post-process solution data & fill all the properties of this class
        CDS_SolutionSim
        CDS_SolutionExp
        CDS_SolutionInterpolated
        CDS_SolutionSaved
%}

classdef CDS_Solution < handle & matlab.mixin.Heterogeneous
properties (SetAccess=protected)
    % Solution time
    t(1,:) double
    
    % Generalised coordinates
    q_free(:,1) CDS_Param_Free
    qf(:,:) double    % (q_free,time)
    qf_d(:,:) double  % (q_free,time)
    qf_dd(:,:) double % (q_free,time)
    
    % Time and state dependent variable system parameters
    q_input(:,1) CDS_Param_Input
    qi(:,:) double    % (q_input,time)
    qi_d(:,:) double  % (q_input,time)
    qi_dd(:,:) double % (q_input,time)
    
    % Lagrange multipliers
    q_lambda(:,1) CDS_Param_Lambda
    ql(:,:) double   % (lambda,time)
    ql_d(:,:) double % (lambda,time)
    
    % Points with mass
    p_mass(:,1) CDS_Point
    K(:,:) double % Kinetic energy (K,time)
    V(:,:) double % Potential energy (V,time)
    E(1,:) double % Total system energy (E,time)
    
    % All points
    p_all(:,1) CDS_Point
    Px(:,:) double % Task space position (x,time)
    Py(:,:) double % Task space position (y,time)
    Pz(:,:) double % Task space position (z,time)

    %TODO: R_0n(:,1) cell % Task space rotation - Each cell contains (3,3,t) double
    
    % Kinematic chains (for CDS_Solution_Animate)
    chains(1,:) cell % Cell array of linear arrays of CDS_Point instances, where each array is a chain
end
end

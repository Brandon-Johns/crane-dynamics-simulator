%{
PURPOSE
    Post processed solution data

NOTATION
    _d:  1st time derivative
    _dd: 2nd time derivative

NOTES
    Treat this class as abstract
    The subclasses enforce proper construction
        CDS_SolutionSim
        CDS_SolutionExp
        CDS_SolutionInterpolated
        CDS_SolutionSaved
%}

classdef CDS_Solution < handle & matlab.mixin.Heterogeneous
properties (SetAccess=protected)
    % The system description that was used to generate this solution
    sys(1,1) CDS_SystemDescription

    % Solution time
    t(1,:) double

    % Free generalised coordinates
    qf(:,:) double    % DIM[length(sys.params.q_free),  length(t)] 0th time derivative
    qf_d(:,:) double  % DIM[length(sys.params.q_free),  length(t)] 1st time derivative
    qf_dd(:,:) double % DIM[length(sys.params.q_free),  length(t)] 2nd time derivative

    % Input generalised coordinates
    qi(:,:) double    % DIM[length(sys.params.q_input), length(t)] 0th time derivative
    qi_d(:,:) double  % DIM[length(sys.params.q_input), length(t)] 1st time derivative
    qi_dd(:,:) double % DIM[length(sys.params.q_input), length(t)] 2nd time derivative

    % Lagrange multipliers
    ql(:,:) double    % DIM[length(sys.params.lambda),  length(t)] 0th time derivative
    ql_d(:,:) double  % DIM[length(sys.params.lambda),  length(t)] 1st time derivative

    % Task space position
    Px(:,:) double    % DIM[length(sys.points), length(t)] x coordinate
    Py(:,:) double    % DIM[length(sys.points), length(t)] y coordinate
    Pz(:,:) double    % DIM[length(sys.points), length(t)] z coordinate

    % Total system energy
    E(1,:) double     % DIM[1, length(t)]

    % Component energies
    K_mass(:,:) double           % DIM[length(sys.points.GetIfHasMass), length(t)] Kinetic energy
    V_mass(:,:) double           % DIM[length(sys.points.GetIfHasMass), length(t)] Potential energy
    V_linearSprings(:,:) double  % DIM[length(sys.linearSprings),       length(t)] Potential energy
    V_torsionSprings(:,:) double % DIM[length(sys.torsionSprings),      length(t)] Potential energy
end
methods
    %**********************************************************************
    % Interface - high-level get and operate on data
    %***********************************
    % Get indices to the solution arrays at given times
    % INPUT
    %   Solution times to get indices for
    % OUTPUT
    %   (double) DIM[length(frameTimes), 1] Indices of the nearest time coordinates to the input times
    function result = t_idx(this, frameTimes)
        arguments
            this(1,1)
            frameTimes(:,1) double
        end
        if isempty(this.t)
            error("Solution time is empty");
        end
        % Note: this function can also return the error from the nearest points,
        %   in case I need that later
        result = dsearchn(this.t.', frameTimes(:));
    end

    % Evaluate an array of symbolic expressions by substituting in numeric values
    % Use the registered params for any symbolic variables that are not provided
    % AUTOMATIC SUBSTITUTIONS
    %   this.const.Sym      for this.const.Num
    %   Any generalised coordinates for their values from the solution arrays
    % NOTE
    %   Row vectors have DIM[1,n] which implies nDims=2, but if nDims=1 is specified,
    %   then, instead of throwing an error for "symExprs has more dimensions than is specified by nDimsIn",
    %   it is automatically corrected into a column vector
    % INPUT
    %   symExprs: (symbolic expression) Expressions to evaluate
    %   idx_time: Time coordinates by index, according the time in this.t
    % INPUT (Name=Value)
    %   nDimsIn
    %       Number of dimensions of symExprs
    %       This is used to account for possible trailing length-1 dimensions
    % OUTPUT
    %   (double) DIM[size(symExprs,1:nDimsIn), length(idx_time)] Using convention (tensor dims, batch dims)
    function result = EvaluateSymExpr_atTimeIdx(this, symExprs, idx_time, options)
        arguments
            this(1,1)
            symExprs sym
            idx_time(:,1) uint64 = 1:length(this.t)
        end
        arguments
            options.nDimsIn(1,1) uint64 {mustBePositive} = 1
        end
        % Only sub in lambda or lambda_d if calculated
        lambda = [];
        lambda_d = [];
        if ~isempty(this.ql);   lambda   = this.sys.params.lambda.Sym; end
        if ~isempty(this.ql_d); lambda_d = this.sys.params.lambda.Sym(1); end

        % Substitute in solution
        xu = [this.sys.params.q_free.Sym; this.sys.params.q_free.Sym(1); this.sys.params.q_free.Sym(2);...
              this.sys.params.q_input.Sym; this.sys.params.q_input.Sym(1); this.sys.params.q_input.Sym(2);...
              lambda; lambda_d];
        xu_sol = [this.qf(:,idx_time); this.qf_d(:,idx_time); this.qf_dd(:,idx_time);...
                  this.qi(:,idx_time); this.qi_d(:,idx_time); this.qi_dd(:,idx_time);...
                  this.ql(:,idx_time); this.ql_d(:,idx_time)];
        result = this.sys.params.EvaluateSymExpr(symExprs, this.t(idx_time), xu,xu_sol, nDimsIn=options.nDimsIn);
    end
end
end

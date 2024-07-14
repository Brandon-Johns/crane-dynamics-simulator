%{
PURPOSE
    Post-process the simulated solution
    Hold the post processed solution data

EXAMPLE
    % Given
    %   sys: CDS_SystemDescription

    S = CDS_Solver;
    [t,x,xd] = S.Solve(sys);
    SS = CDS_SolutionSim(sys, t, x, xd);
%}

classdef CDS_SolutionSim < CDS_Solution
methods
    %**********************************************************************
    % Interface - Create & Initialise
    %***********************************
    % INPUT
    %   sys: CDS_SystemDescription that was solved
    %   t_sol,x_sol,xd_sol: Output of CDS_Solver.Solve(sys)
    function this = CDS_SolutionSim(sys, t_sol,x_sol,xd_sol)
        arguments
            sys(1,1) CDS_SystemDescription
            t_sol(1,:) double
            x_sol(:,:) double
            xd_sol(:,:) double = []
        end
        % Validate input: x_sol & xd_sol must be same size
        % but xd_sol is optional, so fill unset portion of xd_sol with nan
        if ~isempty(xd_sol) && size(xd_sol,1)~=size(xd_sol,1); warning("mismatching inputs"); end
        if ~isempty(xd_sol) && size(x_sol ,2)~=size(xd_sol,2); warning("mismatching inputs"); end
        
        tmp_xd_sol = nan(size(x_sol));
        tmp_xd_sol(1:size(xd_sol,1), 1:size(xd_sol,2)) = xd_sol;
        xd_sol = tmp_xd_sol;
        
        % Validate input: match length of time coords
        if length(t_sol)~=size(x_sol,2)
            % Try transpose
            if length(t_sol)==size(x_sol,1)
                % Transposing works
                warning("Input transposed");
                x_sol = x_sol.';
                xd_sol = xd_sol.';
            else
                % Still not matched
                error("mismatching inputs");
            end
        end
        
        % Validate input: match length of state vector
        if length(sys.params.x)~=size(xd_sol,1)
            % Try toggle lagrange multipliers
            if sys.params.x_mode=="withLambda"; try_xMode="withoutLambda"; else; try_xMode="withLambda"; end
            sys.params.SetStateVectorMode(try_xMode);
            
            % Try validate again
            if length(sys.params.x)==size(xd_sol,1)
                % Toggle works
                warning("State vector mode set to: " + try_xMode);
            else
                % Still not matched
                error("mismatching inputs");
            end
        end
        
        % Save solution time
        this.t = t_sol;
        
        % Sort x into arrays for q_free and lambda
        [x_underlying, d_offset, type] = sys.params.x.ParamUnderlying;
        
        this.q_free = unique(x_underlying(strcmp(type, "CDS_Param_Free")), 'stable');
        if any(strcmp(type, "CDS_Param_Lambda"))
            this.q_lambda = unique(x_underlying(strcmp(type, "CDS_Param_Lambda")), 'stable');
        end
        
        % Save solution data in arrays with index corresponding to object array
        for idxX = 1:length(x_underlying)
            if strcmp(type(idxX), "CDS_Param_Free")
                idxQF = this.q_free==x_underlying(idxX);
                if d_offset(idxX)==0
                    this.qf(idxQF,:) = x_sol(idxX,:);
                    %this.qf_d(idxQF,:) = xd_sol(idxX,:); % This is set for d_offset=1
                else
                    this.qf_d(idxQF,:) = x_sol(idxX,:);
                    this.qf_dd(idxQF,:) = xd_sol(idxX,:);
                end
            else %strcmp(type(idxX), "CDS_Param_Lambda")
                idxL = this.q_lambda==x_underlying(idxX);
                this.ql(idxL,:) = x_sol(idxX,:);
                this.ql_d(idxL,:) = xd_sol(idxX,:);
            end
        end
        
        % Generate input
        %   TODO: In CDS_Param_Input, make an interface to always allow vectorised inputs
        %   Maybe should also detect that the solver has finished and use the saved values?
        %*** Vectorised version ***
        %this.q_input = sys.params.q_input;
        %for idx = 1:length(this.q_input)
        %    this.qi(idx,:) = this.q_input.q(t_sol,x_sol);
        %    this.qi_d(idx,:) = this.q_input.q_d(t_sol,x_sol);
        %    this.qi_dd(idx,:) = this.q_input.q_dd(t_sol,x_sol);
        %end
        this.q_input = sys.params.q_input;
        for idxU = 1:length(this.q_input)
            for idxT = 1:length(t_sol)
                this.qi(idxU,idxT) = this.q_input(idxU).q(t_sol(idxT), x_sol(:,idxT));
                this.qi_d(idxU,idxT) = this.q_input(idxU).q_d(t_sol(idxT), x_sol(:,idxT));
                this.qi_dd(idxU,idxT) = this.q_input(idxU).q_dd(t_sol(idxT), x_sol(:,idxT));
            end
        end
        
        this.CalcEnergy(sys);
        this.CalcTransforms(sys);
        
        this.chains = sys.chains;
    end
end
methods (Access=private)
    % This is the same as 'CDS_Calc_Energy', but I really want to be sure of the input/output order
    function CalcEnergy(this, sys)
        x = [this.q_free.Sym; this.q_free.Sym(1)];
        u = [this.q_input.Sym; this.q_input.Sym(1); this.q_input.Sym(2)];
        c = sys.params.const.Sym;
        xSol = [this.qf; this.qf_d];
        uSol = [this.qi; this.qi_d; this.qi_dd];
        cNum = sys.params.const.Num;
        
        % Plot system energy
        %   DIM: (energy, time)
        GenEquations = CDS_Solver_GenerateEquations;
        [K_sym, V_sym, this.p_mass] = GenEquations.Energy(sys);
        V_semiNum = subs(V_sym, c,cNum);
        K_semiNum = subs(K_sym, c,cNum);
        
        % Tested matlabFunction is ~10x faster than subs
        % Loop because of bug in matlabFunction when one of the values in the array is a constant (vertcat error)
        mNum = length(this.p_mass);
        this.V = zeros(mNum, length(this.t));
        this.K = zeros(mNum, length(this.t));
        for idx = 1:mNum
            V_h = matlabFunction(V_semiNum(idx),'Vars',{[sym('t'); x; u]});
            K_h = matlabFunction(K_semiNum(idx),'Vars',{[sym('t'); x; u]});
            this.V(idx,:) = V_h([this.t; xSol; uSol]);
            this.K(idx,:) = K_h([this.t; xSol; uSol]);
        end
        
        % Total system energy
        tmp = this.K + this.V;
        
        % Sum energy of all masses
        this.E = sum(tmp, 1);
    end
    
    function CalcTransforms(this, sys)
        x = [this.q_free.Sym; this.q_free.Sym(1)];
        u = [this.q_input.Sym; this.q_input.Sym(1); this.q_input.Sym(2)];
        c = sys.params.const.Sym;
        xSol = [this.qf; this.qf_d];
        uSol = [this.qi; this.qi_d; this.qi_dd];
        cNum = sys.params.const.Num;
        
        % Save point objects
        points = sys.points.all;
        this.p_all = points;
        
        % Evaluate positions
        this.Px = zeros(length(points), length(this.t));
        this.Py = zeros(length(points), length(this.t));
        this.Pz = zeros(length(points), length(this.t));
        for idx = 1:length(points)
            % Split points into functions with single output
            %   to avoid errors internal to matlabFunction if one of the outputs is constant
            %   e.g. it tries to eval @ [in1(1,:), 0.0, 0.0]
            %   which causes a concatenation error
            P_semiNum = subs(points(idx).T_0n.P, c,cNum);
            Px_h = matlabFunction(P_semiNum(1),'Vars',{[sym('t'); x; u]});
            Py_h = matlabFunction(P_semiNum(2),'Vars',{[sym('t'); x; u]});
            Pz_h = matlabFunction(P_semiNum(3),'Vars',{[sym('t'); x; u]});
            this.Px(idx,:) = Px_h([this.t; xSol; uSol]);
            this.Py(idx,:) = Py_h([this.t; xSol; uSol]);
            this.Pz(idx,:) = Pz_h([this.t; xSol; uSol]);
        end
    end
end
end

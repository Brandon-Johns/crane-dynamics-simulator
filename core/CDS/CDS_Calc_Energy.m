%{
PURPOSE
    Calculate the system energy for any given configuration
    Does not require solving the system

EXAMPLE
    CE = CDS_Calc_Energy(sys);
    CE.InputList
    % Use the displayed list to form the input to CE.V
    energies = CE.V(...);
    energyOfMassB = energies( CE.OutputList.PointIdx("B"), : );
%}

classdef CDS_Calc_Energy < handle
properties (SetAccess=protected)
    % List of all variables in the energy equations (time, generalised coordinates, inputs)
    InputList(:,1) string      % Specifies the column order of inputs to this.V, this.K, this.E
    InputList_0Vel(:,1) string % Specifies the column order of inputs to this.V_0Vel, this.K_0Vel, this.E_0Vel

    % List of all points with mass
    OutputList(:,1) CDS_Point  % Specifies the column order of outputs from all functions

    % Initial conditions
    V0(:,1) double = nan
    K0(:,1) double = nan
    E0(:,1) double = nan
end
properties (Access=private)
    sys CDS_SystemDescription

    % Cell of function handles
    %   One cell for each mass, following the order of this.OutputList
    %   For each handle,
    %       Input size: (length(this.InputList), nOutputs)
    %           where each input(:,idx) is a set of values corresponding to this.InputList, defining specific configurations to evaluate
    %       Output size: (1, nOutputs)
    V_handles(:,1) cell % Potential energy
    K_handles(:,1) cell % Kinetic energy
end
methods
    function this = CDS_Calc_Energy(sys)
        arguments
            sys(1,1) CDS_SystemDescription
        end
        this.sys = sys;
        x = sys.params.x("withoutLambda");
        u = sys.params.u;
        c = sys.params.const;
        cNum = sys.params.const.Num;
        
        % Plot system energy
        %   DIM: (energy, time)
        GenEquations = CDS_Solver_GenerateEquations;
        [K_sym, V_sym, this.OutputList] = GenEquations.Energy(sys);
        V_semiNum = subs(V_sym, c.Sym,cNum);
        K_semiNum = subs(K_sym, c.Sym,cNum);
        
        % Tested matlabFunction is ~10x faster than subs
        % Cell of handles because of bug in matlabFunction when one of the values in the array is a constant (vertcat error)
        numMass = length(this.OutputList);
        this.V_handles = cell(numMass,1);
        this.K_handles = cell(numMass,1);
        for idx = 1:numMass
            this.V_handles{idx} = matlabFunction(V_semiNum(idx),'Vars',{[sym('t'); x.Sym; u.Sym]});
            this.K_handles{idx} = matlabFunction(K_semiNum(idx),'Vars',{[sym('t'); x.Sym; u.Sym]});
        end

        this.InputList = ["t"; x.Str; u.Str];
        this.InputList_0Vel = [sys.params.q_free.Str; sys.params.q_input.Str];

        % Initial conditions
        u_h = sys.params.u.q;
        this.V0 = this.V([ 0; x.x0; u_h(0, x.x0)]);
        this.K0 = this.K([ 0; x.x0; u_h(0, x.x0)]);
        this.E0 = this.E([ 0; x.x0; u_h(0, x.x0)]);
    end

    % Potential energy
    %   Let
    %       a = length(InputList)
    %       b = number of configurations to calculate the energy of
    %       c = number of masses
    % INPUT
    %   Size
    %       varargin(1,1): (a,b)
    %       varargin(a,1): (1,b), (1,b), (1,b), (1,b), ...
    %   Each column is a set of values corresponding to this.InputList, defining a specific configuration to evaluate
    % OUTPUT
    %   Size: (c,b)
    %   The energy of each mass, keeping the same order as this.OutputList
    function out = V(this, varargin)
        in = this.vararginToMat(varargin, length(this.InputList));
        numOutputs = size(in,2);
        numMass = length(this.OutputList);
        out = zeros(numMass, numOutputs);
        for idx = 1:numMass
            out(idx,:) = this.V_handles{idx}(in);
        end
    end

    % Kinetic energy
    % INPUT/OUTPUT: same as this.V
    function out = K(this, varargin)
        in = this.vararginToMat(varargin, length(this.InputList));
        numOutputs = size(in,2);
        numMass = length(this.OutputList);
        out = zeros(numMass, numOutputs);
        for idx = 1:numMass
            out(idx,:) = this.K_handles{idx}(in);
        end
    end

    % Total system energy
    % INPUT
    %   same as this.V
    % OUTPUT
    %   Size: (1,b)
    %   Each element is the total system energy for that configuration
    function out = E(this, varargin)
        % Definition can vary
        %     1) E = sum( d[L]/d[q_d] * q_d ) - L
        %     2) E = K + V
        % Note that (1) is the Hamiltonian
        % For a mechanical system, these are the same for the case where all of the following are satisfied
        %     K =/= K(t) i.e. The kinetic energy is not an explicit function of time
        %     V =/= V(t) i.e. The potential energy is not an explicit function of time
        %     V =/= V(q_d) i.e. V is not a function of velocities
        % I'm going with (2), and calling the case where they differ as non-conservative systems
        
        % Sum energy of all masses
        out = sum(this.V(varargin{:}) + this.K(varargin{:}), 1);
    end

    % Same as the this.V, this.K, and this.E, but with automatically input 0 time, 0 velocity, 0 acceleration
    % Inputs correspond to this.InputList_0Vel instead of this.InputList
    function out = V_0Vel(this, varargin)
        in = this.vararginToMat(varargin, length(this.InputList_0Vel));
        numOutputs = size(in,2);
        numQF = length(this.sys.params.q_free);
        numQI = length(this.sys.params.q_input);
        out = this.V([ zeros(1+numQF, numOutputs); in; zeros(2*numQI, numOutputs) ]);
    end
    function out = K_0Vel(this, varargin)
        in = this.vararginToMat(varargin, length(this.InputList_0Vel));
        numOutputs = size(in,2);
        numQF = length(this.sys.params.q_free);
        numQI = length(this.sys.params.q_input);
        out = this.K([ zeros(1+numQF, numOutputs); in; zeros(2*numQI, numOutputs) ]);
    end
    function out = E_0Vel(this, varargin)
        in = this.vararginToMat(varargin, length(this.InputList_0Vel));
        numOutputs = size(in,2);
        numQF = length(this.sys.params.q_free);
        numQI = length(this.sys.params.q_input);
        out = this.E([ zeros(1+numQF, numOutputs); in; zeros(2*numQI, numOutputs) ]);
    end
end
methods (Access=private)
    % Effectively cell2mat(), but with different input validation
    % Only allows 1D column cell
    % Automatically transforms cells that are columns to rows
    % Exception: scalar input is passed through
    function out = vararginToMat(~, in, nRows)
        arguments
            ~
            in(:,1) cell
            nRows(1,1) int64 % Validate that the output must have this many rows
        end
        if length(in) == 1
            % The input is a single matrix
            out = in{1};
            % Validate the size (automatically fix the size only if it's a vector)
            if size(out,1)==1 && size(out,2)==nRows
                out = out.';
            end
            if size(out,1) ~= nRows
                error("Bad input size. Requires dim1="+nRows);
            end
            return
        end

        if length(in) ~= nRows
            error("Bad number of inputs. Requires "+nRows+" inputs")
        end

        % The input is a comma separated list of arrays
        out = zeros(nRows, length(in{1}));
        for idx = 1:nRows
            if ~isvector(in{idx})
                error("Bad input shape. Each input must be a vector")
            end
            out(idx,:) = [in{idx}(:)];
        end
    end
end
end

%{
Intended for internal use only

PURPOSE
    Common parts of the Components classes

%}

classdef CDS_Components_Common < handle
methods (Static)
    % Validate at least 1 input
    % Convert all inputs to CDS_T
    % Clear the rotation
    function out = SanitiseLocations(locations)
        arguments(Repeating)
            locations {mustBeA(locations,["CDS_Point","CDS_T","sym","double"])}
        end
        if isempty(locations); error("Bad input: Specify at least one location"); end
        out = CDS_T.Zeros(1, numel(locations));
        for idx = 1:numel(locations)
            loc = locations{idx};
            if isa(loc,"CDS_Point")
                if ~isscalar(loc)
                    sizeStr = strjoin(string(size(loc)),", ");
                    error("Bad input: At location %d\nType: %s\nSize: [%s] <-- Should be [1,1]", idx, class(loc), sizeStr);
                end
                % Clear rotation
                out(idx) = CDS_T("P", loc.T_0n.P);
            elseif isa(loc,"CDS_T")
                if ~isscalar(loc)
                    sizeStr = strjoin(string(size(loc)),", ");
                    error("Bad input: At location %d\nType: %s\nSize: [%s] <-- Should be [1,1]", idx, class(loc), sizeStr);
                end
                % Clear rotation
                out(idx) = CDS_T("P", loc.P);
            else
                if ~(isvector(loc) && length(loc)==3)
                    sizeStr = strjoin(string(size(loc)),", ");
                    error("Bad input: At location %d\nType: %s\nSize: [%s] <-- Should be [3,1]", idx, class(loc), sizeStr);
                end
                out(idx) = CDS_T("P", loc);
            end
        end
    end

    % Validate at least 1 input
    % Ensure at least 2 outputs
    % Convert all inputs to CDS_T
    % Clear the rotation
    function out = SanitiseConnections(varargin)
        out = CDS_Components_Common.SanitiseLocations(varargin{:});
        if numel(out)==1
            % Only 1 input => Default the other connection point to the origin
            out = [CDS_T(); out];
        end
    end

    % Ensure either 0 outputs OR at least 2 outputs
    % Convert all inputs to CDS_T
    % Clear the rotation
    function out = SanitiseConnections_AllowEmpty(varargin)
        if nargin==0
            out = CDS_T.empty(0,1);
            return
        end
        out = CDS_Components_Common.SanitiseConnections(varargin{:});
    end

    % Total length of a path, by straight line distance
    % INPUT
    %   points: Array of (at least 2) route points
    % OUTPUT
    %   length = ||P_1 - P_2|| + ||P_2 - P_3|| + ||P_3 - P_4|| + ...
    function length = LinearRouteLength(points)
        arguments
            points(:,1) CDS_T
        end
        length = 0;
        for idx = 1:numel(points)-1
            P_A = points(idx).P;
            P_B = points(idx+1).P;
            P_AB = P_A - P_B;
            length = length + simplify(norm(P_AB));
        end
    end

    %**********************************************************************
    % Decomposition of Hamiltonian
    %***********************************
    % Time-rate of change of energy
    % OUTPUT
    %   (symbolic expression)

    % d[K]/d[qdT] . qd - 2K
    function out = Hamiltonian_H_nonQuadraticK(component)
        arguments
            component {mustBeA(component,"CDS_Point")}
        end
        if isempty(component); out=sym.empty(size(component)); return; end
        qd = component(1).sys.params.q.Sym(1);
        K = component(:).Energy_K;
        out = jacobian(K, qd) * qd - 2*K;
        out = reshape(out, size(component));
    end

    % d[K]/d[qfdT] . qfd - 2K
    function out = Hamiltonian_Hf_nonQuadraticK(component)
        arguments
            component {mustBeA(component,"CDS_Point")}
        end
        if isempty(component); out=sym.empty(size(component)); return; end
        qfd = component(1).sys.params.q_free.Sym(1);
        K = component(:).Energy_K;
        out = jacobian(K, qfd) * qfd - 2*K;
        out = reshape(out, size(component));
    end

    % - d[V]/d[qdT] . qd
    function out = Hamiltonian_H_velocityDependentV(component)
        arguments
            component {mustBeA(component,["CDS_Point","CDS_Component_LinearSpring","CDS_Component_TorsionSpring"])}
        end
        if isempty(component); out=sym.empty(size(component)); return; end
        qd = component(1).sys.params.q.Sym(1);
        V = component(:).Energy_V;
        out = - jacobian(V, qd) * qd;
        out = reshape(out, size(component));
    end

    % - d[V]/d[qfdT] . qfd
    function out = Hamiltonian_Hf_velocityDependentV(component)
        arguments
            component {mustBeA(component,["CDS_Point","CDS_Component_LinearSpring","CDS_Component_TorsionSpring"])}
        end
        if isempty(component); out=sym.empty(size(component)); return; end
        qfd = component(1).sys.params.q_free.Sym(1);
        V = component(:).Energy_V;
        out = - jacobian(V, qfd) * qfd;
        out = reshape(out, size(component));
    end

    %**********************************************************************
    % Decomposition of Power
    %***********************************
    % Time-rate of change of energy
    % OUTPUT
    %   (symbolic expression)

    % D[K]
    function out = Power_dKdt(component)
        arguments
            component {mustBeA(component,"CDS_Point")}
        end
        if isempty(component); out=sym.empty(size(component)); return; end
        out = component(1).sys.params.TotalDiff(component.Energy_K);
    end

    % D[V]
    function out = Power_dVdt(component)
        arguments
            component {mustBeA(component,["CDS_Point","CDS_Component_LinearSpring","CDS_Component_TorsionSpring"])}
        end
        if isempty(component); out=sym.empty(size(component)); return; end
        out = component(1).sys.params.TotalDiff(component.Energy_V);
    end

    % - d[K]/d[t]
    function out = Power_dWdt_timeDependentK(component)
        arguments
            component {mustBeA(component,"CDS_Point")}
        end
        syms t real
        K = component(:).Energy_K;
        out = - jacobian(K, t);
        out = reshape(out, size(component));
    end

    % d[V]/d[t]
    function out = Power_dWdt_timeDependentV(component)
        arguments
            component {mustBeA(component,["CDS_Point","CDS_Component_LinearSpring","CDS_Component_TorsionSpring"])}
        end
        syms t real
        V = component(:).Energy_V;
        out = jacobian(V, t);
        out = reshape(out, size(component));
    end

    % - D[ d[K]/d[qdT] . qd - 2K ]
    function out = Power_dWdt_nonQuadraticK(component)
        arguments
            component {mustBeA(component,"CDS_Point")}
        end
        if isempty(component); out=sym.empty(size(component)); return; end
        out = - component(1).sys.params.TotalDiff(CDS_Components_Common.Hamiltonian_H_nonQuadraticK(component));
    end

    % - D[ - d[V]/d[qdT] . qd ]
    function out = Power_dWdt_velocityDependentV(component)
        arguments
            component {mustBeA(component,["CDS_Point","CDS_Component_LinearSpring","CDS_Component_TorsionSpring"])}
        end
        if isempty(component); out=sym.empty(size(component)); return; end
        out = - component(1).sys.params.TotalDiff(CDS_Components_Common.Hamiltonian_H_velocityDependentV(component));
    end

    %**********************************************************************
    % Decomposition of Generalised Force
    %***********************************
    % The generalised force vector, ordered with respect to sys.params.q
    % OUTPUT
    %   (symbolic expression) DIM[length(sys.params.q), size(component)] Using convention (tensor dims, batch dims)

    % - d2[K]/d[qd]d[qdT] . qdd
    function out = Q_inertial(component, sys)
        arguments
            component {mustBeA(component,"CDS_Point")}
            sys(1,1) CDS_SystemDescription
        end
        qd = sys.params.q.Sym(1);
        qdd = sys.params.q.Sym(2);
        K = component.Energy_K;
        num_q = length(qd);
        out = sym(zeros(num_q, numel(component)));
        for idx = 1:numel(component)
            out(:, idx) = - hessian(K(idx), qd) * qdd;
        end
        out = reshape(out, [num_q, size(component)]);
    end

    % - d2[K]/d[qd]d[qT] . qd + d[K]/d[q]
    function out = Q_CentrifugalAndCoriolis(component, sys)
        arguments
            component {mustBeA(component,"CDS_Point")}
            sys(1,1) CDS_SystemDescription
        end
        q = sys.params.q.Sym;
        qd = sys.params.q.Sym(1);
        K = component.Energy_K;
        num_q = length(q);
        out = sym(zeros(num_q, numel(component)));
        for idx = 1:numel(component)
            out(:, idx) = - jacobian(jacobian(K(idx), qd), q)*qd + jacobian(K(idx), q).';
        end
        out = reshape(out, [num_q, size(component)]);
    end

    % - d2[K]/d[qd]d[t]
    function out = Q_timeDependentK(component, sys)
        arguments
            component {mustBeA(component,"CDS_Point")}
            sys(1,1) CDS_SystemDescription
        end
        syms t real
        qd = sys.params.q.Sym(1);
        K = component(:).Energy_K;
        num_q = length(qd);
        out = sym(zeros(num_q, numel(component)));
        for idx = 1:numel(component)
            out(:, idx) = - jacobian(jacobian(K(idx), qd), t);
        end
        out = reshape(out, [length(qd), size(component)]);
    end

    % d2[V]/d[qd]d[qdT] . qdd + d2[V]/d[qd]d[qT] . qd + d2[V]/d[qd]d[t]
    function out = Q_velocityDependentV(component, sys)
        arguments
            component {mustBeA(component,["CDS_Point","CDS_Component_LinearSpring","CDS_Component_TorsionSpring"])}
            sys(1,1) CDS_SystemDescription
        end
        syms t real
        q = sys.params.q.Sym;
        qd = sys.params.q.Sym(1);
        qdd = sys.params.q.Sym(2);
        V = component.Energy_V;
        num_q = length(q);
        out = sym(zeros(num_q, numel(component)));
        for idx = 1:numel(component)
            out(:, idx) = hessian(V(idx), qd) * qdd + jacobian(jacobian(V(idx), qd), q)*qd + jacobian(jacobian(V(idx), qd), t);
        end
        out = reshape(out, [num_q, size(component)]);
    end

    % - d[V]/d[q]
    function out = Q_potential(component, sys)
        arguments
            component {mustBeA(component,["CDS_Point","CDS_Component_LinearSpring","CDS_Component_TorsionSpring"])}
            sys(1,1) CDS_SystemDescription
        end
        q = sys.params.q.Sym;
        V = component(:).Energy_V;
        out = - jacobian(V, q).';
        out = reshape(out, [length(q), size(component)]);
    end
end
end

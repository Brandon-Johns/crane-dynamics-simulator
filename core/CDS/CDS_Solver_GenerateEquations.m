%{
Intended for internal use only

PURPOSE
    Generate the equation of motion
%}

classdef CDS_Solver_GenerateEquations < handle
properties
    %
end
methods
    function this = CDS_Solver_GenerateEquations()
        %
    end
    
    %**********************************************************************
    % Interface
    %***********************************
    % Reference frames
    %   n: Nominal point frame (given in T_0n)
    %   c: Location of centre of mass, orientation aligned with 'n'
    %   p: Frame of input moment of inertia (principle or other)
    %   To reduce confusion, I Enforce that P_0n=P_0c=P_0p
    %   => 'c'='n' (but 'p' may be rotated from 'n')
    function [K, V, massPoints] = Energy(this, sys)
        arguments
            this(1,1)
            sys
        end
        massPoints = sys.points.all.GetIfHasMass;
        numMass = length(massPoints);
        
        q = sys.params.q.Sym;
        q_d = sys.params.q.Sym(1);
        q_swap = sys.params.q_SymSwap;
        q_swap_t = sys.params.q_SymSwap('t');
        
        % Energy: K=kinetic, V=potential
        K = sym(zeros(numMass,1));
        V = sym(zeros(numMass,1));
        for idx = 1:numMass
            % Position & orientation of center of mass
            P0c = massPoints(idx).T_0n.P;
            R0c = massPoints(idx).T_0n.R;
            
            % Jacobian & velocity of center of mass
            J0c = jacobian(P0c, q);
            P0c_d = J0c*q_d;

            % Branch: using point mass assumption or not
            if massPoints(idx).IsPointMass
                % Set moment of inertia = 0
                % => angular velocity doesn't matter => set w=0
                Icc = zeros(3,3);
                wcc = [0;0;0];
            else
                % Moment of inertia: joint frame <- principal frame
                Icc = massPoints(idx).R_np * massPoints(idx).I_pn * (massPoints(idx).R_np.');
                
                % Angular velocity of center of mass
                %   NOTE: Carefully define input Toc for correct Roc.
                %   > Conflict with 'moving then rotating' instead of 'rotating then moving'
                %   > Toc should not rotate towards next link
                % Derivation for relation for R->w
                %   https://en.wikipedia.org/wiki/Rotation_formalisms_in_three_dimensions#Rotation_matrix_%E2%86%94_angular_velocities
                R0c_t = subs(R0c, q_swap, q_swap_t);
                Wcc = diff(R0c_t, sym('t'))*(R0c_t.'); % Angular velocity tensor
                wcc_t = [Wcc(3,2); Wcc(1,3); Wcc(2,1)]; % Decompose angular velocity tensor
                wcc = subs(wcc_t, q_swap_t, q_swap);
            end
            
            m = massPoints(idx).m;
            
            % Kinetic energy = sum(0.5m(v').v + 0.5(w').I.w)
            K(idx) = (1/2)*m*(P0c_d.')*P0c_d + (1/2)*(wcc.')*Icc*wcc;
            
            % Potential energy = sum(-mg.P)
            V(idx) = -m*(sys.g0.')*P0c;
        end
    end
    
    % Form: Euler-Lagrange equations from Lagrangian (2nd order ODEs)
    %   DAEs_EL = 0
    function DAEs_EL = EulerLagrange(this, sys, K, V)
        arguments
            this(1,1)
            sys
            K
            V
        end
        C = sys.C;
        
        q_free = sys.params.q_free.Sym;
        q_free_d = sys.params.q_free.Sym(1);
        q_swap = sys.params.q_SymSwap;
        q_swap_t = sys.params.q_SymSwap('t');
        lambda = sys.params.lambda.Sym;
        
        % Lagrangian
        L = sum(K - V);
        
        % System equations from Euler-Lagrange
        % Note: no equations for inputs, only generalised coordinates
        DAEs_EL = sym(zeros(length(q_free),1));
        for idx = 1:length(q_free)
            % dL/dq
            dLdq = diff(L, q_free(idx));
            
            % dL/d(q_d)
            dLdq_d = diff(L, q_free_d(idx));
            
            % d(dL/d(q_d))/dt
            dLdq_d = subs(dLdq_d, q_swap, q_swap_t);
            ddLdq_d_dt = diff(dLdq_d, sym('t'));
            ddLdq_d_dt = subs(ddLdq_d_dt, q_swap_t, q_swap);
            
            % System equations
            DAEs_EL(idx) = ddLdq_d_dt - dLdq;
            
            % Add Lagrange multipliers
            % Note: matrix multiplication here
            %   sum_i{lambda_i*d(C_i)/dq}
            lambda_dCdq = (lambda.') * diff(C, q_free(idx));
            
            % Append to system equations
            DAEs_EL(idx) = DAEs_EL(idx) + lambda_dCdq;
        end
    end
    
    % Form: Constraint equations
    %   DEAs_C = 0
    function DAEs_C = Constraint(this, sys, mode)
        arguments
            this(1,1)
            sys
            mode(1,1) string {mustBeMember(mode,["C_d","C_dd"])} = "C_d"
        end
        q_swap = sys.params.q_SymSwap;
        q_swap_t = sys.params.q_SymSwap('t');
        
        % Constraint equations
        C = sys.C;
        C_t = subs(C, q_swap, q_swap_t);
        
        % Differentiate constraint equations
        if strcmp(mode, "C_d")
            % dC/dt (matrix)
            C_dt = diff(C_t, sym('t'));
            C_d = subs(C_dt, q_swap_t, q_swap);
            
            DAEs_C = C_d;
            
        elseif strcmp(mode, "C_dd")
            % dC/dt (matrix)
            C_ddt = diff(C_t, sym('t'), 2);
            C_dd = subs(C_ddt, q_swap_t, q_swap);
            
            DAEs_C = C_dd;
        else
            error("Bad input: mode")
        end
    end
end
end

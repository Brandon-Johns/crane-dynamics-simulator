%{
Incomplete!
%}

classdef CDS_Param_Input_Fun < handle
properties (SetAccess=immutable, GetAccess=private)
    params
end
properties (SetAccess=private, GetAccess=public)
    t(1,:) double
    x(:,:) double % (x,time)
    q(1,:) double
    q_d(1,:) double
    q_dd(1,:) double
end
methods
    %**********************************************************************
    % Interface - Create & Initialise
    %***********************************
    function this = CDS_Param_Input_Fun(params)
        this.params = params;
        
        % Pad the first few values to allow looking back
        %   Assuming that t starts a 0 (don't try anything fancy)
        %   Assuming that x0 is 0 velocity (how bold of me to assume)
        this.t = [-2,-1,0];
        this.x = repmat(params.x.x0, 1,3);
        this.q = [0,0,0];
        this.q_d = [0,0,0];
        this.q_dd = [0,0,0];
    end
    
    %**********************************************************************
    % Interface - Called by Solver
    %***********************************
    function [q_now, qd_now, qdd_now] = Evaluate(this, tNow, xNow)
        this.SaveState(tNow, xNow);
        theta1d = xNow(1);
        theta1 = xNow(2);
        
        % Sub in everything
        %x = this.params.x.Sym;
        %c = this.params.const.Sym;
        %cNum = this.params.const.Num;
        %qNum = double(subs(qSym, [sym('t');x;c], [t;x;cNum]));
        %q_dNum = double(subs(q_dSym, [sym('t');x;c], [t;x;cNum]));
        %q_ddNum = double(subs(q_ddSym, [sym('t');x;c], [t;x;cNum]));
        
        % Controlled quantity
        %qd_now = -0.2*theta1d;
        %qdd_now = 5*theta1d;
        qdd_now = 5*theta1d - 0.5*this.q_d(end) - 0.15*this.q(end);
        
        % Find other derivatives from controlled quantity
        %[q_now, qd_now, qdd_now] = VelocityControl(this, qd_now);
        [q_now, qd_now, qdd_now] = AccelerationControl(this, qdd_now);
        
        this.SaveInput(q_now, qd_now, qdd_now);
    end
    
    function numOut = Eval_q(this, t, x)
        [numOut,~,~] = Evaluate(this, t, x);
    end
    function numOut = Eval_q_d(this, t, x)
        [~,numOut,~] = Evaluate(this, t, x);
    end
    function numOut = Eval_q_dd(this, t, x)
        [~,~,numOut] = Evaluate(this, t, x);
    end
    
end
methods (Access=private)
    % Save past state and corresponding time
    % Remove any future values (if the solver jumps back)
    function SaveState(this, t, x)
        if isempty(this.t) || t > this.t(end)
            % New values
            this.t(end+1) = t;
            this.x(:,end+1) = x;
        else
            % Solver is stepping back or evaluating again at current step
            % => Overwrite old values
            this.t = [this.t(this.t<t), t];
            idxEnd = length(this.t);
            
            this.x(:,idxEnd:end) = [];
            this.x(:,end+1) = x;
            
            this.q(idxEnd:end) = [];
            this.q_d(idxEnd:end) = [];
            this.q_dd(idxEnd:end) = [];
        end
    end
    
    function SaveInput(this, q_new, qd_new, qdd_new)
        this.q(end+1) = q_new;
        this.q_d(end+1) = qd_new;
        this.q_dd(end+1) = qdd_new;
    end
    
    function [q_now, qd_now, qdd_now] = AccelerationControl(this, qdd_now)
        % Position and velocity approximations
        if length(this.t)<2
            % Initial conditions - TODO: allow user input
            q_now = 0;
            qd_now = 0;
        else
            dt = this.t(end) - this.t(end-1);
            q_prev = this.q(end);
            qd_prev = this.q_d(end);
            q_now = q_prev + dt*qd_prev + 0.5*qdd_now*dt^2;
            qd_now = qd_prev + dt*qdd_now;
        end
        
    end
    
    function [q_now, qd_now, qdd_now] = VelocityControl(this, qd_now)
        % Position and acceleration approximations
        if length(this.t)<2
            % Initial conditions - TODO: allow user input
            q_now=0;
            qdd_now=0;
        else
            dt = this.t(end) - this.t(end-1);
            q_prev = this.q(end);
            qd_prev = this.q_d(end);
            qdd_now = (qd_now-qd_prev)/dt;
            q_now = q_prev + dt*qd_prev + 0.5*qdd_now*dt^2;
        end
    end
end
end

%{
Abstract Class
'C3' models series

PURPOSE
    Build a predefined crane model
%}

classdef CDSm_C3 < CDSm
properties
    % Reduce to 2D (true or false)
    Flag_2D(1,1) logical = true

    % Point I: True or equilibrium
    % Must be equilibrium for pendulum models (false)
    %Flag_pointI_truePosition(1,1) logical = false % Not implemented
end
methods
    %**********************************************************************
    % Interface: Create
    %***********************************
    function this = CDSm_C3(varargin)
        % Call superclass constructor
        this@CDSm(varargin{:});
    end
end
end


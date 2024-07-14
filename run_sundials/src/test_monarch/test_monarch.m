%{
Written By: Brandon Johns
Date Version Created: 2020-11-17
Date Last Edited: 2020-11-17
Purpose: Test running on MonARCH
Status: Complete
Referenced files: NA           Version , date

%%% PURPOSE %%%

%%% VERSION CHANGES %%%

%%% TODO %%%

%%% NOTES %%%


%}
close all
clear all
clc

% Sample data
t = (0:20).';
x = t.^2;
x_names = {'x'};

%**********************************************************************
% Syms
%***********************************
syms t_sym
x_sym = t_sym.^3;
x = double(subs(x_sym, t_sym, t))

%**********************************************************************
% ODE
%***********************************
% % System equation - for ode45
% x_d = @(t,x) [-x(1)+x(2).*(1+x(1)); -x(1).*(1+x(1))];
%
% % Simulation
% t_span = [0 50];
% y0 = 5;
% ICs = [y0; 0];
% [t,x] = ode45(x_d, t_span, ICs);
%
% x_names = {'x1', 'x2'};
%
% %plot(x(:,1),x(:,2))

%**********************************************************************
% Excel out
%***********************************
fileName = 'hw_excel';

names = [{'t'}, x_names];
values = [t, x];
data = array2table(values, 'VariableNames',names);

writetable(data, strcat(fileName,'.xlsx'),...
    'WriteMode','replacefile',...
    'Range','A1',...
    'UseExcel',0);



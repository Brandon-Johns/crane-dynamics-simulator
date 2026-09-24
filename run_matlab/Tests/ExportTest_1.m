% Run these manually
% Rough tests to cover different export / import modes
% Not exhaustive


% Matlab export
%   Run the file normally
%   Run the export command
%   Run the exported file
%   Import the results and check error
E4_ParticleOnPath_B
S.Solve(sys,"ode45", "export");
tmp
aaa = readmatrix("solvetimeTxt_excel.xlsx");
aaa_t = aaa(:, 1);
aaa_x = aaa(:, 2:end);
max(abs(aaa_t - SS.t.'))             % 1e-16
max(abs(aaa_x - [SS.qf_d; SS.qf].')) % 1e-11


% Sundials export
%   Run this for an already exported and verified file
%   Check the diff in vscode
run_C3ExpSim_ExportSun


% Solution export / import
%   Clear the cache
%   Run this file twice
%   Check that the results are the same between them
run_C3_UseCaching
run_C3_UseCaching


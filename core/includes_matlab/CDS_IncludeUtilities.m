%{
PURPOSE
    Calling this file includes "core/Utilities" on the matlab path
%}

% Full path to this file (no matter where it is called from)
[CDS_pathDir,~,~] = fileparts( mfilename('fullpath') );

% Directories to include, relative to directory that holds this file
CDS_include1 = fullfile(CDS_pathDir, "..","Utilities");

% Add to the Matlab path + all subdirectories
addpath(genpath(CDS_include1));

% Remove variables from user's workspace
clearvars CDS_pathDir CDS_include1

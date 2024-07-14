% Call this file from your own file to add to the Matlab path: the include files

% Full path to this file (no matter where it is called from)
[CDS_pathDir,~,~] = fileparts( mfilename('fullpath') );

% Directories to include, relative to directory that holds this file
CDS_include1 = fullfile(CDS_pathDir, "..","..","includes_matlab");

% Add to the Matlab path
addpath(CDS_include1);

clearvars CDS_pathDir CDS_include1
% colorGaborSceneCreateTest
%
% Test the routine that creats a color gabor scene.
%
% 7/7/16  dhb  Wrote it.

%% Clear
clear; close all;

%% Add project toolbox to Matlab path
AddToMatlabPathDynamically(fullfile(fileparts(which(mfilename)),'../toolbox')); 

%% Make sure we can make a basic scene.
p.fieldOfViewDegs = 4;
p.cyclesPerDegree = 2;
p.gaussianFWHMDegs = 1.5;
p.row = 128;
p.col = 128;
p.contrast = 1;
p.ang = 0;
p.ph = 0;
coneContrasts = [0.05 -0.05 0]';
backgroundxyY = [0.27 0.30 49.8]';
monitorFile = 'CRT-HP';
viewingDistance = 1;
gaborScene = colorGaborSceneCreate(p,coneContrasts,backgroundxyY,monitorFile,viewingDistance);
vcAddAndSelectObject(gaborScene);sceneWindow;
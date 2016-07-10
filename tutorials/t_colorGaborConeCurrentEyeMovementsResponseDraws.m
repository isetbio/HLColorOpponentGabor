%% t_colorGaborConeCurrentEyeMovementsResponseDraws
%
%  Show how to generate a number of response instances for a given stimulus condition.
%
%  See also t_coneGaborConeCurrentEyeMovementsMovie. 
%
%  7/9/16  ncp Wrote it.

%% Initialize
ieInit; clear; close all;

% Add project toolbox to Matlab path
AddToMatlabPathDynamically(fullfile(fileparts(which(mfilename)),'../toolbox')); 

%% Define parameters of simulation
%
% The time step at which to compute eyeMovements and osResponses
simulationTimeStep = 1/1000;

% Stimulus (gabor) params
scaleF = 0.5;
gaborParams.fieldOfViewDegs = 3*scaleF;
gaborParams.gaussianFWHMDegs = 0.75*scaleF;
gaborParams.cyclesPerDegree = 2/scaleF;
gaborParams.row = 128;
gaborParams.col = 128;
gaborParams.contrast = 1;
gaborParams.ang = 0;
gaborParams.ph = 0;
gaborParams.coneContrasts = [0.5 0.5 0.5]';
gaborParams.backgroundxyY = [0.27 0.30 49.8]';
gaborParams.leakageLum = 2.0;
gaborParams.monitorFile = 'CRT-HP';
gaborParams.viewingDistance = 0.75;

% Temporal modulation and stimulus sampling parameters
frameRate = 60;
temporalParams.windowTauInSeconds = 0.165;
temporalParams.stimulusDurationInSeconds = 5*temporalParams.windowTauInSeconds;
temporalParams.stimulusSamplingIntervalInSeconds = 1/frameRate;

% Optional CRT raster effects
temporalParams.addCRTrasterEffect = false;
temporalParams.rasterSamples = 5;    % generate this many raster samples / stimulus refresh interval

% Optical image parameters
oiParams.fieldOfViewDegs = gaborParams.fieldOfViewDegs;
oiParams.offAxis = false;
oiParams.blur = false;
oiParams.lens = true;

% Cone mosaic parameters
paddingDegs = 1.0;
mosaicParams.fieldOfViewDegs = (gaborParams.fieldOfViewDegs + paddingDegs)/2;
mosaicParams.macular = true;
mosaicParams.LMSRatio = [1 0 0/3];
mosaicParams.timeStepInSeconds = simulationTimeStep;
mosaicParams.integrationTimeInSeconds = 50/1000;
mosaicParams.photonNoise = false;
mosaicParams.osNoise = true;
mosaicParams.osModel = 'Linear';


%% Create the optics
theOI = colorDetectOpticalImageConstruct(oiParams);

%% Create the cone mosaic
theMosaic = colorDetectConeMosaicConstruct(mosaicParams);

% Generate response instances for a number of trials
trialsNum = 10;
for iTrial = 1:trialsNum
    
    fprintf('\nComputing response instance %d/%d ... ', iTrial, trialsNum);
    tic
    % compute the response instance
    responseInstance{iTrial} = colorDetectResponseInstanceConstruct(simulationTimeStep, ...
            gaborParams, temporalParams, mosaicParams, theOI, theMosaic);
    fprintf('Completed in %2.2f seconds', toc);
    
    % Visualize this response instance
    visualizeResponseInstance(responseInstance{iTrial});
end


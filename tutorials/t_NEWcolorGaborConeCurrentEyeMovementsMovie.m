%% t_NEWconeGaborConeCurrentEyeMovementsMovie
%
%  Show how to generate a movie with the cone absoprtions and photocurrent
%  to a stimulus, with eye movements and optional CRT raster effects
%
%  7/9/16  npc Wrote it.

%% Initialize
ieInit; clear; close all;

% Add project toolbox to Matlab path
AddToMatlabPathDynamically(fullfile(fileparts(which(mfilename)),'../toolbox')); 

%% Define parameters of simulation  
%
% The time step at which to compute eyeMovements and osResponses
simulationTimeStep = 5/1000;

% Stimulus (gabor) params
scaleF = 1.0;
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
theBaseGaborParams = gaborParams;

% Temporal modulation and stimulus sampling parameters
frameRate = 60;
temporalParams.windowTauInSeconds = 0.165;
temporalParams.stimulusDurationInSeconds = 5*temporalParams.windowTauInSeconds;
temporalParams.stimulusSamplingIntervalInSeconds = 1/frameRate;

% Optional CRT raster effects.
% 
% The underlying routine that generates temporal samples 
% can simulate the fact that CRTs produce an impulse during
% each frame, although this simulation works on a frame basis
% not on a pixel-by-pixel basis.  
% 
% The parameer rasterSamples is the number
% of raster samples generated per CRT refresh
% interval.
temporalParams.addCRTrasterEffect = true;
temporalParams.rasterSamples = 5; 
if (temporalParams.addCRTrasterEffect)
    simulationTimeStep = 1/1000;
end

% Optical image parameters
oiParams.fieldOfViewDegs = gaborParams.fieldOfViewDegs;
oiParams.offAxis = false;
oiParams.blur = false;
oiParams.lens = true;

% Cone mosaic parameters
paddingDegs = 1.0;
mosaicParams.fieldOfViewDegs = (gaborParams.fieldOfViewDegs + paddingDegs)/2;
mosaicParams.macular = true;
mosaicParams.LMSRatio = [1/3 1/3 1/3];
mosaicParams.timeStepInSeconds = simulationTimeStep;
mosaicParams.integrationTimeInSeconds = 50/1000;
mosaicParams.photonNoise = false;
mosaicParams.osNoise = true;
mosaicParams.osModel = 'Linear';

%% Create the optics
theOI = colorDetectOpticalImageConstruct(oiParams);

%% Create the cone mosaic
theMosaic = colorDetectConeMosaicConstruct(mosaicParams);

%% Create stimulus temporal window
[stimulusSampleTimes, gaussianTemporalWindow, rasterModulation] = gaussianTemporalWindowCreate(temporalParams);
if (temporalParams.addCRTrasterEffect)
    temporalParams.stimulusSamplingIntervalInSeconds = stimulusSampleTimes(2)-stimulusSampleTimes(1);
end
stimulusFramesNum = length(stimulusSampleTimes);

%% Generate eye movements for the entire stimulus duration
eyeMovementsPerStimFrame = temporalParams.stimulusSamplingIntervalInSeconds/simulationTimeStep;
eyeMovementsTotalNum = round(eyeMovementsPerStimFrame*stimulusFramesNum);
eyeMovementSequence = theMosaic.emGenSequence(eyeMovementsTotalNum);

%% Loop over our stimulus frames
for stimFrameIndex = 1:stimulusFramesNum
    fprintf('Computing isomerizations for frame %d of %d\n', stimFrameIndex, stimulusFramesNum);
    
    % Modulate stimulus contrast
    gaborParams.contrast = gaussianTemporalWindow(stimFrameIndex);
    
    % Apply CRT raster modulation
    if (~isempty(rasterModulation))
        gaborParams = theBaseGaborParams;
        gaborParams.contrast = gaborParams.contrast * rasterModulation(stimFrameIndex);
        gaborParams.backgroundxyY(3) = gaborParams.leakageLum + theBaseGaborParams.backgroundxyY(3)*rasterModulation(stimFrameIndex);
    end
    
    % Create a scene for the current frame
    theScene = colorGaborSceneCreate(gaborParams);
    
    % Compute the optical image
    theOI = oiCompute(theOI, theScene);
    
    % Apply current frame eye movements to the mosaic
    eyeMovementIndices = (round((stimFrameIndex-1)*eyeMovementsPerStimFrame)+1 : round(stimFrameIndex*eyeMovementsPerStimFrame));
    theMosaic.emPositions = eyeMovementSequence(eyeMovementIndices,:);
    
    % Compute isomerizations for the current frame
    frameIsomerizationSequence = theMosaic.compute(theOI,'currentFlag',false);
    
    if (stimFrameIndex==1)
        coneIsomerizationSequence = frameIsomerizationSequence;
    else
        coneIsomerizationSequence = cat(3, coneIsomerizationSequence, frameIsomerizationSequence);
    end
end 

%% Compute photocurrent sequence
fprintf('Computing photocurrent sequence ...\n');
coneIsomerizationRate = coneIsomerizationSequence/mosaicParams.integrationTimeInSeconds;
photocurrentSequence = theMosaic.os.compute(coneIsomerizationRate,theMosaic.pattern);

%% Update theMosaic params
theMosaic.absorptions = coneIsomerizationRate;
theMosaic.current = photocurrentSequence;
theMosaic.emPositions = eyeMovementSequence;
timeAxis = (1:size(photocurrentSequence,3))*mosaicParams.timeStepInSeconds;

%% Visualize isomerization and photocurrent sequences
renderVideo = true;
visualizeIsomerizationAndPhotocurrentSequences(theMosaic, timeAxis, renderVideo);
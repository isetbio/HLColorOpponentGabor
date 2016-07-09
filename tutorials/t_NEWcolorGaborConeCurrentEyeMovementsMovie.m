%% t_NEWconeGaborConeCurrentEyeMovementsMovie
%
%  Show how to generate a movie with the cone absoprtions and photocurrent
%  to a scene, with fixational eye movements.  Also illustrates how to take
%  the mean response movie and generate multiple noisy draws.  This then is
%  the heart of what we need to train up a classifier.
%
%  7/9/16  ncp Wrote it.

%% Initialize
ieInit; clear; close all;

% Add project toolbox to Matlab path
AddToMatlabPathDynamically(fullfile(fileparts(which(mfilename)),'../toolbox')); 

%% Define parameters of a gabor pattern
%
% Parameters in degrees.  The field of view is the horizontal dimension.
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
gaborParams.monitorFile = 'CRT-HP';
gaborParams.viewingDistance = 0.75;

% The time step at which to compute
simulationTimeStep = 1/1000;

% Temporal stimulus parameters
frameRate = 60;
temporalParams.windowTauInSeconds = 0.165;
temporalParams.stimulusDurationInSeconds = 5*temporalParams.windowTauInSeconds;
temporalParams.stimulusSamplingIntervalInSeconds = 1/frameRate;
temporalParams.addCRTrasterEffect = false;
temporalParams.rasterSamples = 5;


%% Create stimulus temporal window
[stimulusSampleTimes, gaussianTemporalWindow] = gaussianTemporalWindowCreate(temporalParams);
if (temporalParams.addCRTrasterEffect)
    temporalParams.stimulusSamplingIntervalInSeconds = stimulusSampleTimes(2)-stimulusSampleTimes(1);
end
stimulusFramesNum = length(stimulusSampleTimes);

% Optical image parameters
oiParams.fieldOfViewDegs = gaborParams.fieldOfViewDegs;
oiParams.offAxis = false;
oiParams.blur = false;
oiParams.lens = true;
theBaseOI = colorDetectOpticalImageConstruct(oiParams);

% Cone mosaic parameters
paddingDegs = 1.0;
mosaicParams.fieldOfViewDegs = (gaborParams.fieldOfViewDegs + paddingDegs)/2;
mosaicParams.macular = true;
mosaicParams.LMSRatio = [1 0 0/3];
mosaicParams.osModel = 'Linear';
mosaicParams.timeStepInSeconds = simulationTimeStep;       % eye movements & osComputation; must evently divide temporalParams.samplingIntervalInSeconds
mosaicParams.integrationTimeInSeconds = 50/1000;
mosaicParams.photonNoise = false;
mosaicParams.osNoise = false;

%% Create the optics
theOI = colorDetectOpticalImageConstruct(oiParams);

%% Create the cone mosaic
theMosaic = colorDetectConeMosaicConstruct(mosaicParams);

% Generate eye movements for the entire stimulus duration
eyeMovementsPerStimFrame = temporalParams.stimulusSamplingIntervalInSeconds/simulationTimeStep;
eyeMovementsTotalNum = round(eyeMovementsPerStimFrame*stimulusFramesNum);
eyeMovementSequence = theMosaic.emGenSequence(eyeMovementsTotalNum);

%% Loop over our stimulus frames
for stimFrameIndex = 1:stimulusFramesNum
    fprintf('Computing isomerizations for frame %d of %d\n', stimFrameIndex, stimulusFramesNum);
    
    % modulate stimulus contrast
    gaborParams.contrast = gaussianTemporalWindow(stimFrameIndex);
    
    % create a scene for the current frame
    theScene = colorGaborSceneCreate(gaborParams);
    
    % compute the optical image
    theOI = oiCompute(theOI, theScene);
    
    % apply current frame eye movements to the mosaic
    eyeMovementIndices = (round((stimFrameIndex-1)*eyeMovementsPerStimFrame)+1 : round(stimFrameIndex*eyeMovementsPerStimFrame));
    theMosaic.emPositions = eyeMovementSequence(eyeMovementIndices,:);
    
    % compute isomerizations for the current frame
    frameIsomerizationSequence = theMosaic.compute(theOI,'currentFlag',false);
    
    if (stimFrameIndex==1)
        coneIsomerizationSequence = frameIsomerizationSequence;
    else
        coneIsomerizationSequence = cat(3, coneIsomerizationSequence, frameIsomerizationSequence);
    end
end % for stimFrameIndex

% Compute photocurrent sequence
coneIsomerizationRate = coneIsomerizationSequence/mosaicParams.timeStepInSeconds;
photocurrentSequence = theMosaic.os.compute(coneIsomerizationRate,theMosaic.pattern);
    
% Determine ranges
isomerizationRange = [min(coneIsomerizationRate(:)) max(coneIsomerizationRate(:))];
photocurrentRange = [min(photocurrentSequence(:)) max(photocurrentSequence(:))];
timeAxis = (1:size(photocurrentSequence,3))*mosaicParams.timeStepInSeconds;

%% Visualize isomerization and photocurrent sequences
hFig = figure(1); 
set(hFig, 'Position', [10 10 1070 520], 'Color', [1 1 1]);
clf; colormap(bone(1024));
% Open video stream
videoFilename = sprintf('IsomerizationsWithEyeMovements.m4v');
writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
writerObj.FrameRate = 15; 
writerObj.Quality = 100;
writerObj.open();
mosaicXaxis = -theMosaic.cols/2:theMosaic.cols/2;
mosaicYaxis = -theMosaic.rows/2:theMosaic.rows/2;
for timeStep = 1:size(coneIsomerizationSequence,3)
    subplot('Position', [0.01 0.03 0.45 0.94]);
    imagesc(mosaicXaxis, mosaicYaxis, coneIsomerizationRate(:,:,timeStep));
    hold on;
    idx = max([1 timeStep-50]);
    plot(eyeMovementSequence(idx:timeStep,1), eyeMovementSequence(idx:timeStep,2), 'w-', 'LineWidth', 2.0);
    plot(eyeMovementSequence(idx:timeStep,1), eyeMovementSequence(idx:timeStep,2), 'r.-');
    hold off;
    xlabel(sprintf('%2.0f microns (%2.2f deg)', theMosaic.width*1e6, mosaicParams.fieldOfViewDegs), 'FontSize', 14, 'FontName', 'Menlo');
    axis 'image'
    set(gca, 'CLim', isomerizationRange, 'XTick', [], 'YTick', []);
    hCbar = colorbar(); % 'Ticks', cbarStruct.ticks, 'TickLabels', cbarStruct.tickLabels);
    hCbar.Orientation = 'vertical'; 
    hCbar.Label.String = 'isomerization rate (R*/cone/sec)'; 
    hCbar.FontSize = 14; 
    hCbar.FontName = 'Menlo'; 
    hCbar.Color = [0.2 0.2 0.2];
    title(sprintf('isomerization map (t: %2.2f ms)', timeAxis(timeStep)*1000), 'FontSize', 16, 'FontName', 'Menlo');
        
    subplot('Position', [0.52 0.05 0.45 0.94]);
    imagesc(photocurrentSequence(:,:,timeStep));
    xlabel(sprintf('%2.0f microns (%2.2f deg)', theMosaic.width*1e6, mosaicParams.fieldOfViewDegs), 'FontSize', 14, 'FontName', 'Menlo');
    axis 'image'
    set(gca, 'CLim', photocurrentRange, 'XTick', [], 'YTick', []);
    hCbar = colorbar(); % 'Ticks', cbarStruct.ticks, 'TickLabels', cbarStruct.tickLabels);
    hCbar.Orientation = 'vertical'; 
    hCbar.Label.String = 'photocurrent (pAmps)'; 
    hCbar.FontSize = 14; 
    hCbar.FontName = 'Menlo'; 
    hCbar.Color = [0.2 0.2 0.2];
    title(sprintf('photocurrent map (t: %2.2f ms)', timeAxis(timeStep)*1000), 'FontSize', 16, 'FontName', 'Menlo');
    
    drawnow;
    writerObj.writeVideo(getframe(hFig));
end
writerObj.close();

return;
%%


% This will generate nSampleTimes worth of fixational eye movements in the
% coneMosaic object. These eye movements will then be applied when calling
% the compute function.



%% Create a static scene and oi
%
% We can generate a static gabor stimulus here. We'll also pass it through
% the human optics.
gaborScene = colorGaborSceneCreate(gaborParams);
gaborOI = oiCompute(oiCreate('human'),gaborScene);

%% Compute cone current
%
% There is a name-value input pair for the coneMosaic.compute function that
% specifies if it should return the cone current signal. The default is
% true. Note that when computing the cone current this way, the photon
% noise flag is held constant throughout the calculation. Therefore, if it
% is set to false, the current computed will also NOT contain photon noise.
[isomerizations,coneCurrent] = theMosaic.compute(gaborOI,'currentFlag',true);

% We can examine the results in the coneMosaic gui window.
theMosaic.guiWindow;

%% Manually compute cone current
%
% If we would like to generate cone currents for a single scene but for a
% set of photon noise (as every draw will be slightly different), we can
% save computational time by making use of some hidden functions in the
% coneMosaic object. These functions are public but will not appear in
% Matlab's tab completion or ismethod function.

% We'll need to create a mosaic that is the same size as our stimulus
% (since the one we are using is a quarter the size). We'll do this by
% copying our current mosaic and then resizing it.
largeMosaic = theMosaic.copy;
largeMosaic.fov = gaborParams.fieldOfViewDegs;
largeMosaic.noiseFlag = false;

% We'll also need to know the size difference between the large sensor and
% our original sensor in units of cones. One somewhat annoying thing is
% that the size difference between our sensors must be an even number. We
% assure this by subtracting 1 cone from the large mosaic if this is not
% the case.
colPadding = (largeMosaic.cols-theMosaic.cols)/2;
rowPadding = (largeMosaic.rows-theMosaic.rows)/2;
if ~isinteger(colPadding), largeMosaic.cols = largeMosaic.cols - 1; end
if ~isinteger(rowPadding), largeMosaic.rows = largeMosaic.rows - 1; end
colPadding = (largeMosaic.cols-theMosaic.cols)/2;
rowPadding = (largeMosaic.rows-theMosaic.rows)/2;

% This is the first of two hidden functions we will use. This function
% computes the absorptions at each cone location for all three types of
% cones.
LMS = largeMosaic.computeSingleFrame(gaborOI,'FullLMS',true);

% We can now generate absorptions for any number of eye movement paths, add
% photon noise, and then compute the cone current. Note that the for loop
% below can be iterated for as many times as desired.
for ii = 1:10
    theMosaic.emGenSequence(nSampleTimes);
    isomerizations = theMosaic.applyEMPath(LMS,'padRows',rowPadding,'padCols',colPadding);
    
    % We'll now make use of the static function coneMosaic.photonNoise to add
    % photon noise to our absorptions.
    isomerizations = coneMosaic.photonNoise(isomerizations);
    
    % There currently does not exist a function to compute cone current
    % directly from the coneMosaic and absorptions data. We can however perform
    % this calculation by accessing the outer segment object inside the
    % coneMosaic. Keep in mind that the cone current calculation takes in
    % absorption RATE and not absolute number of absorptions.
    photonRate = isomerizations/theMosaic.sampleTime;
    coneCurrent = theMosaic.os.compute(photonRate,theMosaic.pattern);
    
    % Since we manually computed some things here, we need to set the
    % appropriate fields in the coneMosaic before using the window.
    theMosaic.absorptions = isomerizations;
    theMosaic.current = coneCurrent;
    theMosaic.guiWindow;
end

%% Generate cone current from movie stimulus
%
% We may also like to look at the cone current from a movie stimulus.
% Because movie stimuli are currently not supported directly, we need to
% calculate the absorptions at each frame and contatenate the results into
% a matrix. Then, as in the section above, we'll calcuate the cone current
% by directly accessing the outer segment object.

% For generating the static absorptions, we'll want to adjust some
% parameters regarding the integration time and remove any eye movements
% present in our coneMosaic object. We'll do this by creating a temporary copy.
tempMosaic = theMosaic.copy;
tempMosaic.integrationTime = temporalParams.samplingIntervalInSeconds;
tempMosaic.emPositions = [0 0];
tempMosaic.noiseFlag = false;

isomerizations = zeros([tempMosaic.rows tempMosaic.cols nSampleTimes]);
theBaseGaborParams = gaborParams;

for ii = 1:nSampleTimes
    fprintf('Computing optical image %d of %d, time %0.3f\n',ii,nSampleTimes,sampleTimes(ii));
    gaborParams.coneContrasts = theBaseGaborParams.coneContrasts*gaussianTemporalWindow(ii);
    tempScene = colorGaborSceneCreate(gaborParams);
    tempOI = oiCompute(oiCreate('human'),tempScene);
    isomerizations(:,:,ii) = tempMosaic.compute(tempOI,'currentFlag',false);
end

% We can add photon noise through the static function in the coneMosaic
% object. Then we convert to photon rate as before and use our original
% coneMosaic item to compute the cone current.
isomerizations = coneMosaic.photonNoise(isomerizations);
photonRate = isomerizations/temporalParams.samplingIntervalInSeconds;

coneCurrent = theMosaic.os.compute(photonRate,theMosaic.pattern);

% Set fields in the coneMosaic object as before
theMosaic.absorptions = isomerizations;
theMosaic.current = coneCurrent;
theMosaic.guiWindow;
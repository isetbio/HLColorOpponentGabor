%% t_coneMosaicConeCurrent
%
%  The cone current object does not support movie stimuli as of now,
%  requiring us to manually compute the photocurrent signals. There is code
%  however that will generate a short eye movement movie for us, allowing
%  us to generate cone current signals automatically via coneMosaic.compute
%  or do the calculations manually. This tutorial will go over the three
%  cases mentioned above.
%
%  7/8/16  xd  wrote it

ieInit;

%% Define parameters of a gabor pattern
%
% Parameters in degrees.  The field of view is the horizontal dimension.
gaborParams.fieldOfViewDegs = 4;
gaborParams.cyclesPerDegree = 2;
gaborParams.gaussianFWHMDegs = 1.5;

% Convert to image based parameterss for call into pattern generating routine.
cyclesPerImage = gaborParams.fieldOfViewDegs*gaborParams.cyclesPerDegree;
gaussianStdDegs = FWHMToStd(1.5);
gaussianStdImageFraction = gaussianStdDegs/gaborParams.fieldOfViewDegs;

% Parameters for a full contrast vertical gabor centered on the image
gaborParams.row = 128;
gaborParams.col = 128;
gaborParams.freq = cyclesPerImage;
gaborParams.contrast = 1;
gaborParams.ang = 0;
gaborParams.ph = 0;
gaborParams.GaborFlag = gaussianStdImageFraction;

% Temporal stimulus parameters
temporalParams.windowTauInSeconds = 0.165;
temporalParams.stimulusDurationInSeconds = 5*temporalParams.windowTauInSeconds;
temporalParams.samplingIntervalInSeconds = 0.010;

% It's convenient to define to define the sample at t = 0 to correspond to
% the maximum stimulus, and to define evenly spaced temporal samples on
% before and after 0.  The method below does this, and extends the stimulus
% duration if necessary to make the sampling come out as nice integers.
nPositiveTimeSamples = ceil(0.5*temporalParams.stimulusDurationInSeconds/temporalParams.samplingIntervalInSeconds);
sampleTimes = linspace(-nPositiveTimeSamples*temporalParams.samplingIntervalInSeconds, ...
    nPositiveTimeSamples*temporalParams.samplingIntervalInSeconds, ...
    2*nPositiveTimeSamples+1);
nSampleTimes = length(sampleTimes);
gaussianTemporalWindow = exp(-(sampleTimes.^2/temporalParams.windowTauInSeconds.^2));

% Specify L, M, S cone contrasts for what we define as a 100% contrast
% modulation.
testConeContrasts = [0.05 -0.05 0]';

% Specify xyY (Y in cd/m2) coordinates of background (because this is what is often
% done in papers.  This is a slighly bluish background, as was used by
% Poirson & Wandell (1996).
backgroundxyY = [0.27 0.30 49.8]';

% File describing the monitor we'll use to create the scene
monitorFile = 'CRT-HP';
viewingDistance = 0.75;

%% Create a cone mosaic
%
% Normally, we'd construct some scene and oi first. Since we will be using
% two types of scenes in this tutorial, we'll make the coneMosaic here as
% it will be used throughout the tutorial. We set the integration time and
% sample time in the constructor because setting the sample time via the
% setter gives us a warning. We'll also just use one set of temporal
% variables across all three stimuli to keep things consistent.
theMosaic = coneMosaic('IntegrationTime',temporalParams.samplingIntervalInSeconds,...
    'SampleTime',temporalParams.samplingIntervalInSeconds);
theMosaic.fov = gaborParams.fieldOfViewDegs/2;

% This will generate nSampleTimes worth of fixational eye movements in the
% coneMosaic object. These eye movements will then be applied when calling
% the compute function.
theMosaic.emGenSequence(nSampleTimes);

%% Create a static scene and oi
%
% We can generate a static gabor stimulus here. We'll also pass it through
% the human optics.
gaborScene = colorGaborSceneCreate(gaborParams,testConeContrasts,backgroundxyY,monitorFile,viewingDistance);
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
for ii = 1:1
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
    theMosaic.absorptions = photons;
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
for ii = 1:nSampleTimes
    currentContrast = testConeContrasts*gaussianTemporalWindow(ii);
    tempScene = colorGaborSceneCreate(gaborParams,testConeContrasts,backgroundxyY,monitorFile,viewingDistance);
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
theMosaic.absorptions = photons;
theMosaic.current = coneCurrent;
theMosaic.guiWindow;
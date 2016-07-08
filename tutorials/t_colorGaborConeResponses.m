% t_colorGaborConeResponses
%
% Create a series of scenes and corresponding cone respones that represent
% a temporally modulated color gabor.
%
% 7/8/16  dhb  Wrote it.

%% Initialize
ieInit; clear; close all;

% Add project toolbox to Matlab path
AddToMatlabPathDynamically(fullfile(fileparts(which(mfilename)),'../toolbox')); 

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

%% Figure out temporal sampling and compute Gaussian temporal window
%
% It's convenient to define to define the sample at t = 0 to correspond to
% the maximum stimulus, and to define evenly spaced temporal samples on
% before and after 0.  The method below does this, and extends the stimulus
% duration if necessary to make the sampling come out as nice integers.
nPositiveTimeSamples = ceil(0.5*temporalParams.stimulusDurationInSeconds/temporalParams.samplingIntervalInSeconds);
sampleTimes = linspace(-nPositiveTimeSamples*temporalParams.samplingIntervalInSeconds, ...
    nPositiveTimeSamples*temporalParams.samplingIntervalInSeconds, ...
    2*nPositiveTimeSamples+1);
nSampleTimes = length(sampleTimes);
actualDurationInSeconds = sampleTimes(end)-sampleTimes(1);
fprintf('Stimulus duration: %0.2f seconds, requested duration: %0.2f seconds\n', ...
    actualDurationInSeconds,temporalParams.stimulusDurationInSeconds);
gaussianTemporalWindow = exp(-(sampleTimes.^2/temporalParams.windowTauInSeconds.^2));

% Plot the temporal window, just to make sure it looks right
vcNewGraphWin;
plot(sampleTimes,gaussianTemporalWindow,'r');
xlabel('Time (seconds)');
ylabel('Window Amplitude');
title('Stimulus Temporal Window');

%% Create the OI object we'll use to compute the retinal images from the scenes
oiParams.fieldOfViewDegs = gaborParams.fieldOfViewDegrees;
oiParams.offAxis = false;
oiParams.blur = false;
oiParams.lens = true;

%% Create the coneMosaic object we'll use to compute cone respones
%
% STILL NEED TO IMPLEMENT SOME OF THESE PARAMETERS.
mosaicParams.fieldOfViewDegs = gaborParams.fieldOfViewDegs/2;
mosaicParams.maculur = true;
mosaicParams.LMSRatio = [1/3 1/3 1/3];
mosaicParams.outputType = 'isomerizations';

% Create a coneMosaic object here. This gives default foveal parameters for
% humans.
theMosaic = coneMosaic;

% Set mosaic field of view.  In principle this would be as large as the
% stimulus, but space and time considerations may lead to it being smaller.
theMosaic.setSizeToFOV(mosaicParams.fieldOfViewDegs);

% We compute mean responses for each time and then generate lots of noisy
% samples later.
theMosaic.noiseFlag = false;

%% Loop over time, build scene, and get cone responses for each time
for ii = 1:nSampleTimes
    % Make the sence for this time
    gaborParams.contrast = gaussianTemporalWindow(ii);
    fprintf('Computing %d of %d, time %0.3f, windowVal %0.3f\n',ii,nSampleTimes,sampleTimes(ii),gaussianTemporalWindow(ii));

    gaborScene = colorGaborSceneCreate(gaborParams,testConeContrasts,backgroundxyY,monitorFile,viewingDistance);
    
    % Compute retinal image
    theOI = oiCompute(theOI,gaborScene);
    
    % Compute mosaic response
    gaborConeResponse = theMosaic.compute(theOI,'currentFlag',false);
    
    % Compute cone contrasts
    LMSContrasts(:,ii) = mosaicUnsignedConeContrasts(gaborConeResponse,theMosaic);
end

%% Plot cone contrasts as a function of time, as a check
vcNewGraphWin; hold on;
plot(sampleTimes,LMSContrasts(1,:)','r');
plot(sampleTimes,LMSContrasts(2,:)','g');
plot(sampleTimes,LMSContrasts(3,:)','b');
xlabel('Time (seconds)');
ylabel('Contrast');
title('LMS Cone Contrasts');





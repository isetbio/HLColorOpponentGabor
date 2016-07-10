%% t_colorGaborConeCurrentEyeMovementsResponseInstances
%
%  Show how to generate a number of response instances for a given stimulus condition.
%
%  See also t_ßcolorGaborConeCurrentEyeMovementsMovie. 
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

% Temporal modulation and stimulus sampling parameters
frameRate = 60;
temporalParams.windowTauInSeconds = 0.165;
temporalParams.stimulusDurationInSeconds = 5*temporalParams.windowTauInSeconds;
temporalParams.stimulusSamplingIntervalInSeconds = 1/frameRate;

% Optional CRT raster effects
temporalParams.addCRTrasterEffect = false;
temporalParams.rasterSamples = 5;    % generate this many raster samples / stimulus refresh interval
if (temporalParams.addCRTrasterEffect)
    simulationTimeStep = simulationTimeStep/temporalParams.rasterSamples;
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
mosaicParams.LMSRatio = [1 0 0];
mosaicParams.timeStepInSeconds = simulationTimeStep;
mosaicParams.integrationTimeInSeconds = 50/1000;
mosaicParams.photonNoise = true;
mosaicParams.osNoise = true;
mosaicParams.osModel = 'Linear';

%% Create the optics
theOI = colorDetectOpticalImageConstruct(oiParams);

%% Create the cone mosaic
theMosaic = colorDetectConeMosaicConstruct(mosaicParams);

% Generate response instances for a number of trials
trialsNum = 1;

% Compute the trial data using the default parallel pool
for iTrial = 1:trialsNum
    fprintf('Computing responses for trial %d/%d\n', iTrial, trialsNum);
    % compute and accumulate the response instances, one for each trial
    responseInstances{iTrial} = colorDetectResponseInstanceConstruct(simulationTimeStep, ...
            gaborParams, temporalParams, oiParams, mosaicParams, theOI, theMosaic);
    
end

saveData = false;
exportToPDF = true;

% Save response instance data
if (saveData)
    fileName = 'testData.mat';
    save(fileName, 'responseInstances', '-v7.3');
end

% Visualize responses
fprintf('\nVisualizing responses ...\n');
for iTrial = 1:trialsNum
    % Visualize this response instance
    figHandle = visualizeResponseInstance(responseInstances{iTrial}, iTrial, trialsNum);
    figFileNames{iTrial} = sprintf('responseInstance_%d.pdf',iTrial);
    if (exportToPDF)
        NicePlot.exportFigToPDF(figFileNames{iTrial}, figHandle, 300);
    end
end

% Export summary PDF with all responses
if (exportToPDF)
    summaryPDF = fullfile(pwd(), 'AllInstances.pdf');
    fprintf('Exported a summary PDF with all response instances in %s\n', summaryPDF);
    NicePlot.combinePDFfilesInSinglePDF(figFileNames, summaryPDF);
end

%% t_colorGaborConeCurrentEyeMovementsResponseInstances
%
% Show how to generate a number of response instances for a given stimulus condition.
% This tutorial relies on routine
%   colorDetectResponseInstanceArrayConstruct
% which does most of the hard work.  The code underlying colorDetectResponseInstanceArrayConstruct
% itself is demonstrated in tutorial 
%   t_colorGaborConeCurrentEyeMovementsMovie.
%
% This tutorial saves its output in a .mat file, which is then read in by
%   t_colorGaborDetectFindThresholds
% which shows how to use the data to find the thresholds.
%
% 7/9/16  npc Wrote it.

%% Initialize
ieInit; clear; close all;

% Add project toolbox to Matlab path
AddToMatlabPathDynamically(fullfile(fileparts(which(mfilename)),'../toolbox')); 

%% Define parameters of simulation
%
% The time step at which to compute eyeMovements and osResponses
simulationTimeStep = 10/1000;

% Stimulus (gabor) params
gaborParams.fieldOfViewDegs = 1.0;
gaborParams.gaussianFWHMDegs = 0.35;
gaborParams.cyclesPerDegree = 2;
gaborParams.row = 128;
gaborParams.col = 128;
gaborParams.ang = 0;
gaborParams.ph = 0;
gaborParams.backgroundxyY = [0.27 0.30 49.8]';
gaborParams.leakageLum = 2.0;
gaborParams.monitorFile = 'OLED-Sony';  % 'CRT-HP';
gaborParams.viewingDistance = 0.75;

% Temporal modulation and stimulus sampling parameters.
%
% The millisecondsToInclude field tells how many milliseconds of the
% stimulus around the peak to include in data saved to pass to the
% classification routines.
frameRate = 60;
temporalParams.windowTauInSeconds = 0.165;
temporalParams.stimulusDurationInSeconds = 4*temporalParams.windowTauInSeconds;
temporalParams.stimulusSamplingIntervalInSeconds = 1/frameRate;
temporalParams.millisecondsToInclude = 50;

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
temporalParams.addCRTrasterEffect = false;
temporalParams.rasterSamples = 5; 
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

%% Define stimulus set
% Chromatic directions: L+M, L-M
LMangles = (0:45:135)/180*pi;
for angleIndex = 1:numel(LMangles)
    theta = LMangles(angleIndex);
    testConeContrasts(:,angleIndex) = 0.07*[cos(theta) sin(theta) 0.0]';
end

% Contrasts
testContrasts = linspace(0.1, 1, 10);

%% Define how many data instances to generate
trialsNum =  200;

%% Generate data for the no stimulus condition
gaborParams.coneContrasts = [0 0 0]';
gaborParams.contrast = 0;
stimulusLabel = sprintf('LMS=%2.2f,%2.2f,%2.2f,Contrast=%2.2f', gaborParams.coneContrasts(1), gaborParams.coneContrasts(2), gaborParams.coneContrasts(3), gaborParams.contrast);
theNoStimData = struct(...
                 'testContrast', gaborParams.contrast, ...
            'testConeContrasts', gaborParams.coneContrasts, ...
                'stimulusLabel', stimulusLabel, ...
        'responseInstanceArray', colorDetectResponseInstanceArrayFastConstruct(stimulusLabel, trialsNum, simulationTimeStep, ...
                                         gaborParams, temporalParams, theOI, theMosaic));
                                     
%% Generate data for all the examined stimuli 
for testChromaticDirectionIndex = 1:size(testConeContrasts,2)
    gaborParams.coneContrasts = testConeContrasts(:,testChromaticDirectionIndex);
    for testContrastIndex = 1:numel(testContrasts)
        gaborParams.contrast = testContrasts(testContrastIndex);
        stimulusLabel = sprintf('LMS=%2.2f,%2.2f,%2.2f,Contrast=%2.2f', gaborParams.coneContrasts(1), gaborParams.coneContrasts(2), gaborParams.coneContrasts(3), gaborParams.contrast);
        theStimData{testChromaticDirectionIndex, testContrastIndex} = struct(...
                 'testContrast', gaborParams.contrast, ...
            'testConeContrasts', gaborParams.coneContrasts, ...
                'stimulusLabel', stimulusLabel, ...
        'responseInstanceArray', colorDetectResponseInstanceArrayFastConstruct(stimulusLabel, trialsNum, simulationTimeStep, ...
                                          gaborParams, temporalParams, theOI, theMosaic));
    end % testContrastIndex
end % testChromaticDirectionIndex
                                 
%% Save the data for use by the classifier preprocessing subroutine
saveData = true;
if (saveData)
    dataDir = colorGaborDetectDataDir();
    fprintf('\nSaving generated data in %s ...\n', dataDir);
    fileName = fullfile(dataDir, sprintf('colorGaborDetectResponses_LMS_%2.2f_%2.2f_2.2f.mat', gaborParams.coneContrasts(1), gaborParams.coneContrasts(2), gaborParams.coneContrasts(3)));
    save(fileName, 'theStimData', 'theNoStimData', 'testConeContrasts', 'testContrasts', 'theMosaic', 'gaborParams', 'temporalParams', 'oiParams', 'mosaicParams', '-v7.3');
end

%% Visualize responses
visualizeResponses = false;
exportToPDF = true;
renderVideo = false;
if (visualizeResponses)
    fprintf('\nVisualizing responses ...\n');
    for testChromaticDirectionIndex = 1:size(testConeContrasts,2)
        for testContrastIndex = 1:numel(testContrasts)
            stimulusLabel = theStimData{testChromaticDirectionIndex, testContrastIndex}.stimulusLabel;
            s = theStimData{testChromaticDirectionIndex, testContrastIndex};  
            % Visualize a few response instances only
            for iTrial = 1:2
                figHandle = visualizeResponseInstance(s.responseInstanceArray(iTrial), stimulusLabel, theMosaic, iTrial, trialsNum, renderVideo);
                if (exportToPDF)
                    figFileNames{testChromaticDirectionIndex, testContrastIndex, iTrial} = ...
                        fullfile(colorGaborDetectFiguresDir(),sprintf('%s_Trial%dOf%d.pdf', stimulusLabel, iTrial, trialsNum));
                    NicePlot.exportFigToPDF(figFileNames{testChromaticDirectionIndex, testContrastIndex, iTrial}, figHandle, 300);
                end
            end % iTrial
        end
    end

    % Export summary PDF with all responses
    if (exportToPDF)
        summaryPDF = fullfile(colorGaborDetectFiguresDir(), 'AllInstances.pdf');
        fprintf('Exporting a summary PDF with all response instances in %s\n', summaryPDF);
        NicePlot.combinePDFfilesInSinglePDF(figFileNames(:), summaryPDF);
    end
end

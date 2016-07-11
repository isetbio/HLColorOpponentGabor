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
gaborParams.ang = 0;
gaborParams.ph = 0;
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
mosaicParams.LMSRatio = [1/3 1/3 1/3];
mosaicParams.timeStepInSeconds = simulationTimeStep;
mosaicParams.integrationTimeInSeconds = 50/1000;
mosaicParams.photonNoise = true;
mosaicParams.osNoise = true;
mosaicParams.osModel = 'Linear';

%% Create the optics
theOI = colorDetectOpticalImageConstruct(oiParams);

%% Create the cone mosaic
theMosaic = colorDetectConeMosaicConstruct(mosaicParams);

% Conditions to examine
% Chromatic directions: L+M, L-M
testConeContrasts(:,1) = [0.10   0.10  0.00]';
testConeContrasts(:,2) = [0.10  -0.10  0.00]';

% Contrasts
testContrasts = linspace(0.1, 1.0, 10);

% Data instances to generate
trainingInstances = 2;
crossValidationInstances = 2;
testingInstances = 1;
trialsNum = trainingInstances + crossValidationInstances + testingInstances;

for testChromaticDirectionIndex = 1:size(testConeContrasts,2)
    gaborParams.coneContrasts = testConeContrasts(:,testChromaticDirectionIndex);
    for testContrastIndex = 1:numel(testContrasts)
        gaborParams.contrast = testContrasts(testContrastIndex);
        stimulusLabel = sprintf('LMS=(%2.2f %2.2f %2.2f), C=%2.2f', gaborParams.coneContrasts(1), gaborParams.coneContrasts(2), gaborParams.coneContrasts(3), gaborParams.contrast);
        theData{testChromaticDirectionIndex, testContrastIndex} = struct(...
            'testContrast', gaborParams.contrast, ...
            'testConeContrasts',  gaborParams.coneContrasts, ...
            'stimulusLabel', stimulusLabel, ...
            'responseInstances', colorDetectResponseInstanceArrayConstruct(stimulusLabel, trialsNum, ...
                    simulationTimeStep, gaborParams, temporalParams, oiParams, mosaicParams, theOI, theMosaic));
    end % testContrastIndex
end % testChromaticDirectionIndex
 
saveData = false;
% Save response instance data
if (saveData)
    fileName = 'testData.mat';
    save(fileName, 'theData', 'testConeContrasts', 'testContrasts', 'theMosaic', 'gaborParams', 'temporalParams', 'oiParams', 'mosaicParams', '-v7.3');
end

% Visualize responses
exportToPDF = false;

fprintf('\nVisualizing responses ...\n');
for testChromaticDirectionIndex = 1:size(testConeContrasts,2)
    for testContrastIndex = 1:numel(testContrasts)
        stimulusLabel = theData{testChromaticDirectionIndex, testContrastIndex}.stimulusLabel;
        responseInstances = theData{testChromaticDirectionIndex, testContrastIndex}.responseInstances;
        % Visualize training response instances only
        for iTrial = 1:trainingInstances
            figHandle = visualizeResponseInstance(responseInstance, stimulusLabel, theMosaic, iTrial, trialsNum);
            if (exportToPDF)
                figFileNames{testChromaticDirectionIndex, testContrastIndex, iTrial} = sprintf('%s_%d.pdf', stimulusLabel, iTrial);
                NicePlot.exportFigToPDF(figFileNames{testChromaticDirectionIndex, testContrastIndex, iTrial}, figHandle, 300);
            end
        end % iTrial
    end
end

% Export summary PDF with all responses
if (exportToPDF)
    summaryPDF = fullfile(pwd(), 'AllInstances.pdf');
    fprintf('Exported a summary PDF with all response instances in %s\n', summaryPDF);
    NicePlot.combinePDFfilesInSinglePDF(figFileNames{:}, summaryPDF);
end

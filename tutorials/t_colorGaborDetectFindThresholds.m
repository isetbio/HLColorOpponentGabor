%% t_colorGaborDetectFindThresholds
%
% Classify data generated by
%   t_colorGaborConeCurrentEyeMovementsResponseInstances.
% That tutorial generates multiple noisy instances of responses for color
% gabors and saves them out in a .mat file.  Here we read that file and use
% SVM to build a computational observer that gives us percent correct, and
% then do this for multiple contrasts so that we find the predicted
% detection threshold.
%
% 7/11/16  npc Wrote it.

%% Initialize
ieInit; clear; close all;

% Add project toolbox to Matlab path
AddToMatlabPathDynamically(fullfile(fileparts(which(mfilename)),'../toolbox')); 

%% Define parameters of analysis
%
% signal source: select between 'photocurrents' and 'isomerizations'
signalSource = 'photocurrents';

%% Get data saved by t_colorGaborConeCurrentEyeMovementsResponseInstances
dataDir = colorGaborDetectOutputDir(conditionDir,'output');
responseFile = 'colorGaborDetectResponses_LMS_1.00_0.00_0.00';
responsesFullFile = fullfile(dataDir, sprintf('%s.mat',responseFile));
classificationPerformanceFile = fullfile(dataDir, sprintf('%s_ClassificationPerformance.mat',responseFile));
fprintf('\nLoading data from %s ...', responsesFullFile); 
fprintf('\nWill save classification performance in %s\n', classificationPerformanceFile);
pause(0.1);
load(responsesFullFile);
nTrials = numel(theNoStimData.responseInstanceArray);

%% Put zero contrast response instances into data that we will pass to the SVM
responseVector = theNoStimData.responseInstanceArray(1).theMosaicPhotoCurrents(:);
fprintf('\nLoading null stimulus data from %d trials into design matrix %s ...\n', nTrials);
for iTrial = 1:nTrials
    if (iTrial == 1)
        data = zeros(2*nTrials, numel(responseVector));
        classes = zeros(2*nTrials, 1);
    end
    if (strcmp(signalSource,'photocurrents'))
        data(iTrial,:) = theNoStimData.responseInstanceArray(iTrial).theMosaicPhotoCurrents(:);
    else
        data(iTrial,:) = theNoStimData.responseInstanceArray(iTrial).theMosaicIsomerizations(:);
    end
    classes(iTrial,1) = 0;
end
% clear to save memory
clear 'theNoStimData'

tic
%% Do SVM for each test contrast and color direction.
for testChromaticDirectionIndex = 1:size(testConeContrasts,2)
    for testContrastIndex = 1:numel(testContrasts)
        fprintf('\nLoading (%d,%d) stimulus data from %d trials into design matrix %s ...\n', testChromaticDirectionIndex, testContrastIndex, nTrials);
        for iTrial = 1:nTrials
            % Put data into the right form for SVM. 
            % This loop overwrites the stimlus data each time through, a
            % little risky, coding wise, but will work unless someone
            % modifies the data generation tutorial to produce a different
            % number of noisy instances for different test directions or
            % contrasts.
            if (strcmp(signalSource,'photocurrents'))
                data(nTrials+iTrial,:) = theStimData{testChromaticDirectionIndex, testContrastIndex}.responseInstanceArray(iTrial).theMosaicPhotoCurrents(:);
            else
                data(nTrials+iTrial,:) = theStimData{testChromaticDirectionIndex, testContrastIndex}.responseInstanceArray(iTrial).theMosaicIsomerizations(:);
            end
            classes(nTrials+iTrial,1) = 1;
        end
        % Perform SVM classification for this stimulus vs the zero contrast stimulus
        fprintf('\tRunning SVM for chromatic direction %d, contrast %2.2f ...  ', testChromaticDirectionIndex , testContrasts(testContrastIndex));
        [percentCorrect(testChromaticDirectionIndex, testContrastIndex), stdErr(testChromaticDirectionIndex, testContrastIndex)] = classifyWithSVM(data,classes);
        fprintf('Correct: %2.2f%%', percentCorrect(testChromaticDirectionIndex, testContrastIndex)*100);
    end
end
fprintf('SVM classification took %2.2f minutes\n', toc/60);

% Save classification performance data
save(classificationPerformanceFile, 'percentCorrect', 'stdErr', 'testConeContrasts','testContrasts', 'nTrials', ...
    'gaborParams', 'temporalParams', 'oiParams', 'mosaicParams');


%% Plot performances obtained.
hFig = figure(1); clf;
set(hFig, 'Position', [10 10 680 590], 'Color', [1 1 1]);
for testChromaticDirectionIndex = 1:size(testConeContrasts,2)
    subplot(size(testConeContrasts,2), 1, testChromaticDirectionIndex)
    errorbar(testContrasts, squeeze(percentCorrect(testChromaticDirectionIndex,:)), squeeze(stdErr(testChromaticDirectionIndex, :)), ...
        'ro-', 'LineWidth', 2.0, 'MarkerSize', 12, 'MarkerFaceColor', [1.0 0.5 0.50]);
    axis 'square'
    set(gca, 'YLim', [0 1.0],'XLim', [testContrasts(1) testContrasts(end)], 'FontSize', 14);
    xlabel('contrast', 'FontSize' ,16, 'FontWeight', 'bold');
    ylabel('percent correct', 'FontSize' ,16, 'FontWeight', 'bold');
    box off; grid on
    title(sprintf('LMS = [%2.2f %2.2f %2.2f]', testConeContrasts(1,testChromaticDirectionIndex), testConeContrasts(2,testChromaticDirectionIndex), testConeContrasts(3,testChromaticDirectionIndex)));
end


%% t_colorDetectFindThresholds

dataDir = colorGaborDetectDataDir();
fprintf('\nLoading data  from %s ...\n', dataDir);
fileName = fullfile(dataDir, 'testData.mat');
load(fileName);

nTrials = numel(theNoStimData.responseInstanceArray);

% Enter the zero contrast response instances
responseVector = theNoStimData.responseInstanceArray(1).theMosaicPhotoCurrents(:);
for iTrial = 1:nTrials
    fprintf('\nLoading null stimulus data from %d trial into design matrix %s ...\n', iTrial);
    if (iTrial == 1)
        data = zeros(2*nTrials, numel(responseVector));
        classes = zeros(2*nTrials, 1);
    end
    data(iTrial,:) = theNoStimData.responseInstanceArray(iTrial).theMosaicPhotoCurrents(:);
    classes(iTrial,1) = 0;
end
clear 'theNoStimData'

% Enter the stimulus response instances
for testChromaticDirectionIndex = 1:size(testConeContrasts,2)
    for testContrastIndex = 1:numel(testContrasts)
        for iTrial = 1:nTrials
            fprintf('\nLoading (%d,%d) stimulus data from %d trial into design matrix %s ...\n', testChromaticDirectionIndex, testContrastIndex, iTrial);
            data(nTrials+iTrial,:) = theStimData{testChromaticDirectionIndex, testContrastIndex}.responseInstanceArray(iTrial).theMosaicPhotoCurrents(:);
            classes(nTrials+iTrial,1) = 1;
            theStimData{testChromaticDirectionIndex, testContrastIndex}.responseInstanceArray(iTrial).theMosaicPhotoCurrents = [];
        end
        % Perform SVM classification for this stimulus vs the zero contrast stimulus
        fprintf('Running SVM for chromatic direction %d, contrast %2.2f ...', testChromaticDirectionIndex , testContrasts(testContrastIndex));
        percentCorrect(testChromaticDirectionIndex, testContrastIndex) = classifyWithSVM(data,classes);
        fprintf('% correct: %2.2f\n', percentCorrect(testChromaticDirectionIndex, testContrastIndex));
    end
end

% Plot performances
figure(1); clf;
for testChromaticDirectionIndex = 1:size(testConeContrasts,2)
    subplot(1,size(testConeContrasts,2), testChromaticDirectionIndex)
    plot(testContrasts, squeeze(percentCorrect(testChromaticDirectionIndex,:)), 'ks-');
    xlabel('contrast');
    ylabel('percent correct');
    title(sprintf('%2.2f %2.2f %2.2f', testConeContrasts(1,testChromaticDirectionIndex), testConeContrasts(2,testChromaticDirectionIndex), testConeContrasts(3,testChromaticDirectionIndex)));
end





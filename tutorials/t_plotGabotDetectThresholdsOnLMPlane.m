%% t_plotGabotDetectThresholdsOnLMPlane
%
% Read classification performance data, fit a Weibul to find the treshold and plot the results
% At the moment the Weibul fit is still not coded. David can you do this (Line 21)
% 
% 7/11/16  npc Wrote it.

%% Initialize
ieInit; clear; close all;

% Add project toolbox to Matlab path
AddToMatlabPathDynamically(fullfile(fileparts(which(mfilename)),'../toolbox')); 

responseFile = 'colorGaborDetectResponses_LMS_1.00_0.00_0.00_4angles';
dataDir = colorGaborDetectDataDir();
responsesFullFile = fullfile(dataDir, sprintf('%s.mat',responseFile));
classificationPerformanceFile = fullfile(dataDir, sprintf('%s_ClassificationPerformance.mat',responseFile));
theClassificationPerformance = load(classificationPerformanceFile);
testContrasts = theClassificationPerformance.testContrasts;
testConeContrasts = theClassificationPerformance.testConeContrasts;
nTrials = theClassificationPerformance.nTrials;
fitContrasts = linspace(0,1,100)';
thresholdCriterionFraction = 0.75;

hFig = figure(1); clf;
set(hFig, 'Position', [10 10 680 590], 'Color', [1 1 1]);
for ii = 1:size(theClassificationPerformance.testConeContrasts,2)
    thePerformance = squeeze(theClassificationPerformance.percentCorrect(ii,:));
    theStandardError = squeeze(theClassificationPerformance.stdErr(ii, :));
    
    % Fit psychometric function and find threshold
    [tempThreshold,fitFractionCorrect(:,ii),psychometricParams{ii}] = ...
       singleThresholdExtraction(testContrasts,thePerformance,thresholdCriterionFraction,nTrials,fitContrasts);
    thresholds(ii) = tempThreshold;
    
    subplot(2, ceil(size(testConeContrasts,2)/2), ii); hold on
    errorbar(testContrasts, thePerformance, theStandardError, 'ro', 'MarkerSize', 12, 'MarkerFaceColor', [1.0 0.5 0.50]);
    plot(fitContrasts,fitFractionCorrect(:,ii),'r','LineWidth', 2.0);
    plot(thresholds(ii)*[1 1],[0 thresholdCriterionFraction],'b', 'LineWidth', 2.0);
    hold off;
    axis 'square'
    set(gca, 'YLim', [0 1.0],'XLim', [testContrasts(1) testContrasts(end)], 'FontSize', 14);
    xlabel('contrast', 'FontSize' ,16, 'FontWeight', 'bold');
    ylabel('percent correct', 'FontSize' ,16, 'FontWeight', 'bold');
    box off; grid on
    title(sprintf('LMangle = %2.1f deg', atan2(testConeContrasts(2,ii), testConeContrasts(1,ii))/pi*180));
end



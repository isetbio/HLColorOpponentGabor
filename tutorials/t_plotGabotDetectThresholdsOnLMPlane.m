%% t_plotGabotDetectThresholdsOnLMPlane
%
% Read classification performance data, fit a Weibul to find the treshold and plot the results
% At the moment the Weibul fit is still not coded. David can you do this (Line 21)
% 
% 7/11/16  npc Wrote it.

responseFile = 'colorGaborDetectResponses_LMS_1.00_0.00_0.00_4angles';
dataDir = colorGaborDetectDataDir();
responsesFullFile = fullfile(dataDir, sprintf('%s.mat',responseFile));
classificationPerformanceFile = fullfile(dataDir, sprintf('%s_ClassificationPerformance.mat',responseFile));
load(classificationPerformanceFile)

size(stdErr)
hFig = figure(1); clf;
set(hFig, 'Position', [10 10 680 590], 'Color', [1 1 1]);
for testChromaticDirectionIndex = 1:size(testConeContrasts,2)
    thePerformance = squeeze(percentCorrect(testChromaticDirectionIndex,:));
    theStandardError = squeeze(stdErr(testChromaticDirectionIndex, :));
    
    % DAVID ---> Call Palamedes here with(testContrasts, thePerformance, criterion) to find threshold
    % YOU HAVE TO MULTIPLY thePerformance by 100.
    threshold = 0.70;

    subplot(2, ceil(size(testConeContrasts,2)/2), testChromaticDirectionIndex)
    errorbar(testContrasts, thePerformance, theStandardError, 'ro-', 'LineWidth', 2.0, 'MarkerSize', 12, 'MarkerFaceColor', [1.0 0.5 0.50]);
    hold on;
    plot([testContrasts(1) testContrasts(end)], threshold*[1 1], 'b--', 'LineWidth', 2.0);
    hold off;
    axis 'square'
    set(gca, 'YLim', [0 1.0],'XLim', [testContrasts(1) testContrasts(end)], 'FontSize', 14);
    xlabel('contrast', 'FontSize' ,16, 'FontWeight', 'bold');
    ylabel('percent correct', 'FontSize' ,16, 'FontWeight', 'bold');
    box off; grid on
    title(sprintf('LMangle = %2.1f deg', atan2(testConeContrasts(2,testChromaticDirectionIndex), testConeContrasts(1,testChromaticDirectionIndex))/pi*180));
end



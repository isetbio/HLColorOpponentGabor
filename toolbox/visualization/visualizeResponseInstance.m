function visualizeResponseInstance(responseInstance)

    % Determine ranges
    isomerizationRange = [min(responseInstance.coneIsomerizationRate(:)) max(responseInstance.coneIsomerizationRate(:))];
    photocurrentRange = [min(responseInstance.photocurrentSequence(:)) max(responseInstance.photocurrentSequence(:))];
    
    coneRows = size(responseInstance.coneIsomerizationRate,1);
    coneCols = size(responseInstance.coneIsomerizationRate,2);
    mosaicXaxis = linspace(-coneCols/2, coneCols/2, coneCols);
    mosaicYaxis = linspace(-coneRows/2, coneRows/2, coneRows);
    totalTimeSteps = size(responseInstance.photocurrentSequence,3);
    timeStepVisualized = round(totalTimeSteps/2);
    
    hFig = figure(); 
    set(hFig, 'Position', [10 10 1070 520], 'Color', [1 1 1]);
    clf; colormap(bone(1024));

    subplot('Position', [0.01 0.03 0.45 0.94]);
    imagesc(mosaicXaxis, mosaicYaxis, responseInstance.coneIsomerizationRate(:,:,timeStepVisualized));
    hold on;
    plot(responseInstance.eyeMovementSequence(:,1), -responseInstance.eyeMovementSequence(:,2), 'w-', 'Color', [1.0 0.5 0.5], 'LineWidth', 4.0);
    plot(responseInstance.eyeMovementSequence(:,1), -responseInstance.eyeMovementSequence(:,2), 'r.-', 'LineWidth', 2.0);
    hold off;
    axis 'image'; axis 'xy'
    %xlabel(sprintf('%2.0f microns (%2.2f deg)', theMosaic.width*1e6, theMosaic.fov(1)), 'FontSize', 14, 'FontName', 'Menlo');
    set(gca, 'CLim', isomerizationRange, 'XTick', [], 'YTick', []);
    hCbar = colorbar(); % 'Ticks', cbarStruct.ticks, 'TickLabels', cbarStruct.tickLabels);
    hCbar.Orientation = 'vertical'; 
    hCbar.Label.String = 'isomerization rate (R*/cone/sec)'; 
    hCbar.FontSize = 14; 
    hCbar.FontName = 'Menlo'; 
    hCbar.Color = [0.2 0.2 0.2];
    title(sprintf('isomerization map (t: %2.2f ms)', responseInstance.timeAxis(timeStepVisualized)*1000), 'FontSize', 16, 'FontName', 'Menlo');

    subplot('Position', [0.52 0.03 0.45 0.94]);
    imagesc(responseInstance.photocurrentSequence(:,:,timeStepVisualized));
    % xlabel(sprintf('%2.0f microns (%2.2f deg)', theMosaic.width*1e6, theMosaic.fov(1)), 'FontSize', 14, 'FontName', 'Menlo');
    axis 'image'; axis 'xy'
    set(gca, 'CLim', photocurrentRange, 'XTick', [], 'YTick', []);
    hCbar = colorbar(); % 'Ticks', cbarStruct.ticks, 'TickLabels', cbarStruct.tickLabels);
    hCbar.Orientation = 'vertical'; 
    hCbar.Label.String = 'photocurrent (pAmps)'; 
    hCbar.FontSize = 14; 
    hCbar.FontName = 'Menlo'; 
    hCbar.Color = [0.2 0.2 0.2];
    title(sprintf('photocurrent map (t: %2.2f ms)', responseInstance.timeAxis(timeStepVisualized)*1000), 'FontSize', 16, 'FontName', 'Menlo');
    drawnow;
end

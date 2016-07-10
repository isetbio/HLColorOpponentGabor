function visualizeIsomerizationAndPhotocurrentSequences(theMosaic, timeAxis, renderVideo)
% visualizeIsomerizationAndPhotocurrentSequences(theMosaic, timeAxis, renderVideo)
%
% Visualize the time cource of a mosaic response and optionally generate a
% video of it.
%
%
%  7/9/16  npc Wrote it.
%

    % Retrieve isomerization rate, photocurrent, and eye movement sequence
    isomerizationRate = theMosaic.absorptions/theMosaic.integrationTime;
    photocurrent = theMosaic.current;
    eyeMovementSequence = theMosaic.emPositions;
    
    % Determine ranges for plotting
    isomerizationRateRange = [min(theMosaic.absorptions(:)) max(theMosaic.absorptions(:))]/theMosaic.integrationTime;
    photocurrentRange = [min(theMosaic.current(:)) max(theMosaic.current(:))];
    
    hFig = figure(1); 
    set(hFig, 'Position', [10 10 1070 520], 'Color', [1 1 1]);
    clf; colormap(bone(1024));
    
    if (renderVideo)
        % Open video stream
        videoFilename = fullfile(pwd(), sprintf('IsomerizationsWithEyeMovements.m4v'));
        writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
        writerObj.FrameRate = 15; 
        writerObj.Quality = 50;
        writerObj.open();
    end
    
    fprintf('Rendering responses ...\n');
    mosaicXaxis = linspace(-theMosaic.cols/2, theMosaic.cols/2, theMosaic.cols);
    mosaicYaxis = linspace(-theMosaic.rows/2, theMosaic.rows/2, theMosaic.rows);
    for timeStep = 1:size(theMosaic.absorptions,3)
        subplot('Position', [0.01 0.03 0.43 0.94]);
        imagesc(mosaicXaxis, mosaicYaxis, isomerizationRate(:,:,timeStep));
        hold on;
        idx = max([1 timeStep-100]);
        plot(eyeMovementSequence(idx:timeStep,1), -eyeMovementSequence(idx:timeStep,2), 'w-', 'Color', [1.0 0.5 0.5], 'LineWidth', 4.0);
        plot(eyeMovementSequence(idx:timeStep,1), -eyeMovementSequence(idx:timeStep,2), 'r.-', 'LineWidth', 2.0);
        hold off;
        axis 'image'; axis 'xy'
        xlabel(sprintf('%2.0f microns (%2.2f deg)', theMosaic.width*1e6, theMosaic.fov(1)), 'FontSize', 14, 'FontName', 'Menlo');
        set(gca, 'CLim', isomerizationRateRange, 'XTick', [], 'YTick', []);
        hCbar = colorbar(); % 'Ticks', cbarStruct.ticks, 'TickLabels', cbarStruct.tickLabels);
        hCbar.Orientation = 'vertical'; 
        hCbar.Label.String = 'isomerization rate (R*/cone/sec)'; 
        hCbar.FontSize = 14; 
        hCbar.FontName = 'Menlo'; 
        hCbar.Color = [0.2 0.2 0.2];
        title(sprintf('isomerization map (t: %2.2f ms)', timeAxis(timeStep)*1000), 'FontSize', 16, 'FontName', 'Menlo');

        subplot('Position', [0.52 0.03 0.43 0.94]);
        imagesc(photocurrent(:,:,timeStep));
        xlabel(sprintf('%2.0f microns (%2.2f deg)', theMosaic.width*1e6, theMosaic.fov(1)), 'FontSize', 14, 'FontName', 'Menlo');
        axis 'image'; axis 'xy'
        set(gca, 'CLim', photocurrentRange, 'XTick', [], 'YTick', []);
        hCbar = colorbar(); % 'Ticks', cbarStruct.ticks, 'TickLabels', cbarStruct.tickLabels);
        hCbar.Orientation = 'vertical'; 
        hCbar.Label.String = 'photocurrent (pAmps)'; 
        hCbar.FontSize = 14; 
        hCbar.FontName = 'Menlo'; 
        hCbar.Color = [0.2 0.2 0.2];
        title(sprintf('photocurrent map (t: %2.2f ms)', timeAxis(timeStep)*1000), 'FontSize', 16, 'FontName', 'Menlo');

        drawnow;
        if (renderVideo)
            writerObj.writeVideo(getframe(hFig));
        end
    end
    if (renderVideo)
        writerObj.close();
        fprintf('Movie saved in %s\n', videoFilename);
    end
end

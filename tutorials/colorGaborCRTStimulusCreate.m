function colorGaborCRTStimulusCreate
    
    p.fieldOfViewDegs = 4; p.cyclesPerDegree = 2; 
    p.gaussianFWHMDegs = 1.5;
    p.row = 128; p.col = 128; 
    p.contrast = 1; p.ang = 0; p.ph = 0;
    coneContrasts = [0.05 -0.05 0]';
    backgroundxyY = [0.27 0.30 49.8]';
    monitorFile = 'CRT-HP';
    viewingDistanceInMeters = 1.82;
    
    staticScene = colorGaborSceneCreate(p, coneContrasts, backgroundxyY, monitorFile, viewingDistanceInMeters);
    vcAddObject(staticScene); sceneWindow;
    staticPhotons = sceneGet(staticScene, 'photons');

    % light leakage image (10.0 cd/m2)
    leakagexyY = [0.33 0.33 10.0]';
    leakageScene = colorGaborSceneCreate(p, [0 0 0]', leakagexyY, monitorFile, viewingDistanceInMeters);
    leakagePhotons = sceneGet(leakageScene, 'photons');
    
    
    % Generate phosphor activation function (fast onset, slower decay)
    refreshRate = 60;
    phosphorFunction = generatePhosphorActivationFunction(refreshRate);
        
    % Stimulus temporal ramping params
    rampTauInSeconds = 0.165;  stimulusDurationInSeconds = 5*rampTauInSeconds;
    
    % Generate stimulus time-series
    [rasterPhotons, timeInSeconds, rasterActivation] = generateRasterSequence(staticPhotons, phosphorFunction, stimulusDurationInSeconds);
    
    % Ramp stimulus presentation
    [rasterPhotons, temporalEnvelope] = generateRampedSequence(rasterPhotons, leakagePhotons, timeInSeconds, rampTauInSeconds);
    
    % Visualize
    visualizeStimulusTimeSeries(timeInSeconds,rasterPhotons, rasterActivation, temporalEnvelope);
end

function [rasterPhotons, timeInSeconds, rasterActivation] = generateRasterSequence(staticPhotons, phosphorFunction, stimulusDurationInSeconds)
    dt = phosphorFunction.timeInSeconds(2)-phosphorFunction.timeInSeconds(1);
    tBins = round(stimulusDurationInSeconds/dt);
    rasterActivation = [];
    while numel(rasterActivation) < tBins
        rasterActivation = cat(2, rasterActivation, phosphorFunction.activation);
    end
    rasterActivation = rasterActivation(1:tBins);
    tBins = numel(rasterActivation);
    timeInSeconds = (0:(tBins-1))*dt;
    rasterPhotons = bsxfun(@times, staticPhotons, reshape(rasterActivation, [1 1 1 numel(rasterActivation)]));
end

function [photonSequence, temporalEnvelope] = generateRampedSequence(rasterPhotons, leakagePhotons, timeInSeconds, rampTauInSeconds)
    t0 = timeInSeconds(1) + (timeInSeconds(end)-timeInSeconds(1))/2;
    temporalEnvelope = exp(-((timeInSeconds-t0)/rampTauInSeconds).^2);
    rasterPhotons  = bsxfun(@times, rasterPhotons, reshape(temporalEnvelope, [1 1 1 numel(temporalEnvelope)]));
    photonSequence = bsxfun(@plus, rasterPhotons, leakagePhotons);
end

function phosphorFunction = generatePhosphorActivationFunction(refreshRate) 
    alpha = 1.9; t_50 = 0.05/1000; n = 2;
    samplesPerRefreshCycle = 33;
    phosphorFunction.timeInSeconds = linspace(0,1.0/refreshRate,samplesPerRefreshCycle);
    phosphorFunction.activation = (phosphorFunction.timeInSeconds.^n)./(phosphorFunction.timeInSeconds.^(alpha*n) + t_50^(alpha*n));
    phosphorFunction.activation = phosphorFunction.activation - phosphorFunction.activation(end);
    phosphorFunction.activation(phosphorFunction.activation<0) = 0;
    phosphorFunction.activation = phosphorFunction.activation / max(phosphorFunction.activation);
end

function visualizeStimulusTimeSeries(timeInSeconds,rasterPhotons, rasterActivation, temporalEnvelope)  
    
    totalEnergyTimeSeries = squeeze(sum(rasterPhotons,3));
    maxEnergy = max(totalEnergyTimeSeries(:));
    minEnergy = min(totalEnergyTimeSeries(:));
    
    hFig = figure(1); clf; colormap(gray(1024));
    set(hFig, 'Position', [10 10 1520 960], 'Color', [1 1 1]);
    
    % Open video stream
    videoFilename = sprintf('CRTGaborStimulus.m4v');
    writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
    
    for tBin = 1:size(rasterPhotons,4)
        subplot('Position', [0.03 0.62 0.95 0.35]);
        plot(timeInSeconds*1000, rasterActivation, 'k.-', 'Color', [0.5 0.5 0.5], 'LineWidth', 2.0);
        hold on;
        plot(timeInSeconds*1000, temporalEnvelope, 'r.-', 'LineWidth', 2.0);
        plot(timeInSeconds(tBin)*1000*[1 1], [-0.5 1.5], '-', 'Color', [0 0.3 1.0 0.5], 'LineWidth', 3.0);
        plot(timeInSeconds(tBin)*1000, rasterActivation(tBin), 'ko', 'MarkerSize', 12, 'MarkerFaceColor', [1.0 0.5 0.5], 'MarkerEdgeColor', [1 0.2 0.2], 'LineWidth', 1.0);
        yTicks =  0:0.2:1.0;
        set(gca, 'XLim', [timeInSeconds(1) timeInSeconds(end)]*1000, 'YLim', [-0.01 1.01], 'YTick', yTicks, 'YTickLabel', sprintf('%-1.1f\n', yTicks), 'FontSize', 14);
        xlabel('time (ms)', 'FontWeight', 'bold', 'FontSize', 16);
        hL = legend({'raster', 'ramp'});
        set(hL, 'FontSize', 12);
        hold off; 
        box off
        
        subplot('Position', [0.01 0.02 0.49 0.49]);
        energyFrame = squeeze(totalEnergyTimeSeries(:,:,tBin));
        imagesc(energyFrame);
        set(gca, 'XTick', [], 'YTick', []);
        axis 'image'
        set(gca, 'CLim', [minEnergy maxEnergy]);
        hCbar = colorbar(); % 'Ticks', cbarStruct.ticks, 'TickLabels', cbarStruct.tickLabels);
        hCbar.Orientation = 'vertical'; 
        hCbar.Label.String = 'CRT photon emission rate (photons/sec)'; 
        hCbar.FontSize = 16; 
        hCbar.FontName = 'Menlo'; 
        hCbar.Color = [0.2 0.2 0.2];
        title(sprintf('CRT photon emission map (t: %2.3f ms)', 1000*timeInSeconds(tBin)), 'FontSize', 14);
        
        subplot('Position', [0.51 0.02 0.49 0.49]);
        imagesc(energyFrame*0);
        set(gca, 'XTick', [], 'YTick', []);
        axis 'image'
        set(gca, 'CLim', [0 1]);
        hCbar = colorbar(); % 'Ticks', cbarStruct.ticks, 'TickLabels', cbarStruct.tickLabels);
        hCbar.Orientation = 'vertical'; 
        hCbar.Label.String = 'Isomerization map (R*/cone/sec)'; 
        hCbar.FontSize = 16; 
        hCbar.FontName = 'Menlo'; 
        hCbar.Color = [0.2 0.2 0.2];
        title(sprintf('cone isomerization map (t: %2.3f ms)', 1000*timeInSeconds(tBin)), 'FontSize', 14);
         
        % Write video frame
        drawnow;
        writerObj.writeVideo(getframe(hFig));
    end
    
    % Close video stream
    writerObj.close();
end

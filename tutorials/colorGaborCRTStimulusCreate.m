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

    % light leakage image (10.0 cd/m2)
    leakagexyY = [0.33 0.33 10.0]';
    leakageScene = colorGaborSceneCreate(p, [0 0 0]', leakagexyY, monitorFile, viewingDistanceInMeters);
    
    % Generate phosphor activation function (fast onset, slower decay)
    refreshRate = 60;
    phosphorFunction = generatePhosphorActivationFunction(refreshRate);
         
    % Stimulus temporal ramping params
    rampTauInSeconds = 0.165;  stimulusDurationInSeconds = 5.5*rampTauInSeconds;
    
    % Generate frame scenes
    dt = phosphorFunction.timeInSeconds(2)-phosphorFunction.timeInSeconds(1);
    tBins = round(stimulusDurationInSeconds/dt);
    rasterActivation = [];
    frameIndex = 0;
    to = stimulusDurationInSeconds/2;
    totalFrames = round(stimulusDurationInSeconds/phosphorFunction.timeInSeconds(end));
    while numel(rasterActivation) < tBins
        fprintf('Generating frame %d of %d\n', frameIndex, totalFrames)
        frameTimeInSeconds = frameIndex * phosphorFunction.timeInSeconds(end);
        frameIndex = frameIndex+1;
        rasterActivation = cat(2, rasterActivation, phosphorFunction.activation);
        rampGain = exp(-((frameTimeInSeconds-to)/rampTauInSeconds).^2);
        frameSequence(frameIndex) = struct(...
            'scene', colorGaborSceneCreate(p, coneContrasts*rampGain, backgroundxyY, monitorFile, viewingDistanceInMeters),...
            'leakageScene', leakageScene, ...
            'timeInSeconds', frameTimeInSeconds, ...
            'rampGain', rampGain, ...
            'phosphorFunction', phosphorFunction);
    end
    
    visualizeStimulus(frameSequence);
end

function visualizeStimulus(frameSequence)
    framesNum = numel(frameSequence);
    leakagePhotons = sceneGet(frameSequence(1).leakageScene, 'photons');
    
    for iFrame = 1:framesNum
        framePhotons = sceneGet(frameSequence(iFrame).scene, 'photons');
        framePhotons = framePhotons + leakagePhotons;
        if (iFrame == 1)
            totalEnergy = zeros(size(framePhotons,1), size(framePhotons,2), framesNum);
        end
        % sum photons over all waveleghts
        totalEnergy(:,:, iFrame) = squeeze(sum(framePhotons,3));
    end
    
    maxEnergy = max(totalEnergy(:));
    minEnergy = min(totalEnergy(:));
    
    hFig = figure(1); clf; 
    set(hFig, 'Position', [10 10 1520 960], 'Color', [1 1 1]);
    
    % Open video stream
    videoFilename = sprintf('CRTGaborStimulus.m4v');
    writerObj = VideoWriter(videoFilename, 'MPEG-4'); % H264 format
    writerObj.FrameRate = 15; 
    writerObj.Quality = 100;
    writerObj.open();
    
    rasterTrace = []; rampTrace = []; rampTime = [];
    totalTimeInSeconds = frameSequence(framesNum).timeInSeconds(end);
    
    for iFrame = 1:framesNum
        phosphorFunction = frameSequence(iFrame).phosphorFunction;
            
        subplot('Position', [0.01 0.02 0.49 0.49]);
        energyFrame = squeeze(totalEnergy(:,:,iFrame));
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
        title(sprintf('CRT photon emission map (frame: %d)', iFrame), 'FontSize', 14);

        for rasterBin = 1:numel(phosphorFunction.timeInSeconds)
            subplot('Position', [0.51 0.02 0.49 0.49]);
            rasterFrame = energyFrame * phosphorFunction.activation(rasterBin);
            imagesc(rasterFrame);
            set(gca, 'XTick', [], 'YTick', []);
            axis 'image'
            set(gca, 'CLim', [minEnergy maxEnergy]);
            hCbar = colorbar(); % 'Ticks', cbarStruct.ticks, 'TickLabels', cbarStruct.tickLabels);
            hCbar.Orientation = 'vertical'; 
            hCbar.Label.String = 'CRT photon emission rate (photons/sec)'; 
            hCbar.FontSize = 16; 
            hCbar.FontName = 'Menlo'; 
            hCbar.Color = [0.2 0.2 0.2];
            title(sprintf('CRT raster photon emission map (t: %2.2fms)', 1000*(frameSequence(iFrame).timeInSeconds+phosphorFunction.timeInSeconds(rasterBin))), 'FontSize', 14);

            rasterTrace = cat(2,rasterTrace, phosphorFunction.activation(rasterBin));
            rasterTime  = (1:numel(rasterTrace))*(phosphorFunction.timeInSeconds(2)-phosphorFunction.timeInSeconds(1));
            rampTrace = cat(2, rampTrace, frameSequence(iFrame).rampGain);
            
            subplot('Position', [0.03 0.62 0.95 0.35]);
            plot(rasterTime*1000, rasterTrace, 'k.-', 'Color', [0.5 0.5 0.5], 'LineWidth', 2.0);
            hold on
            stairs(rasterTime*1000, rampTrace, 'Color', [1 0 0], 'LineWidth', 3.0);
            hold off;
            yTicks =  0:0.2:1.0;
            set(gca, 'XLim', [0 totalTimeInSeconds]*1000, 'YLim', [-0.01 1.01], 'YTick', yTicks, 'YTickLabel', sprintf('%-1.1f\n', yTicks), 'FontSize', 14);
            xlabel('time (ms)', 'FontWeight', 'bold', 'FontSize', 16);
            hL = legend({'CRT raster', 'contrast ramp'});
            set(hL, 'FontSize', 12);
            box off
        
            % Write video frame
            colormap(gray(1024));
            drawnow;
            writerObj.writeVideo(getframe(hFig));
        end % rasterBin
    end
    % Close video stream
    writerObj.close();
end


function phosphorFunction = generatePhosphorActivationFunction(refreshRate) 
    alpha = 1.9; t_50 = 0.05/1000; n = 2;
    samplesPerRefreshCycle = round(2*1000/refreshRate)
    phosphorFunction.timeInSeconds = linspace(0,1.0/refreshRate, samplesPerRefreshCycle);
    phosphorFunction.activation = (phosphorFunction.timeInSeconds.^n)./(phosphorFunction.timeInSeconds.^(alpha*n) + t_50^(alpha*n));
    phosphorFunction.activation = phosphorFunction.activation - phosphorFunction.activation(end);
    phosphorFunction.activation(phosphorFunction.activation<0) = 0;
    phosphorFunction.activation = phosphorFunction.activation / max(phosphorFunction.activation);
end
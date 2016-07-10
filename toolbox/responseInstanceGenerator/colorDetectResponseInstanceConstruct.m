function responseInstance = colorDetectResponseInstanceConstruct(simulationTimeStep, gaborParams, temporalParams, mosaicParams, theOI, theMosaic)
% responseInstance = colorDetectResponseInstanceConstruct(simulationTimeStep, gaborParams, temporalParams, mosaicParams, theOI, theMosaic)
% 
% Construct a response instance given the simulationTimeStep, gaborParams, temporalParams, mosaicParams, theOI, theMosaic
%
%
%  7/9/16  npc Wrote it.
%

    % Inform user regarding the computation progress
    progressHandle = waitbar(0,'Starting computation ...');
        
    % Save base gabor params
    theBaseGaborParams = gaborParams;
    
    % Create stimulus temporal window
    [stimulusSampleTimes, gaussianTemporalWindow, rasterModulation] = gaussianTemporalWindowCreate(temporalParams);
    if (temporalParams.addCRTrasterEffect)
        temporalParams.stimulusSamplingIntervalInSeconds = stimulusSampleTimes(2)-stimulusSampleTimes(1);
    end
    stimulusFramesNum = length(stimulusSampleTimes);
    
    % Generate eye movements for the entire stimulus duration
    eyeMovementsPerStimFrame = temporalParams.stimulusSamplingIntervalInSeconds/simulationTimeStep;
    eyeMovementsTotalNum = round(eyeMovementsPerStimFrame*stimulusFramesNum);
    responseInstance.eyeMovementSequence = theMosaic.emGenSequence(eyeMovementsTotalNum);
    
    % Loop over our stimulus frames
    for stimFrameIndex = 1:stimulusFramesNum
        
        waitbar(0.9*stimFrameIndex/stimulusFramesNum, progressHandle, sprintf('Computing isomerizations for frame %d', stimFrameIndex));
        % modulate stimulus contrast
        gaborParams.contrast = gaussianTemporalWindow(stimFrameIndex);
        
        % apply CRT raster modulation
        if (~isempty(rasterModulation))
            gaborParams = theBaseGaborParams;
            gaborParams.contrast = gaborParams.contrast * rasterModulation(stimFrameIndex);
            gaborParams.backgroundxyY(3) = gaborParams.leakageLum + theBaseGaborParams.backgroundxyY(3)*rasterModulation(stimFrameIndex);
        end
    
        % create a scene for the current frame
        theScene = colorGaborSceneCreate(gaborParams);
    
        % compute the optical image
        theOI = oiCompute(theOI, theScene);
    
        % apply current frame eye movements to the mosaic
        eyeMovementIndices = (round((stimFrameIndex-1)*eyeMovementsPerStimFrame)+1 : round(stimFrameIndex*eyeMovementsPerStimFrame));
        theMosaic.emPositions = responseInstance.eyeMovementSequence(eyeMovementIndices,:);
    
        % compute isomerizations for the current frame
        frameIsomerizationSequence = theMosaic.compute(theOI,'currentFlag',false);
    
        if (stimFrameIndex==1)
            coneIsomerizationSequence = frameIsomerizationSequence;
        else
            coneIsomerizationSequence = cat(3, coneIsomerizationSequence, frameIsomerizationSequence);
        end
    end % for stimFrameIndex

    % Compute photocurrent sequence
    waitbar(0.95, progressHandle, sprintf('Computing photocurrent sequence'));
    responseInstance.coneIsomerizationRate = coneIsomerizationSequence/mosaicParams.integrationTimeInSeconds;
    responseInstance.photocurrentSequence = theMosaic.os.compute(responseInstance.coneIsomerizationRate,theMosaic.pattern);
    responseInstance.timeAxis = (1:size(responseInstance.photocurrentSequence,3))*mosaicParams.timeStepInSeconds;
    
    % Close progress bar
    close(progressHandle);
end

function responseInstanceArray = colorDetectResponseInstanceArrayConstruct(stimulusLabel, nTrials, simulationTimeStep, gaborParams, temporalParams, theOI, theMosaic)
% responseInstanceArray = colorDetectResponseInstanceArrayConstruct(stimulusLabel, nTrials, simulationTimeStep, gaborParams, temporalParams, theOI, theMosaic)
% 
% Construct an array of nTrials response instances given the simulationTimeStep, gaborParams, temporalParams, theOI, theMosaic
%
%
%  7/10/16  npc Wrote it.
%

    % Inform user regarding the computation progress
    progressHandle = generateProgressBar('Starting computation ...');

    % Save base gabor params
    theBaseGaborParams = gaborParams;
    
    % Create stimulus temporal window
    [stimulusSampleTimes, gaussianTemporalWindow, rasterModulation] = gaussianTemporalWindowCreate(temporalParams);
    if (temporalParams.addCRTrasterEffect)
        temporalParams.stimulusSamplingIntervalInSeconds = stimulusSampleTimes(2)-stimulusSampleTimes(1);
    end
    stimulusFramesNum = length(stimulusSampleTimes);
    
    % Loop over our stimulus frames
    for stimFrameIndex = 1:stimulusFramesNum 
        waitbar(0.5*stimFrameIndex/stimulusFramesNum, progressHandle, sprintf('stimulus label: %s\ncomputing optical image for frame #%d/%d', stimulusLabel, stimFrameIndex, stimulusFramesNum));
        
        % Modulate stimulus contrast
        gaborParams.contrast = gaussianTemporalWindow(stimFrameIndex);
        
        % Apply CRT raster modulation
        if (~isempty(rasterModulation))
            gaborParams = theBaseGaborParams;
            gaborParams.contrast = gaborParams.contrast * gaussianTemporalWindow(stimFrameIndex) * rasterModulation(stimFrameIndex);
            gaborParams.backgroundxyY(3) = gaborParams.leakageLum + theBaseGaborParams.backgroundxyY(3)*rasterModulation(stimFrameIndex);
        end
        
        % Create a scene for the current frame
        theScene = colorGaborSceneCreate(gaborParams);
    
        % Compute the optical image
        theFrameOI{stimFrameIndex} = oiCompute(theOI, theScene);
    end % stimFrameIndex
    
    % For each trial compute new eye movement path and obtain new response
    for iTrial = 1: nTrials
        waitbar(0.5+0.5*iTrial/nTrials, progressHandle, sprintf('stimulus label: %s\ncomputing responses for trial %d/%d', stimulusLabel, iTrial, nTrials));
        
        % Generate eye movements for the entire stimulus duration of this trial
        eyeMovementsPerStimFrame = temporalParams.stimulusSamplingIntervalInSeconds/simulationTimeStep;
        eyeMovementsTotalNum = round(eyeMovementsPerStimFrame*stimulusFramesNum);
        eyeMovementSequence = theMosaic.emGenSequence(eyeMovementsTotalNum);    
        
        % Loop over our stimulus frames
        for stimFrameIndex = 1:stimulusFramesNum
            % Apply current frame eye movements to the mosaic
            eyeMovementIndices = (round((stimFrameIndex-1)*eyeMovementsPerStimFrame)+1 : round(stimFrameIndex*eyeMovementsPerStimFrame));
            theMosaic.emPositions = eyeMovementSequence(eyeMovementIndices,:);
        
            % Compute isomerizations only for the current frame
            frameIsomerizationSequence = theMosaic.compute(theFrameOI{stimFrameIndex},'currentFlag',false);
            if (stimFrameIndex==1)
                coneIsomerizationSequence = frameIsomerizationSequence;
            else
                coneIsomerizationSequence = cat(3, coneIsomerizationSequence, frameIsomerizationSequence);
            end
        end % stimFrameIndex
        
        % Compute photocurrent sequence
        coneIsomerizationRate = coneIsomerizationSequence/theMosaic.integrationTime;
        photocurrentSequence = theMosaic.os.compute(coneIsomerizationRate,theMosaic.pattern);
        
        % Accumulate data in cell array of structs. Here we have to decide
        % which part (spatial and temporal) of the responses to keep for
        % classification
        responseInstanceArray(iTrial) = struct(...
            'theMosaicIsomerizations', single(coneIsomerizationSequence), ...
             'theMosaicPhotoCurrents', single(photocurrentSequence), ...
              'theMosaicEyeMovements', single(eyeMovementSequence) ...
        );
    end % iTrial
    
    % Close progress bar
    close(progressHandle);
end

function progressHandle = generateProgressBar(initialMessage)
    progressHandle = waitbar(0, '');
    titleHandle = get(findobj(progressHandle,'Type','axes'),'Title');
    set(titleHandle,'FontSize',12, 'FontName', 'Menlo');
    waitbar(0, progressHandle, initialMessage);
end

function [sampleTimes, gaussianTemporalWindow] = gaussianTemporalWindowCreate(temporalParams)
% [sampleTimes,gaussianTemporalWindow] = gaussianTemporalWindowCreate(temporalParams)
%
% Create a Gaussian temporal window.
%
% It's convenient to define to define the sample at t = 0 to correspond to
% the maximum stimulus, and to define evenly spaced temporal samples on
% before and after 0.  The method below does this, and extends the stimulus
% duration if necessary to make the sampling come out as nice integers.
% 
% temporalParams.windowTauInSeconds - standard deviation of Gaussian window 
% temporalParams.stimulusDurationInSeconds - stimulus duration
% temporalParams.samplingIntervalInSeconds - stimulus sampling interval

nPositiveTimeSamples = ceil(0.5*temporalParams.stimulusDurationInSeconds/temporalParams.stimulusSamplingIntervalInSeconds);
sampleTimes = linspace(-nPositiveTimeSamples*temporalParams.stimulusSamplingIntervalInSeconds, ...
    nPositiveTimeSamples*temporalParams.stimulusSamplingIntervalInSeconds, ...
    2*nPositiveTimeSamples+1);
gaussianTemporalWindow = exp(-(sampleTimes.^2/temporalParams.windowTauInSeconds.^2));


if (isfield(temporalParams, 'addCRTrasterEffect')) && (temporalParams.addCRTrasterEffect)
    % Add CRT raster effect
    phosphorFunction = crtPhosphorActivationFunction(1/temporalParams.stimulusSamplingIntervalInSeconds, temporalParams.rasterSamples);
    rasterSamples = numel(phosphorFunction.timeInSeconds);
    raster = zeros(1,(numel(gaussianTemporalWindow))*rasterSamples);
    raster(1,1:rasterSamples:end) = gaussianTemporalWindow;
    rasterModulation = conv(raster, phosphorFunction.activation);
    rasterModulation = rasterModulation(1:numel(gaussianTemporalWindow)*rasterSamples);
    gaussianTemporalWindow = rasterModulation;
    sampleTimes = linspace(sampleTimes(1), sampleTimes(end), numel(gaussianTemporalWindow));
%     figure(2);
%     plot(sampleTimes, gaussianTemporalWindow);
%     title('raster modulation');
end


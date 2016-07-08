function [sampleTimes,gaussianTemporalWindow] = gaussianTemporalWindowCreate(temporalParams)
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

nPositiveTimeSamples = ceil(0.5*temporalParams.stimulusDurationInSeconds/temporalParams.samplingIntervalInSeconds);
sampleTimes = linspace(-nPositiveTimeSamples*temporalParams.samplingIntervalInSeconds, ...
    nPositiveTimeSamples*temporalParams.samplingIntervalInSeconds, ...
    2*nPositiveTimeSamples+1);
gaussianTemporalWindow = exp(-(sampleTimes.^2/temporalParams.windowTauInSeconds.^2));
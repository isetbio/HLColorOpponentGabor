function [thresholds,paramsValues] = multipleThresholdExtraction(data,stimLevels,criterion)
% [thresholds,paramsValues] = multipleThresholdExtraction(data)
%
% Given a NxM data matrix containing M sets of data with N datapoints in
% each, this function will return a length M vector of thresholds and a Mx4
% matrix of parameters that fit the data to a cumulative Weibull. If the
% data vector cannot be fit, then the threshold at that index will be NaN,
% and the data paramsValues will be a zero vector. The thresholds will be
% extracted at the given criterion, which should be a percentage.
%
% Inputs:
%   data       -  A NxM matrix containing M sets of data with N datapoints 
%                 each.  Contains percentage data.
% 
%   stimLevels -  A N vector containing stimuli levels that correspond
%                 to the rows in data
%
%   criterion  -  A percentage specifying where to fit the threshold.
%
% xd  6/21/16  wrote it

%% Preallocate space for the data
thresholds = zeros(size(data,2),1);
paramsValues = zeros(size(data,2),4);

%% Get thresholds
for ii = 1:size(data,2)
    [thresholds(ii), paramsValues(ii,:)] = singleThresholdExtraction(data(:,ii),stimLevels,criterion);
end

end


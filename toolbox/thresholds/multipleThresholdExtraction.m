function [thresholds, paramsValues] = multipleThresholdExtraction(data, criterion)
% [thresholds, paramsValues] = multipleThresholdExtraction(data)
%
% Given a NxM data matrix containing M sets of data with N datapoints in
% each, this function will return a length M vector of thresholds and a Mx4
% matrix of parameters that fit the data to a cumulative Weibull. If the
% data vector cannot be fit, then the threshold at that index will be -1,
% and the data paramsValues will be a zero vector. The thresholds will be
% extracted at the given criterion, which should be a percentage.
%
% xd  6/21/16  wrote it

%% Preallocate space for the data
thresholds = zeros(size(data,2),1);
paramsValues = zeros(size(data,2),4);

%% Get thresholds
for ii = 1:size(data,2)
    [thresholds(ii), paramsValues(ii,:)] = singleThresholdExtraction(data(:,ii), criterion);
end

end


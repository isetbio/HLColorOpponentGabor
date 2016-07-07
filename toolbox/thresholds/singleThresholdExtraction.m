function [threshold, paramsValues] = singleThresholdExtraction(data, criterion)
% [threshold, paramValues] = singleThresholdExtraction(data)
% 
% This function fits a cumulative Weibull to the data variable and returns
% the threshold at the criterion as well as the parameters needed to plot the
% fitted curve. It is assumed that the data vector contains percentage
% performance and is ordered in increasing stimulus value (or however you'd
% like the data to be fit). This function requires the data vector to have
% at least 6 points. If the data cannot be fit, the threshold returned will
% be NaN and the paramsValues will a zero row vector. It is also assumed
% that the criterion is given as a percentage.
%
% xd  6/21/16 wrote it

%% Check to make sure data is fittable
% We check the average value of the first 5 and last 5 numbers to get an
% idea of if the data is fittable to a curve. If the first 5 values are
% less than criterion and the last 5 are greater than criterion+10, we proceed with the
% fitting.  Otherwise, we return 0 for the threshold, which indicates that
% the data cannot be fit.
if mean(data(1:5)) > criterion+10 || mean(data(end-4:end)) < criterion, threshold = nan; paramsValues = zeros(1,4); return; end; 

%% Set some parameters for the curve fitting
criterion      = criterion/100;
paramsEstimate = [10 1 0.5 0];
numTrials      = 100;
paramsFree     = [1 1 0 0];
stimLevels     = 1:length(data);
outOfNum       = repmat(numTrials,1,length(data));
PF             = @PAL_Weibull;

%% Some optimization settings for the fit
options             = optimset('fminsearch');
options.TolFun      = 1e-09;
options.MaxFunEvals = 10000*100;
options.MaxIter     = 500*100;

%% Fit the data to a curve
paramsValues = PAL_PFML_Fit(stimLevels(:), data(:), outOfNum(:), ...
    paramsEstimate, paramsFree, PF, 'SearchOptions', options);

threshold = PF(paramsValues, criterion, 'inverse');
end


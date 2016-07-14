function data = transformDataWithPCA(data,numPCAComponents,STANDARDIZE)
% data = transformDataWithPCA(data,numPCA,STANDARDIZE)
%
% Projects data along a specified number of principal components. PCA is
% done on the data matrix and the first numPCA components (ordered by
% variance explained) will be used to project the data into a lower
% dimensional space.
%
% By default, the data will be standardized before the PCA calculation.
% 
% Inputs:
%   data             -  A matrix containing data to project into a lower dimension.
%                       Rows represent instances of data and columns are features.
%
%   numPCAComponents -  The number of principal components to project onto.
%
% Optional Paramters as key value paris
%   'Standardize'    -  true/false: determine whether or not to standardize the
%                       data, default true.
%
% 7/7/16  xd  wrote it

%% Parse input
% p = inputParser;
% p.addRequired('data',@isnumeric);
% p.addRequired('numPCA',@isnumeric);
% p.addParameter('Standardize',true,@islogical);
% p.parse(data,numPCAComponents,varargin{:});
% STANDARDIZE = p.Results.Standardize;

%% Standardize the data
if (STANDARDIZE)
    m = mean(data,1);
    s = std(data,1);
    data = (data - repmat(m,size(data,1),1)) ./ repmat(s,size(data,1),1);
end

%% Do PCA and project data into new vector space
coeff = pca(data,'NumComponents',numPCAComponents);
data = data*coeff;

end


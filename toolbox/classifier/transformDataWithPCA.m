function data = transformDataWithPCA(data,numPCA,varargin)
% data = transformDataWithPCA(data,numPCA,varargin)
%
% Projects data along a specified number of principal components. PCA is
% done on the data matrix and the first numPCA components (ordered by
% variance explained) will be used to project the data into a lower
% dimension.
% 
% Inputs:
%   data    -  A matrix containing data to project into a lower dimension.
%              Rows represent instances of data and columns are features.
%
%   numPCA  -  The number of principal components to project onto.
%
%  {Optional Paramter}
%   toStd   -  A boolean to determine whether or not to standardize the
%              data. By default this is set to true.
%
% 7/7/16  xd  wrote it

%% Parse input
p = inputParser;
p.addRequired('data',@isnumeric);
p.addRequired('numPCA',@isnumeric);
p.addParameter('toStd',true,@islogical);

p.parse(data,numPCA,varargin{:});
toStd = p.Results.toStd;

%% Standardize the data
if toStd
    m = mean(data,1);
    s = std(data,1);
    data = (data - repmat(m,size(data,1),1)) ./ repmat(s,size(data,1),1);
end

%% Do PCA and projects data into new vector space
coeff = pca(data,'NumComponents',numPCA);
data = data*coeff;

end


function theMosaic = colorDetectConeMosaicConstruct(mosaicParams)
% theMosaic = colorDetectConeMosaicConstruct(mosaicParams)
% 
% Construct a cone mosaic according to the passed parameters structure.
% Designed to allow us to control exactly what features of early vision
% we're using.
% 
%   mosaicParams.fieldOfViewDegs - field of view in degrees
%
% THESE ARE NOT YET IMPLEMENTED
%   mosaicParams.macular -  true/false, include macular pigment?
%   mosaicParams.LMSRatio - vector with three entries summing to one
%                           proportion of L, M, and S cones in mosaic
%   mosaicParams.osModel - 'Linear','Biophys', which outer segment model
 
% Create a coneMosaic object here. This gives default foveal parameters for
% humans.
theMosaic = coneMosaic;

% Set mosaic field of view.  In principle this would be as large as the
% stimulus, but space and time considerations may lead to it being smaller.
theMosaic.setSizeToFOV(mosaicParams.fieldOfViewDegs);

% We compute mean responses for each time and then generate lots of noisy
% samples later.

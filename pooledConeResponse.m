function [pooledData] = pooledConeResponse(os, sensor, varargin)
% Computes the pooled response across the cone mosaic.
%
%  [pooledData] = pooledConeResponse(os, sensor, varargin)
%
% The pooling across cones and times is an ideal observer computation
% found in Hass, Horwitz, Angueyra, Lindbloom-Brown & Rieke, "Chromatic
% Detection from cone photorectpors to V1 neurons to behavior in rhesus
% monkeys," (2015).
% 
% The outer segment object stores the noisy cone current response in an
% [x,y,t] matrix composed of time-series responses of a spatial mosaic of
% L, M and S cones. This function pools the response for each type of cone
% over the whole time series and across all positions, reducing the [x,y,t]
% matrix to a single point (L pooled, M pooled, S pooled). The pooling is
% looped totalIters times, and in each iteration a new noisy [x,y,t] cone
% current response is generated from the noiseless version and compressed
% to a single point (L pooled, M pooled, S pooled), generating totalIters
% points in 3D space. A linear classifier is then applied to discriminate
% between the clouds of points for different contrast levels.
% 
% The actual pooling operation consists of applying a matched filter by
% projecting the time series response for each spatial location back onto
% the cone's linear impulse response, and taking its mean over space and
% time for all cones of a given type.
%
% See also: t_colorGaborDetection.m.
%
% NC/JG ISETBIO Team, 2015

% Find coordinates of L, M and S cones.
cone_mosaic = sensorGet(sensor,'cone type');
[sz1, sz2] = size(cone_mosaic);

% Get cone current signal for each cone in the mosaic over time.
coneCurrent = osGet(os,'coneCurrentSignal');

% Get number of time steps.
nSteps = size(coneCurrent, 3);

% The next step is to convolve the 1D filters with the 1D current
% data at each point in the cone mosaic.

[sz1, sz2, sz3] = size(coneCurrent);
coneCurrentRS = reshape(coneCurrent(:,:,1:sz3),[sz1*sz2],nSteps);

if isempty(varargin),     totalIters = 250;
else                      totalIters = varargin{1};
end

fprintf('\nGenerating pooled noisy responses:     \n');
for iter = 1:totalIters
    
    fprintf('\b\b\b%02d%%', round(100*iter/totalIters));
    
    for cone_type = 2:4
        % Pull out the appropriate 1D filter for the cone type.
        % Filter_cone_type = newIRFs(:,cone_type-1);
        switch cone_type
            case 2
                FilterConeType = os.sConeFilter;
            case 3
                FilterConeType = os.mConeFilter;
            case 4
                FilterConeType = os.lConeFilter;
        end
        FilterConeType = (FilterConeType - mean(FilterConeType))./max(FilterConeType - mean(FilterConeType));
        
        % Only place the output signals corresponding to pixels in the mosaic
        % into the final output matrix.
        cone_locations = find(cone_mosaic==cone_type);
        
        % The osAddNoise needs to know the sensor sample time because it
        % computes the cone photon rate, not just the number of photons.
        params.sampTime       = sensorGet(sensor,'time interval');  % Sec
        coneCurrentRSnoisy    = osAddNoise(coneCurrentRS,params);   % Current is in pA
        coneCurrentSingleType = (coneCurrentRSnoisy(cone_locations,:));
        
        if (ndims(coneCurrent) == 3)
            
            % pre-allocate memory
            adaptedDataSingleType = zeros(size(coneCurrentSingleType));
            
            for y = 1:size(coneCurrentSingleType, 1)
                noisySignal = squeeze((coneCurrentSingleType(y, :)));
                tempData = conv(noisySignal, FilterConeType);
                % tempData = real(ifft(conj(fft(squeeze(coneCurrent(x, y, :))) .* FilterFFT)));
                
                adaptedDataSingleType(y, :) = tempData(1:nSteps);
                
            end
            
            %     elseif (ndims(coneCurrent) == 2)
            %
            %         % pre-allocate memory
            %         adaptedData = zeros(size(coneCurrent,1),timeBins);
            %
            %         for xy = 1:size(coneCurrent, 1)
            %             tempData = conv(squeeze(coneCurrent(xy, :)), Filter);
            %             if (initialState.Compress)
            %                 tempData = tempData / maxCur;
            %                 tempData = meanCur * (tempData ./ (1 + 1 ./ tempData)-1);
            %             else
            %                 tempData = tempData - meanCur;
            %             end
            %             adaptedData(xy, :) = tempData(1:timeBins);
            %         end
            %     end
            
            % Signals are in pA here
            adaptedDataRS(cone_locations,:) = adaptedDataSingleType;
            pooledData(iter, cone_type-1) = mean(adaptedDataSingleType(:));
            
        end
        
        
    end
    
    % toc
end
fprintf('\n');
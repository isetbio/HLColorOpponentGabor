%% t_colorOpponentGabor
% 
% Models cone responses for the experiment on detection of Gabor color opponents
% found in "Chromatic detection from cone photoreceptors to V1 neurons to
% behavior in rhesus monkeys" by Horwitz, Hass, Angueyra, Lindbloom-Brown &
% Rieke, J. Neuroscience, 2015.
%
% Outline:
%     1. Build scene as a color-opponent Gabor patch with Horwitz Lab
%           display and imageHarmonicColor.
%     2. Build oi and sensor with specified properties from paper (pupil
%           width, macular density, eccentricity, etc.).
%     3. Create a dynamic scene over time by altering the Gabor phase and
%         regenerating the scene and recomputing the oi and sensor.
%     4. Build the outer segment object with linear filters and compute its
%         response with the dynamic sensor structure.
%     5. Compute the pooled response across each cone type by taking the
%         mean of all of the noisy responses over time of a given cone type 
%         projected onto the cone's linear filter function. This results in an 
%         (L, M, S) triplet for each noise iteration in which the
%         osAddNoise/riekeAddNoise function is applied. This is a specific
%         implementation of an ideal observer; see the paper for details.
%     6. This process is first done for zero contrast with no Gabor
%         present, and repeated for a range of contrasts specified in the
%         contrastArr variable. The pooled response for the cone array at
%         each contrast level is compared to the pooled response for no
%         Gabor present using a linear SVM, and the cross-validated
%         accuracy of the linear SVM is calculated.
%      7. The accuracy is plotted as a function of the contrast, and a
%         psychometric function of the form 
%               p = 1 - 0.5*exp(-(x/alpha)^beta)
%         is fit to the curve, where alpha is the threshold for detection 
%         and beta is the slope of the curve.
% 
% JRG/NC/BW ISETBIO Team, Copyright 2015
%
%
% **************************
% PROBLEM TO FIX:
%   THIS CODE WILL ONLY WORK IF @osLinear/osCompute.m line 31 is changed to
%   isomerizations = sensorGet(sensor, 'photon rate');
%   The osAddNoise function adds too much noise if cone current is comptued
%   based on 'photons' as it currently is.
% Ask Fred about this!
% **************************
% 
% Init
clear
ieInit
ieSessionSet('wait bar', 'off')

%% Specify parameters for contrast values and noise repititions 

contrastArr = [0:0.25:1]; % must start with 0
noiseIterations = 100;    % more iterations will improve accuracy but take longer!

for colorInd = 4 % choose from 1:4, where 1 = s_iso, 2 = L-M, 3 = LM+S, 4 = L-M-S
for contrastInd = 1:length(contrastArr)


%% Set parameters for building the dynamic scene/oi/sensor
% The stimulus consists of a color opponent Gabor patch with phase varying 
% over time. The parameters for the stimulus are set according to Fig. 6 of
% the manuscript.

% parameters found in Fig. 6 caption
params = paramsGaborColorOpponent(); 
params.contrast = contrastArr(contrastInd);  % set max contrast of gabor
params.color = colorInd;                     % 1 = s_iso, 2 = L-M, 3 = LMS, 4 = L-M
params.image_size = 64;                      % scene is (image_size X image_size) pixels
params.fov = 0.6; 
params.nSteps = 60;

stimulusRGBdata = imageHarmonicColor(params); % sceneCreateGabor(params);

% stimulusRGBdata = rgbGaborColorOpponentNormalized(params); % sceneCreateGabor(params);
%% Build the display and scene from the rgb data

% Load the display from the Horwitz Lab
display = displayCreate('CRT-Sony-HorwitzLab');

% Generate scene object from stimulus RGB matrix and display object
scene = sceneFromFile(stimulusRGBdata, 'rgb', params.meanLuminance, display);

% vcAddObject(scene); sceneWindow;

%% Initialize the optics and the sensor

% % According to the paper, cone collecting area is 0.6 um^2
% wave = sceneGet(scene,'wave');
% pixel = pixelCreate('human', wave);
% pixel = pixelSet(pixel, 'pd width', 0.774e-6); % photo-detector width
% pixel = pixelSet(pixel, 'pd height', 0.774e-6);

oi  = oiCreate('wvf human');
sensor = sensorCreate('human');

% % % Uncomment when eccentricity branch is merged back!
% coneP = coneCreate;% 
% % see caption for Fig. 4 of Horwitz, Hass, Rieke, 2015, J. Neuro.
% retinalPosDegAz = 5; retinalPosDegEl = -3.5;
% retinalRadiusDegrees = sqrt(retinalPosDegAz^2+retinalPosDegEl^2);
% retinalPolarDegrees = abs(atand(retinalPosDegEl/retinalPosDegAz));
% retinalPos = [retinalRadiusDegrees retinalPolarDegrees]; whichEye = 'right';
% sensor = sensorCreate('human', [coneP], [retinalPos], [whichEye]);

sensor = sensorSetSizeToFOV(sensor, params.fov, scene, oi);
sensor = sensorSet(sensor, 'exp time', params.expTime); % 1 ms
sensor = sensorSet(sensor, 'time interval', params.timeInterval); % 1 ms

% % macular pigment absorbance was scaled to 0.35 at 460 nm
% macular = sensorGet(sensor, 'human macular');
% macular = macularSet(macular, 'density', 0.35);
% sensor = sensorSet(sensor, 'human macular', macular);

%% Compute a dynamic set of cone absorptions

% ieSessionSet('wait bar',true);
wFlag = ieSessionGet('wait bar');
if wFlag, wbar = waitbar(0,'Stimulus movie'); end

fprintf('Computing dynamic scene/oi/sensor data    ');
% Loop through frames to build movie
for t = 1 : params.nSteps
    
    fprintf('\b\b\b%02d%%', round(100*t/params.nSteps));
    
    if wFlag, waitbar(t/params.nSteps,wbar); end
        
    % Update the phase of the Gabor
    params.ph = 2*pi*(t-1)/params.nSteps; % one period over nSteps
    % scene = sceneCreate('harmonic', params);
    % scene = sceneSet(scene, 'h fov', fov);
    
    stimulusRGBdata = imageHarmonicColor(params); % sceneCreateGabor(params);
    scene = sceneFromFile(stimulusRGBdata, 'rgb', params.meanLuminance, display);
    scene = sceneSet(scene, 'h fov', params.fov);
    
    % Get scene RGB data    
    % sceneRGB(:,:,t,:) = sceneGet(scene,'rgb');
    
    scene = sceneAdjustLuminance(scene, 200);
    % if t < 160 %nSteps / 4
    %     scene = sceneAdjustLuminance(scene, 200 * (t/(160)) );
    %     % elseif (t >= nSteps / 4) && (t <= 3 * nSteps / 4)
    % elseif (t >= 160) && (t <= 160+346)
    %     scene = sceneAdjustLuminance(scene, 200);
    % elseif t > 160+346 %3 * nSteps / 4
    %     scene = sceneAdjustLuminance(scene, 200 * (((160+346+160) - t)/160) );
    % end
    
    % oi  = oiCreate('wvf human');
    % Compute optical image
    oi = oiCompute(oi, scene);    
    
    % Compute absorptions
    sensor = sensorSet(sensor,'noise flag',0);
    sensor = sensorCompute(sensor, oi);

    if t == 1
        volts = zeros([sensorGet(sensor, 'size') params.nSteps]);
        vcAddObject(scene); sceneWindow
    end
    
    volts(:,:,t) = sensorGet(sensor, 'volts');
    
    % vcAddObject(scene); sceneWindow
    % pause(.1);
end

if wFlag, delete(wbar); end

% Set the stimuls into the sensor object
sensor = sensorSet(sensor, 'volts', volts);
% vcAddObject(sensor); sensorWindow;

%% Train linear SVM and find cross-validated accuracy
% Create the outer segment object
os = osCreate('linear');
 
% Compute the photocurrent
os = osCompute(os, sensor);

% Pool all of the noisy responses across each cone type
pooledData{contrastInd} = pooledConeResponse_orig(os, sensor, noiseIterations);

if contrastInd > 1
    
    % Visulaize pooled responses in LMS space
    figure; scatter3(pooledData{1}(:,1),pooledData{1}(:,2),pooledData{1}(:,3))
    hold on; scatter3(pooledData{contrastInd}(:,1),pooledData{contrastInd}(:,2),pooledData{contrastInd}(:,3))

    % Fit a linear svm classifier between pooled responses at contrast = 0
    % and contrast = contrastArr(contrastInd):
    m1 = fitcsvm([pooledData{1}; pooledData{contrastInd}], [ones(noiseIterations,1); -1*ones(noiseIterations,1)], 'KernelFunction', 'linear');
    % Calculate cross-validated accuracy based on model:
    cv = crossval(m1);    
    rocarea(contrastInd) = 1-kfoldLoss(cv);
end

clear sensor scene oi display params os
end%colorInd
end%contrastInd

%%

%% Fit psychometric curve to thresholds as a function of contrast
[xData, yData] = prepareCurveData( [contrastArr], [ rocarea]);

% Set up fittype and options.
ft = fittype( '1 - 0.5*exp(-(x/a)^b)', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [0.323369521886293 0.976303691832645];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

% Plot fit with data.
figure( 'Name', 'untitled fit 1' );
h = plot( fitresult, xData, yData );
hold on; scatter(contrastArr,rocarea,40,'filled');
% set(gca,'xscale','log')
legend( h, 'data', 'fitted curve', 'Location', 'NorthWest' );
% Label axes
xlabel Contrast
ylabel p(Correct)
grid on
thresh1 = fitresult.a;
title(sprintf('Detection, \\alpha = %1.2f',(thresh1)));
set(gca,'fontsize',16')
axis([0 1 0.5 1]);

%% Show the movie of volts
% 
% % This should be a sensorMovie() call.
% %
% % Can we easily make that movie when we color the cones by type
% vcNewGraphWin;axis image; colormap(gray)
% for ii=1:params.nSteps
%     imagesc(volts(:,:,ii)); pause(.2); 
% end

% % Time series at a point
% vcNewGraphWin; plot(squeeze(volts(1,1,:)))
% 
% %% Movie of the cone absorptions over cone mosaic
% % from t_VernierCones by HM
% 
% step = 1;
% tmp = coneImageActivity(sensor,[],step,false);
% 
% % Show the movie
% vcNewGraphWin;
% tmp = tmp/max(tmp(:));
% for ii=1:size(tmp,4)
%     img = squeeze(tmp(:,:,:,ii));
%     imshow(img.^3); truesize;
%     title('Cone absorptions')
%     drawnow
% end
% 
% %% Outer segment calculation
% 
% % The outer segment converts cone absorptions into cone photocurrent.
% % There are 'linear','biophys' and 'identity' types of conversion.  The
% % linear is a standard convolution.  The biophys is based on Rieke's
% % biophysical work.  And identity is a copy operation.
% os = osCreate('linear');
%  
% % Compute the photocurrent
% os = osCompute(os, sensor);
%  
% % Plot the photocurrent for a pixel
% % Let's JG and BW mess around with various plotting things to check the
% % validity.
% osPlot(os,sensor);
% 
% % Input = RGB
% % os = osCreate('identity');
% % os = osSet(os, 'rgbData', sceneRGB);
% 
% %% Rieke biophysics case
% 
% os = osCreate('biophys');
%  
% % Compute the photocurrent
% os = osCompute(os, sensor);
%  
% % Plot the photocurrent for a pixel
% % Let's JG and BW mess around with various plotting things to check the
% % validity.
% osPlot(os,sensor,'output')
% 
% %% Build rgc
% 
% eyeAngle = 180; % degrees
% eyeRadius = 3; % mm
% eyeSide = 'right';
% rgc1 = rgcCreate('GLM', scene, sensor, os, eyeSide, eyeRadius, eyeAngle);
% 
% rgc1 = rgcCompute(rgc1, os);
% 
% % rgcPlot(rgc1, 'mosaic');
% % rgcPlot(rgc1, 'linearResponse');
% rgcPlot(rgc1, 'spikeResponse');
% %% Build rgc response movie
% %  https://youtu.be/R4YQCTZi7s8
% 
% % % osLinear
% % rgcMovie(rgc1, sensor);
% 
% % % osIdentity
% % rgcMovie(rgc1, os);
% 
% 

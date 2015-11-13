%% t_colorOpponentGabor
% 
% Model cone responses for experiment on detection of gabor color opponents
% found in "Chromatic detection from cone photoreceptors to V1 neurons to
% behavior in rhesus monkeys" by Horwitz, Hass, Angueyra, Lindbloom-Brown &
% Rieke, J. Neuroscience, 2015
%
% 
% JRG/NC ISETBIO Team, Copyright 2015
%
%
% Init
ieInit
ieSessionSet('wait bar', 'off')



%% Set parameters for building the dynamic scene/oi/sensor
% The stimulus consists of a color opponent Gabor patch with phase varying 
% over time. The parameters for the stimulus are set according to Fig. 6 of
% the manuscript.

% parameters found in Fig. 6 caption
params.color_val = 3;          % 1 = s_iso, 2 = L-M, 3 = LMS, 4 = L-M
params.contrast = 0.8;        % set max contrast of gabor
params.image_size = 32;        % scene is (image_size X image_size) pixels
params.disp_movie = 0;         % display movie flag

params.fov = 1.2;              % degrees, sd = 0.4 deg, truncated at 3 sd
params.freq = 3.6;             % cyc/image = cyc/1.2 degs; want 3 cyc/deg = x cyc/1.2 degs, x = 3.6
params.period = 10;            % in millseconds
params.ph  = 2*pi*((0)/params.period);  % vary with time at 3 hz?
params.ang = 0;
params.row = params.image_size;
params.col = params.image_size;
params.GaborFlag = (128/params.image_size)*0.1/3.6; % standard deviation of the Gaussian window FIX
params.nSteps = 666;          % total length of movie in millseconds
params.meanLuminance = 100;

% For the sensor
params.expTime = 0.001;
params.timeInterval = 0.001;

stimulusRGBdata = rgbGaborColorOpponentNormalized(params); % sceneCreateGabor(params);

%% Build display according to calibration data from the Horwitz Lab

% Display calibration data provided by the Horwitz Lab
load('monitorCalibration/spdCalibrationHorwitzHass.mat');
wave = cal.monSpectWavelengths; 
NspectralSamples = length(wave);

% power at each of the above wavelengths, in Watts/steradian/m^2/nm, for each of the R,G,B channels
spd = reshape(cal.monSpect,NspectralSamples,3); 

dpi   = 96;              % display resolution in pixels per inch
vd_inMeters = 2.0;       % viewing distance in meters

% Generate a display object to model Horwitz's display
display = displayCreate;
display = displaySet(display, 'name', 'Horwitz');

% Set the display's SPDs
display = displaySet(display, 'wave', wave);
display = displaySet(display, 'spd', spd);
display = displaySet(display, 'ambientspd', zeros(1,length(spd))); 

% Set the display's resolution (dots-per-inch)
display = displaySet(display, 'dpi', dpi);

% Set the display's viewing distance
display = displaySet(display, 'viewing distance', vd_inMeters);

%% Generate scene object from stimulus RGB matrix and display object

scene = sceneFromFile(stimulusRGBdata, 'rgb', params.meanLuminance, display);

% vcAddAndSelectObject(scene); sceneWindow
vcAddObject(scene); sceneWindow;

% % According to the paper, cone collecting area is 0.6 um^2
% wave = sceneGet(scene,'wave');
% pixel = pixelCreate('human', wave);
% pixel = pixelSet(pixel, 'pd width', 0.774e-6); % photo-detector width
% pixel = pixelSet(pixel, 'pd height', 0.774e-6);

%% Initialize the optics and the sensor
oi  = oiCreate('wvf human');

sensor = sensorCreate('human');

% coneP = coneCreate;
% 
% % see caption for Fig. 4 of Horwitz, Hass, Rieke, 2015, J. Neuro.
% retinalPosDegAz = 5; 
% retinalPosDegEl = -3.5;
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
% % macular = macularSet(macular, 'density', 0);
% sensor = sensorSet(sensor, 'human macular', macular);

%% Compute a dynamic set of cone absorptions

% ieSessionSet('wait bar',true);
wFlag = ieSessionGet('wait bar');
if wFlag, wbar = waitbar(0,'Stimulus movie'); end

fprintf('Computing dynamic scene/oi/sensor data    ');
% Loop through frames to build movie
for t =333% : params.nSteps
    
    fprintf('\b\b\b%02d%%', round(100*t/params.nSteps));
    
    if wFlag, waitbar(t/params.nSteps,wbar); end
        
    % Update the phase of the Gabor
    params.ph = 2*pi*(t-1)/params.nSteps; % one period over nSteps
    % scene = sceneCreate('harmonic', params);
    % scene = sceneSet(scene, 'h fov', fov);
    
    stimulusRGBdata = rgbGaborColorOpponentNormalized(params); % sceneCreateGabor(params);
    scene = sceneFromFile(stimulusRGBdata, 'rgb', params.meanLuminance, display);
    scene = sceneSet(scene, 'h fov', params.fov);
    
    % Get scene RGB data    
    % sceneRGB(:,:,t,:) = sceneGet(scene,'rgb');
    
    scene = sceneAdjustLuminance(scene, 200);
%     if t < 160 %nSteps / 4
%         scene = sceneAdjustLuminance(scene, 200 * (t/(160)) );
%         % elseif (t >= nSteps / 4) && (t <= 3 * nSteps / 4)
%     elseif (t >= 160) && (t <= 160+346)
%         scene = sceneAdjustLuminance(scene, 200);
%     elseif t > 160+346 %3 * nSteps / 4
%         scene = sceneAdjustLuminance(scene, 200 * (((160+346+160) - t)/160) );
%     end
    % oi  = oiCreate('wvf human');
    % Compute optical image
    oi = oiCompute(oi, scene);    
    
    % Compute absorptions
    sensor = sensorSet(sensor,'noise flag',0);
    sensor = sensorCompute(sensor, oi);

    if t == 1
        volts = zeros([sensorGet(sensor, 'size') params.nSteps]);
    end
    
    volts(:,:,t) = sensorGet(sensor, 'volts');
    
    vcAddObject(scene); sceneWindow
%     pause(.1);
end

if wFlag, delete(wbar); end

% Set the stimuls into the sensor object
sensor = sensorSet(sensor, 'volts', volts);
% vcAddObject(sensor); sensorWindow;
%%
os = osCreate('linear');
 
% Compute the photocurrent
os = osCompute(os, sensor);

% [pooledData] = pooledConeResponse_orig(os, sensor);
% 
% savestr2 = ['pooledData_ecc_orig_cv_' num2str(params.color_val) '_Cont_' sprintf('%0.4d',10000*params.contrast) '.mat'];

% savestr2 = ['pooledData_redo_cv_' num2str(params.color_val) '_Cont_' sprintf('%0.4d',10000*params.contrast) '.mat'];
% save(savestr2);
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

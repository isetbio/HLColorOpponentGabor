function sensor = sensorHorwitzHass(params, scene, oi, display)
%Build a scene object following parameters from "Chromatic detection from 
% cone photoreceptors to V1 neurons to behavior in rhesus monkeys" by 
% Horwitz, Hass, Angueyra, Lindbloom-Brown & Rieke, J. Neuronscience, 2015
% 
% color_set = 1;         % 1-4, choose color opponent gabor
% contrast_set = 0.8;    % set max contrast of gabor
% image_size = 64;       % scene is image_size x image_size pixels
% disp_movie = 0;        % display movie flag
% 
% sensor = build_sensor_horwitz_hass_2015(color_set, contrast_set, image_size, disp_movie);



nSteps = params.nsteps;

coneP = coneCreate; 
pos = [5, 3.5];  % 5 degree eccentricity to the right
whichEye = 'left'; % left eye
% sensor = sensorCreate('human', coneP, pos, whichEye); 
% sensor = sensorSetSizeToFOV(sensor, params.fov, scene, oi);
sensor = sensorCreate('human');
sensor = sensorSetSizeToFOV(sensor, params.fov, scene, oi);
sensor = sensorSet(sensor, 'exp time', 0.001); % 1 ms
sensor = sensorSet(sensor, 'time interval', 0.001); % 1 ms
    
% Compute cone absorptions for each ms, for a second.
% This is very slow.
% nSteps = 160+346+160;
volts = zeros([sensorGet(sensor, 'size') nSteps]);
% volts = zeros([params.row params.col nSteps]);

%%
stimulus = zeros(1, nSteps);
fprintf('The computation of the stimulus is very slow.\n');
fprintf('Go get a cup of coffee while this runs.\n');
fprintf('Computing cone isomerization:    ');
for t = 1 : nSteps
    fprintf('\b\b\b%02d%%', round(100*t/nSteps));
    % Low luminance for first 500 msec and the step up.
    params.ph  = 2*pi*((t-1)/params.period);
    
    stimulusRGBdata = rgbGaborColorOpponentNormalized(params);
% %     stimulusRGBdata = 0.5*ones(128,128,3);
% 
%     im_gray = rgb2gray(stimulusRGBdata);
%     [m mi1] = max(max(im_gray,[],1));
%     [m mi2] = max(max(im_gray,[],2));
% %    im_gray(mi2,mi1)
%     mi1arr(t) = mi1;
%     mi2arr(t) = mi2;
    
    scene = sceneFromFile(stimulusRGBdata, 'rgb', params.meanLuminance, display);
    
% % %     scene = sceneCreate('harmonic', params);
    scene = sceneSet(scene, 'h fov', params.fov);
    oi  = oiCreate('wvf human');
%     sensor = sensorCreate('human');
%     sensor = sensorSetSizeToFOV(sensor, params.fov, scene, oi);

    coneP = coneCreate;
    pos = [5, 3.5];  % 5 degree eccentricity to the right
    whichEye = 'left'; % left eye
    sensor = sensorCreate('human');%, coneP, pos, whichEye);
    sensor = sensorSetSizeToFOV(sensor, params.fov, scene, oi);
    sensor = sensorSet(sensor, 'exp time', 0.001); % 1 ms
    sensor = sensorSet(sensor, 'time interval', 0.001); % 1 ms
    
    
    % According to the paper, cone collecting area is 0.6 um^2
    wave = sceneGet(scene,'wave');
    pixel = pixelCreate('human', wave);
    pixel = pixelSet(pixel, 'pd width', 0.774e-6); % photo-detector width
    pixel = pixelSet(pixel, 'pd height', 0.774e-6);
    
%     % set cone spacing after Curcio & Sloan, 1987
%     theta = 6; % degrees eccentricity
%     dia = 2*.001*sqrt(theta./(pi*7e4)); % spacing between photoreceptors in m
%     height = pixelGet(pixel, 'height');
%     width  = pixelGet(pixel, 'width');
%     pixel = pixelSet(pixel, 'widthgap', dia - width);    
%     pixel = pixelSet(pixel, 'heightgap', dia - height);
%     
%     sensor = sensorSet(sensor, 'pixel', pixel);
    
        
    
    % macular pigment absorbance was scaled to 0.35 at 460 nm
    macular = sensorGet(sensor, 'human macular');
    macular = macularSet(macular, 'density', 0.35);
%     macular = macularSet(macular, 'density', 0);
    sensor = sensorSet(sensor, 'human macular', macular);

    if t < 160 %nSteps / 4
        scene = sceneAdjustLuminance(scene, 200 * (t/(160)) );
%     elseif (t >= nSteps / 4) && (t <= 3 * nSteps / 4)
    elseif (t >= 160) && (t <= 160+346)
        scene = sceneAdjustLuminance(scene, 200);
    elseif t > 160+346 %3 * nSteps / 4
        scene = sceneAdjustLuminance(scene, 200 * (((160+346+160) - t)/160) );
    end

    
    % Compute optical image
    oi = oiCompute(scene, oi);
    
    % Compute absorptions
%     sensor = sensorCompute(sensor, oi);
    
    sensor = sensorComputeNoiseFree(sensor, oi);
%     add coneabsorptions function here to simulate eye movements
    volts(:,:,t) = sensorGet(sensor, 'volts');
    stimulus(t)  = median(median(volts(:,:,t)));
    
%     fprintf('\n');
end %t

% Set the stimuls into the sensor object
sensor = sensorSet(sensor, 'volts', volts);
stimulus = stimulus / sensorGet(sensor, 'conversion gain') /...
    sensorGet(sensor, 'exp time');
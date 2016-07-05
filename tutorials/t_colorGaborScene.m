% t_colorGaborScene
%
% Create a scene with a color gabor patch.
%
% 7/6/16  dhb  Wrote it.

%% Clear
ieInit; clear; close all;

%% Define parameters of a gabor pattern
%
% Parameters in degrees
fieldOfViewDegs = 4;
cyclesPerDegree = 2;
gaussianFWHMDegs = 1.5;

% Convert to image based parameterss for call into pattern generating routine.
cyclesPerImage = fieldOfViewDegs*cyclesPerDegree;
gaussianStdDegs = FWHMToStd(1.5);
gaussianStdImageFraction = gaussianStdDegs/fieldOfViewDegs;

% Parameters for a full contrast vertical gabor centered on the image
parms.row = 128;
parms.col = 128;
parms.freq = cyclesPerImage;
parms.contrast = 1;
parms.ang = 0;
parms.ph = 0;
parms.GaborFlag = gaussianStdImageFraction;

%% Make the gabor pattern and have a look
%
% We can see it as a grayscale image
gaborPattern = imageHarmonic(parms);
vcNewGraphWin; imagesc(gaborPattern), colormap(gray); axis square

% And plot a slice through the center.
%
% This is useful for verifying that the spatial parameters produce the desired
% result in degrees.  If you generate the Gabor for 0 cpd you can see the Gaussian
% profile and verify that the FWHM is in fact the specified number of
% degrees, and if you make the Gaussian window wide you can count cycles
% and make sure they come out right as well.
figure; hold on;
xDegs = linspace(-fieldOfViewDegs/2,fieldOfViewDegs/2,parms.col);
plot(xDegs,gaborPattern(parms.row/2,:));

%% Convert Gabor to a color modulation specified in cone space
%
% This requires a little colorimetry.

% Specify L, M, S cone contrasts for the modulation
testConeContrast = [0.05 -0.05 0]';

% Specify xyY (Y in cd/m2) coordinates of background (because this is what is often
% done in papers.
backgroundxyY = [0.27 0.30 49.8]';

% Need to load cone fundamentals and XYZ color matching functions to do the
% needed conversions.  Here we'll use the Stockman-Sharpe 2-degree
% fundamentals and the proposed CIE corresponding XYZ functions.  These
% have the advantage that they are an exact linear transformation away from
% one another.
%
% This is the PTB style data, which I know like the back of my hand.  There
% is an isetbio way to do this too, I'm sure.  The factor of 683 in front
% of the XYZ color matching functions brings the luminance units into cd/m2
% when radiance is in Watts/[m2-sr-nm], which are fairly standard units.
whichXYZ = 'xyzCIEPhys2';
theXYZ = load(['T_' whichXYZ]);
eval(['T_XYZ = 683*theXYZ.T_' whichXYZ ';']);
eval(['S_XYZ = theXYZ.S_' whichXYZ ';']);
clear theXYZ

whichCones = 'cones_ss2';
theCones = load(['T_' whichCones]);
eval(['T_cones = 683*theCones.T_' whichCones ';']);
eval(['S_cones = theCones.S_' whichCones ';']);
clear theCones

% Tranform background into cone excitation coordinates. I always like to
% check with a little plot that I didn't bungle the regression.
M_XYZToCones = ((T_XYZ')\(T_cones'))';
T_conesCheck = M_XYZToCones*T_XYZ;
if (max(abs(T_conesCheck(:)-T_cones(:))) > 1e-3)
    error('Cone fundamentals are not a close linear transform of XYZ CMFs');
end

% Convert background to cone excitations
backgroundConeExcitations = M_XYZToCones*xyYToXYZ(backgroundxyY);

% Convert test cone contrasts to cone excitations
testConeExcitations = (testConeContrast .* backgroundConeExcitations)./backgroundConeExcitations;



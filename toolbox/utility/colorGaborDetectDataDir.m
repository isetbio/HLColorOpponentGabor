function dataDir = colorGaborDetectDataDir()
    [p,~] = fileparts(which(mfilename()));
    videoDir = fullfile(p(1:strfind(p,'IBIOColorDetect')+numel('IBIOColorDetect')-1), 'data');
    if (~exist(videoDir, 'dir'))
        fprintf('Creating %s directory on your disk.\n', videoDir);
        mkdir(videoDir)
    end
end
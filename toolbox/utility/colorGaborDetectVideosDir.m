function videoDir = colorGaborDetectVideosDir()
    [p,~] = fileparts(which(mfilename()));
    videoDir = fullfile(p(1:strfind(p,'IBIOColorDetect')+numel('IBIOColorDetect')-1), 'videos');
    if (~exist(videoDir, 'dir'))
        fprintf('Creating %s directory on your disk.\n', videoDir);
        mkdir(videoDir)
    end
end
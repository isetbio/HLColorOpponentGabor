function theDir = colorGaborDetectDataDir()
    subDir = 'data';
    [p,~] = fileparts(which(mfilename()));
    theDir = fullfile(p(1:strfind(p,'IBIOColorDetect')+numel('IBIOColorDetect')-1), subDir);
    if (~exist(theDir, 'dir'))
        fprintf('Creating %s directory on your disk.\n', theDir);
        mkdir(theDir);
    end
end
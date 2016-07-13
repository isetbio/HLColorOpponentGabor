function theDir = colorGaborDetectVideosDir()

subDir = 'videos';

if (ispref('IBIOColorDetect','outputBaseDir'))
    topDir = fullfile(getpref('IBIOColorDetect','outputBaseDir'),conditionDir);
else
    [p,~] = fileparts(which(mfilename()));
    topDir = fullfile(p(1:strfind(p,'IBIOColorDetect')+numel('IBIOColorDetect')-1),conditionDir);
end

if (~exist(topDir),'dir')
    mdir(topDir);
end
theDir = fullfile(topDir,subDir);
if (~exist(theDir, 'dir'))
    mkdir(theDir);
end

end

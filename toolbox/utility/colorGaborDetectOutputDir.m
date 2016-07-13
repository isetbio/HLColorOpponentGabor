function theDir = colorGaborDetectDataDir()
    
subDir = 'output';

if (ispref('IBIOColorDetect','outputBaseDir'))
    theDir = fullfile(getpref('IBIOColorDetect','outputBaseDir'),subDir);
else
    [p,~] = fileparts(which(mfilename()));
    theDir = fullfile(p(1:strfind(p,'IBIOColorDetect')+numel('IBIOColorDetect')-1), subDir);
end
if (~exist(theDir, 'dir'))
    fprintf('Creating %s directory on your disk.\n', theDir);
    mkdir(theDir);
end

end
end
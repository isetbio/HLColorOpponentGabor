function figureDir = colorGaborDetectFiguresDir()
    [p,~] = fileparts(which(mfilename()));
    figureDir = fullfile(p(1:strfind(p,'IBIOColorDetect')+numel('IBIOColorDetect')-1), 'figures');
    if (~exist(videoDir, 'dir'))
        fprintf('Creating %s directory on your disk.\n', figureDir);
        mkdir(videoDir)
    end
end
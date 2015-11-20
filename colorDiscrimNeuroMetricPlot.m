

clear

contrast = 0.0; color_val = 3;
savestr2 = ['gaborData2/pooledData_long_cv_' num2str(color_val) '_Cont_' sprintf('%0.4d',10000*contrast) '.mat'];
load(savestr2, 'pooledData');
pooledData0 = pooledData;

contrast_arr = [0.02:0.02:0.4 0.5 0.6 0.7]%[0.1 0.15:0.01:0.25 .3 .35]
for contrast_ind = 1:length(contrast_arr)    
%     contrast = contrast_arr(contrast_ind);
% 
%     load('pooledData_ecc_cv_2_Cont_0000.mat')
%     
%     pooledData0 = pooledData;
%     
    clear pooledData;
    
%      figure; scatter3(pooledData0(:,1),pooledData0(:,2),pooledData0(:,3))
%     
%     load('pooled_Response_new_CV_1_Cont_0060.mat');
%     
%     pooledData1 = pooledData;
%     
%     clear pooledData;
%     
%     hold on; scatter3(pooledData1(:,1),pooledData1(:,2),pooledData1(:,3),'r')     
%     
%     rp0 = randperm(length(pooledData0)); rp1 = randperm(length(pooledData1));
%     classifyLinearDiscr(pooledData1(rp1,1),pooledData1(rp1,2),pooledData1(rp1,3), pooledData0(rp0,1),pooledData0(rp0,2),pooledData0(rp0,3));
 contv = 10000*contrast_arr(contrast_ind);   
%     savestr2 = ['gaborData2/pooledData_long_cv_' num2str(color_val) '_Cont_' sprintf('%0.4d', 10000*contrast_arr(contrast_ind)) '.mat'];
 savestr2 = sprintf('gaborData2/pooledData_long_cv_%d_Cont_%0.4d.mat',color_val,round(contv));
    load(savestr2, 'pooledData');
    
    pooledData1 = pooledData;
%      hold on; scatter3(pooledData1(:,1),pooledData1(:,2),pooledData1(:,3),'r')  
    clear pooledData
    
    m1 = fitcsvm([pooledData0; pooledData1], [ones(250,1); -1*ones(250,1)], 'KernelFunction', 'linear');
    cv = crossval(m1);
    rocarea(contrast_ind) = 1-kfoldLoss(cv);
    
    %clear pooledData1
    clear savestr2
end
% classifyLinearDiscr(pooledData0(:,1),pooledData0(:,2),pooledData0(:,3),pooledData1(:,1),pooledData1(:,2),pooledData1(:,3))
% figure; scatter(contrast_arr, rocarea, 'o', 'filled');
%%
[xData, yData] = prepareCurveData( contrast_arr, rocarea );

% Set up fittype and options.
ft = fittype( '1 - 0.5*exp(-(x/a)^b)', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [0.323369521886293 0.976303691832645];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

%% Plot fit with data.
figure( 'Name', 'untitled fit 1' );
h = plot( fitresult, xData, yData );
set(gca,'xscale','log')
legend( h, 'data', 'fitted curve', 'Location', 'NorthWest' );
% Label axes
xlabel Contrast
ylabel p(Correct)
grid on
thresh1 = fitresult.a;
title(sprintf('L-M Detection, \\alpha = %1.2f',(thresh1)));
set(gca,'fontsize',16')
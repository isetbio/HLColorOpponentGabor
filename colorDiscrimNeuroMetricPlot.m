

clear

contrast = 0; color_val = 3;
savestr2 = ['pooledData_ecc_orig_cv_' num2str(color_val) '_Cont_' sprintf('%0.4d',10000*contrast) '.mat'];
load(savestr2, 'pooledData');
pooledData0 = pooledData;

contrast_arr = 0.8%[0.001 0.002 0.004 0.006 0.008 0.01];
for contrast_ind = 1:length(contrast_arr)    
%     contrast = contrast_arr(contrast_ind);
% 
%     load('pooledData_ecc_cv_2_Cont_0000.mat')
%     
%     pooledData0 = pooledData;
%     
    clear pooledData;
    
    figure; scatter3(pooledData0(:,1),pooledData0(:,2),pooledData0(:,3))
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
    
    savestr2 = ['pooledData_ecc_orig_cv_' num2str(color_val) '_Cont_' sprintf('%0.4d', 10000*contrast_arr(contrast_ind)) '.mat'];
    load(savestr2, 'pooledData');
    
    pooledData1 = pooledData;
    hold on; scatter3(pooledData1(:,1),pooledData1(:,2),pooledData1(:,3),'r')  
    clear pooledData
    
    m1 = fitcsvm([pooledData0; pooledData1], [ones(40,1); -1*ones(40,1)], 'KernelFunction', 'linear');
    cv = crossval(m1);
    rocarea(contrast_ind) = 1-kfoldLoss(cv);
    
    %clear pooledData1
    
end

figure; scatter(contrast_arr, rocarea, 'o', 'filled');
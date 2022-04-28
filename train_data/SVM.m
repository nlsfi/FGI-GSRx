%% I. 清空环境变量
clear all
close all;
warning off
addpath(genpath(pwd))
% addpath DATA_Me


%% II. 导入数据
% load 'train_data.mat'
% load 'train_data2.mat'
% load 'train_data3.mat'
load('train_data_clean.mat')
load('train_data_ds2.mat')
load('train_data_ds3.mat')
load('train_data_ds7.mat')
TrainData=[TrainData_clean;TrainData_ds2;TrainData_ds3;TrainData_ds7];
% TrainData=TrainData(1:4021,:)


%%%%%%%%%%%% 样本数据归一化处理
for i=3:9%%%训练样本的输入数据
   for j=1:39
       range=4021*(j-1)+1:4021*j;%单颗卫星的范围
       TrainData(range,i)=(TrainData(range,i)-mean(TrainData(range,i)))/std(TrainData(range,i));%%%标准化处理
   end
end
aa = randperm(length(TrainData));%打乱数据
TrainData = TrainData(aa,:); 
t=ceil(length(TrainData)*0.7);
Train=TrainData(1:t,:);
Test=TrainData(t:length(TrainData),:);
Train1=Train;
Test1=Test;

time=10;

%%
for i=1:time
    a1 = randperm(length(Train1));%打乱数据
    a2 = randperm(length(Test1));
    Train2 = Train1(a1,:);
    Test2 = Test1(a2,:); 
    i

    %%%%%%%%%%  随机森林算法%%%%%%%%%%%
    %%
    % 2. 训练数据
    P_train = Train2(:,3:9);
    T_train = Train2(:,10);
    %%
    % 3. 测试数据
    P_test = Test2(:,3:9);
    T_test = Test2(:,10);
    Test_Num=length(Test2);
    Train_Num=length(Train2);
    %% III. 创建随机森林分类器
%     model = classRF_train(P_train,T_train,1000);
% 
%     %% IV. 仿真测试
%     [T_sim,votes] = classRF_predict(P_test,model);
% 
%     RFaccuracy(i) = length(find(T_sim == T_test))/Test_Num;
% 
%     [RF_X,RF_Y,RF_AUC] = plot_roc(T_test, T_sim);    %返回ROC曲线的曲线下的面积
% 
%     RF_Xlog(:,i)=RF_X;
%     RF_Ylog(:,i)=RF_Y;
%     RF_AUClog(:,i)=RF_AUC;


    %%%%%%%%  支持向量机 SVM 算法%%%%%%%%%%%

    svmStr = fitcsvm(P_train,T_train,'KernelFunction','gaussian');
    % SVM predict

    [SVM_label,scores] = predict(svmStr,P_test);     % svm预测

     SVMaccuracy(i) = length(find(SVM_label == T_test))/Test_Num;

    [SVM_X,SVM_Y,SVM_AUC] = plot_roc(SVM_label, T_test);    %返回ROC曲线的曲线下的面积

    SVM_Xlog(:,i)=SVM_X;
    SVM_Ylog(:,i)=SVM_Y;
    SVM_AUClog(:,i)=SVM_AUC;


end

% RF_accuracy=mean(RFaccuracy)
% SVM_accuracy=mean(SVMaccuracy)




%%%%%% ROC 曲线
figure(1)
% plot(mean(RF_Xlog,2),mean(RF_Ylog,2),'b-','lineWidth',2);hold on;  %%%% RF算法 ROC曲线 
plot(mean(SVM_Xlog,2),mean(SVM_Ylog,2),'r-','lineWidth',2);hold on;  %%%% SVM算法 ROC曲线 

xlabel('False positive rate'); ylabel('True positive rate');
title('ROC')
% legend('RF','SVM');

grid on;


% V. 结果分析
count_B = length(find(T_train == 1));
count_M = length(find(T_train == 0));
% total_B = length(find(Data(:,5) == 1));
% total_M = length(find(Data(:,5) == 0));
number_B = length(find(T_test == 1));
number_M = length(find(T_test == 0));
number_B_sim = length(find(SVM_label == 1 & T_test == 1));
number_M_sim = length(find(SVM_label == 0 & T_test == 0));
% number_B_sim = length(find(T_sim == 1 & T_test == 1));
% number_M_sim = length(find(T_sim == 0 & T_test == 0));
% disp(['总数据：' num2str(DataNum)...
%       '  正常数据：' num2str(total_B)...
%       '  欺骗数据：' num2str(total_M)]);
disp(['训练总数据：' num2str(Train_Num)...
      '  正常数据：' num2str(count_B)...
      '  欺骗数据：' num2str(count_M)]);
disp(['测试总数据：' num2str(Test_Num)...
      '  正常数据：' num2str(number_B)...
      '  欺骗数据：' num2str(number_M)]);
disp(['测试数据中正常数据个数：' num2str(number_B_sim)...
      '  虚警数据个数：' num2str(number_B - number_B_sim)...
      '  虚警概率=' num2str((number_B - number_B_sim)/number_B*100) '%']);
disp(['测试数据中欺骗数据个数：' num2str(number_M_sim)...
      '  漏报数据数：' num2str(number_M - number_M_sim)...
      '  漏报概率=' num2str((number_M - number_M_sim)/number_M*100) '%']);
  
disp(['测试数据个数：' num2str(Test_Num)...
      '   正确识别个数（正常+欺骗）：' num2str(number_B_sim+number_M_sim)...
      '  准确率=' num2str((number_B_sim+number_M_sim)/Test_Num*100) '%']);
 
%  votes1=votes/max(votes(:,1));
    



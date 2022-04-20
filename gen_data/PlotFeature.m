close all;
clear all;
clc;

addpath(genpath(pwd));
satId = [3,6,7,8,10,11,13,16,19,20,23,30,32];
Img_path='figure/';
load 'train_data_clean.mat'
load 'train_data_ds2.mat'
load 'train_data_ds3.mat'
load 'train_data_ds7.mat'
all_title={'snrma','snrmv','Com-sqm-ma','Com-sqm-mv','rangeRes','dopplerResid','Df','pse','dopplor','Mn','Spoof','Dt','Posf','Velf'};
for h=3:16
    fgtitle=all_title{h-2};
    for i=1:length(satId)
        satprn=satId(i);
        index_clean=find(TrainData_clean(:,2)==satprn);
        index_ds2=find(TrainData_ds2(:,2)==satprn);        
        index_ds3=find(TrainData_ds3(:,2)==satprn);
        index_ds7=find(TrainData_ds7(:,2)==satprn);
        figure;
        set(0,'DefaultFigureVisible', 'off');%图片不显示
%         set(0,'DefaultFigureVisible', 'on');%图片不显示
        plot(TrainData_clean(index_clean,1),TrainData_clean(index_clean,h));hold on;
        plot(TrainData_ds2(index_ds2,1),TrainData_ds2(index_ds2,h));hold on;
        plot(TrainData_ds3(index_ds3,1),TrainData_ds3(index_ds3,h));hold on;
        plot(TrainData_ds7(index_ds7,1),TrainData_ds7(index_ds7,h));hold on;
        legend('cleanstatic','ds2','ds3','ds7');
        axis tight;
        grid on;
        title([fgtitle,' prn',num2str(satprn)]);
        xlabel('epoch');
        fileName=[fgtitle,'_prn',num2str(satprn),'.jpg'];
        saveas(gcf,[Img_path,fileName]);
    end
end
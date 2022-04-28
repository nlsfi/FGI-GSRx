close all;
clear all;
clc;

addpath(genpath(pwd));
satId = [8,10,11,12,14,15,18,20,21,24,25,27,31,32];
Img_path='figure_oakbat_gps_static/';
load 'train_data_oakbat_clean.mat'
load 'train_data_os2.mat'
load 'train_data_os3.mat'
% load 'train_data_ds7.mat'
all_title={'snrma','snrmv','Com-sqm-ma','Com-sqm-mv','rangeRes','dopplerResid','Df','pse','dopplor','Mn','Spoof','Dt','Posf','Velf'};
for h=3:16
    fgtitle=all_title{h-2};
    for i=1:length(satId)
        satprn=satId(i);
        index_clean=find(TrainData_oakbat_clean(:,2)==satprn);
        index_os2=find(TrainData_os2(:,2)==satprn);        
        index_os3=find(TrainData_os3(:,2)==satprn);
%         index_ds7=find(TrainData_ds7(:,2)==satprn);
        figure;
        set(0,'DefaultFigureVisible', 'off');%图片不显示
%         set(0,'DefaultFigureVisible', 'on');%图片不显示
        plot(TrainData_oakbat_clean(index_clean,1),TrainData_oakbat_clean(index_clean,h));hold on;
        plot(TrainData_os2(index_os2,1),TrainData_os2(index_os2,h));hold on;
        plot(TrainData_os3(index_os3,1),TrainData_os3(index_os3,h));hold on;
%         plot(TrainData_ds7(index_ds7,1),TrainData_ds7(index_ds7,h));hold on;
        legend('cleanstatic','os2','os3');
        axis tight;
        grid on;
        title([fgtitle,' prn',num2str(satprn)]);
        xlabel('epoch');
        fileName=[fgtitle,'_prn',num2str(satprn),'.jpg'];
        saveas(gcf,[Img_path,fileName]);
    end
end
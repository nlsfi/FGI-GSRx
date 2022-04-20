close all;
clear all;
clc;
format long g;
addpath(genpath(pwd));

%% load mat file
load('E:\Old_data\data\oakbat\mat\Fix\trackData_GPSL1_texbatds7_dev.mat');

%% define the struct of traindata
c=299792458;
f_L1=1575.42e6;
nrOfEpochs = size(obsData,2);
Datalist = 13; % second of week;prn;sqm-mv;sqm-ma;cn0-mv;cn0-ma;pse;codephase;doppler;pd;spoofed mask;
TrainData = zeros(nrOfEpochs,Datalist);
calstep = 100;
startepo = 10;% discard the first one minute
% tracking data
row=1;
satId=[];
for sat = 1:trackData.gpsl1.nrObs
    satprn = trackData.gpsl1.channel(sat).SvId.satId
    for epo = startepo:1:nrOfEpochs
%         ind_c = obsData{1,epo}.gpsl1.channel(sat).channelStartIndex:obsData{1,epo}.gpsl1.channel(sat).prevStartIndex;
        ind_c = obsData{1,epo}.gpsl1.channel(sat).prevStartIndex:1:obsData{1,epo}.gpsl1.channel(sat).prevStartIndex+calstep-1;
        %% 增加判断条件,防止出现空值和异常值
        % 1.电文解析是否正常；2.电文校验是否正常；3.星历参数是否正常；4.观测值是否符合要求;5.卫星号不相等
        if ((obsData{1,epo}.gpsl1.channel(sat).bPreambleOk==0)||...
              (obsData{1,epo}.gpsl1.channel(sat).bParityOk==0)||...
              (obsData{1,epo}.gpsl1.channel(sat).bEphOk==0)||...
              (obsData{1,epo}.gpsl1.channel(sat).bObsOk==0)||...
              (satprn ~= obsData{1,epo}.gpsl1.channel(sat).SvId.satId))
            continue;
        end

        %% 信号层特征
        % 复合SQM均值和移动方差
        [Com_sqm_ma,Com_sqm_mv] = CalcCombSQM(trackData.gpsl1.channel(sat).I_E(ind_c),trackData.gpsl1.channel(sat).I_P(ind_c),...
                                            trackData.gpsl1.channel(sat).I_L(ind_c),trackData.gpsl1.channel(sat).Q_E(ind_c),...
                                            trackData.gpsl1.channel(sat).Q_E(ind_c),trackData.gpsl1.channel(sat).Q_L(ind_c),...
                                            trackData.gpsl1.channel(sat).I_E_E(ind_c),trackData.gpsl1.channel(sat).Q_E_E(ind_c));
        % 载噪比均值和移动方差
        snrma = mean(trackData.gpsl1.channel(sat).CN0fromSNR(ind_c));
        snrmv = std(trackData.gpsl1.channel(sat).CN0fromSNR(ind_c));
        
        %% 信息层特征
        % 伪距、载波相位和多普勒观测量
        pse=obsData{1,epo}.gpsl1.channel(sat).rawP;
        codePhase=obsData{1,epo}.gpsl1.channel(sat).codephase;
        dopplor=obsData{1,epo}.gpsl1.channel(sat).doppler;
%         伪距-多普勒一致性关系        
        if epo>1
            lastpse=obsData{1,epo-1}.gpsl1.channel(sat).rawP;%
        else
            lastpse=pse;
        end
        Mn=pse-lastpse+0.1*dopplor*c/f_L1;%多普勒一致性
%         lastpse=pse;
        
        %% 解算层特征
        rangeRes=obsData{1,epo}.gpsl1.channel(sat).rangeResid;
        dopplerResid=obsData{1,epo}.gpsl1.channel(sat).dopplerResid;%钟漂
        dt=navData{1,epo}.Pos.dt;%钟差
        df=navData{1,epo}.Vel.df;%钟差
        pf=navData{1,epo}.Pos.fom;%伪距定位中误差
        vf=navData{1,epo}.Vel.fom;%多普勒测速中误差
        
        %% 数据集赋值
        TrainData(row,1)=round(obsData{1,epo}.gpsl1.receiverTow*10)/10;
        TrainData(row,2)=satprn;
        TrainData(row,3)=snrma;
        TrainData(row,4)=snrmv;
        TrainData(row,5)=Com_sqm_ma;
        TrainData(row,6)=Com_sqm_mv;
        TrainData(row,7)=rangeRes;
        TrainData(row,8)=dopplerResid;
        TrainData(row,9)=df;
        TrainData(row,10)=pse;
        TrainData(row,11)=dopplor;
        TrainData(row,12)=Mn;
        TrainData(row,13)=1;
        if TrainData(row,1)>477991.5
            TrainData(row,13)=0;
        end
        TrainData(row,14)=dt;
        TrainData(row,15)=pf;
        TrainData(row,16)=vf;
        
        row=row+1;
    end
end
TrainData_ds7=TrainData;
save('train_data_ds7.mat','TrainData_ds7');
%% dev main function
%  shelsen chen 
% date:26 March, 2022
%
%%
close all;
clear all;
clc;
format long g

% gsrx('default_param_BeiDouB1_Chapter5.txt');
% gsrx('default_param_GPSL1_Staticclean.txt');
% gsrx('default_param_GPSL1_Oakbatoastaticlean.txt');
% gsrx('default_param_GalileoE1_Oakbatos11_test.txt');
% gsrx('default_param_GalileoE1_cleanStatic_galileo_test.txt');
% LY
% gsrx('default_param_GPSL1_Texbatds2.txt');
gsrx('default_param_GPSL1_Texbatds4.txt');
% LJ
% gsrx('default_param_GPSL1_Texbatds3.txt');
% gsrx('default_param_GPSL1_Texbatds7.txt');

settings.nav.elevationMask = 4;
obsData = generateObservations(trackData, settings);
% Execute frame decoding. Needed for time stamps at least 
[obsData, ephData] = doFrameDecoding(obsData, trackData, settings);
% Execute navigation
[obsData,satData,navData] = doNavigation(obsData, settings, ephData);

plotTracking(trackData, settings); 
% Calculate statistics

statResults = calcStatistics(navData,[trueLat trueLong trueHeight],settings.nav.navSolPeriod,settings.const); 
save(settings.sys.dataFileOut,'settings','acqData','ephData','trackData','obsData','satData','navData');

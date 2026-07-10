%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copyright 2015-2021 Finnish Geospatial Research Institute FGI, National
%% Land Survey of Finland. This file is part of FGI-GSRx software-defined
%% receiver. FGI-GSRx is a free software: you can redistribute it and/or
%% modify it under the terms of the GNU General Public License as published
%% by the Free Software Foundation, either version 3 of the License, or any
%% later version. FGI-GSRx software receiver is distributed in the hope
%% that it will be useful, but WITHOUT ANY WARRANTY, without even the
%% implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
%% See the GNU General Public License for more details. You should have
%% received a copy of the GNU General Public License along with FGI-GSRx
%% software-defined receiver. If not, please visit the following website 
%% for further information: https://www.gnu.org/licenses/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function settings = gpsl1UpdateTrackingParametersFor20msIntegration(settings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

settings.gpsl1.codeLengthMs = 20;
settings.gpsl1.codeLengthInChips = 1023*settings.gpsl1.codeLengthMs;  
settings.gpsl1.Nc = 0.001*settings.gpsl1.codeLengthMs;    
settings.gpsl1.fllNoiseBandwidthWide = 10;
settings.gpsl1.fllNoiseBandwidthNarrow = 10;
settings.gpsl1.fllNoiseBandwidthVeryNarrow = 10;
settings.gpsl1.fllDampingRatio = 0.2;
settings.gpsl1.fllLoopGain = 0.14;
settings.gpsl1.pllNoiseBandwidthWide = 5;
settings.gpsl1.pllNoiseBandwidthNarrow = 5;
settings.gpsl1.pllNoiseBandwidthVeryNarrow = 5;
settings.gpsl1.pllDampingRatio = 0.08;    
settings.gpsl1.pllLoopGain = 0.03;    
settings.gpsl1.dllDampingRatio = 1;     
settings.gpsl1.dllNoiseBandwidth =0.2;   
settings.gpsl1.dllLoopGain = 0.5;
settings.gpsl1.corrFingers = [-2 -0.05 0 0.05];    
settings.gpsl1.earlyFingerIndex = 2;            
settings.gpsl1.promptFingerIndex = 3;    
settings.gpsl1.lateFingerIndex = 4;    
settings.gpsl1.noiseFingerIndex = 1;    
settings.gpsl1.pllWideBandLockIndicatorThreshold = 0.4;    
settings.gpsl1.pllNarrowBandLockIndicatorThreshold = 0.4;    
settings.gpsl1.runningAvgWindowForLockDetectorInMs = 300;    
settings.gpsl1.fllWideBandLockIndicatorThreshold = 0.4;    
settings.gpsl1.fllNarrowBandLockIndicatorThreshold = 0.4;   

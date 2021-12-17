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
function  corrInputData = generateCorrectionInputData(obs,ephData,allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function takes input of tracking results and generates
% observations for the navigation
%
% Inputs:
%   obs             - Observation data
%   ephData              - ephemeris data
%   allSettings     - Receiver settings
%
% Outputs:
%   corrInputData      - correction data which can be applied for different
%   corrections depeding on the model type
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Loop over all signals
for signalIndex = 1:allSettings.sys.nrOfSignals
    
    % Extract block of parameters for one signal from settings
    signal = allSettings.sys.enabledSignals{signalIndex};
    signalSettings = allSettings.(signal);
    eph = ephData.(signal);

    % Loop over all channels
    for channelNr = 1:obs.(signal).nrObs
        if(obs.(signal).channel(channelNr).bPreambleOk)    
            if strcmp(signalSettings.ionomodel,'default')==1                              
                corrInputData.iono.default.alpha0 = 4.6566128999999998e-09;        
                corrInputData.iono.default.alpha1 = 1.4901161000000001e-08;        
                corrInputData.iono.default.alpha2 = -5.9604600000000002e-08;        
                corrInputData.iono.default.alpha3 = -5.9604600000000002e-08;                    
                corrInputData.iono.default.beta0 = 7.9872000000000000e+04;        
                corrInputData.iono.default.beta1 = 6.5536000000000000e+04;        
                corrInputData.iono.default.beta2 = -6.5536000000000000e+04;        
                corrInputData.iono.default.beta3 = -3.9321600000000000e+05;  
            elseif strcmp(signalSettings.ionomodel,'beib1')==1            
                corrInputData.iono.beib1.alpha0 = eph(obs.(signal).channel(channelNr).SvId.satId).alpha0;        
                corrInputData.iono.beib1.alpha1 = eph(obs.(signal).channel(channelNr).SvId.satId).alpha1;        
                corrInputData.iono.beib1.alpha2 = eph(obs.(signal).channel(channelNr).SvId.satId).alpha2;        
                corrInputData.iono.beib1.alpha3 = eph(obs.(signal).channel(channelNr).SvId.satId).alpha3;        
                corrInputData.iono.beib1.beta0 = eph(obs.(signal).channel(channelNr).SvId.satId).beta0;        
                corrInputData.iono.beib1.beta1 = eph(obs.(signal).channel(channelNr).SvId.satId).beta1;        
                corrInputData.iono.beib1.beta2 = eph(obs.(signal).channel(channelNr).SvId.satId).beta2;        
                corrInputData.iono.beib1.beta3 = eph(obs.(signal).channel(channelNr).SvId.satId).beta3;        
            elseif strcmp(signalSettings.ionomodel,'gale1b')==1   %No iono parameters are transmitted from Glonass satellites                             
                corrInputData.iono.gale1b.a0 = eph(obs.(signal).channel(channelNr).SvId.satId).ai0_5;        
                corrInputData.iono.gale1b.a1 = eph(obs.(signal).channel(channelNr).SvId.satId).ai1_5;        
                corrInputData.iono.gale1b.a2 = eph(obs.(signal).channel(channelNr).SvId.satId).ai2_5;                        
            elseif strcmp(signalSettings.ionomodel,'glol1')==1   %No iono parameters are transmitted from Glonass satellites                             
                corrInputData.iono.glol1.alpha0 = 0;        
                corrInputData.iono.glol1.alpha1 = 0;        
                corrInputData.iono.glol1.alpha2 = 0;        
                corrInputData.iono.glol1.alpha3 = 0;        
                corrInputData.iono.glol1.beta0 = 0;        
                corrInputData.iono.glol1.beta1 = 0;
                corrInputData.iono.glol1.beta2 = 0;        
                corrInputData.iono.glol1.beta3 = 0;
            elseif strcmp(signalSettings.ionomodel,'navicl5')==1   %To be checked by Sarang                             
                corrInputData.iono.glol1.alpha0 = 0;        
                corrInputData.iono.glol1.alpha1 = 0;        
                corrInputData.iono.glol1.alpha2 = 0;        
                corrInputData.iono.glol1.alpha3 = 0;        
                corrInputData.iono.glol1.beta0 = 0;        
                corrInputData.iono.glol1.beta1 = 0;
                corrInputData.iono.glol1.beta2 = 0;        
                corrInputData.iono.glol1.beta3 = 0;                
            elseif strcmp(signalSettings.ionomodel,'ionex')==1   %Ionex processing
                corrInputData.iono.ionex.tecTables = parseIonex(signalSettings.ionexFile);
            else
                ;
            end   
        end
    end
end
        
end
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
function [eph, obsCh] = gpsl1DecodeEphemeris(obsCh, I_P, prn, signalSettings, const)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function decodes ephemerides and time of frame start from the given bit
% stream. 
%
% Inputs:
%   obsCh               - Observations for one channel
%   I_P                 - Prompt correlator output
%   prn                 - Prn number
%   signalSettings      - Settings for one signal
%   const               - Constants
%
% Outputs:
%   eph                 - SV ephemeris
%   obsCh               - Observations for one channel
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Pi used in the GPS coordinate system
gpsPi = const.PI;

% For GPS we need the previous subframes last bit 
bit = sum(I_P(obsCh.firstSubFrame-20:obsCh.firstSubFrame-1));
preBit(bit > 0)  = 1;
preBit(bit <= 0) = -1;  
preBit = (preBit > 0);        
D30Star = dec2bin(preBit);

% Convert tracking output to navigation bits 
startIndex = signalSettings.codeLengthMs * obsCh.firstSubFrame; % Include 2 bits from previous subframe
endIndex = signalSettings.codeLengthMs * (obsCh.firstSubFrame + (signalSettings.frameLength) - 1);
navBitsSamples = I_P(startIndex : signalSettings.codeLengthMs: endIndex)';

% Group I_P values into bits
navBitsSamples = reshape(navBitsSamples, ...
                         signalSettings.bitDuration, (size(navBitsSamples, 1) / signalSettings.bitDuration));

% Sum all samples in the bits to get the best estimate
navBits = sum(navBitsSamples,1);
bits(navBits > 0)  = 1;
bits(navBits <= 0) = -1;    

% The expression (navBits > 0) returns an array with elements set to 1
% if the condition is met and set to 0 if it is not met.
navBits = (navBits > 0);
                
% Convert from decimal to binary 
% The function decodeGpsEphemeris expects input in binary form. In Matlab it is
% a string array containing only "0" and "1" characters.
bits = dec2bin(navBits)';

%% Check if there is enough data for navigation message deocding===========
if length(bits) < 1500
    error('Not enough navigation bits to decode!');
end

%% Check if the parameters are strings ====================================
if ischar(bits)==0
    error('The parameter bits must be a character array!');
end

if ischar(D30Star)==0
    error('The parameter D30Star must be a character!');
end

subfMask = 0;

% Decode first three subframes, which contains navigation message 
i = 1;
while (i*300 <= length(bits))

    % Take one subframe at a time
    subframe = bits(300*(i-1)+1 : 300*i);
    i = i + 1;
    
    % Correct polarity of the data bits in all 10 words 
    for j = 1:10
        [subframe(30*(j-1)+1 : 30*j)] = ...
            gpsl1CheckPhase(subframe(30*(j-1)+1 : 30*j), D30Star);
        
        D30Star = subframe(30*j);
    end

    % Decode subframe id 
    % For more details on subframe content definition, please refer to GPS ICD.
    subframeID = bin2dec(subframe(50:52));
    
    subfMask = bitset(subfMask,subframeID);

    % Decode GPS subframe 1 to 3 based on the subframe id 
    % The objective is to select necessary bits and convert them to decimal
    % numbers. For more details on subframe content definition, please refer to GPS ICD.( for exaxmple, IS-GPS-200).
    switch subframeID
        case 1  % Subframe 1 decoding
            % Contains Week Number, SV clock corrections, health and accuracy
            weekNumber  = bin2dec(subframe(61:70)) + 1024;
            accuracy    = bin2dec(subframe(73:76));
            health      = bin2dec(subframe(77:82));
            T_GD        = twosComp2dec(subframe(197:204)) * 2^(-31);
            IODC        = bin2dec([subframe(83:84) subframe(211:218)]);
            t_oc        = bin2dec(subframe(219:234)) * 2^4;
            a_f2        = twosComp2dec(subframe(241:248)) * 2^(-55);
            a_f1        = twosComp2dec(subframe(249:264)) * 2^(-43);
            a_f0        = twosComp2dec(subframe(271:292)) * 2^(-31);
            
            TOW = bin2dec(subframe(31:47)) * 6 - (i-1)*6;            

        case 2  % Subframe 2 decoding
            % Contains first part of ephemeris parameters
            IODE_sf2    = bin2dec(subframe(61:68));
            C_rs        = twosComp2dec(subframe(69: 84)) * 2^(-5);
            deltan      = twosComp2dec(subframe(91:106)) * 2^(-43) * gpsPi;
            M_0         = twosComp2dec([subframe(107:114) subframe(121:144)])* 2^(-31) * gpsPi;
            C_uc        = twosComp2dec(subframe(151:166)) * 2^(-29);
            e           = bin2dec([subframe(167:174) subframe(181:204)])* 2^(-33);
            C_us        = twosComp2dec(subframe(211:226)) * 2^(-29);
            sqrtA       = bin2dec([subframe(227:234) subframe(241:264)])* 2^(-19);
            t_oe        = bin2dec(subframe(271:286)) * 2^4;

        case 3  % Subframe 3 
            % Contains second part of ephemeris parameters
            C_ic        = twosComp2dec(subframe(61:76)) * 2^(-29);
            omega_0     = twosComp2dec([subframe(77:84) subframe(91:114)]) ...
                * 2^(-31) * gpsPi;
            C_is        = twosComp2dec(subframe(121:136)) * 2^(-29);
            i_0         = twosComp2dec([subframe(137:144) subframe(151:174)]) ...
                * 2^(-31) * gpsPi;
            C_rc        = twosComp2dec(subframe(181:196)) * 2^(-5);
            omega       = twosComp2dec([subframe(197:204) subframe(211:234)]) ...
                * 2^(-31) * gpsPi;
            omegaDot    = twosComp2dec(subframe(241:264)) * 2^(-43) * gpsPi;
            IODE_sf3    = bin2dec(subframe(271:278));
            iDot        = twosComp2dec(subframe(279:292)) * 2^(-43) * gpsPi;

        case 4  % Subframe 4 
            % Almanac, ionospheric model, UTC parameters SV health for PRN: 25-32 are not decoded                         

        case 5  % Subframe 5 
            % SV almanac and health, almanac reference week number and time for PRN: 1-24 are not decoded            
    end 

    % Convert decoded values to ephemeris data structure in a way identical
    % to other constellation as much as possible
    if(bitand(subfMask,7) == 7)
        % Subframe #1
        eph.weekNumber  = weekNumber;           
        eph.accuracy    = accuracy;            
        eph.health      = health;            
        eph.T_GD        = T_GD;
        eph.IODC        = IODC;
        eph.t_oc        = t_oc;
        eph.a_f2        = a_f2;
        eph.a_f1        = a_f1;
        eph.a_f0        = a_f0;

        % Subframe #2   
        eph.IODE_sf2    = IODE_sf2;    
        eph.C_rs        = C_rs;            
        eph.deltan      = deltan;            
        eph.M_0         = M_0;            
        eph.C_uc        = C_uc;            
        eph.e           = e;            
        eph.C_us        = C_us;            
        eph.sqrtA       = sqrtA;            
        eph.t_oe        = t_oe;

        % Subframe #3   
        eph.C_ic        = C_ic;
        eph.omega_0     = omega_0;
        eph.C_is        = C_is;
        eph.i_0         = i_0;
        eph.C_rc        = C_rc;
        eph.omega       = omega;
        eph.omegaDot    = omegaDot;
        eph.IODE_sf3    = IODE_sf3;
        eph.iDot        = iDot;
        eph.geo = false; 
        
        % Output info
        if(eph.health == 0)
            disp(['   Ephemeris for ', obsCh.signal ,' prn ', int2str(prn),' found.'])          
            obsCh.bEphOk = true;
            obsCh.tow = TOW;            
        else
            obsCh.bEphOk = false;            
            disp(['   Ephemeris for ', obsCh.signal ,' prn ', int2str(prn),' is unhealthy.'])  
        end        
        break;
    end    
end 

% Output info
if(obsCh.bEphOk == false)
    disp(['   Ephemeris for ', obsCh.signal ,' prn ', int2str(prn),' NOT found.'])                
end


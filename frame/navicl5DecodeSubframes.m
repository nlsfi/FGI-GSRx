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

function [eph, TOW] = navicl5DecodeSubframes(FECdecodedSubFrame, eph, const)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function decodes ephemerides from the given decoded SubFrame. The subframe must contain 292 bits.
%
%   Inputs:
%       FECdecodedSubFrame    -    292 bits of the navigation messages (1 subframe).
%                               Type is character array and it must contain only
%                               characters '0' or '1'.
%       eph         - SV ephemeris
%
%   Outputs:
%       eph         - SV ephemeris
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check if there is enough data ==========================================
if length(FECdecodedSubFrame) < 292
    error('Not enough data for extracting ephemeris and/or almanac!');
end

% Pi used in the GPS coordinate system
insPi = const.PI;

% Extract the TOW
%The transmitted TOW is TOW of the next subframe and we need the TOW of the current subframe. In
% order to get the TOW for the start of the current subframe we need to subtract 12 seconds !
TOW = bin2dec(FECdecodedSubFrame(9:25)) * 12 - 12;

% Extract the Alert flag
alertFlag = FECdecodedSubFrame(26);
eph.alertFlag = alertFlag;

% Extract the subframe ID
subframeID = bin2dec(FECdecodedSubFrame(28:29)) + 1;

%--- Decode sub-frame based on the sub-frame id ----------------------
% The task is to select the necessary bits and convert them to decimal
% numbers. For more details on sub-frame contents please refer to NAVIC L5 ICD.
switch subframeID
    case 1  %--- subframe 1 -------------------------------------
        %It contains WN, SV clock corrections, health and accuracy
        weekNumber  = bin2dec(FECdecodedSubFrame(31:40)); %+ 1024;
        a_f2        = twosComp2dec(FECdecodedSubFrame(79:86)) * 2^(-55);
        a_f1        = twosComp2dec(FECdecodedSubFrame(63:78)) * 2^(-43);
        a_f0        = twosComp2dec(FECdecodedSubFrame(41:62)) * 2^(-31);
        accuracy    = bin2dec(FECdecodedSubFrame(87:90)); %URA
        t_oc        = bin2dec(FECdecodedSubFrame(91:106)) * 2^4;
        T_GD        = twosComp2dec(FECdecodedSubFrame(107:114)) * 2^(-31);
        deltan      = twosComp2dec(FECdecodedSubFrame(115:136)) * 2^(-41) * insPi;
        IODEC       = bin2dec(FECdecodedSubFrame(137:144)); %IODEC = combination of IDOC and IDOE
        L5_Flag     = bin2dec(FECdecodedSubFrame(155));
        C_uc        = twosComp2dec(FECdecodedSubFrame(157:171)) * 2^(-28);
        C_us        = twosComp2dec(FECdecodedSubFrame(172:186)) * 2^(-28);
        C_ic        = twosComp2dec(FECdecodedSubFrame(187:201)) * 2^(-28);
        C_is        = twosComp2dec(FECdecodedSubFrame(202:216)) * 2^(-28);
        C_rc        = twosComp2dec(FECdecodedSubFrame(217:231)) * 2^(-4);
        C_rs        = twosComp2dec(FECdecodedSubFrame(232:246)) * 2^(-4);
        iDot        = twosComp2dec(FECdecodedSubFrame(247:260)) * 2^(-43) * insPi;
        
        eph.weekNumber  = weekNumber;
        eph.a_f2        = a_f2;
        eph.a_f1        = a_f1;
        eph.a_f0        = a_f0;
        eph.accuracy    = accuracy;
        eph.t_oc        = t_oc;
        eph.T_GD        = T_GD;
        eph.deltan      = deltan;
        eph.IODEC       = IODEC;
        eph.health     = L5_Flag;
        eph.C_uc        = C_uc;
        eph.C_us        = C_us;
        eph.C_ic        = C_ic;
        eph.C_is        = C_is;
        eph.C_rc        = C_rc;
        eph.C_rs        = C_rs;
        eph.iDot        = iDot;
        
    case 2  %--- subframe 2 -------------------------------------
        %         % It contains remaining ephemeris parameters
        M_0         = twosComp2dec(FECdecodedSubFrame(31:62)) * 2^(-31) * insPi;
        t_oe        = bin2dec(FECdecodedSubFrame(63:78)) * 2^4;
        e           = bin2dec(FECdecodedSubFrame(79:110)) * 2^(-33);
        sqrtA       = bin2dec(FECdecodedSubFrame(111:142)) * 2^(-19);
        omega_0     = twosComp2dec(FECdecodedSubFrame(143:174)) * 2^(-31) * insPi;
        omega       = twosComp2dec(FECdecodedSubFrame(175:206)) * 2^(-31) * insPi;
        omegaDot    = twosComp2dec(FECdecodedSubFrame(207:228)) * 2^(-41) * insPi;
        i_0         = twosComp2dec(FECdecodedSubFrame(229:260)) * 2^(-31) * insPi;
        
        eph.M_0         = M_0;
        eph.t_oe        = t_oe;
        eph.e           = e;
        eph.sqrtA       = sqrtA;
        eph.omega_0     = omega_0;
        eph.omega       = omega;
        eph.omegaDot    = omegaDot;
        eph.i_0         = i_0;
        
    case 3  %--- subframe 3 -------------------------------------
        % It contains secondary navigation parameters
        prnID = bin2dec(FECdecodedSubFrame(257:262));
        msgID = bin2dec(FECdecodedSubFrame(31:36));
        switch msgID
            case 0
            case 5
            case 7
            case 9
            case 11
            case 14
            case 18
            case 26
        end        
        eph.prnID = prnID;
        eph.geo = 0;        
    case 4  %--- subframe 4 -------------------------------------
        % It contains secondary navigation parameters
        prnID = bin2dec(FECdecodedSubFrame(257:262));
        msgID = bin2dec(FECdecodedSubFrame(31:36));
        switch msgID
            case 0
            case 5
            case 7
            case 9
            case 11
            case 14
            case 18
            case 26
        end
        
        eph.prnID = prnID;
        eph.geo = 0;
end % switch subframeID ...

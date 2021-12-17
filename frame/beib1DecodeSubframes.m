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
function [eph,alm,subfMask] = beib1DecodeSubframes(sbfrm_num,decoded_sbfrm, eph, alm, subfMask)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function decodes subframes from nav data bits for Beidou signals
%
% Inputs:
%   sbfrm_num           - Subframe number
%   decoded_sbfrm       - Navigation bits for one subframe
%   eph                 - SV ephemeris
%   alm                 - SV almanac
%   subfMask            - Bitmask for decoded subframes
%
% Outputs:
%   eph                 - SV ephemeris
%   alm                 - SV almanac
%   subfMask            - Bitmask for decoded subframes
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% PI as defined for the Beidou system
BDPi = 3.1415926535898;

% Bitmask for decoded subframes
subfMask = bitset(subfMask,sbfrm_num);
    
switch sbfrm_num
    case 1  %%subframe ?1.
        eph.SatH1     = decoded_sbfrm(28);%%/
        eph.IODC      = bin2dec(  strcat( dec2bin(decoded_sbfrm(29:33)) )'  );
        eph.URAI      = bin2dec(  strcat( dec2bin(decoded_sbfrm(34:37)) )'  );%%/
        eph.weekNumber        = bin2dec(  strcat( dec2bin(decoded_sbfrm(38:50)) )'  );%%/
        eph.t_oc      = bin2dec(  strcat( dec2bin(decoded_sbfrm(51:67)) )'  ) * 2^3;%%/[s]
        eph.T_GD    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(68:77)) )'  )-...
            (decoded_sbfrm(68))*2^(length(decoded_sbfrm(68:77))) ) * 0.1*10^-9;%%/[s]
        eph.alpha0    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(88:95)) )'  ) -...
            (decoded_sbfrm(88))*2^(length(decoded_sbfrm(88:95))) ) * 2^(-30) ;%%/[s]; 
        eph.alpha1    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(96:103)) )'  )-...
            (decoded_sbfrm(96))*2^(length(decoded_sbfrm(96:103))) ) * 2^(-27);%%/[s/pi]; 
        eph.alpha2    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(104:111)) )'  )-...
            (decoded_sbfrm(104))*2^(length(decoded_sbfrm(104:111))) ) * 2^(-24);%%/[s/pi^2]; 
        eph.alpha3    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(112:119)) )'  )-...
            (decoded_sbfrm(88))*2^(length(decoded_sbfrm(88:95))) ) * 2^(-24);%%/[s/pi^3]; 
        eph.beta0     = (bin2dec(  strcat( dec2bin(decoded_sbfrm(120:127)) )'  )-...
            (decoded_sbfrm(120))*2^(length(decoded_sbfrm(120:127))) ) * 2^(11);%%/[s]; 
        eph.beta1     = (bin2dec(  strcat( dec2bin(decoded_sbfrm(128:135)) )'  )-...
            (decoded_sbfrm(120))*2^(length(decoded_sbfrm(120:127))) ) * 2^(14);%%/[s/pi]; 
        eph.beta2     = (bin2dec(  strcat( dec2bin(decoded_sbfrm(136:143)) )'  )-...
            (decoded_sbfrm(136))*2^(length(decoded_sbfrm(136:143))) ) * 2^(16);%%/[s/pi^2];
        eph.beta3     = (bin2dec(  strcat( dec2bin(decoded_sbfrm(144:151)) )'  )-...
            (decoded_sbfrm(144))*2^(length(decoded_sbfrm(144:151))) ) * 2^(16);%%/[s/pi^3];
        eph.a_f2        = (bin2dec(  strcat( dec2bin(decoded_sbfrm(152:162)) )'  )-...
            (decoded_sbfrm(152))*2^(length(decoded_sbfrm(152:162))) ) * 2^(-66);%%/[s/s^2];
        eph.a_f0        = (bin2dec(  strcat( dec2bin(decoded_sbfrm(163:186)) )'  )-...
            (decoded_sbfrm(163))*2^(length(decoded_sbfrm(163:186))) ) * 2^(-33);%%/[s];
        eph.a_f1        = (bin2dec(  strcat( dec2bin(decoded_sbfrm(187:208)) )'  )-...
            (decoded_sbfrm(187))*2^(length(decoded_sbfrm(187:208))) ) * 2^(-50);%%/[s/s];
        eph.IODE      = bin2dec(  strcat( dec2bin(decoded_sbfrm(209:213)) )'  );
    case 2 %%subframe ?2.
        eph.deltan    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(28:43)) )'  )-...
            (decoded_sbfrm(28))*2^(length(decoded_sbfrm(28:43))) ) * 2^(-43) * BDPi;%%/[pi/s]->[1/s]
        eph.C_uc      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(44:61)) )'  )-...
            (decoded_sbfrm(44))*2^(length(decoded_sbfrm(44:61))) ) * 2^(-31);%%/[rad]
        eph.M_0       = (bin2dec(  strcat( dec2bin(decoded_sbfrm(62:93)) )'  )-...
            (decoded_sbfrm(62))*2^(length(decoded_sbfrm(62:93))) ) * 2^(-31) * BDPi;%%/[pi]->[-]
        eph.e         = bin2dec(  strcat( dec2bin(decoded_sbfrm(94:125)) )'  ) * 2^(-33);%%/[-]
        eph.C_us      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(126:143)) )'  )-...
            (decoded_sbfrm(126))*2^(length(decoded_sbfrm(126:143))) ) * 2^(-31);%%/[rad]
        eph.C_rc      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(144:161)) )'  )-...
            (decoded_sbfrm(144))*2^(length(decoded_sbfrm(144:161))) ) * 2^(-6);%%/[m]
        eph.C_rs      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(162:179)) )'  )-...
            (decoded_sbfrm(162))*2^(length(decoded_sbfrm(162:179))) ) * 2^(-6);%%/[m]
        eph.sqrtA     = bin2dec(  strcat( dec2bin(decoded_sbfrm(180:211)) )'  ) * 2^(-19);%%/[m^(1/2)]
        eph.t_oe_msb  = bin2dec(  strcat( dec2bin(decoded_sbfrm(212:213)) )'  ) * 2^(15) * 2^(3);%%/[s]
    case 3 %%subframe ?3.
        eph.t_oe_lsb  = bin2dec(  strcat( dec2bin(decoded_sbfrm(28:42)) )'  ) * 2^(3);%%/[s]
        eph.i_0       = (bin2dec(  strcat( dec2bin(decoded_sbfrm(43:74)) )'  )-...
            (decoded_sbfrm(43))*2^(length(decoded_sbfrm(43:74))) ) * 2^(-31) * BDPi;%%/[pi]->[-]
        eph.C_ic      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(75:92)) )'  )-...
            (decoded_sbfrm(75))*2^(length(decoded_sbfrm(75:92))) ) * 2^(-31);%%/[rad]
        eph.omegaDot  = (bin2dec(  strcat( dec2bin(decoded_sbfrm(93:116)) )'  )-...
            (decoded_sbfrm(93))*2^(length(decoded_sbfrm(93:116))) ) * 2^(-43) * BDPi;%%/[pi/s]->[1/s]
        eph.C_is      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(117:134)) )'  )-...
            (decoded_sbfrm(117))*2^(length(decoded_sbfrm(117:134))) ) * 2^(-31);%%/[rad]
        eph.iDot      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(135:148)) )'  )-...
            (decoded_sbfrm(135))*2^(length(decoded_sbfrm(135:148))) ) * 2^(-43) * BDPi;%%/[pi/s]-> [1/s]
        eph.omega_0   = (bin2dec(  strcat( dec2bin(decoded_sbfrm(149:180)) )'  )-...
            (decoded_sbfrm(149))*2^(length(decoded_sbfrm(149:180))) ) * 2^(-31) * BDPi;%%/[pi]
        eph.omega     = (bin2dec(  strcat( dec2bin(decoded_sbfrm(181:212)) )'  )-...
            (decoded_sbfrm(181))*2^(length(decoded_sbfrm(181:212))) ) * 2^(-31) * BDPi;%%/[pi]
    case 4 %%subframe #4.
        page_num = bin2dec(strcat(dec2bin(decoded_sbfrm(29:35)))');
        alm.sqrtA(page_num)     = bin2dec(strcat(dec2bin(decoded_sbfrm(36:59)))') * 2^(-11);%%/[m^(1/2)];
        alm.a_f1(page_num)      = (bin2dec(strcat(dec2bin(decoded_sbfrm(60:70)))')-(decoded_sbfrm(60))*2^(length(decoded_sbfrm(60:70)))) * 2^(-38);%%/[s/s];
        alm.a_f0(page_num)      = (bin2dec(strcat(dec2bin(decoded_sbfrm(71:81)))')-(decoded_sbfrm(71))*2^(length(decoded_sbfrm(71:81)))) * 2^(-20);%%/[s];
        alm.omega_0(page_num)   = (bin2dec(strcat(dec2bin(decoded_sbfrm(82:105)))')-(decoded_sbfrm(82))*2^(length(decoded_sbfrm(82:105)))) * 2^(-23) * BDPi;%%/[pi]
        alm.e(page_num)         = bin2dec(strcat(dec2bin(decoded_sbfrm(106:122)))') * 2^(-21);%%/[-]
        alm.delta_i(page_num)   = bin2dec(strcat(dec2bin(decoded_sbfrm(123:138)))') * 2^(-19) * BDPi;%%/[pi]
        alm.t_oa(page_num)      = bin2dec(strcat(dec2bin(decoded_sbfrm(139:146)))') * 2^(12);%%/[m^(1/2)];
        alm.omegaDot(page_num)  = (bin2dec(strcat(dec2bin(decoded_sbfrm(147:163)))')-(decoded_sbfrm(147))*2^(length(decoded_sbfrm(147:163)))) * 2^(-38) * BDPi;%%/[pi/s]->[1/s]
        alm.omega(page_num)     = (bin2dec(strcat(dec2bin(decoded_sbfrm(164:187)))')-(decoded_sbfrm(164))*2^(length(decoded_sbfrm(164:187)))) * 2^(-23) * BDPi;%%/[pi]
        alm.M_0(page_num)       = (bin2dec(strcat(dec2bin(decoded_sbfrm(188:211)))')-(decoded_sbfrm(188))*2^(length(decoded_sbfrm(188:211)))) * 2^(-23) * BDPi;%%/[pi]->[-]
    case 5 %%subframe #5.
        page_num = bin2dec(strcat(dec2bin(decoded_sbfrm(29:35)))');
        subframe5_page_num = page_num; %for correct indexing when putting this decoded data into the almanac data structure
        if page_num <= 6
            alm.sqrtA(page_num+24)     = bin2dec(strcat(dec2bin(decoded_sbfrm(36:59)))') * 2^(-11);%%/[m^(1/2)];
            alm.a_f1(page_num+24)      = (bin2dec(strcat(dec2bin(decoded_sbfrm(60:70)))')-(decoded_sbfrm(60))*2^(length(decoded_sbfrm(60:70)))) * 2^(-38);%%/[s/s];
            alm.a_f0(page_num+24)      = (bin2dec(strcat(dec2bin(decoded_sbfrm(71:81)))')-(decoded_sbfrm(71))*2^(length(decoded_sbfrm(71:81)))) * 2^(-20);%%/[s];
            alm.omega_0(page_num+24)   = (bin2dec(strcat(dec2bin(decoded_sbfrm(82:105)))')-(decoded_sbfrm(82))*2^(length(decoded_sbfrm(82:105)))) * 2^(-23) * BDPi;%%/[pi]
            alm.e(page_num+24)         = bin2dec(strcat(dec2bin(decoded_sbfrm(106:122)))') * 2^(-21);%%/[-]
            alm.delta_i(page_num+24)   = bin2dec(strcat(dec2bin(decoded_sbfrm(123:138)))') * 2^(-19) * BDPi;%%/[pi]
            alm.t_oa(page_num+24)      = bin2dec(strcat(dec2bin(decoded_sbfrm(139:146)))') * 2^(12);%%/[m^(1/2)];
            alm.omegaDot(page_num+24)  = (bin2dec(strcat(dec2bin(decoded_sbfrm(147:163)))')-(decoded_sbfrm(147))*2^(length(decoded_sbfrm(147:163)))) * 2^(-38) * BDPi;%%/[pi/s]->[1/s]
            alm.omega(page_num+24)     = (bin2dec(strcat(dec2bin(decoded_sbfrm(164:187)))')-(decoded_sbfrm(164))*2^(length(decoded_sbfrm(164:187)))) * 2^(-23) * BDPi;%%/[pi]
            alm.M_0(page_num+24)       = (bin2dec(strcat(dec2bin(decoded_sbfrm(188:211)))')-(decoded_sbfrm(188))*2^(length(decoded_sbfrm(188:211)))) * 2^(-23) * BDPi;%%/[pi]->[-]
        elseif page_num == 7
            alm.Health(1,:)         = strcat(dec2bin(decoded_sbfrm(36:44)))';
            alm.Health(2,:)         = strcat(dec2bin(decoded_sbfrm(45:53)))';
            alm.Health(3,:)         = strcat(dec2bin(decoded_sbfrm(54:62)))';
            alm.Health(4,:)         = strcat(dec2bin(decoded_sbfrm(63:71)))';
            alm.Health(5,:)         = strcat(dec2bin(decoded_sbfrm(72:80)))';
            alm.Health(6,:)         = strcat(dec2bin(decoded_sbfrm(81:89)))';
            alm.Health(7,:)         = strcat(dec2bin(decoded_sbfrm(90:98)))';
            alm.Health(8,:)         = strcat(dec2bin(decoded_sbfrm(99:107)))';
            alm.Health(9,:)         = strcat(dec2bin(decoded_sbfrm(108:116)))';
            alm.Health(10,:)        = strcat(dec2bin(decoded_sbfrm(117:125)))';
            alm.Health(11,:)        = strcat(dec2bin(decoded_sbfrm(126:134)))';
            alm.Health(12,:)        = strcat(dec2bin(decoded_sbfrm(135:143)))';
            alm.Health(13,:)        = strcat(dec2bin(decoded_sbfrm(144:152)))';
            alm.Health(14,:)        = strcat(dec2bin(decoded_sbfrm(153:161)))';
            alm.Health(15,:)        = strcat(dec2bin(decoded_sbfrm(162:170)))';
            alm.Health(16,:)        = strcat(dec2bin(decoded_sbfrm(171:179)))';
            alm.Health(17,:)        = strcat(dec2bin(decoded_sbfrm(180:188)))';
            alm.Health(18,:)        = strcat(dec2bin(decoded_sbfrm(189:197)))';
            alm.Health(19,:)        = strcat(dec2bin(decoded_sbfrm(198:206)))';
        elseif page_num == 8
            alm.Health(20,:)        = strcat(dec2bin(decoded_sbfrm(36:44)))';
            alm.Health(21,:)        = strcat(dec2bin(decoded_sbfrm(45:53)))';
            alm.Health(22,:)        = strcat(dec2bin(decoded_sbfrm(54:62)))';
            alm.Health(23,:)        = strcat(dec2bin(decoded_sbfrm(63:71)))';
            alm.Health(24,:)        = strcat(dec2bin(decoded_sbfrm(72:80)))';
            alm.Health(25,:)        = strcat(dec2bin(decoded_sbfrm(81:89)))';
            alm.Health(26,:)        = strcat(dec2bin(decoded_sbfrm(90:98)))';
            alm.Health(27,:)        = strcat(dec2bin(decoded_sbfrm(99:107)))';
            alm.Health(28,:)        = strcat(dec2bin(decoded_sbfrm(108:116)))';
            alm.Health(29,:)        = strcat(dec2bin(decoded_sbfrm(117:125)))';
            alm.Health(30,:)        = strcat(dec2bin(decoded_sbfrm(126:134)))';
            alm.WNa                 = bin2dec(strcat(dec2bin(decoded_sbfrm(135:142)))');
            alm.t_oa(31)            = bin2dec(strcat(dec2bin(decoded_sbfrm(143:150)))') * 2^(12);%%/[m^(1/2)]; %putting this t_oa at position 31 because
            %aleady the first 30 positions for t_oa are filled by the usual almanac
        elseif page_num == 9
            alm.A0GPS               = (bin2dec(strcat(dec2bin(decoded_sbfrm(66:79)))')-(decoded_sbfrm(66))*2^(length(decoded_sbfrm(66:79)))) * 0.1;%%ns;
            alm.A1GPS               = (bin2dec(strcat(dec2bin(decoded_sbfrm(80:95)))')-(decoded_sbfrm(80))*2^(length(decoded_sbfrm(80:95)))) * 0.1;%%ns/s;
            alm.A0Gal               = (bin2dec(strcat(dec2bin(decoded_sbfrm(96:109)))')-(decoded_sbfrm(96))*2^(length(decoded_sbfrm(96:109)))) * 0.1;%%ns;
            alm.A1Gal               = (bin2dec(strcat(dec2bin(decoded_sbfrm(110:125)))')-(decoded_sbfrm(110))*2^(length(decoded_sbfrm(110:125)))) * 0.1;%%ns/s;
            alm.A0Glo               = (bin2dec(strcat(dec2bin(decoded_sbfrm(126:139)))')-(decoded_sbfrm(126))*2^(length(decoded_sbfrm(126:139)))) * 0.1;%%ns;
            alm.A1Glo               = (bin2dec(strcat(dec2bin(decoded_sbfrm(140:155)))')-(decoded_sbfrm(140))*2^(length(decoded_sbfrm(140:155)))) * 0.1;%%ns/s;
        elseif page_num == 10
            alm.delta_T_LS          = (bin2dec(strcat(dec2bin(decoded_sbfrm(36:43)))')-(decoded_sbfrm(36))*2^(length(decoded_sbfrm(36:43))));%%s;
            alm.delta_T_LSF         = (bin2dec(strcat(dec2bin(decoded_sbfrm(44:51)))')-(decoded_sbfrm(44))*2^(length(decoded_sbfrm(44:51))));%%s;
            alm.WN_LSF              = bin2dec(strcat(dec2bin(decoded_sbfrm(52:59)))');%%week;
            alm.A0UTC               = (bin2dec(strcat(dec2bin(decoded_sbfrm(60:91)))')-(decoded_sbfrm(60))*2^(length(decoded_sbfrm(60:91)))) * 2^(-30);%%s;
            alm.A1UTC               = (bin2dec(strcat(dec2bin(decoded_sbfrm(92:115)))')-(decoded_sbfrm(92))*2^(length(decoded_sbfrm(92:115)))) * 2^(-50);%%s/s;
            alm.DN                  = bin2dec(strcat(dec2bin(decoded_sbfrm(116:123)))');%%day;
        end %page numbers 11-24 for subframe 5 are reserved
end

if(bitand(subfMask,6) == 6)
    eph.t_oe = eph.t_oe_msb + eph.t_oe_lsb; %%Surprise from BeiDou ;)
end

% TBA Do we need these ?
% if (subframe5_page_num == 7 || subframe5_page_num == 8)
%     alm.alm_Health      = alm_Health;
% end
% if (subframe5_page_num == 8)
%     alm.alm_WNa         = alm_WNa;
% end
% if (subframe5_page_num == 9)
%     alm.alm_A0GPS       = alm_A0GPS;
%     alm.alm_A1GPS       = alm_A1GPS;
%     alm.alm_A0Gal       = alm_A0Gal;
%     alm.alm_A1Gal       = alm_A1Gal;
%     alm.alm_A0Glo       = alm_A0Glo;
%     alm.alm_A1Glo       = alm_A1Glo;
% end
% if (subframe5_page_num == 10)
%     alm.alm_delta_T_LS  = alm_delta_T_LS;
%     alm.alm_delta_T_LSF = alm_delta_T_LSF;
%     alm.alm_WN_LSF      = alm_WN_LSF;
%     alm.alm_A0UTC       = alm_A0UTC;
%     alm.alm_A1UTC       = alm_A1UTC;
%     alm.alm_DN          = alm_DN;
% end

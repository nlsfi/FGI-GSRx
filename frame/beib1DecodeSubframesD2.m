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
function [eph,ephTemp,alm,subfMask] = beib1DecodeSubframesD2(sbfrm_num,decoded_sbfrm, eph, ephTemp, alm, subfMask)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function decodes subframes from nav data bits for Beidou Geo satellites
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
%   alm         - SV almanac
%   subfMask            - Bitmask for decoded subframes
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% PI as defined in the Beidou system
BDPi = 3.1415926535898;

switch sbfrm_num
  case 1  % Subframe 1.
      pageNumber = bin2dec(strcat( dec2bin(decoded_sbfrm(28:31)) )');
      subfMask = bitset(subfMask,pageNumber);      
      switch pageNumber
          case 1
                eph.SatH1     = decoded_sbfrm(32);%%/
                eph.IODC      = bin2dec(  strcat( dec2bin(decoded_sbfrm(33:37)) )'  );
                eph.URAI      = bin2dec(  strcat( dec2bin(decoded_sbfrm(38:41)) )'  );%%/
                eph.weekNumber        = bin2dec(  strcat( dec2bin(decoded_sbfrm(42:54)) )'  );%%/
                eph.t_oc      = bin2dec(  strcat( dec2bin(decoded_sbfrm(55:71)) )'  ) * 2^3;%%/[s]
                eph.T_GD    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(72:81)) )'  )-...
                                (decoded_sbfrm(72))*2^(length(decoded_sbfrm(72:81))) ) * 0.1*10^-9;%%/[s]
          case 2                                 
                eph.alpha0    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(32:39)) )'  ) -...
                                (decoded_sbfrm(32))*2^(length(decoded_sbfrm(32:39))) );%%/[s]; % The coefficient term 2^(-30) is taken care of in the model itself
                eph.alpha1    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(40:47)) )'  )-...
                                (decoded_sbfrm(40))*2^(length(decoded_sbfrm(40:47))) );%%/[s/pi]; % The coefficient term 2^(-27) is taken care of in the model itself
                eph.alpha2    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(48:55)) )'  )-...
                                (decoded_sbfrm(48))*2^(length(decoded_sbfrm(48:55))) );%%/[s/pi^2]; % The coefficient term 2^(-24) is taken care of in the model itself
                eph.alpha3    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(56:63)) )'  )-...
                                (decoded_sbfrm(56))*2^(length(decoded_sbfrm(56:63))) );%%/[s/pi^3]; % The coefficient term 2^(-24) is taken care of in the model itself
                eph.beta0     = (bin2dec(  strcat( dec2bin(decoded_sbfrm(64:71)) )'  )-...
                                (decoded_sbfrm(64))*2^(length(decoded_sbfrm(64:71))) );%%/[s]; % The coefficient term 2^(11) is taken care of in the model itself
                eph.beta1     = (bin2dec(  strcat( dec2bin(decoded_sbfrm(72:79)) )'  )-...
                                (decoded_sbfrm(72))*2^(length(decoded_sbfrm(72:79))) );%%/[s/pi]; % The coefficient term 2^(14) is taken care of in the model itself
                eph.beta2     = (bin2dec(  strcat( dec2bin(decoded_sbfrm(80:87)) )'  )-...
                                (decoded_sbfrm(80))*2^(length(decoded_sbfrm(80:87))) );%%/[s/pi^2]; % The coefficient term 2^(16) is taken care of in the model itself
                eph.beta3     = (bin2dec(  strcat( dec2bin(decoded_sbfrm(88:95)) )'  )-...
                                (decoded_sbfrm(88))*2^(length(decoded_sbfrm(88:95))) );%%/[s/pi^3]; % The coefficient term 2^(16) is taken care of in the model itself  
          case 3                  
                eph.a_f0      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(70:93)) )'  )-...
                                (decoded_sbfrm(70))*2^(length(decoded_sbfrm(70:93))) ) * 2^(-33);%%/[s/s^2];
                ephTemp.a_f1_first_part = decoded_sbfrm(94:97); % save the bits for processing with the second part in page 4                    
          case 4
                ephTemp.a_f1_last_part = decoded_sbfrm(32:49);                    
                eph.a_f2      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(50:60)) )'  )-...
                                (decoded_sbfrm(50))*2^(length(decoded_sbfrm(50:60))) ) * 2^(-66);%%/[s/s^2];
                eph.IODE      = bin2dec(  strcat( dec2bin(decoded_sbfrm(61:65)) )'  );
                eph.deltan    = (bin2dec(  strcat( dec2bin(decoded_sbfrm(66:81)) )'  )-...
                            (decoded_sbfrm(66))*2^(length(decoded_sbfrm(66:81))) ) * 2^(-43) * BDPi;%%/[pi/s]->[1/s]        
                ephTemp.C_uc_first_part  = decoded_sbfrm(82:95);
          case 5
                ephTemp.C_uc_last_part  = decoded_sbfrm(32:35);                      
                eph.M_0       = (bin2dec(  strcat( dec2bin(decoded_sbfrm(36:67)) )'  )-...
                            (decoded_sbfrm(36))*2^(length(decoded_sbfrm(36:67))) ) * 2^(-31) * BDPi;%%/[pi]->[-]        
                eph.C_us      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(68:85)) )'  )-...
                            (decoded_sbfrm(68))*2^(length(decoded_sbfrm(68:85))) ) * 2^(-31);%%/[rad]
                ephTemp.e_first_part = decoded_sbfrm(86:95);
          case 6
                ephTemp.e_last_part = decoded_sbfrm(32:53);                    
                eph.sqrtA     = bin2dec(  strcat( dec2bin(decoded_sbfrm(54:85)) )'  ) * 2^(-19);%%/[m^(1/2)]
                ephTemp.C_ic_first_part = decoded_sbfrm(86:95);                               
          case 7
                ephTemp.C_ic_last_part = decoded_sbfrm(32:39);                    
                eph.C_is      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(40:57)) )'  )-...
                            (decoded_sbfrm(40))*2^(length(decoded_sbfrm(40:57))) ) * 2^(-31);%%/[rad]  
                eph.t_oe_msb  = bin2dec(  strcat( dec2bin(decoded_sbfrm(58:59)) )'  ) * 2^(15) * 2^(3);%%/[s]
                eph.t_oe_lsb  = bin2dec(  strcat( dec2bin(decoded_sbfrm(60:74)) )'  ) * 2^(3);%%/[s]      
                ephTemp.i_0_first_part = decoded_sbfrm(75:95);    
                eph.t_oe = eph.t_oe_msb + eph.t_oe_lsb; %%Surprise from BeiDou ;)                
          case 8
                ephTemp.i_0_last_part = decoded_sbfrm(32:42);                                  
                eph.C_rc      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(43:60)) )'  )-...
                            (decoded_sbfrm(43))*2^(length(decoded_sbfrm(43:60))) ) * 2^(-6);%%/[m]                            
                eph.C_rs      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(61:78)) )'  )-...
                            (decoded_sbfrm(61))*2^(length(decoded_sbfrm(61:78))) ) * 2^(-6);%%/[m]                    
                ephTemp.omegaDot_first_part  = decoded_sbfrm(79:97);
          case 9
                ephTemp.omegaDot_last_part = decoded_sbfrm(32:36);                  	
                eph.omega_0   = (bin2dec(  strcat( dec2bin(decoded_sbfrm(37:68)) )'  )-...
                            (decoded_sbfrm(37))*2^(length(decoded_sbfrm(37:68))) ) * 2^(-31) * BDPi;%%/[pi]                    
                ephTemp.omega_first_part = decoded_sbfrm(69:95);        
          case 10
                ephTemp.omega_last_part = decoded_sbfrm(32:36);                    
                eph.iDot      = (bin2dec(  strcat( dec2bin(decoded_sbfrm(37:50)) )'  )-...
                            (decoded_sbfrm(37))*2^(length(decoded_sbfrm(37:50))) ) * 2^(-43) * BDPi;%%/[pi/s]-> [1/s]                  
      end

  case 2 % Subframe #2.
      ;
  case 3 % Subframe #3.
      ;
  case 4 % Subframe #4.
      ;
  case 5 % Subframe #5. 
      ;
end

if(bitand(subfMask,1023) == 1023)
    ephTemp.a_f1_all_parts  = [ephTemp.a_f1_first_part ephTemp.a_f1_last_part];
    eph.a_f1            = (bin2dec(  strcat( dec2bin(ephTemp.a_f1_all_parts))'  )-...
                        (ephTemp.a_f1_all_parts(1))*2^(length(ephTemp.a_f1_all_parts)) ) * 2^(-50);%%/[s/s];
    ephTemp.C_uc_all_parts  = [ephTemp.C_uc_first_part ephTemp.C_uc_last_part];
    eph.C_uc            = (bin2dec(  strcat( dec2bin(ephTemp.C_uc_all_parts) )'  )-...
                    (ephTemp.C_uc_all_parts(1))*2^(length(ephTemp.C_uc_all_parts)) ) * 2^(-31);%%/[rad] 
    ephTemp.e_all_parts     = [ephTemp.e_first_part ephTemp.e_last_part];
    eph.e               = bin2dec(  strcat( dec2bin(ephTemp.e_all_parts) )'  ) * 2^(-33);%%/[-]
    ephTemp.C_ic_all_parts  = [ephTemp.C_ic_first_part ephTemp.C_ic_last_part];
    eph.C_ic            = (bin2dec(  strcat( dec2bin(ephTemp.C_ic_all_parts) )'  )-...
                    (ephTemp.C_ic_all_parts(1))*2^(length(ephTemp.C_ic_all_parts)) ) * 2^(-31);%%/[rad]
    ephTemp.i_0_all_parts   = [ephTemp.i_0_first_part ephTemp.i_0_last_part];
    eph.i_0             = (bin2dec(  strcat( dec2bin(ephTemp.i_0_all_parts) )'  )-...
                    (ephTemp.i_0_all_parts(1))*2^(length(ephTemp.i_0_all_parts)) ) * 2^(-31) * BDPi;%%/[pi]->[-] 
    ephTemp.omegaDot_all_parts = [ephTemp.omegaDot_first_part ephTemp.omegaDot_last_part];
    eph.omegaDot        = (bin2dec(  strcat( dec2bin(ephTemp.omegaDot_all_parts) )'  )-...
                    (ephTemp.omegaDot_all_parts(1))*2^(length(ephTemp.omegaDot_all_parts)) ) * 2^(-43) * BDPi;%%/[pi/s]->[1/s]
    ephTemp.omega_all_parts = [ephTemp.omega_first_part ephTemp.omega_last_part];
    eph.omega           = (bin2dec(  strcat( dec2bin(ephTemp.omega_all_parts) )'  )-...
                    (ephTemp.omega_all_parts(1))*2^(length(ephTemp.omega_all_parts)) ) * 2^(-31) * BDPi;%%/[pi]                
end



  
  
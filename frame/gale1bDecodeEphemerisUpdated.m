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
function [eph, obsCh] = gale1bDecodeEphemerisUpdated(obsCh, I_P, prn, signalSettings, const)
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
obsCh.bEphOk = false;
eph = [];

signal = 'gale1b';

% Pi used in the Galileo coordinate system
galileoPi = const.PI;

% Extract nav bits from track channel data 
%navBitsSamples = I_P(4 * obsCh.firstSubFrame : 4 : 4 * (obsCh.firstSubFrame + 250*2*20 -1))';
%NEW%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%OSNMA
%Initialization of long data for OSNMA 
%if((signalSettings.osnma==1)||(signalSettings.enabledongdata==1))
    %x=floor((((length(I_P)-150000)/4)+obsCh.firstSubFrame+1)/500);
    x=floor((((length(I_P))/4)-obsCh.firstSubFrame+1)/500);
    navBitsSamples = I_P(4 * obsCh.firstSubFrame : 4 : 4 * (obsCh.firstSubFrame + 250*2*x -1))';
%else
    navBitsSamples = I_P(4 * obsCh.firstSubFrame : 4 : 4 * (obsCh.firstSubFrame + 250*2*20 -1))';
%end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Now threshold the output and convert it to -1 and +1 
navBits( navBitsSamples > 0)  =  1;
navBits( navBitsSamples <= 0) = -1;

% Calculate cross correlation between nav bits and preamble
corrValPreamble = calcCrossCorrelation(navBits,signalSettings.preamble);

% Find peaks in CC values
indPositiveCorrelation = find(corrValPreamble>=10);
indNegativeCorrelation = find(corrValPreamble<=-10);

if length(indPositiveCorrelation) > length(indNegativeCorrelation)
    % We have more positive than negative matches, i.e. bits are NOT
    % inverted ! Only change -1:s to 0:s.
    navBits( find(navBits==-1) ) = 0;
else
    % We have more negative than positive matches, i.e. bits are most
    % probably inverted. Flip bits and change -1:s.
    navBits( find(navBits==1) ) = 0;
    navBits( find(navBits==-1) ) = 1;        
end

% Decode from symbols to the navigation bits (250 symbols -> 120 bits)
[decodedNavBits] = gale1bDecoderDeinterleaver(navBits,signal);

% Convert from decimal to binary 
% The function ephemeris expects input in binary form. In Matlab it is
% a string array containing only "0" and "1" characters.
bits = dec2bin(decodedNavBits');

% Check if the parameters are strings 
if ~ischar(bits)
    error('The parameter BITS must be a character array!');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%OSNMA
%%Assign NaN to eph
% Word type 0   
eph.weekNumber = NaN;

    
% Word type 1
eph.IODC = NaN;
eph.IODE_sf2 = NaN;
eph.M_0 = NaN;
eph.e = NaN;
eph.sqrtA = NaN;
eph.t_oe = NaN;
eph.IODE_sf3 = NaN;

    
% Word type 2
eph.omega_0 = NaN;
eph.i_0 = NaN;
eph.omega = NaN;
eph.iDot = NaN;

    
% Word type 3
eph.C_rs = NaN;
eph.deltan = NaN;
eph.C_uc = NaN;
eph.C_us = NaN;
eph.C_rc = NaN;
eph.omegaDot = NaN;
eph.SISA = NaN;
  
% Word type 4
eph.t_oc = NaN;
eph.a_f2 = NaN;
eph.a_f1 = NaN;
eph.a_f0 = NaN;
eph.C_ic = NaN;
eph.C_is = NaN;
    
% Word type 5
eph.ai0_5 = NaN;
eph.ai1_5 = NaN;
eph.ai2_5 = NaN;
eph.Region1_flag_5 = NaN;
eph.Region2_flag_5 = NaN;
eph.Region3_flag_5 = NaN;
eph.Region4_flag_5 = NaN;
eph.Region5_flag_5 = NaN;
eph.T_GD = NaN;
eph.geo = NaN;
eph.E1B_DVS = NaN;
eph.E1B_HS = NaN;
   
% GST-UTC conversion parameters
eph.A0 = NaN;
eph.A1 = NaN;    
eph.Delta_tLS = NaN;
eph.t_ot = NaN; 
eph.WN_ot = NaN;
eph.WN_LSF = NaN;
eph.D = NaN;
eph.Delta_tLSF = NaN;
eph.TOW_6 = NaN;   
eph.A_0G = NaN;
eph.A_1G = NaN;
eph.t_0G = NaN;
eph.WN_0G = NaN;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % %if((signalSettings.osnma==1)||(signalSettings.enabledongdata==1))
 % if(signalSettings.osnma==1)
 %    TOW_OS = NaN;
 %    % Word type 0
 %    %WN_0;
 % 
 %    % Word type 1
 %    IOD_nav_1 = NaN;
 %    IOD_nav_1 = NaN;
 %    M0_1 = NaN;
 %    e_1 = NaN;
 %    A_1 = NaN;
 %    t0e_1 = NaN;
 %    IOD_nav_1 = NaN;
 % 
 %    % Word type 2
 %    OMEGA_0_2 = NaN;
 %    i_0_2 = NaN;
 %    omega_2 = NaN;
 %    iDot_2 = NaN;
 % 
 %    % Word type 3
 %    C_rs_3 = NaN;
 %    delta_n_3 = NaN;
 %    C_uc_3 = NaN;
 %    C_us_3 = NaN;
 %    C_rc_3 = NaN;
 %    OMEGA_dot_3 = NaN;
 %    SISA_3 = NaN;
 % 
 %    % Word type 4
 %    t0c_4 = NaN;
 %    af2_4 = NaN;
 %    af1_4 = NaN;
 %    af0_4 = NaN;
 %    C_ic_4 = NaN;
 %    C_is_4 = NaN;
 % 
 %    % Word type 5
 %    ai0_5 = NaN;
 %    ai1_5 = NaN;
 %    ai2_5 = NaN;
 %    Region1_flag_5 = NaN;
 %    Region2_flag_5 = NaN;
 %    Region3_flag_5 = NaN;
 %    Region4_flag_5 = NaN;
 %    Region5_flag_5 = NaN;    
 %    BGD_E1E5b_5 = NaN;
 % 
 %    E1B_DVS_5 = NaN;
 %    E1B_HS_5 = NaN;
 % 
 %    % GST-UTC conversion parameters
 %    A0_6 = NaN;
 %    A1_6 = NaN;    
 %    Delta_tLS_6 = NaN;
 %    t_ot_6 = NaN; 
 %    WN_ot_6 = NaN;
 %    WN_LSF_6 = NaN;
 %    DN_6 = NaN;
 %    Delta_tLSF_6 = NaN;
 %    TOW_6 = NaN;   
 %    A_0G = NaN;
 %    A_1G = NaN;
 %    t_0G = NaN;
 %    WN_0G = NaN;
 % end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if the page starts with even/odd == 0, then ignore the first 120 bits of
% the page: it will then always start with even/odd = 1, which is needed to
% arrange the bits into word

evenOddTypeBeginningPage = bin2dec(bits(1));
pageTypeBeginningPage = bin2dec(bits(2));
if evenOddTypeBeginningPage == 1 && pageTypeBeginningPage == 0
    bits = bits(121:end);
    shifttow = 0;
else
    shifttow = 1;
end

foundPages = 0;
%NEW%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%OSNMA
%Initialization of OSNMA parameters
%if((signalSettings.osnma==1)||(signalSettings.enabledongdata==1))
if(signalSettings.osnma==1)
    hk_Ind = 0;
    mk_Ind = 0;
    HKROOT = [];
    MACK = [];
    WN_0 = [];
    TOW_NMA= [];
    TOW_OS =[];
    nav_counter=0;
    %navHex = NaN;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
eph_counter=0;
for i=1:(length(bits)/240)

    bitsArrangedPageWise = bits((i-1)*240+1: i*240);
    % CRC check of bits
    chk(i) = gale1bCrcCheck(bitsArrangedPageWise);
       
    % TBA: Wait to implement this since we need tow for the
    if(chk ~= 0) 
        fprintf('CRC check fails!');
        obsCh.bEphOk = false;
        break;
    end
    
    % Arrange bits
    evenOddType = bin2dec(bitsArrangedPageWise(1));
    pageType(i) = bin2dec(bitsArrangedPageWise(2));
    if evenOddType == 0 && pageType(i) == 0 % type odd
        %Arrange the bits into a Word of length 128 bits (112 + 16)        
        bitsArrangedWordWise(1:112) = bitsArrangedPageWise(3:3+111);
        bitsArrangedWordWise(113:128) = bitsArrangedPageWise(120+3:120+3+15);
  %NEW%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %OSNMA
     %if((signalSettings.osnma==1)||(signalSettings.enabledongdata==1))
     if(signalSettings.osnma==1)
         if (~isempty (WN_0))
                week_OSNMA (i)= WN_0;
                if (~isempty (TOW_NMA))
                    if isempty(TOW_OS)
                        TOW_OS = TOW_NMA;
                    end
                   TOW_OS = TOW_OS+2;
                   nav_counter=nav_counter+1; 
                   navHex(nav_counter,4) = string(dec2hex(bin2dec(reshape(bitsArrangedPageWise,4,[]).')).');
                   navHex(nav_counter,1) = prn;
                   navHex(nav_counter,3) = TOW_OS;
                   navHex(nav_counter,2) = WN_0;
                   
                end
         end
     end
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        wordType(i,:) = bin2dec(bitsArrangedWordWise(1:6));
    else
        wordType(i,:) = 7; % This is a hack. Othervise we will get funny page numbers. To be checked. SS
    end
    
    % Decode data words
    switch wordType(i,:) 
        case 0 % Word Type 0
            time =  bin2dec(bitsArrangedWordWise(7:8));
            if time == 2
                WN_0 = bin2dec(bitsArrangedWordWise(97:108));
                TOW_0 = bin2dec(bitsArrangedWordWise(109:128));
%NEW%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%OSNMA
    if(signalSettings.osnma==1)
                    TOW_NMA= TOW_0-1;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
            else
                fprintf('No valid WN & TOW');
            end
            foundPages = bitset(foundPages,1);
        case 1 % Word Type 1
            IOD_nav_1 = bin2dec(bitsArrangedWordWise(7:16));
            t0e_1 = bin2dec(bitsArrangedWordWise(17:30)) * 60;
            M0_1 = twosComp2dec(bitsArrangedWordWise(31:62)) * 2^(-31) * galileoPi;            
            e_1 = bin2dec(bitsArrangedWordWise(63:94)) * 2^(-33);
            A_1 = bin2dec(bitsArrangedWordWise(95:126)) * 2^(-19);
            foundPages = bitset(foundPages,2);
        case 2 % Word Type 2
            IOD_nav_2 = bin2dec(bitsArrangedWordWise(7:16));
            OMEGA_0_2 = twosComp2dec(bitsArrangedWordWise(17:48)) * 2^(-31) * galileoPi;
            i_0_2 = twosComp2dec(bitsArrangedWordWise(49:80)) * 2^(-31) * galileoPi;
            omega_2 = twosComp2dec(bitsArrangedWordWise(81:112)) * 2^(-31) * galileoPi;
            iDot_2 = twosComp2dec(bitsArrangedWordWise(113:126)) * 2^(-43) * galileoPi;
            foundPages = bitset(foundPages,3);
        case 3 % Word Type 3
            IOD_nav_3 = bin2dec(bitsArrangedWordWise(7:16));
            OMEGA_dot_3 = twosComp2dec(bitsArrangedWordWise(17:40)) * 2^(-43) * galileoPi;
            delta_n_3 = twosComp2dec(bitsArrangedWordWise(41:56)) * 2^(-43) * galileoPi;
            C_uc_3 = twosComp2dec(bitsArrangedWordWise(57:72)) * 2^(-29);
            C_us_3 = twosComp2dec(bitsArrangedWordWise(73:88)) * 2^(-29);
            C_rc_3 = twosComp2dec(bitsArrangedWordWise(89:104))* 2^(-5);
            C_rs_3 = twosComp2dec(bitsArrangedWordWise(105:120))* 2^(-5);
            SISA_3 = bin2dec(bitsArrangedWordWise(121:128));
            foundPages = bitset(foundPages,4);
        case 4 % Word Type 4
            IOD_nav_4 = bin2dec(bitsArrangedWordWise(7:16));
            SV_ID_4 = bin2dec(bitsArrangedWordWise(17:22));
            C_ic_4 = twosComp2dec(bitsArrangedWordWise(23:38))*2^(-29);
            C_is_4 = twosComp2dec(bitsArrangedWordWise(39:54))*2^(-29);
            t0c_4 = bin2dec(bitsArrangedWordWise(55:68)) * 60;
            af0_4 = twosComp2dec(bitsArrangedWordWise(69:99)) * 2^(-34);
            af1_4 = twosComp2dec(bitsArrangedWordWise(100:120)) * 2^(-46);
            af2_4 = twosComp2dec(bitsArrangedWordWise(121:126)) * 2^(-59);
            foundPages = bitset(foundPages,5);
        case 5 % Word Type 5
            % TBA Require revision from ICD
            ai0_5 = bin2dec(bitsArrangedWordWise(7:17))* 2^(-2);
            ai1_5 = twosComp2dec(bitsArrangedWordWise(18:28))* 2^(-8);
            ai2_5 = twosComp2dec(bitsArrangedWordWise(29:42))* 2^(-15);
            Region1_flag_5 = bin2dec(bitsArrangedWordWise(43));
            Region2_flag_5 = bin2dec(bitsArrangedWordWise(44));
            Region3_flag_5 = bin2dec(bitsArrangedWordWise(45));
            Region4_flag_5 = bin2dec(bitsArrangedWordWise(46));
            Region5_flag_5 = bin2dec(bitsArrangedWordWise(47));
            BGD_E1E5a_5 = twosComp2dec(bitsArrangedWordWise(48:57)) * 2^(-32);
            BGD_E1E5b_5 = twosComp2dec(bitsArrangedWordWise(58:67)) * 2^(-32);
            E5b_HS_5 = bin2dec(bitsArrangedWordWise(68:69));
            E1B_HS_5 = bin2dec(bitsArrangedWordWise(70:71));
            E5b_DVS_5 = bin2dec(bitsArrangedWordWise(72));
            E1B_DVS_5 = bin2dec(bitsArrangedWordWise(73));
            WN_5 = bin2dec(bitsArrangedWordWise(74:85));
            TOW_5 = bin2dec(bitsArrangedWordWise(86:105));
            ind_TOW_5 = i;
            foundPages = bitset(foundPages,6);
        case 6 % Word Type 6: GST-UTC conversion parameters
            % Require revision from ICD
            A0_6 = bin2dec(bitsArrangedWordWise(7:38));
            A1_6 = bin2dec(bitsArrangedWordWise(39:62));
            Delta_tLS_6 = bin2dec(bitsArrangedWordWise(63:70));
            t_ot_6 = bin2dec(bitsArrangedWordWise(71:78)); 
            WN_ot_6 = bin2dec(bitsArrangedWordWise(79:86));
            WN_LSF_6 = bin2dec(bitsArrangedWordWise(87:94));
            DN_6 = bin2dec(bitsArrangedWordWise(95:97));
            Delta_tLSF_6 = bin2dec(bitsArrangedWordWise(98:105));
            TOW_6 = bin2dec(bitsArrangedWordWise(106:125));
            foundPages = bitset(foundPages,7);            
        case 7
            ;
        case 8
            ;
        case 9
            ;
        case 10
            % GPS-Galileo time comversion parameters
            A_0G = bin2dec(bitsArrangedWordWise(87:102)) * 2^(-35);            
            A_1G = bin2dec(bitsArrangedWordWise(103:114)) * 2^(-51);            
            t_0G = bin2dec(bitsArrangedWordWise(115:122)) * 3600;            
            WN_0G = bin2dec(bitsArrangedWordWise(123:128));            
            foundPages = bitset(foundPages,11);  
         case 16 %Reduced Clock and Ephemeris Data (CED) parameters
            ;
            % delta_Ared = bin2dec(bitsArrangedWordWise(7:11));
            % e_xred = bin2dec(bitsArrangedWordWise(12:24));
            % e_yred = bin2dec(bitsArrangedWordWise(25:37));
            % delta_i_0_red = bin2dec(bitsArrangedWordWise(38:54));
            % omega_0_red = bin2dec(bitsArrangedWordWise(55:77));
            % delta_0_red = bin2dec(bitsArrangedWordWise(78:100));
            % af0_red = bin2dec(bitsArrangedWordWise(101:122));
            % af1_red = bin2dec(bitsArrangedWordWise(120:128));
        case 17 %FEC2 Reed-Solomon for Clock and Ephemeris Data (CED)
            ;
            % FEC2_17_1 = bin2dec(bitsArrangedWordWise(7:14));
            % LSB_17 = bin2dec(bitsArrangedWordWise(15:16));
            % FEC2_17_2 = bin2dec(bitsArrangedWordWise(17:128));   %large number and needs further analysis of how to convert to dec
        case 18 %FEC2 Reed-Solomon for Clock and Ephemeris Data (CED)
            ;
            % FEC2_18_1 = bin2dec(bitsArrangedWordWise(7:14));
            % LSB_18 = bin2dec(bitsArrangedWordWise(15:16));
            % FEC2_18_2 = bin2dec(bitsArrangedWordWise(17:128)); %large number and needs further analysis of how to convert to dec
        case 19 %FEC2 Reed-Solomon for Clock and Ephemeris Data (CED)
            ;
            % FEC2_19_1 = bin2dec(bitsArrangedWordWise(7:14));
            % LSB_19 = bin2dec(bitsArrangedWordWise(15:16));
            % FEC2_19_2 = bin2dec(bitsArrangedWordWise(17:128)); %large number and needs further analysis of how to convert to dec
        case 20 %FEC2 Reed-Solomon for Clock and Ephemeris Data (CED)
            ;
            % FEC2_20_1 = bin2dec(bitsArrangedWordWise(7:14));
            % LSB_20 = bin2dec(bitsArrangedWordWise(15:16));
            % FEC2_20_2 = bin2dec(bitsArrangedWordWise(17:128)); %large number and needs further analysis of how to convert to dec
        case 63 % Dummy data word: Type 63
            ;
        otherwise
            fprintf('Wrong Word Number! Word type: %d. Check CRC!\n',wordType(i));
    end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(signalSettings.osnma==1)
%if((signalSettings.osnma==1)||(signalSettings.enabledongdata==1))
        if(~isempty (WN_0))
            eph_counter=eph_counter+1;
            if(eph_counter==1)
                eph1(eph_counter)=eph;
            else
                eph1(eph_counter)=eph1(eph_counter-1);
            end
            
            
            if(WN_0)
                eph1(eph_counter).weekNumber = WN_0;
            end
        
            if(TOW_OS)
                eph1(eph_counter).TOW = TOW_OS;
            end
            % Word type 0
            if(WN_0)
                eph1(eph_counter).weekNumber1 = WN_0;
            end
            % Word type 1
            if(~isnan(IOD_nav_1))
                eph1(eph_counter).IODC = IOD_nav_1;
            end
            if(~isnan(IOD_nav_1))
                eph1(eph_counter).IODE_sf2 = IOD_nav_1;
            end
            if(~isnan(M0_1))
                eph1(eph_counter).M_0 = M0_1;
            end
            if(~isnan(e_1))
               eph1(eph_counter).e = e_1;
            end
            if(~isnan(A_1))
               eph1(eph_counter).sqrtA = A_1;
            end
            if(~isnan(t0e_1))
               eph1(eph_counter).t_oe = t0e_1;
            end
            if(~isnan(IOD_nav_1))
               eph1(eph_counter).IODE_sf3 = IOD_nav_1;
            end
        
            % Word type 2
            if(~isnan(OMEGA_0_2))
                eph1(eph_counter).omega_0 = OMEGA_0_2;
            end
            if(~isnan(i_0_2))
                eph1(eph_counter).i_0 = i_0_2;
            end
            if(~isnan(omega_2))
                eph1(eph_counter).omega = omega_2;
            end
            if(~isnan(iDot_2))
                eph1(eph_counter).iDot = iDot_2;
            end
        
            % Word type 3
            if(~isnan(C_rs_3))
                eph1(eph_counter).C_rs = C_rs_3;
            end
            if(~isnan(delta_n_3))
                eph1(eph_counter).deltan = delta_n_3;
            end
            if(~isnan(C_uc_3))
                eph1(eph_counter).C_uc = C_uc_3;
            end
            if(~isnan(C_us_3))
                eph1(eph_counter).C_us = C_us_3;
            end
            if(~isnan(C_rc_3))
                eph1(eph_counter).C_rc = C_rc_3;
            end
            if(~isnan(OMEGA_dot_3))
                eph1(eph_counter).omegaDot = OMEGA_dot_3;
            end
            if(~isnan(SISA_3))
                eph1(eph_counter).SISA = SISA_3;
            end
        
            % Word type 4
            if(~isnan(t0c_4))
                eph1(eph_counter).t_oc = t0c_4;
            end
            if(~isnan(af2_4))
                eph1(eph_counter).a_f2 = af2_4;
            end
            if(~isnan(af1_4))
                eph1(eph_counter).a_f1 = af1_4;
                end
            if(~isnan(af0_4))
                eph1(eph_counter).a_f0 = af0_4;
                end
            if(~isnan(C_ic_4))
                eph1(eph_counter).C_ic = C_ic_4;
                end
            if(~isnan(C_is_4))
                eph1(eph_counter).C_is = C_is_4;
            end
        
            % Word type 5
            if(~isnan(ai0_5))
                eph1(eph_counter).ai0_5 = ai0_5;
            end
            if(~isnan(ai1_5))
                eph1(eph_counter).ai1_5 = ai1_5;
            end
            if(~isnan(ai2_5))
                eph1(eph_counter).ai2_5 = ai2_5;
            end
            if(~isnan(Region1_flag_5))
                eph1(eph_counter).Region1_flag_5 = Region1_flag_5;
            end
            if(~isnan(Region2_flag_5))
                eph1(eph_counter).Region2_flag_5 = Region2_flag_5;
            end
            if(~isnan(Region3_flag_5))
                eph1(eph_counter).Region3_flag_5 = Region3_flag_5;
            end
            if(~isnan(Region4_flag_5))
                eph1(eph_counter).Region4_flag_5 = Region4_flag_5;
            end
            if(~isnan(Region5_flag_5))
                eph1(eph_counter).Region5_flag_5 = Region5_flag_5;    
            end
            if(~isnan(BGD_E1E5b_5))
                eph1(eph_counter).T_GD = BGD_E1E5b_5;
            end
            
            eph1(eph_counter).geo = false;
                    
            if(~isnan(E1B_DVS_5))
                eph1(eph_counter).E1B_DVS = E1B_DVS_5;
            end
            if(~isnan(E1B_HS_5))
                eph1(eph_counter).E1B_HS = E1B_HS_5;
            end
        
        
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % GST-UTC conversion parameters
                if(~isnan(A0_6))
                    eph1(eph_counter).A0 = A0_6;
                end
                
                if(~isnan(A1_6))
                    eph1(eph_counter).A1 = A1_6;
                end
        
                if(~isnan(Delta_tLS_6))
                    eph1(eph_counter).Delta_tLS = Delta_tLS_6;
                end
                
                if(~isnan(t_ot_6))
                    eph1(eph_counter).t_ot = t_ot_6;
                end
                
                if(~isnan(WN_ot_6))
                    eph1(eph_counter).WN_ot = WN_ot_6;
                end
                
                if(~isnan(WN_LSF_6))
                    eph1(eph_counter).WN_LSF = WN_LSF_6;
                end
                
                if(~isnan(DN_6))
                    eph1(eph_counter).D = DN_6;
                end
                
                if(~isnan(Delta_tLSF_6))
                    eph1(eph_counter).Delta_tLSF = Delta_tLSF_6;
                end
                
                if(~isnan(TOW_6))
                    eph1(eph_counter).TOW_6 = TOW_6;
                end
                
                % Word type 10
                % GPS to Galileo time conversion parameters
                if(~isnan(A_0G))
                    eph1(eph_counter).A_0G = A_0G;
                end
                
                if(~isnan(A_1G))
                    eph1(eph_counter).A_1G = A_1G;
                end
                
                if(~isnan(t_0G))
                    eph1(eph_counter).t_0G = t_0G;
                end
                
                if(~isnan(WN_0G))
                    eph1(eph_counter).WN_0G = WN_0G;
                end
        
                %OSNMA
                if(signalSettings.osnma==1)
                    eph1(eph_counter).HKROOT=HKROOT;
                    eph1(eph_counter).MACK=MACK;

                    if(nav_counter>1)
                        eph1(eph_counter).osnmaHEX = navHex(nav_counter, :);
                    else
                        eph1(eph_counter).osnmaHEX = [0 0 0 0];
                    end
                end
        end
       
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

obsCh.bEphOk = false;
eph = [];
%NEW%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%OSNMA
if(signalSettings.osnma==1)
    if (~isempty (WN_0))
        eph.HKROOT=HKROOT;
        eph.MACK=MACK;
        eph.osnmaHEX = navHex(2:end, :);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% Let's also decode into same format as for GPS.
if(bitand(foundPages,63) == 63)
    % Word type 0
    eph.weekNumber = WN_0;

    % Word type 1
    eph.IODC = IOD_nav_1;
    eph.IODE_sf2 = IOD_nav_1;
    eph.M_0 = M0_1;
    eph.e = e_1;
    eph.sqrtA = A_1;
    eph.t_oe = t0e_1;
    eph.IODE_sf3 = IOD_nav_1;

    % Word type 2
    eph.omega_0 = OMEGA_0_2;
    eph.i_0 = i_0_2;
    eph.omega = omega_2;
    eph.iDot = iDot_2;

    % Word type 3
    eph.C_rs = C_rs_3;
    eph.deltan = delta_n_3;
    eph.C_uc = C_uc_3;
    eph.C_us = C_us_3;
    eph.C_rc = C_rc_3;
    eph.omegaDot = OMEGA_dot_3;
    eph.SISA = SISA_3;

    % Word type 4
    eph.t_oc = t0c_4;
    eph.a_f2 = af2_4;
    eph.a_f1 = af1_4;
    eph.a_f0 = af0_4;
    eph.C_ic = C_ic_4;
    eph.C_is = C_is_4;

    % Word type 5
    eph.ai0_5 = ai0_5;
    eph.ai1_5 = ai1_5;
    eph.ai2_5 = ai2_5;
    eph.Region1_flag_5 = Region1_flag_5;
    eph.Region2_flag_5 = Region2_flag_5;
    eph.Region3_flag_5 = Region3_flag_5;
    eph.Region4_flag_5 = Region4_flag_5;
    eph.Region5_flag_5 = Region5_flag_5;    
    eph.T_GD = BGD_E1E5b_5;
    eph.geo = false;
    eph.E1B_DVS = E1B_DVS_5;
    eph.E1B_HS = E1B_HS_5;
    % TOW_5 is from the last decoded wordtype = 5.
    % The index tells us in which word this was.
    % Each word corresponds to 2 seconds in TOW.
    % If, for example we decoded TOW_5 in word 16 that TOW points to the
    % beginning of that WORD and we need to subtract 15 x 2 sec to get the TOW
    % at the beginning of the bitbuffer.
    % Also we need to subtract one sec since our data starts with odd page and
    % frames starts with even page
    TOW = TOW_5 - (2*(ind_TOW_5-1)) - 1 +  shifttow;
    
    obsCh.bEphOk = true;
    obsCh.tow = TOW;    
end

if(bitand(foundPages,64) == 64)
    % GST-UTC conversion parameters
    eph.A0 = A0_6;
    eph.A1 = A1_6;
    eph.Delta_tLS = Delta_tLS_6;
    eph.t_ot = t_ot_6; 
    eph.WN_ot = WN_ot_6;
    eph.WN_LSF = WN_LSF_6;
    eph.D = DN_6;
    eph.Delta_tLSF = Delta_tLSF_6;
    eph.TOW_6 = TOW_6;    
end

if(bitand(foundPages,1024) == 1024)
    % Word type 10
    % GPS to Galileo time conversion parameters
    eph.A_0G = A_0G;
    eph.A_1G = A_1G;
    eph.t_0G = t_0G;
    eph.WN_0G = WN_0G;
end

% Print status
if(obsCh.bEphOk == true)
    disp(['   Ephemeris for ', obsCh.signal ,' prn ', ...
        int2str(prn),' found.'])          
    %eph = eph1;
else
    disp(['   Ephemeris for ', obsCh.signal ,' prn ', ...
        int2str(prn),' is NOT found.'])  

    % Word type 0
    eph.weekNumber = 0;

    % Word type 1
    eph.IODC = 0;
    eph.IODE_sf2 = 0;
    eph.M_0 = 0;
    eph.e = 0;
    eph.sqrtA = 0;
    eph.t_oe = 0;
    eph.IODE_sf3 = 0;

    % Word type 2
    eph.omega_0 = 0;
    eph.i_0 = 0;
    eph.omega = 0;
    eph.iDot = 0;

    % Word type 3
    eph.C_rs = 0;
    eph.deltan = 0;
    eph.C_uc = 0;
    eph.C_us = 0;
    eph.C_rc = 0;
    eph.omegaDot = 0;
    eph.SISA = 0;

    % Word type 4
    eph.t_oc = 0;
    eph.a_f2 = 0;
    eph.a_f1 = 0;
    eph.a_f0 = 0;
    eph.C_ic = 0;
    eph.C_is = 0;

    % Word type 5
    eph.ai0_5 = 0;
    eph.ai1_5 = 0;
    eph.ai2_5 = 0;
    eph.Region1_flag_5 = 0;
    eph.Region2_flag_5 = 0;
    eph.Region3_flag_5 = 0;
    eph.Region4_flag_5 = 0;
    eph.Region5_flag_5 = 0;    
    eph.T_GD = 0;
    eph.geo = false;
    eph.E1B_DVS = 0;
    eph.E1B_HS = 0;

    % GST-UTC conversion parameters
    eph.A0 = 0;
    eph.A1 = 0;
    eph.Delta_tLS = 0;
    eph.t_ot = 0; 
    eph.WN_ot = 0;
    eph.WN_LSF = 0;
    eph.D = 0;
    eph.Delta_tLSF = 0;
    eph.TOW_6 = 0;   

    eph.A_0G = 0;
    eph.A_1G = 0;
    eph.t_0G = 0;
    eph.WN_0G = 0;
    obsCh.bEphOk = false;    
end












	
	





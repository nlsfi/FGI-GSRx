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
function [eph, obsCh] = gpsl1cDecodeEphemeris(obsCh, I_P, prn, signalSettings, const)
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

%% TBA: integrate with multisatpos

% Pi used in the GPS coordinate system
gpsPi = const.PI;

% Convert tracking output to navigation bits
startIndex = 10*obsCh.firstSubFrame;
endIndex = startIndex + 10*(signalSettings.frameLength-1);

% Symbols
symbolSamples = -obsCh.preambleSign*I_P(startIndex:10:endIndex)';

% Estimate symbol level and variance
[symbolMean, symbolVar] = momEstimator(I_P(10:10:end)',100);
symbolSamples = symbolSamples./symbolMean(obsCh.firstSubFrame:obsCh.firstSubFrame+1799);    % Normalize symbols according to mean
symbolVar = symbolVar(obsCh.firstSubFrame:obsCh.firstSubFrame+1799)./symbolMean(obsCh.firstSubFrame:obsCh.firstSubFrame+1799).^2;

%% Check if there is enough data for navigation message decoding===========
if length(symbolSamples) < 1800
    error('Not enough navigation bits to decode!');
end

%% Deconding of nav message

% TOI and NAV symbols
TOIsymbols = symbolSamples(1:52)';
NAVsymbols = symbolSamples(53:1800)';

% TOI and NAV variances
TOIvariances = symbolVar(1:52)';
NAVvariances = symbolVar(53:1800)';

% Deinterleave NAV part of the message
temp_NAVsymbols = zeros(1,1748);
temp_NAVvariances = zeros(1,1748);
for i = 0:37
    temp_NAVsymbols((i*46+1):(i*46+46)) = NAVsymbols((i+1):38:end);
    temp_NAVvariances((i*46+1):(i*46+46)) = NAVvariances((i+1):38:end);
end
NAVsymbols = temp_NAVsymbols;
NAVvariances = temp_NAVvariances;

% CRC polynomial
crcPoly = [1,1,0,0,0,0,1,1,0,0,1,0,0,1,1,0,0,1,1,1,1,1,0,1,1]; 

% Subframe 2
H2 = load("H2.mat").H2;
decoded_sf2 = reallyFastLDPCdecoder(H2,NAVsymbols(1:1200)',30,NAVvariances(1:1200)')'; % LDPC FEC
subframe2 = decoded_sf2(1:600);     % Data bits with CRC
check2 = crcDecode(subframe2(1:576),subframe2(577:600), crcPoly);   

% Subframe 3
H3 = load("H3.mat").H3;
decoded_sf3 = reallyFastLDPCdecoder(H3,NAVsymbols(1201:1748)',30,NAVvariances(1201:1748)')'; % LDPC FEC
subframe3 = decoded_sf3(1:274);     % Data bits with CRC
check3 = crcDecode(subframe3(1:250), subframe3(251:274), crcPoly);   

% Check that parity matches. TBA: Add subframe 3 data parsing
if check2 ~= 0 %&& check3 ~= 0
    crc = 0;
else
    crc = 1;
end

% Replace with binary char arrays
subframe2 = strrep(num2str(subframe2),' ','');
%subframe3 = strrep(num2str(subframe3),' ',''); % TBA

% Initialize ephemeris from subdrame 2 and ehpemeris check
eph = [];
obsCh.bEphOk = false;

% Initialize page information from subframe 3
%page = [];

% Data in subframe 1: Time of interval (TOI)
TOIlogL = 2*TOIsymbols./TOIvariances;
corr = zeros(1,256);
for k = 0:255
    candidate_TOI_bits = TOIcoder(k);
    corr(k+1) = sum(candidate_TOI_bits(2:end) .* TOIlogL(2:end));
end
[~,m] = max(abs(corr));
TOILSB = m-1;
TOIMSB = (1-sign(corr(m)))/2;
eph.TOI = 256*TOIMSB + TOILSB;


% Data in subframe 2: Clock, Ephemeris, ITOW
eph.weekNumber  =   bin2dec(subframe2(  1 : 13  ))*1;
eph.ITOW =          bin2dec(subframe2(  14: 21  ));
eph.t_op =          bin2dec(subframe2(  22: 32  ))*300;
eph.health =        bin2dec(subframe2(  33      ));
eph.URA_ED =        twosComp2dec(subframe2(  34:38   ));
eph.t_oe =          bin2dec(subframe2(  39:49   ))*300;
eph.deltaA =        twosComp2dec(subframe2(  50:75   ))*2^-9;
eph.ADot =          twosComp2dec(subframe2(  76:100  ))*2^-21;
eph.deltan_0 =      twosComp2dec(subframe2(  101:117 ))*2^-44 * gpsPi;
eph.deltan_0Dot =   twosComp2dec(subframe2(  118:140 ))*2^-57 * gpsPi;
eph.M_0 =           twosComp2dec(subframe2(  141:173 ))*2^-32 * gpsPi;
eph.e =             bin2dec(subframe2(  174:206 ))*2^-34;
eph.omega =         twosComp2dec(subframe2(  207:239 ))*2^-32 * gpsPi;
eph.Omega_0 =       twosComp2dec(subframe2(  240:272 ))*2^-32 * gpsPi;
eph.i_0 =           twosComp2dec(subframe2(  273:305 ))*2^-32 * gpsPi;
eph.deltaOmegaDot = twosComp2dec(subframe2(  306:322 ))*2^-44 * gpsPi;
eph.IDOT =          twosComp2dec(subframe2(  323:337 ))*2^-44 * gpsPi;
eph.C_is =          twosComp2dec(subframe2(  338:353 ))*2^-30;
eph.C_ic =          twosComp2dec(subframe2(  354:369 ))*2^-30;
eph.C_rs =          twosComp2dec(subframe2(  370:393 ))*2^-8;
eph.C_rc =          twosComp2dec(subframe2(  394:417 ))*2^-8;
eph.C_us =          twosComp2dec(subframe2(  418:438 ))*2^-30;
eph.C_uc =          twosComp2dec(subframe2(  439:459 ))*2^-30;
eph.URA_NED0 =      twosComp2dec(subframe2(  460:464 ));
eph.URA_NED1 =      bin2dec(subframe2(  465:467 ));
eph.URA_NED2 =      bin2dec(subframe2(  468:370 ));
eph.a_f0 =          twosComp2dec(subframe2(  471:496 ))*2^-35;
eph.a_f1 =          twosComp2dec(subframe2(  497:516 ))*2^-48;
eph.a_f2 =          twosComp2dec(subframe2(  517:526 ))*2^-60;
eph.T_GD =          twosComp2dec(subframe2(  527:539 ))*2^-35;
eph.ISC_L1CP =      twosComp2dec(subframe2(  540:552 ))*2^-35;
eph.ISC_L1CD =      twosComp2dec(subframe2(  553:565 ))*2^-35;
eph.ISF =           bin2dec(subframe2(  566     ));
eph.WN_OP =         bin2dec(subframe2(  567:574 ));

% TBA: Data in subframe 3
% PRN =           bin2dec(subframe3(  1:8 ));
% pageNo =        bin2dec(subframe3(  9:14 ));
%
% switch pageNo
%     case 1      % Page 1 UTC & IONO
%         page.PRN = PRN;
%         page.pageNo = pageNo;
%         page.A_0 =         twosComp2dec(subframe3(15:30))*2^-35;
%         page.A_1=          twosComp2dec(subframe3(31:43))*2^-51;
%         page.A_2=          twosComp2dec(subframe3(44:50))*2^-68;
%         page.deltat_LS =   twosComp2dec(subframe3(51:58));
%         page.t_ot =        bin2dec(subframe3(59:74))*2^4;
%         page.WN_ot =       bin2dec(subframe3(75:87));
%         page.WN_LSF =      bin2dec(subframe3(88:100));
%         page.DN =          bin2dec(subframe3(101:104));
%         page.Dt_LSF =      twosComp2dec(subframe3(105:112));
%         page.alpha_0 =     twosComp2dec(subframe3(113:120))*2^-30;
%         page.alpha_1 =     twosComp2dec(subframe3(121:120))*2^-27 / gpsPi;
%         page.alpha_2 =     twosComp2dec(subframe3(129:136))*2^-24 / gpsPi^2;
%         page.alpha_3 =     twosComp2dec(subframe3(137:144))*2^-24 / gpsPi^3;
%         page.beta_0 =      twosComp2dec(subframe3(145:152))*2^11;
%         page.beta_1 =      twosComp2dec(subframe3(153:160))*2^14 / gpsPi;
%         page.beta_2 =      twosComp2dec(subframe3(161:168))*2^16 / gpsPi^2;
%         page.beta_3 =      twosComp2dec(subframe3(169:176))*2^16 / gpsPi^3;
%         page.ISC_L1CA =    twosComp2dec(subframe3(177:189))*2^-35;
%         page.ISC_L2C =     twosComp2dec(subframe3(190:202))*2^-35;
%         page.ISC_L5I5 =    twosComp2dec(subframe3(203:215))*2^-35;
%         page.ISC_L5Q5 =    twosComp2dec(subframe3(216:228))*2^-35;
%
%     case 2      % Page 2 GGTO & EOP
%         page.PRN = PRN;
%         page.pageNo = pageNo;
%         page.A_0 =         twosComp2dec(subframe3(15:30))*2^-35;
%         page.A_1=          twosComp2dec(subframe3(31:43))*2^-51;
%         page.A_2=          twosComp2dec(subframe3(44:50))*2^-68;
%         page.deltat_LS =   twosComp2dec(subframe3(51:58));
%         page.t_ot =        bin2dec(subframe3(59:74))*2^4;
%         page.WN_ot =       bin2dec(subframe3(75:87));
%         page.WN_LSF =      bin2dec(subframe3(88:100));
%         page.DN =          bin2dec(subframe3(101:104));
%         page.Dt_LSF =      twosComp2dec(subframe3(105:112));
%         page.alpha_0 =     twosComp2dec(subframe3(113:120))*2^-30;
%         page.alpha_1 =     twosComp2dec(subframe3(121:120))*2^-27 / gpsPi;
%         page.alpha_2 =     twosComp2dec(subframe3(129:136))*2^-24 / gpsPi^2;
%         page.alpha_3 =     twosComp2dec(subframe3(137:144))*2^-24 / gpsPi^3;
%         page.beta_0 =      twosComp2dec(subframe3(145:152))*2^11;
%         page.beta_1 =      twosComp2dec(subframe3(153:160))*2^14 / gpsPi;
%         page.beta_2 =      twosComp2dec(subframe3(161:168))*2^16 / gpsPi^2;
%         page.beta_3 =      twosComp2dec(subframe3(169:176))*2^16 / gpsPi^3;
%         page.ISC_L1CA =    twosComp2dec(subframe3(177:189))*2^-35;
%         page.ISC_L2C =     twosComp2dec(subframe3(190:202))*2^-35;
%         page.ISC_L5I5 =    twosComp2dec(subframe3(203:215))*2^-35;
%         page.ISC_L5Q5 =    twosComp2dec(subframe3(216:228))*2^-35;
%     case 3
%     case 4
%     case 5
%     case 6
%     case 7
%     case 8
%     otherwise
% end

% Output info
if(eph.health == 0 && crc == 1) % CRC succesful and epheris is obtained
    disp(['Ephemeris for ', obsCh.signal ,' prn ', int2str(prn),' found.'])
    obsCh.bEphOk = true;
    obsCh.bParityOk = true;

    % GPS time of week for the message: 120 (minutes) * 60 (seconds/minute) * ITOW + 18 (seconds) * TOI-1
    obsCh.tow = 120*60*eph.ITOW + 18*(eph.TOI-1);

elseif (crc == 1) % CRC succesful, but satellite is unhealthy
    obsCh.bEphOk = false;
    obsCh.bParityOk = true;
    disp(['Ephemeris for ', obsCh.signal ,' prn ', int2str(prn),' is unhealthy'])

else % CRC fail
    obsCh.bEphOk = false;
    obsCh.bParityOk = false;
    disp(['Parity check fail for ', obsCh.signal ,' prn ', int2str(prn),'.'])
end

% Output info
if(obsCh.bEphOk == false)
    disp(['Ephemeris for ', obsCh.signal ,' prn ', int2str(prn),' NOT found.'])
end


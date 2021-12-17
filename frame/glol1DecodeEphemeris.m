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
function [eph, obsCh] = glol1DecodeEphemeris(obsCh, I_P, prn, signalSettings, const)
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

 % Copy 15 strings long record from tracking output 
navBitsSamples = I_P(obsCh.firstSubFrame + 300 : ...
                      obsCh.firstSubFrame + 300 + (1500 * 20) -1);

% TBA: Function does not check parity!

% Check that we have enough bits
if length(navBitsSamples)<30000
    error('The data array must contain 30000 bits (30 seconds of data)!!!)');
end

string_1_pos = 0; % Used to detect first string number.
eph.tk_h = 0;
eph.tk_m = 0;
eph.tk_s = 0;
subfMask = 0;

% Decode 15 data strings
for i=1:15
    
    % Take 1700 samples which correspond to 85 data bits
    curr_str = navBitsSamples(2000*(i-1)+1 : 2000*(i-1)+1700);  

    % Bits in the form: "-1" / "+1"
    decoded_str = glol1DecodeData(curr_str);  

    % Convert "-1"/"+1" bits to "0"/"1".
    decoded_str = (decoded_str +1) / 2;     

    % This check is important for the case of weak signals or signal lost.
    wrong_bits = find(decoded_str==0.5);    
    if ~isempty(wrong_bits)                 
      continue; %goto next loop iteration. 
    end                                    

    % Convert from decimal to binary string array.
    decoded_str = dec2bin(decoded_str)';    

    str_num = bin2dec( decoded_str(84:-1:81) );
    
    subfMask = bitset(subfMask,str_num);    

  % Only 5 first strings are of interest. The rest strings contain almanac that 
  % is not used in this program.
    switch str_num
      case 1   % String 1.
        P1        = bin2dec(  decoded_str(78:-1:77) );
        tk_h      = bin2dec(  decoded_str(76:-1:72) );
        tk_m      = bin2dec(  decoded_str(71:-1:66) );
        tk_s      = bin2dec(  decoded_str(65)       ) * 30;
        xdot      = bin2dec(  decoded_str(63:-1:41) ) * ((-1)^decoded_str(64)) * (2^-20);
        xdotdot   = bin2dec(  decoded_str(39:-1:36) ) * ((-1)^decoded_str(40)) * (2^-30);
        x         = bin2dec(  decoded_str(34:-1:9 ) ) * ((-1)^decoded_str(35)) * (2^-11);
        string_1_pos = i;

      case 2  % String 2.
        Health    = bin2dec(  decoded_str(80)       ); % Highest bit of word Bn
        P2        = bin2dec(  decoded_str(65)       );
        tb        = bin2dec(  decoded_str(76:-1:70) ) * 15;
        ydot      = bin2dec(  decoded_str(63:-1:41) ) * ((-1)^decoded_str(64)) * (2^-20);
        ydotdot   = bin2dec(  decoded_str(39:-1:36) ) * ((-1)^decoded_str(40)) * (2^-30);
        y         = bin2dec(  decoded_str(34:-1:9 ) ) * ((-1)^decoded_str(35)) * (2^-11);

      case 3  % String 3.
        P3        = bin2dec(  decoded_str(80)       );
        gamman    = bin2dec(  decoded_str(78:-1:69 ) ) * ((-1)^decoded_str(79)) * (2^-40); % carrier frequency deviation
        P         = bin2dec(  decoded_str(67:-1:66) );
        In3       = bin2dec(  decoded_str(65)       );
        zdot      = bin2dec(  decoded_str(63:-1:41) ) * ((-1)^decoded_str(64)) * (2^-20);
        zdotdot   = bin2dec(  decoded_str(39:-1:36) ) * ((-1)^decoded_str(40)) * (2^-30);
        z         = bin2dec(  decoded_str(34:-1:9 ) ) * ((-1)^decoded_str(35)) * (2^-11);

      case 4  % String 4.
        taun      = bin2dec(  decoded_str(79:-1:59 ) ) * ((-1)^decoded_str(80)) * (2^-30);
        deltataun = bin2dec(  decoded_str(57:-1:54 ) ) * ((-1)^decoded_str(58)) * (2^-30);
        En        = bin2dec(  decoded_str(53:-1:49) );
        P4        = bin2dec(  decoded_str(34)       ); % Valid ephemeris flag
        Ft        = bin2dec(  decoded_str(33:-1:30) );
        Nt        = bin2dec(  decoded_str(26:-1:16) ); % Date in days within a four-year interval
        n         = bin2dec(  decoded_str(15:-1:11) ); % Slot number
        M         = bin2dec(  decoded_str(10:-1:9 ) ); % Satellite type: 00:Glonass 1st gen. 01:Glonass-M.
      case 5  % String 5.
        NA        = bin2dec(  decoded_str(80:-1:70) );
        tauc      = bin2dec(  decoded_str(68:-1:38) ) * ((-1)^decoded_str(69)) * (2^-31);
        N4        = bin2dec(  decoded_str(36:-1:32) ); % Four-year interval number starting from 1996
        tauGPS    = bin2dec(  decoded_str(30:-1:10) ) * ((-1)^decoded_str(31)) * (2^-30);
        In5       = bin2dec(  decoded_str(9 )       );
    end

    if(bitand(subfMask,31) == 31)
        %String 1.    
        eph.P1 = P1;
        eph.tk_h = tk_h;
        eph.tk_m = tk_m;
        eph.tk_s = tk_s;
        eph.xdot = xdot;
        eph.xdotdot = xdotdot;
        eph.x = x;    

        %String 2
        eph.Health    = Health;
        eph.P2        = P2;
        eph.tb        = tb;
        eph.ydot      = ydot;
        eph.ydotdot   = ydotdot;
        eph.y         = y;

        %String 3
        eph.P3        = P3;
        eph.gamman    = gamman; % carrier frequency deviation
        eph.P         = P;
        eph.In3       = In3;
        eph.zdot      = zdot;
        eph.zdotdot   = zdotdot;
        eph.z         = z;

        %String 4
        eph.taun      = taun;
        eph.deltataun = deltataun;
        eph.En        = En;
        eph.P4        = P4; % Valid ephemeris flag
        eph.Ft        = Ft;
        eph.Nt        = Nt; % Date in days within a four-year interval
        eph.n         = n; % Slot number
        eph.M         = M; % Satellite type: 00:Glonass 1st gen. 01:Glonass-M.

        %String 5 
        eph.NA        = NA;         
        eph.tauc      = tauc;            
        eph.N4        = N4;            
        eph.tauGPS    = tauGPS;            
        eph.In5       = In5;
        eph.geo = false;   
        
        if(eph.Health == 0)
            disp(['   Ephemeris for ', obsCh.signal ,' prn ', ...
                int2str(prn),' found.'])      
            t = (eph.tk_h * 60 * 60) + (eph.tk_m * 60) + eph.tk_s; 
            
            %Time of the frame start in 24-hour format is converted in the 
            % number of seconds since the day-start.
            t = t - ( (string_1_pos-1)*2 ) - 0.3; % 0.3 - time mark duration.
            
            obsCh.bEphOk = true;
            obsCh.tow = t;            
        else
            obsCh.bEphOk = false;            
            disp(['   Ephemeris for ', obsCh.signal ,' prn ', ...
                int2str(prn),' is unhealthy.'])  
        end
        
        break;
    end
end 
    

if(obsCh.bEphOk == false)
    disp(['   Ephemeris for ', obsCh.signal ,' prn ', ...
        int2str(prn),' NOT found.'])                              
    
       %String 1.    
        eph.P1 = 0;
        eph.tk_h = 0;
        eph.tk_m = 0;
        eph.tk_s = 0;
        eph.xdot = 0;
        eph.xdotdot = 0;
        eph.x = 0;    

        %String 2
        eph.Health    = 0;
        eph.P2        = 0;
        eph.tb        = 0;
        eph.ydot      = 0;
        eph.ydotdot   = 0;
        eph.y         = 0;

        %String 3
        eph.P3        = 0;
        eph.gamman    = 0; % carrier frequency deviation
        eph.P         = 0;
        eph.In3       = 0;
        eph.zdot      = 0;
        eph.zdotdot   = 0;
        eph.z         = 0;

        %String 4
        eph.taun      = 0;
        eph.deltataun = 0;
        eph.En        = 0;
        eph.P4        = 0; % Valid ephemeris flag
        eph.Ft        = 0;
        eph.Nt        = 0; % Date in days within a four-year interval
        eph.n         = 0; % Slot number
        eph.M         = 0; % Satellite type: 00:Glonass 1st gen. 01:Glonass-M.

        %String 5 
        eph.NA        = 0;         
        eph.tauc      = 0;            
        eph.N4        = 0;            
        eph.tauGPS    = 0;            
        eph.In5       = 0;
        eph.geo = false;   
end


 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copyright 2015-2026 Finnish Geospatial Research Institute FGI, National
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
function meas = getNavMeasurements(ephData, signame, obsData, settings)
% GETNAVMEASUREMENTS Extracts navigation message blocks for the given signal.
%
% Currently only supports Galileo and GPS.
% 
% Inputs: 
%   ephData:struct
%   signame:string
%   obsData:struct
%
% Outputs:
%   meas:struct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    meas = struct('sysChar', {}, 'prn', {}, ...
        'orbit1', {}, 'orbit2', {}, 'orbit3', {}, 'orbit4', {}, ...
        'orbit5', {}, 'orbit6', {}, 'orbit7', {}, ...
        'epochTime', {}, 'clockBias', {}, 'clockDrift', {}, ...
        'clockDriftRate', {}, 'timeSystem', {} );

    if ~isfield(ephData, signame)
        % Handle error appropriately
        return; 
    end
    
    e = ephData.(signame);
    timeSystem=inferSatSystem({signame});

    datas.gpsRollovers = settings.rnx.gpsRollovers; % Pass GPS rollovers

    % Transmission time of message TODO: 
    valid_indices = find(~isnan([obsData.channel.tow]));
    TTOM = 0.9999E9; % No valid TOW found, set to spec null
    datas.transTimeOfMessage = TTOM;
    
    % Find entries with data(using arrayfun or loop)
    % Note: Accessing struct arrays via e(prn) assumes the index matches PRN exactly.
    % Be careful if 'e' is sparse or indices don't align with PRN numbers.
    validIdx = find(arrayfun(@(x) ...
        (isfield(x, 'subframe') && ~isempty(x.subframe)) || ...
        (isfield(x, 'weekNumber') && ~isempty(x.weekNumber)), e));

    for k = 1:numel(validIdx)
        prn = validIdx(k);
        
        if signame == "gpsl1" % current support for only gpsl1
            eph = e(prn);
            meas(k) = parseGPS(eph, 'G', prn, datas);
            week = eph.weekNumber;
            tow = eph.t_oc;
            
        elseif contains(signame, 'gal', 'IgnoreCase', true)
            eph = e(prn).subframe(end); % take the last subframe


            % Data source bitmask: bits 0-2 for signal presence, bits 8-9 for clock source
            % this method is a bit over the top since signame can only be one of the three and never all of them. Maybe change this in future.
            dataSource = uint16(0);

            % --- Signal source bits (0–2) ---
            if contains(signame, 'e1b', 'IgnoreCase', true)
                dataSource = bitor(dataSource, bitshift(1, 0));
            end

            if contains(signame, 'e5a', 'IgnoreCase', true)
                dataSource = bitor(dataSource, bitshift(1, 1));
            end

            if contains(signame, 'e5b', 'IgnoreCase', true)
                dataSource = bitor(dataSource, bitshift(1, 2));
            end

            % --- Clock source bits (8–9) ---
            if contains(signame, 'e5a', 'IgnoreCase', true)
                % F/NAV → E5a/E1 clock
                dataSource = bitor(dataSource, bitshift(1, 8));

            elseif contains(signame, 'e5b', 'IgnoreCase', true) || ...
                contains(signame, 'e1b', 'IgnoreCase', true)
                % I/NAV → E5b/E1 clock
                dataSource = bitor(dataSource, bitshift(1, 9));
            end

            % Disallow mixed F/NAV + I/NAV 
            validE1B = bitand(dataSource, bitshift(uint16(1),0)) ~= 0;
            validE5a = bitand(dataSource, bitshift(uint16(1),1)) ~= 0;
            validE5b = bitand(dataSource, bitshift(uint16(1),2)) ~= 0;
            if validE5a && (validE1B || validE5b)
                error('Invalid Galileo dataSource: cannot combine F/NAV (E5a) with I/NAV (E1-B/E5b) in one call.');
            end

            % get prn based measurements
            meas(k) = parseGalileo(eph, 'E', prn, dataSource);
            week = eph.weekNumber;
            tow = eph.t_oc;
        else
            error('Unsupported constellation type for signal %s.', signame);
        end
        
        % Calculate Epoch Time
        zeroTime = getZeroTime(timeSystem, settings.rnx.gpsRollovers); 
        meas(k).epochTime = zeroTime + days(week*7) + seconds(tow);
        meas(k).clockBias = eph.a_f0; 
        meas(k).clockDrift = eph.a_f1;
        meas(k).clockDriftRate = eph.a_f2; 
    end
end

% GPS Parser
function meas = parseGPS(eph, sysChar, prn, datas)
    meas.sysChar = sysChar;
    meas.prn = prn;
    meas.epochTime = NaT;
    meas.clockBias= NaN;
    meas.clockDrift = NaN;
    meas.clockDriftRate = NaN; 

    weekNumber = eph.weekNumber + 1024*datas.gpsRollovers; % account for GPS week number rollovers
    TTOM = datas.transTimeOfMessage;
    %if TTOM ~= 0.9999E9
    %    dt = TTOM - eph.t_oe;
    %    if dt > 302400
    %        TTOM = TTOM - 604800;
    %    elseif dt < -302400
    %        TTOM = TTOM + 604800;
    %    end
    %end
    
    
    if isfield(eph, 'URA_ED')
        acc = getAccuracy(eph.URA_ED, prn, "l1c"); % gps l1c
        
        deltan = eph.deltan_0;
        omegaDot = eph.deltaOmegaDot;
        iDot = eph.IDOT;
        omega_0 = eph.Omega_0;

        actualA = 26559710 + eph.deltaA;
        sqrtA = sqrt(actualA);
        
        IODE = 0; % Placeholder for IODE
        IODC = IODE;

    else 
        acc = getAccuracy(eph.accuracy, prn, "l1"); % gps l1

        sqrtA = eph.sqrtA;
        IODE = eph.IODE_sf2;
        IODC = eph.IODC;
        deltan = eph.deltan;
        omegaDot = eph.omegaDot;
        iDot = eph.iDot;
        omega_0 = eph.omega_0;
    end

    meas.orbit1 = [IODE, eph.C_rs, deltan, eph.M_0];
    meas.orbit2 = [eph.C_uc, eph.e, eph.C_us, sqrtA];
    meas.orbit3 = [eph.t_oe, eph.C_ic, omega_0, eph.C_is];
    meas.orbit4 = [eph.i_0, eph.C_rc, eph.omega, omegaDot];
    meas.orbit5 = [iDot, 0, weekNumber, 0];  
    meas.orbit6 = [acc, eph.health, eph.T_GD, IODC];
    meas.orbit7 = [TTOM, 0, 0, 0]; % transmission time from message not known?
    meas.timeSystem = '';
end

% GALILEO Parser
function meas = parseGalileo(eph, sysChar, prn, dataSource)
    meas.sysChar = sysChar;
    meas.prn = prn;
    meas.epochTime = NaT;
    meas.clockBias= NaN;
    meas.clockDrift = NaN;
    meas.clockDriftRate = NaN; 
    
    % Extract valid BGDs and Health using T_GD mapping
    [health, BGD_E1E5a_5, BGD_E1E5b_5] = getGalileoMetadata(eph, dataSource);

    meas.orbit1 = [eph.IODE_sf2, eph.C_rs, eph.deltan, eph.M_0];
    meas.orbit2 = [eph.C_uc, eph.e, eph.C_us, eph.sqrtA];
    meas.orbit3 = [eph.t_oe, eph.C_ic, eph.omega_0, eph.C_is];
    meas.orbit4 = [eph.i_0, eph.C_rc, eph.omega, eph.omegaDot];
    
    % ORBIT 5: IDOT, Data Sources, Week, Spare
    meas.orbit5 = [eph.iDot, double(dataSource), eph.weekNumber+1024, 0]; %GAL week = GST week + 1024 + n*4096 (n=number of GST roll-overs). 
    
    % ORBIT 6: SISA, Health, BGD(E5a/E1), BGD(E5b/E1)
    % Columns 3 and 4 are strictly defined by RINEX 3.04 Table A8
    % BGD_E1E5a_5 is used for F/NAV which is not supported for the time being -> always 0.
    meas.orbit6 = [eph.SISA, double(health), BGD_E1E5a_5, BGD_E1E5b_5];
    
    % Use TOW_6 if available, otherwise default to spec null
    txTime = 0.9999e9;

    % TODO: check the implementation if it is correct
    %if isfield(eph, 'TOW_6') && ~isempty(eph.TOW_6) && ~isnan(eph.TOW_6)
    %    txTime = eph.TOW_6;
    %end
    meas.orbit7 = [txTime, 0, 0, 0];
    meas.timeSystem = '';
end

function [healthVal, BGD_E1E5a_5, BGD_E1E5b_5] = getGalileoMetadata(eph, dataSource)
    %GETGALILEOMETADATA
% Returns a packed health mask and (optionally) BGD values.
% Bit layout (LSB->MSB):
%  [0]   E1B_DVS
%  [1:2] E1B_HS
%  [3]   E5a_DVS
%  [4:5] E5a_HS
%  [6]   E5b_DVS
%  [7:8] E5b_HS
%
% Notes:
%  - E1B/E5b flags come from I/NAV (E1-B, E5b-I).
%  - E5a flags come from F/NAV (E5a-I).
%  - DVS is 1 bit; HS is 2 bits as per ICD §5.1.9.3. Use only when DVS==0 and HS==0.
%
% References: Galileo OS SIS ICD v2.0

    % Health parsing
    healthVal = uint16(0);
    % Data-source presence (bit 0: E1B, bit 1: E5a, bit 2: E5b)
    validE1B = bitand(dataSource, bitshift(1, 0)) ~= 0;
    validE5a = bitand(dataSource, bitshift(1, 1)) ~= 0;
    validE5b = bitand(dataSource, bitshift(1, 2)) ~= 0;


    INAV = validE1B || validE5b;
    FNAV = validE5a;

    if validE1B
        dvs = uint16(eph.E1B_DVS);
        hs  = uint16(eph.E1B_HS);
        healthVal = bitor(healthVal, bitshift(bitand(dvs, 1), 0));
        healthVal = bitor(healthVal, bitshift(bitand(hs, 3), 1));
    end
    if validE5a && isfield(eph,'E5a_DVS') && isfield(eph,'E5a_HS')
        dvs = uint16(eph.E5a_DVS); 
        hs  = uint16(eph.E5a_HS);
        healthVal = bitor(healthVal, bitshift(bitand(dvs, 1), 3));
        healthVal = bitor(healthVal, bitshift(bitand(hs, 3), 4));
    end
    if validE5b && isfield(eph,'E5b_DVS') && isfield(eph,'E5b_HS')
        dvs = uint16(eph.E5b_DVS); 
        hs  = uint16(eph.E5b_HS);
        healthVal = bitor(healthVal, bitshift(bitand(dvs, 1), 6));
        healthVal = bitor(healthVal, bitshift(bitand(hs, 3), 7));
    end

    valTGD = eph.T_GD;
        
    %%
    %eph.BGD_E1E5a_5 = 0;
    %eph.BGD_E1E5b_5 = 0;
    BGD_E1E5a_5 = 0;
    BGD_E1E5b_5 = 0;

    if FNAV && isfield(eph,'BGD_E1E5a_5')
        BGD_E1E5a_5 = eph.BGD_E1E5a_5;
    end

    if INAV
        if isfield(eph,'BGD_E1E5b_5')
            BGD_E1E5b_5 = eph.BGD_E1E5b_5;
        else
            BGD_E1E5b_5 = valTGD;     % T_GD mapped to E1E5b at least for e1b signal.
        end
        if isfield(eph,'BGD_E1E5b_5')
            BGD_E1E5a_5 = eph.BGD_E1E5b_5;
        end
    end
end

function acc = getAccuracy(accuracy, prn, sigName)
    if sigName == "l1"
        if accuracy < 6 
            acc = 2^(1+accuracy/2);
        elseif accuracy >= 6 && accuracy <= 15
            acc = 2^(accuracy-2);
        elseif accuracy == 15
            acc = 8192;
            fprintf('Warning: Satellite %u has accuracy value of 15, which may indicate absence of an accuracy prediction.\n', prn);
        end
    end
    if sigName == "l1c"
        if accuracy <= 6 && accuracy > -16
            acc = 2^(1+accuracy/2);
        elseif accuracy >= 6 && accuracy < 15
            acc = 2^(accuracy-2);
        elseif accuracy == 15 || accuracy == -16
            acc = 8192;
            fprintf('Warning: Satellite %u has accuracy value of %d, which may indicate absence of an accuracy prediction.\n', prn, accuracy);
        else
            acc = 999; % Invalid accuracy value for L1C
        end
    end
    % rounding to 1 decimal place for better readability
     acc = round(acc, 1);
end
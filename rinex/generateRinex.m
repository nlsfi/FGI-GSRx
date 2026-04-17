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
function generateRinex(settings, obsData, navData, ephData)
% GENERATERINEX
% Main function for the RINEX 3.04 file generation. 
% This function includes all the parameters that need to be defined.
% 
% The function loads the output of the FGI-GSRx and generates a RINEX file
% based on the given data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
    fN = settings.fN;
    hD = settings.hD;
    hOD = settings.hOD;

    % Map position to cartesian coordinates
    [x1,x2,x3]=calculateRefPosXyz(navData);
    settings.hOD.antPositionXyz=containers.Map({'x','y','z'},{x1,x2,x3});

    %% -------------- Navigation data file specific settings ------------------
    hND=struct();
    % might need some additional parameters when fully completed
    %% ---------------------------------------------------------------
    
    % Change v2.0.1 obs data format to be compatible with writeRinex3Obs
    % (include only the parameters that we need for writing the Rinex file)
    for signalIndex = 1:settings.sys.nrOfSignals
        
        signalName = settings.sys.enabledSignals{signalIndex};     
        
        % Get all field names (fns) used in obsData and loop through them
        fns = fieldnames(obsData{1}.(signalName));
        for fn_i = 1:length(fns)
            % Get the file name (fn)
            fn = cell2mat(fns(fn_i));
            
            if strcmp(fn, "signal")         % The field "signal" is a string, so process it separately
                newObsData.(signalName).(fn) = strings;
    
                for epoch = 1:length(obsData)
                    newObsData.(signalName).(fn)(epoch) = obsData{epoch}.(signalName).(fn);
                end
            elseif strcmp(fn, "channel")    % The field "channel" is a struct, so process it separately
                % Index for valid observations
                ind = 1;
    
                % Loop through the channels
                for channelNr = 1:obsData{1}.(signalName).nrObs
                    if obsData{1}.(signalName).channel(channelNr).bObsOk    % If the observation is valid
                        % We need at least the following 1x1 fields from each
                        % channel
                        newObsData.(signalName).channel(ind).week = obsData{1}.(signalName).channel(channelNr).week;
                        newObsData.(signalName).channel(ind).SvId = obsData{1}.(signalName).channel(channelNr).SvId;
                        newObsData.(signalName).channel(ind).carrierFreq = obsData{1}.(signalName).channel(channelNr).carrierFreq;

                        % We also want to grab the following field for each
                        % epoch separately
                        for epoch = 1:length(obsData)
                            newObsData.(signalName).channel(ind).rawP(epoch) = obsData{epoch}.(signalName).channel(channelNr).rawP;
                            newObsData.(signalName).channel(ind).SNR(epoch) = obsData{epoch}.(signalName).channel(channelNr).SNR;
                            newObsData.(signalName).channel(ind).doppler(epoch) = obsData{epoch}.(signalName).channel(channelNr).doppler;
                            newObsData.(signalName).channel(ind).tow(epoch) = obsData{epoch}.(signalName).channel(channelNr).tow; %%%% new
                            newObsData.(signalName).channel(ind).accPhase(epoch) = obsData{epoch}.(signalName).channel(channelNr).accPhase; %%new
                            newObsData.(signalName).channel(ind).ionoCorr(epoch) = obsData{epoch}.(signalName).channel(channelNr).ionoCorr;
                        end
    
                        ind = ind + 1;
                    end
                end
            else                            % For other fields than "signal" or "channel"
                % Initialize to zeros
                newObsData.(signalName).(fn) = zeros(1, length(obsData));
    
                % Grab the field from each epoch
                for epoch = 1:length(obsData)
                    newObsData.(signalName).(fn)(epoch) = obsData{epoch}.(signalName).(fn);
                end
            end
        end
    end
    
    
    obsTypes=[obsType.range,obsType.phase,...
            obsType.doppler,obsType.snr];
    
    
    % See what file types we want to generate
    for ftype = 1:length(hD.fileType)
        type = hD.fileType(ftype);
        if type ~= 'N' && type ~= 'O'
            error('Type: %s is not a valid filetype.', type)
        end
        if type == 'O'
            hDObs = hD;
            hDObs.fileType = 'O';
            % merge the observation information to the header
            fields = fieldnames(hOD);
            for j = 1:numel(fields)
                hDObs.(fields{j}) = hOD.(fields{j});
            end
            writeRinex3Obs(newObsData,navData,settings,obsTypes,fN,hDObs);
        end
        if type == 'N'
            hDNav = hD;
            hDNav.fileType = 'N';
            % merge the navigation information to the header
            fields = fieldnames(hND);
            for j = 1:numel(fields)
                hDNav.(fields{j}) = hND.(fields{j});
            end
            writeRinex3Nav(newObsData,navData,ephData,settings,obsTypes,fN,hDNav);
        end
        
    end
    
    % helper function
    function [x,y,z]=calculateRefPosXyz(navData)
        % CALCULATEREFPOSXYZ
        ln=length(navData);
        x=0;y=0;z=0;
        for i=1:ln
            x=x+navData{i}.Pos.xyz(1);
            y=y+navData{i}.Pos.xyz(2);
            z=z+navData{i}.Pos.xyz(3);
        end
        x=x/ln;
        y=y/ln;
        z=z/ln;
    end
end
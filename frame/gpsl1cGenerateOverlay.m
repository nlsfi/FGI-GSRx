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
function codeReplica = gpsl1cGenerateOverlay(PRN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generates one GPS satellite code
%
% Inputs:
%   PRN         - PRN number of satellite which overlay code is generated.
%
% Outputs:
%   codeReplica - Generated code replica in bits for the given PRN number.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% S1 Polynomial coefficients as hexadecimal
S1 = { 'A49','B11','B41','B03','D0F','C61','CE9','D41','C85',...
        'C9D','FE9','D93','DDB','F97','BB7','A29','FB5','CD5',...
        '8F5','9E5','F9B','DE7','93D','895','E33','913','DA9',...
        '871','E9F','93B','B3F','C73','E93','CD3','E55','E1D',...
        '8E1','8EB','847','BDD','DE1','E39','973','BED','C57',...
        '9B9','949','95B','AEF','B87','DBB','C6B','F75','E47',...
        'C89','8D1','E81','929','B09','A61','E21','D9F','97F'    };

% Initial states as hexadecimals
IC = {  '6B6','420','357','6C7','7EE','616','172','110','70D',...
        '0DF','0B5','298','484','320','50A','74E','5F1','7E8',...
        '5C1','286','364','3FC','166','48B','7C7','429','7A8',...
        '3FF','683','3F2','440','179','7C8','75D','648','316',...
        '0AD','0D1','654','17A','3DE','6C6','2C7','7F3','384',...
        '211','594','106','04C','03F','73F','200','730','587',...
        '42F','737','1C6','41A','334','150','3F6','6B8','0E1'   };

% Get coefficient and state vectors which correspond to PRN index
S1c = logical(hex2bin(S1{PRN}));
n = logical(hex2bin(IC{PRN}));

% Drop unnessesary bits off from coefficient and state vectors
S1c = S1c(1:11);
n = n(2:12);

% Initialize output
codeReplica = zeros(1,1800);

% Loop LSFR algorithm (Note that the indexing direction is opposite to that in ICD)
for i = 1:1800
    codeReplica(i) = n(1);      % Pick lowest (highest in ICD) index from the state to output
    nend = mod(sum(S1c.*n),2);  % Calculate new value to be added to state
    n = circshift(n,-1);        % Circshift the state; value of the lowest index is shifted to highest index
    n(end) = nend;              % Replace old lowest and now highest index with the new value
end

% Go from logical to signal representation (0 -> 1, 1 -> -1)
codeReplica = 1-2*codeReplica;


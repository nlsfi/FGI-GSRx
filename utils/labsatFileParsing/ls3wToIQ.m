%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FGI-GSRx software GNSS receiver
%
% Finnish Geospatial Research Institute
% Department of Navigation and Positioning
% DO NOT DISTRIBUTE
%
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ls3wToIQ(ls3w_filepath, ini_filepath, out_filepath, sToSkip, sToParse)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a function to parses LabSat 3 Wideband ls3w-files into 8 + 8 bit I/Q format
%
% Inputs:
%   ls3w_filepath       - Filepath to a LabSat 3 Wideband ls3w-file
%   ini_filepath        - Filepath to a LabSat .ini-file
%   out_filepath        - Path where the output IQ files are stored to
%   sToSkip            - Number of seconds to skip at the beginning of the file
%   sToParse           - Set to 0 to parse the whole file after an initial skip; A few extra ms may be parsed by the program
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Function constants
channels = ['A', 'B', 'C'];     % Channel names
registersPerIter = 1e5;         % Number of processed ls3w register per iteration

% Step 1: Parse the .ini file
ini_data = ls3wReadIni(ini_filepath);

% Extract needed parameters from the .ini file
sample_rate     = str2double(ini_data.config.SMP);  % Sample rate
quantization    = str2double(ini_data.config.QUA);  % Quantization
num_channels    = str2double(ini_data.config.CHN);  % Number of RF channels

% Import frequency and bandwidth settings from each of the channels
switch num_channels
    case 1
        frequency   = str2double(ini_data.channel_A.CFA);
        bandwidth   = str2double(ini_data.channel_A.BWA);
    case 2
        frequency   = [str2double(ini_data.channel_A.CFA), str2double(ini_data.channel_B.CFB)];
        bandwidth   = [str2double(ini_data.channel_A.BWA), str2double(ini_data.channel_B.BWB)];
    case 3
        frequency   = [str2double(ini_data.channel_A.CFA), str2double(ini_data.channel_B.CFB), str2double(ini_data.channel_C.CFC)];
        bandwidth   = [str2double(ini_data.channel_A.BWA), str2double(ini_data.channel_B.BWB), str2double(ini_data.channel_C.BWC)];
end

% Output settings
num_samples_per_register = floor(64 / (quantization * 2 * num_channels));   % Number of samples per register
outputPaths     = string([]);   % Initialize output iq-file paths

% Extract file name
[~,out_filename,~] = fileparts("C:\Data\IQFile_.LS3W");

% Display information about the file
fprintf('Sample Rate: %d Sps\n', sample_rate);
fprintf('Quantization: %d bits per sample\n', quantization);
fprintf('Number of Channels: %d\n', num_channels);

% Available channels
for chIdx = 1:num_channels
    outputPaths(chIdx) = out_filepath + out_filename + "_" + channels(chIdx) + ".iq";
    fprintf('Channel %c: %d Hz at %d Hz bandwidth\n', channels(chIdx), frequency(chIdx), bandwidth(chIdx));
end

%% Open the .ls3w and .iq files
fid = fopen(ls3w_filepath, 'rb');
if fid == -1
    error('Could not open the ls3w file.');
end
input = dir(ls3w_filepath);                         % Total number of bytes
totalRegisters = input.bytes/8;                     % Total number of registers assuming 8-byte registers

nrIter_max = floor(totalRegisters/registersPerIter);    % Maximum number of iterations to parse the file
nrIter_skip = (sample_rate/(registersPerIter*num_samples_per_register))*(sToSkip);   %e.g. 900sec  % Number of iterations to skip in the file as provided by the user
nrIter_parse = round((sample_rate/(registersPerIter*num_samples_per_register))*(sToParse+sToSkip));    % Number of iterations to parse the file  as provided by the user

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 4 
    totalBytesSkipped=0;    % Total number of bytes to skip in the file
else
    totalBytesSkipped=nrIter_skip*(registersPerIter*8); % Total number of bytes to skip in the file assuming 8-byte registers
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 5 
    nrIter = nrIter_max;    % Total number of iterations to parse the file
else
    nrIter = nrIter_parse;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Open output files
for chIdx = 1:num_channels
    fOut(chIdx)  = fopen(outputPaths(chIdx), 'wb');
end

% File mask for opened files
openedFiles = fOut ~= -1;

% Check that all files were opened
if any(~openedFiles)
    % Close opened input file
    fclose(fid);

    % Close opened output files
    for closableFile = fOut(openedFiles)
        fclose(closableFile);
    end

    % Throw error
    error('Could not open the iq files.');
end

%% Parse ls3w file to IQ-file

% Buffer matrix to hold parsed samples; To be written into a file
writeMatrix = zeros(2*registersPerIter*num_samples_per_register, 1, "int8");

% Iterate over the input file and write parsed registers to output
for iterIdx = 1:nrIter

    % Parsed file length so far
    parsedLengthInMs = round((iterIdx-1)*registersPerIter*num_samples_per_register/sample_rate*1000);
    if parsedLengthInMs < (sToSkip*1000)
        % Load in data as ls3w registers
        raw_data = fread(fid, registersPerIter, 'uint64=>uint64');
        fprintf('Processing data please wait parsing will begin soon!\n');
        continue
    end
  
    % % Load in data as ls3w registers
    raw_data = fread(fid, registersPerIter, 'uint64=>uint64');

    % Decode the registers
    [iData, qData] = ls3wDecodeRegisters(raw_data, quantization, num_channels);
    
    % Iterate over frequency channels
    for chIdx = 1:num_channels
        % Interleave I and Q samples for the channel
        writeMatrix(1:2:end) = iData(chIdx:num_channels:end);
        writeMatrix(2:2:end) = qData(chIdx:num_channels:end);

        % Write channel IQ data to an output file
        fwrite(fOut(chIdx), writeMatrix, "int8");
    end

    % Print a update to see progress
    parsedLengthInMs = round(iterIdx*registersPerIter*num_samples_per_register/sample_rate*1000);
    fprintf("Parsed: %d / %d ms\n", (parsedLengthInMs-(sToSkip*1000)), sToParse*1000);
end

% End of processing; Close input and output files
fprintf("End of processing!\n");
fclose(fid);
for chIdx = 1:num_channels
    fclose(fOut(chIdx));
end

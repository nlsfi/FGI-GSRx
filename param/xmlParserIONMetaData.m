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
function mData = xmlParserIONMetaData(metaDataFileIn)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions sets any missing parameters in the settings structure
%
%  Inputs: 
%       settings - Receiver settings 
%
%  Outputs:
%       settings - Updated receiver settings
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xmlFileText = fileread(metaDataFileIn);

%Word size parsing in order to read raw data file properly
wordSizeStartIndex = regexp(xmlFileText,'<sizeword>')+length('<sizeword>');        
wordSizeEndIndex = regexp(xmlFileText,'</sizeword>')-1;           
wordSizeInBytes = str2num(xmlFileText(wordSizeStartIndex:wordSizeEndIndex)); 
metaData.sampleSizeInBytes = wordSizeInBytes;

%Frequency base parsing
freqStartIndex = regexp(xmlFileText,'<freqbase');
freqEndIndex =  regexp(xmlFileText,'</freqbase>')+length('/freqbase>');
freqBase = xmlFileText(freqStartIndex:freqEndIndex);
freqValStartInd = strfind(freqBase,'">')+2;
freqValEndInd = strfind(freqBase,'</')-1;
freqVal = str2num(freqBase(freqValStartInd:freqValEndInd));

if length(strfind(freqBase,'format="Hz"'))>0
    freqVal = freqVal*1;    
elseif length(strfind(freqBase,'format="kHz"'))>0
    freqVal = freqVal*1e3;    
elseif length(strfind(freqBase,'format="MHz"'))>0
    freqVal = freqVal*1e6;    
elseif length(strfind(freqBase,'format="GHz"'))>0
    freqVal = freqVal*1e9;                    
else    
    disp('Something is wrong in Frequency decoding');
end
 
metaData.freqBase = freqVal;
wordSizeEndIndex = regexp(xmlFileText,'</sizeword>')-1;           
wordSizeInBytes = str2num(xmlFileText(wordSizeStartIndex:wordSizeEndIndex)); 
metaData.sampleSizeInBytes = wordSizeInBytes;

streamsStartIndex = regexp(xmlFileText,'<stream id=');
streamsEndIndex = regexp(xmlFileText,'</stream>');
noOfStreams = length(streamsStartIndex);

signalTable = [];
%Initialize number of Signals
noOfSignals = 0;
for i=1:noOfStreams
    currentStream = xmlFileText(streamsStartIndex(i):streamsEndIndex(i)+8);
    streamTag = char(regexp(currentStream, '[^\n]*stream id[^\n]*','match'));
    streamInd =strfind(streamTag,'"');
    streamID = upper(streamTag(streamInd(1)+1:streamInd(2)-1));     
    dashIndex = strfind(streamID,'-');
    streamID(dashIndex) = '_';        
    bandIDLine = char(regexp(currentStream, '[^\n]*band id[^\n]*','match'));
    bandIDInd =strfind(bandIDLine,'"');
    bandID = upper(bandIDLine(bandIDInd(1)+1:bandIDInd(2)-1)); 
        
    if length(strfind(bandID,'L1')) && length(strfind(bandID,'E1'))>0
        signalTable = [signalTable; {'gpsl1'}; {'gale1b'}];
    elseif length(strfind(bandID,'L1')) && length(strfind(bandID,'E1'))>0 && length(strfind(bandID,'G1'))>0
        signalTable = [signalTable; {'gpsl1'}; {'gale1b'}; {'glol1'}];        
    elseif length(strfind(bandID,'L1'))         
        signalTable = [signalTable; {'gpsl1'};];
    elseif length(strfind(bandID,'E1'))>0
        signalTable = [signalTable; {'gpsl1'};];
    elseif length(strfind(bandID,'B1'))>0 && isempty(strfind(bandID,'B1-2'))==1 
        signalTable = [signalTable; {'beib1'};];  
    elseif length(strfind(bandID,'L2'))>0 && length(strfind(bandID,'G2'))>0
        signalTable = [signalTable; {'gpsl2cm'}; {'glol2'};];        
    elseif length(strfind(bandID,'L5')) && length(strfind(bandID,'E5a'))>0
        signalTable = [signalTable; {'gpsl5I'}; {'gale5a'};];  
    elseif length(strfind(bandID,'L5')) && length(strfind(bandID,'E5'))>0
        signalTable = [signalTable; {'gpsl5I'}; {'gale5aI'}; {'gale5bI'};];          
    else
        ;
    end

   %RateFactor parsing in order to calculate sampling frequency
   rateFactorStartIndex = regexp(currentStream,'<ratefactor>')+length('<ratefactor>');        
   rateFactorEndIndex = regexp(currentStream,'</ratefactor>')-1;           
   metaData.(streamID).rateFactor = str2num(currentStream(rateFactorStartIndex:rateFactorEndIndex));   

   %Quantization parsing: not really required for FGI-GSRx processing
   quantizationStartIndex = regexp(currentStream,'<quantization>')+length('<quantization>');        
   quantizationEndIndex = regexp(currentStream,'</quantization>')-1;           
   metaData.(streamID).quantizationBits = str2num(currentStream(quantizationStartIndex:quantizationEndIndex));   
   
   %Data formal parsing: needed to know whether it is real or complex and
   %of which orientation: IQ, or QI
   formatStartIndex = regexp(currentStream,'<format>')+length('<format>');        
   formatEndIndex = regexp(currentStream,'</format>')-1;           
   metaData.(streamID).formatRawData = char(currentStream(formatStartIndex:formatEndIndex));   
    
   
   %Center frequency parsing
   centerFreqStartIndex = regexp(currentStream,'<centerfreq');
   centerFreqEndIndex =  regexp(currentStream,'</centerfreq>')+length('/centerfreq>');
   
   if isempty(centerFreqStartIndex)==1 && noOfStreams==1 %Case of single band system with one stream
       %Center frequency parsing
       centerFreqStartIndex = regexp(xmlFileText,'<centerfreq');
       centerFreqEndIndex =  regexp(xmlFileText,'</centerfreq>')+length('/centerfreq>');
       centerFreqLine = xmlFileText(centerFreqStartIndex:centerFreqEndIndex);
   else
       centerFreqLine = currentStream(centerFreqStartIndex:centerFreqEndIndex);
   end
      
   centerFreqValStartInd = strfind(centerFreqLine,'">')+2;
   centerFreqValEndInd = strfind(centerFreqLine,'</')-1;        
   centerFrequency = str2num(centerFreqLine(centerFreqValStartInd:centerFreqValEndInd));
   
   if length(strfind(centerFreqLine,'format="Hz"'))>0   
       centerFrequency = centerFrequency*1;       
   elseif length(strfind(centerFreqLine,'format="kHz"'))>0   
       centerFrequency = centerFrequency*1e3;  
   elseif length(strfind(centerFreqLine,'format="MHz"'))>0   
       centerFrequency = centerFrequency*1e6;  
   elseif length(strfind(centerFreqLine,'format="GHz"'))>0   
       centerFrequency = centerFrequency*1e9;         
   else       
       disp('Something is wrong in center frequency decoding');       
   end 
   metaData.(streamID).centerFrequency = centerFrequency;
   %Translated frequency parsing
   translatedFrequencyStartIndex = regexp(currentStream,'<translatedfreq');
   translatedFrequencyEndIndex =  regexp(currentStream,'</translatedfreq>')+length('/translatedfreq>');
        
   if isempty(translatedFrequencyStartIndex)==1 && noOfStreams==1 %Case of single band system with one stream
       %Center frequency parsing
       translatedFrequencyStartIndex = regexp(xmlFileText,'<translatedfreq');
       translatedFrequencyEndIndex =  regexp(xmlFileText,'</translatedfreq>')+length('/translatedfreq>');
       translatedFrequencyLine = xmlFileText(translatedFrequencyStartIndex:translatedFrequencyEndIndex);
   else
       translatedFrequencyLine = currentStream(translatedFrequencyStartIndex:translatedFrequencyEndIndex);
   end   
   translatedFrequencyStartInd = strfind(translatedFrequencyLine,'">')+2;
   translatedFrequencyEndInd = strfind(translatedFrequencyLine,'</')-1;        
   translatedFrequency = str2num(translatedFrequencyLine(translatedFrequencyStartInd:translatedFrequencyEndInd));
   
   if length(strfind(translatedFrequencyLine,'format="Hz"'))>0   
       translatedFrequency = translatedFrequency*1;       
   elseif length(strfind(translatedFrequencyLine,'format="kHz"'))>0   
       translatedFrequency = translatedFrequency*1e3;  
   elseif length(strfind(translatedFrequencyLine,'format="MHz"'))>0   
       translatedFrequency = translatedFrequency*1e6;  
   elseif length(strfind(translatedFrequencyLine,'format="GHz"'))>0   
       translatedFrequency = translatedFrequency*1e9;         
   else       
       disp('Something is wrong in translated frequency decoding');       
   end  
   metaData.(streamID).translatedFrequency=translatedFrequency;
   
   %Bandwidth parsing
   bandwidthStartIndex = regexp(currentStream,'<bandwidth');
   bandwidthEndIndex =  regexp(currentStream,'</bandwidth>')+length('/bandwidth>');
   
   if isempty(bandwidthStartIndex)==1 && noOfStreams==1 %Case of single band system with one stream
       %Center frequency parsing
       bandwidthStartIndex = regexp(xmlFileText,'<bandwidth');
       bandwidthEndIndex =  regexp(xmlFileText,'</bandwidth>')+length('/bandwidth>');
       bandwidthLine = xmlFileText(bandwidthStartIndex:bandwidthEndIndex);
   else
       bandwidthLine = currentStream(bandwidthStartIndex:bandwidthEndIndex);
   end   
   bandwidthStartInd = strfind(bandwidthLine,'">')+2;
   bandwidthEndInd = strfind(bandwidthLine,'</')-1;        
   bandwidth = str2num(bandwidthLine(bandwidthStartInd:bandwidthEndInd));
   
   if length(strfind(bandwidthLine,'format="Hz"'))>0   
       bandwidth = bandwidth*1;       
   elseif length(strfind(bandwidthLine,'format="kHz"'))>0   
       bandwidth = bandwidth*1e3;  
   elseif length(strfind(bandwidthLine,'format="MHz"'))>0   
       bandwidth = bandwidth*1e6;  
   elseif length(strfind(bandwidthLine,'format="GHz"'))>0   
       bandwidth = bandwidth*1e9;         
   else       
       disp('Bandwidth is not provided. Initialized to zero in that case!');   
       bandwidth = 0;           
   end    
      
   metaData.(streamID).bandwidth=bandwidth;   
   
   
   for j=noOfSignals+1:length(signalTable)
       mData.(signalTable{j}) = metaData.(streamID);
       mData.freqBase = metaData.freqBase;
       mData.sampleSizeInBytes = metaData.sampleSizeInBytes;
   end
   noOfSignals = length(signalTable);
end

mData.enabledSignals = signalTable;
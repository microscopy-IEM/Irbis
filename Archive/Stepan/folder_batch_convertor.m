clc; close all; clear all;

rename = 0;

% [fileName,path] = uigetfile({'*_REF.mat;*_MSD.mat'},'MultiSelect','on');
[fileName,path] = uigetfile({'*_edited.mat'},'MultiSelect','on');
% [fileName,path] = uigetfile({'*_DC.mat';'*_MSD.mat';'*_edited.mat'},'MultiSelect','on');
% [fileName,path] = uigetfile({'*_REF.mat'},'MultiSelect','on');


if ~iscell(fileName)  
     fileName = {fileName};
end
     
numOfTRS = size(fileName,2);


allTRS = cell(1,numOfTRS);
% groupNames = cell(1,numOfTRS);

f = waitbar(0,['Processing file ' num2str(1) ' of ' num2str(numOfTRS)]);

for TRSnum = 1:numOfTRS
   
    
     % open file
%     [~,origName,~] = fileparts(fileName{TRSnum});
    

    MMpack = TRS2MMpack03(path, fileName{TRSnum});

    % Update waitbar and message
    waitbar(TRSnum/numOfTRS,f,['Processing file ' num2str(TRSnum) ' of ' num2str(numOfTRS)])

       
end

close(f)
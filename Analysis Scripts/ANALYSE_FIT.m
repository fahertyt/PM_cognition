
% function ANALYSE_FIT_exposureroutes
%
%% Script created to analyse FIT and output associated metrics %%
%
% Tom Faherty, 29th January 2024
%
% Provides average RT and Accurary for one-face trials and two-face trials
% Provides average RT and Accuracy for two-trial sequences as well as cognitive control
% Data populated for each session for each participant for later statistical analysis
%
%% SET UP SOME VARIABLES %%

merge_FIT % Creates 'Merged_FIT.xlsx' for later use

clear all
close all
clc

count = 1; % Reset count

minBlock = 0; % Change which blocks are included in the analyses
maxBlock = 5; % Change which blocks are included in the analyses (Max 4)
RT_cut = 200; % Remove all trials less than (200) ms, indicating anticipation error
RT_SDs = 2; % Number of standard deviations to cut RTs by (2)
include_incorrect = 1; % 1 = Keep incorrect trials for sequence analysis; 2 = Remove incorrect trials for sequence analysis
include_missing = 2; % 1 = Keep missed trials for sequence analysis; 2 = Remove missed trials for sequence analysis

% Set up results file

RespMat{1,1} = 'Participant ID';
RespMat{1,2} = 'Day';
RespMat{1,3} = 'Session';
RespMat{1,4} = '1-face Accuracy %';
RespMat{1,5} = '1-face RT';
RespMat{1,6} = '2-face Accuracy %';
RespMat{1,7} = '2-face RT';
RespMat{1,8} = 'Repeat Sequence RT';
RespMat{1,9} = 'Repeat Sequence Accuracy %';
RespMat{1,10} = 'Change Sequence RT';
RespMat{1,11} = 'Change Sequence Accuracy %';
RespMat{1,12} = 'Cognitive Control RT';
RespMat{1,13} = 'Cognitive Control Accuracy %';
RespMat{1,14} = 'Number missed';

results_table = readtable('Merged_FIT.xlsx'); % load results table

%% Readme for CSV file %%

% TargetClassifier = 0  Target was happy for this block
% TargetClassifier = 1  Target was fearful for this block

%% CRITICAL INFORMATION

% Reponse = 0           Incorrect
% Response = 1          Correct
% Response = 2          No response (RT = 1500)

%%

% Congruency = 0        Congruent
% Congruency = 1        Incongruent

% Sequence Type = 0     Repeat Sequence
% Sequence Type = 1     Change Sequence

% Raw RT                This is the response time for the trial (max 1500 indicates no response)

%% Analysis loop %%

% Start loop

for current_p = min(results_table.ParticipantID):max(results_table.ParticipantID) % i.e., For participant number 1:X
    for current_d = min(results_table.DayNumber):max(results_table.DayNumber) % i.e., For visit number 0:X
        for current_s = min(results_table.SessionNumber):max(results_table.SessionNumber) % i.e., For session number 1:2
            
            current_p % Print current participant (So we know the code is running)
            current_d % Print current visit (So we know the code is running)
            current_s % Print current session (So we know the code is running)
            
            % Reset our temporary structures
            
            currentResults = [];
            onetrialResults = [];
            sequenceResults = [];
            
            % Find the results for this participant, session, and visit within the table
            
            currentResults.block = results_table.BlockNumber(results_table.ParticipantID == current_p & results_table.DayNumber == current_d & results_table.SessionNumber == current_s & results_table.RawRT > RT_cut);
            currentResults.blocktrial = results_table.BlockTrialNumber(results_table.ParticipantID == current_p & results_table.DayNumber == current_d & results_table.SessionNumber == current_s & results_table.RawRT > RT_cut);
            currentResults.onetrialType = results_table.TrialType(results_table.ParticipantID == current_p & results_table.DayNumber == current_d & results_table.SessionNumber == current_s & results_table.RawRT > RT_cut); % 1 = 1-face; 2 = 2-face
            currentResults.Response = results_table.Correct_(results_table.ParticipantID == current_p & results_table.DayNumber == current_d & results_table.SessionNumber == current_s & results_table.RawRT > RT_cut); % 0 = Incorrect Response; 1 = Correct Response; 2 = No Response
            currentResults.Accuracy = double(results_table.Correct_(results_table.ParticipantID == current_p & results_table.DayNumber == current_d & results_table.SessionNumber == current_s & results_table.RawRT > RT_cut) == 1); % 1 = Correct; 0 = Incorrect
            currentResults.RT = results_table.RawRT(results_table.ParticipantID == current_p & results_table.DayNumber == current_d & results_table.SessionNumber == current_s & results_table.RawRT > RT_cut);
            
            % Missed trials (Just to indicate unreasonable numbers of errors)
            
            miss_array = results_table.Response(results_table.ParticipantID == current_p & results_table.DayNumber == current_d & results_table.SessionNumber == current_s);
            
            miss_find = find(strcmp('.',miss_array));
            
            miss_num = size(miss_find,1);
            
            
            % Convert structure to table
            
            currentResults = struct2table(currentResults);
            
            % Unused code to remove first X blocktrials
            
            % currentResults.blocktrial(currentResults.blocktrial < (X+1)) = NaN;
            
            % Remove extra blocks if necessary
            
            currentResults.block(currentResults.block < minBlock | currentResults.block > maxBlock) = NaN;
            currentResults = rmmissing(currentResults);
            
            % We don't want to trim our sequences in the same way, so lets create that here
            
            sequenceResults = currentResults;
            
            % Now we can force NaN for responded one-face and two-face trials which are out of a specific range (i.e., 2.5 SDs away from trial type average)
            
            currentResults.RT(currentResults.RT > (mean(currentResults.RT(currentResults.onetrialType == currentResults.onetrialType & currentResults.Response < 2))+(RT_SDs*(std(currentResults.RT(currentResults.onetrialType == currentResults.onetrialType & currentResults.Response < 2))))) | currentResults.RT < (mean(currentResults.RT(currentResults.onetrialType == currentResults.onetrialType & currentResults.Response < 2))-(RT_SDs*(std(currentResults.RT(currentResults.onetrialType == currentResults.onetrialType & currentResults.Response < 2)))))) = NaN;
            
            % Make sure Missed trials all have the same RT
            
            currentResults.RT(currentResults.Response == 2) = 1500;
            
            % Now we can remove all of these NaN rows from our analyses
            
            currentResults = rmmissing(currentResults);
            
            %% Now we have trimmed, we create two seperate tables before any of the other analysis takes place %%
            
            onetrialResults = currentResults;
            
            % Create blank array
            
            onetrial_struct = [];
            
            % Calculate Accuracy for all two-face trials
            
            twoface_acc = mean(onetrialResults.Accuracy(onetrialResults.onetrialType == 2));
            
            % Calculate mean RT for all two-face trials (correct trials only)
            
            twoface_RT = mean(onetrialResults.RT(onetrialResults.onetrialType == 2 & onetrialResults.Accuracy == 1));
            
            % Calculate Accuracy for one-face trial type
            
            oneface_acc = mean(onetrialResults.Accuracy(onetrialResults.onetrialType == 1));
            
            % Calculate mean RT for one-face trial type (correct trials only)
            
            oneface_RT = mean(onetrialResults.RT(onetrialResults.onetrialType == 1 & onetrialResults.Accuracy == 1));
            
            % Identify two-trial sequence results
            
            for i = 1:length(sequenceResults.blocktrial) % Go through all the trials
                
                if include_missing == 1 % If we want to include missed trials
                    
                    if i ~= 1 && sequenceResults.blocktrial(i)-1 == sequenceResults.blocktrial(i-1) % If first iteration is not 1 AND the previous trial is actually the previous trial
                        if sequenceResults.onetrialType(i) == 1 % If current trial is a 1-face trial
                            if sequenceResults.onetrialType(i-1) == 1 % If previous trial is a 1-face
                                sequenceResults.sequenceType(i) = 3;
                            else
                                sequenceResults.sequenceType(i) = 2;
                            end
                        else % Current trial is a 2-face trial
                            if sequenceResults.onetrialType(i-1) == 1 % If previous trial is a 1-face
                                sequenceResults.sequenceType(i) = 1; % Change sequence
                            else % Repeat sequence
                                sequenceResults.sequenceType(i) = 0;
                            end
                        end
                    else % First block trial, or removed trial in between
                        sequenceResults.sequenceType(i) = NaN;
                    end
                    
                else % If we don't want to include missed trials
                    
                    if i ~= 1 && sequenceResults.Response(i-1) < 2 && sequenceResults.Response(i) < 2 && sequenceResults.blocktrial(i)-1 == sequenceResults.blocktrial(i-1) % If first iteration is not 1 AND the previous trial is actually the previous trial, AND the current or previous trial isn't missed
                        
                        if sequenceResults.onetrialType(i) == 1 % If current trial is a 1-face trial
                            if sequenceResults.onetrialType(i-1) == 1 % If previous trial is a 1-face
                                sequenceResults.sequenceType(i) = 3;
                            else
                                sequenceResults.sequenceType(i) = 2;
                            end
                        else % Current trial is a 2-face trial
                            if sequenceResults.onetrialType(i-1) == 1 % If previous trial is a 1-face
                                sequenceResults.sequenceType(i) = 1; % Change sequence
                            else % Repeat sequence
                                sequenceResults.sequenceType(i) = 0;
                            end
                        end
                    else % First block trial, or removed trial in between
                        sequenceResults.sequenceType(i) = NaN;
                    end
                end
                
            end
            
            % Now we need to trim based on our sequence types
            
            % First we remove some NaNs we just created
            
            sequenceResults = rmmissing(sequenceResults);
            
            % First we remove some NaNs we just created
            
            sequenceResults = rmmissing(sequenceResults);
            
            % Now we can delete all trials with incorrect responses (if we so wish)
            
            if include_incorrect == 2
                sequenceResults.RT(sequenceResults.Accuracy == 0) = NaN          
                sequenceResults = rmmissing(sequenceResults);
            end
            
            % Then we can force NaN for responded one-face and two-face trials which are out of a specific range (i.e., 2 SDs away from trial type average)
            
            if isempty(sequenceResults) == 0
                sequenceResults.RT(sequenceResults.RT > (mean(sequenceResults.RT(sequenceResults.sequenceType == sequenceResults.sequenceType)+(RT_SDs*(std(sequenceResults.RT(sequenceResults.sequenceType == sequenceResults.sequenceType)))))) | sequenceResults.RT < (mean(sequenceResults.RT(sequenceResults.sequenceType == sequenceResults.sequenceType)-(RT_SDs*(std(sequenceResults.RT(sequenceResults.sequenceType == sequenceResults.sequenceType))))))) = NaN;
            end

            % Now we can remove all of these NaN rows again
            
            sequenceResults = rmmissing(sequenceResults);
            
            % Now we can find out information on change and repeat sequences
            
            if isempty(sequenceResults) % For missing data
                repeat_RT = NaN;
                change_RT = NaN;
                repeat_acc = NaN;
                change_acc = NaN;
            else
                repeat_RT = mean(sequenceResults.RT(sequenceResults.sequenceType == 0), 'omitnan');
                change_RT = mean(sequenceResults.RT(sequenceResults.sequenceType == 1), 'omitnan');
                repeat_acc = mean(sequenceResults.Accuracy(sequenceResults.sequenceType == 0), 'omitnan');
                change_acc = mean(sequenceResults.Accuracy(sequenceResults.sequenceType == 1), 'omitnan');
            end
            
            % Work out the accuracy, RTs, and other values and save data to associated participant, visit, and session
            
            RespMat{count+1,1} = current_p;
            RespMat{count+1,2} = current_d;
            RespMat{count+1,3} = current_s;
            RespMat{count+1,4} = oneface_acc;
            RespMat{count+1,5} = oneface_RT;
            RespMat{count+1,6} = twoface_acc;
            RespMat{count+1,7} = twoface_RT;
            RespMat{count+1,8} = repeat_RT;
            RespMat{count+1,9} = repeat_acc;
            RespMat{count+1,10} = change_RT;
            RespMat{count+1,11} = change_acc;
            RespMat{count+1,12} = change_RT - repeat_RT;
            RespMat{count+1,13} = change_acc - repeat_acc;
            RespMat{count+1,14} = miss_num;
            
            count = count + 1; % Increase count for writing data
            
        end % Next session
    end % Next visit
end % Next participant

% Delete rows where oneface_RT contains NaN (This will catch all participants who do not have data for session 2 etc.)

RespMat( cellfun( @(C) isnumeric(C) && isnan(C), RespMat(:,5) ), :) = [];

% Save .xlsx

VarNames = RespMat(1,:);
RespMatNew = RespMat(2:end,:);
Data =  cell2table(RespMatNew);
Data.Properties.VariableNames = VarNames;

writetable(Data, 'FIT_Results.xlsx')

% End !
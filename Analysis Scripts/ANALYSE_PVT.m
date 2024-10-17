
% function ANALYSE_PVT_ExposureRoutes
%
%% Script created to analyse PVT and output associated metrics %%
%
% Tom Faherty, 7th August 2023
%
% Counts number of on-time trials, late trials, and missed trials for short and long fixations
% Provides average RT for trials with short and long fixations after trimming
% Data populated for each session for each participant for later statistical analysis
%
%% SET UP SOME VARIABLES %%

merge_PVT % Creates 'Merged_PVT.xlsx' for later use

clear all
close all
clc

count = 1; % Reset count

trialNum_cut = 0; % Number of trials to ignore in analysis (2 = first long and first short)
RT_cut = 0; % Remove all trials less than 100 ms, indicating anticipation error
RT_SDs = 100; % Number of standard deviations to cut RTs by (i.e., Do not cut)

% (!!DO NOT CHANGE!!)
RT_ontime = 400; % Cut off for correct 'ontime' trials
% (!!DO NOT CHANGE!!)
RT_delay = 800; % Cut off for trials not missed

% As accuracy is based on RT, we don't need both measures. We just want simple RT

% Set up results file

RespMat{1,1} = 'Participant ID';
RespMat{1,2} = 'Day';
RespMat{1,3} = 'Session';
RespMat{1,4} = 'Number of trials remaining after trimming';
RespMat{1,5} = '% On-time short trials';
RespMat{1,6} = '% Missed short trials';
RespMat{1,7} = '% On-time long trials';
RespMat{1,8} = '% Missed long trials';
RespMat{1,9} = 'Short trial RTs (all)';
RespMat{1,10} = 'Long trial RTs (all)';

results_table = readtable('Merged_PVT.xlsx'); % load results table

%% Readme for CSV file %%

% Trial type = Short    Fixation prior to stim presentation was 400 to 1800 ms)
% Trial type = Long     Fixation prior to stim presentation was 25 to 35 s)

% Correct? = 1          Participant responded to stim within 400 ms
% Correct? = 0          Participant did not respond to stim within 400 ms

% Raw RT                This is the response time for the trial (max 800 indicates missed trial)

%% Analysis loop %%

% Start loop

for current_p = min(results_table.ParticipantID):max(results_table.ParticipantID) % i.e., For participant number 1:X
    for current_d = min(results_table.DayNumber):max(results_table.DayNumber) % i.e., For day number 1:X
        for current_s = min(results_table.SessionNumber):max(results_table.SessionNumber) % i.e., For session number 1:X

            current_p % Print current participant (So we know the code is running)
            current_d % Print current day (So we know the code is running)
            current_s % Print current session (So we know the code is running)

            % Reset our temporary structure

            currentResults = [];

            % Find the results for this participant, session, and day within the table

            currentResults.accuracy = results_table.Response_(results_table.ParticipantID == current_p & results_table.DayNumber == current_d & results_table.SessionNumber == current_s & results_table.RawRT > RT_cut);
            currentResults.RT = results_table.RawRT(results_table.ParticipantID == current_p & results_table.DayNumber == current_d & results_table.SessionNumber == current_s & results_table.RawRT > RT_cut);
            currentResults.trialLength = double(results_table.TrialType(results_table.ParticipantID == current_p & results_table.DayNumber == current_d & results_table.SessionNumber == current_s & results_table.RawRT > RT_cut) == "Long");
            
            % Convert structure to table

            currentResults = struct2table(currentResults);

            %% Code below if we want to cut the trials before any of the other analysis takes place %%

            currentResults = currentResults((trialNum_cut+1):end, :);
            
            % Now need to create a new variable with actual responses
            %
            % trialResp (On-time = 1; Late = 0; Missed = 2)
            %

            currentResults.trialResp = zeros(length(currentResults.RT), 1);

            % Populate trialResp using RT cut-offs

            currentResults.trialResp(currentResults.RT < (RT_ontime+1)) = 1; % On-time (Correct)
            currentResults.trialResp(currentResults.RT < RT_delay & currentResults.RT > RT_ontime) = 0; % Late (Incorrect)
            currentResults.trialResp(currentResults.RT > RT_delay-1) = 2; % Missed (Incorrect)
            
            % Now we can force NaN for trials which are out of a specific range (i.e., 2.5 SDs away from trial type average)

            % Do this for on-time + late responses together. RT = 800 for missed responses so no trimming required
            
            currentResults.RT(currentResults.RT > (mean(currentResults.RT(currentResults.trialLength == currentResults.trialLength & currentResults.trialResp < 2)) + (RT_SDs*std(currentResults.RT(currentResults.trialLength == currentResults.trialLength & currentResults.trialResp < 2)))) | currentResults.RT < (mean(currentResults.RT(currentResults.trialLength == currentResults.trialLength & currentResults.trialResp < 2))-(RT_SDs*std(currentResults.RT(currentResults.trialLength == currentResults.trialLength & currentResults.trialResp < 2))))) = NaN;
            currentResults.RT(currentResults.trialResp == 2) = 800; % Make sure missed trials are not NaNs

            % Lets remove all of these NaN rows from our analyses

            currentResults = rmmissing(currentResults);

            % Work out the accuracy, RTs, and other values and save data to associated participant, day, and session

            RespMat{count+1,1} = current_p;
            RespMat{count+1,2} = current_d;
            RespMat{count+1,3} = current_s;
            RespMat{count+1,4} = length(currentResults.trialResp);
            RespMat{count+1,5} = round(sum(currentResults.trialLength == 0 & currentResults.trialResp == 1) / sum(currentResults.trialLength == 0), 3);
            RespMat{count+1,6} = round(sum(currentResults.trialLength == 0 & currentResults.trialResp == 2) / sum(currentResults.trialLength == 0), 3);
            RespMat{count+1,7} = round(sum(currentResults.trialLength == 1 & currentResults.trialResp == 1) / sum(currentResults.trialLength == 1), 3);
            RespMat{count+1,8} = round(sum(currentResults.trialLength == 1 & currentResults.trialResp == 2) / sum(currentResults.trialLength == 1), 3);
            RespMat{count+1,9} = round(mean(currentResults.RT(currentResults.trialLength == 0 & currentResults.trialResp < 2)), 3);
            RespMat{count+1,10} = round(mean(currentResults.RT(currentResults.trialLength == 1 & currentResults.trialResp < 2)), 3);

            count = count + 1; % Increase count for writing data

        end % Next session
    end % Next day
end % Next participant

% Delete rows where on-time short accuracy contains NaN (This will catch all participants who do not have data for session 2 etc.)

RespMat( cellfun( @(C) isnumeric(C) && isnan(C), RespMat(:,5) ), :) = [];

% Save .xlsx

VarNames = RespMat(1,:);
RespMatNew = RespMat(2:end,:);
Data =  cell2table(RespMatNew);
Data.Properties.VariableNames = VarNames;

writetable(Data, 'PVT_Results_ExposureRoutes.xlsx')

% End !
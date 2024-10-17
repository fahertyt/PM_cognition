
% function ANALYSE_ERT_exposureroutes
%
%% Script created to analyse ERT and output associated metrics %%
%
% Tom Faherty, 3rd August 2023
%
% Provides d-prime, approach bias, and mean Hit Response Time for all possible conditions
% Provides overall discrimination (d-prime across all conditions) and False Alarm RT
% Data populated for each session for each participant for later statistical analysis
%
%% SET UP SOME VARIABLES %%

merge_ERT % Creates 'Merged_ERT.xlsx' for later use

clear all
close all
clc

count = 1; % Reset count

minBlock = 0; % Change which blocks are included in the analyses
maxBlock = 7; % Change which blocks are included in the analyses
RT_cut = 200; % Remove all trials less than (200 ms), indicating anticipation error
RT_SDs = 2; % Number of standard deviations (2) to cut RTs by

% Set up results file

RespMat{1,1} = 'Participant ID';
RespMat{1,2} = 'Day';
RespMat{1,3} = 'Session';
RespMat{1,4} = 'Task switching d-prime';
RespMat{1,5} = 'Task switching Hit RT';
RespMat{1,6} = 'Happy d-prime';
RespMat{1,7} = 'Fearful d-prime';
RespMat{1,8} = 'Happy Hit RT';
RespMat{1,9} = 'Fearful Hit RT';
RespMat{1,10} = 'Happy False Alarm RT';
RespMat{1,11} = 'Fearful False Alarm RT';
RespMat{1,12} = 'Overall d-prime';

results_table = readtable('Merged_ERT.xlsx'); % load results table

%% Readme for CSV file %%

% TargetClassifier = 0  Target was happy for this block
% TargetClassifier = 1  Target was fearful for this block

%% CRITICAL INFORMATION

% FAHitCROrMiss_ = 0    False Alarm
% FAHitCROrMiss_ = 1    Hit
% FAHitCROrMiss_ = 2    Correct Rejection
% FAHitCROrMiss_ = 3    Miss

%%

% Stimulus Mouth = 0    Open mouth image
% Stimulus Mouth = 1    Closed mouth image

% Task switch = 0       First 8 trials in block 2 onwards (50/50 emotion expression)
% Task switch = 1       Main trials in block (66/33 emotion expression)

% Raw RT                This is the response time for the trial (max 800 indicates no response)

%% Analysis loop %%

% Start loop

for current_p = min(results_table.ParticipantID):max(results_table.ParticipantID) % i.e., For participant number 1:X
    for current_d = min(results_table.DayNumber):max(results_table.DayNumber) % i.e., For day number 1:X
        for current_s = min(results_table.SessionNumber):max(results_table.SessionNumber) % i.e., For session number 1:X

            current_p % Print current participant (So we know the code is running)
            current_d % Print current day (So we know the code is running)
            current_s % Print current session (So we know the code is running)

            % Reset our temporary structures and other values

            hit_count = []; % Hit = 1
            FA_count = []; % False Alarm = 0
            miss_count = []; % Miss = 3
            CR_count = []; % Correct Rejection = 2
            overall_d_prime = [];

            currentResults = [];
            switchResults = [];
            biasResults = [];

            % Find the results for this participant, session, and day within the table

            currentResults.block = results_table.BlockNumber(results_table.ParticipantID == current_p & results_table.DayNumber == current_d & results_table.SessionNumber == current_s);
            currentResults.switchType = results_table.BlockTrialNumber(results_table.ParticipantID == current_p & results_table.DayNumber == current_d & results_table.SessionNumber == current_s) > 8; % 0 = Switch, 1 = Main
            currentResults.targetType = results_table.TargetClassifier(results_table.ParticipantID == current_p & results_table.DayNumber == current_d & results_table.SessionNumber == current_s);
            currentResults.signalResponse = results_table.FAHitCROrMiss_(results_table.ParticipantID == current_p & results_table.DayNumber == current_d & results_table.SessionNumber == current_s);
            currentResults.RT = results_table.RawRT(results_table.ParticipantID == current_p & results_table.DayNumber == current_d & results_table.SessionNumber == current_s);

            % Convert structure to table

            currentResults = struct2table(currentResults);

            % Remove extra blocks if necessary

            currentResults.block(currentResults.block < minBlock | currentResults.block > maxBlock) = NaN;
            currentResults = rmmissing(currentResults);

            %% Need to create two seperate tables before any of the other analysis takes place %%

            switchResults = currentResults;
            switchResults(switchResults.block < 2,:) = []; % Remove 1st block (as no switch occurs! Although starting the task is kind of a switch? Whatever remove it)
            switchResults(switchResults.switchType,:) = [];
            biasResults = currentResults;
            % biasResults(~biasResults.switchType,:) = []; % If we want to remove switch trials from bias analyses we put this in

            % We need to trim our bias trials now!!

            biasResults.RT(biasResults.RT < RT_cut) = NaN;
            biasResults = rmmissing(biasResults);

            % Now we can force NaN for Hit & FA trials which are out of a specific range (i.e., 2 SDs away from trial type average)

            biasResults.RT(biasResults.RT > (mean(biasResults.RT(biasResults.targetType == biasResults.targetType & biasResults.signalResponse == biasResults.signalResponse))+(RT_SDs*(std(biasResults.RT(biasResults.targetType == biasResults.targetType & biasResults.signalResponse == biasResults.signalResponse))))) | biasResults.RT < (mean(biasResults.RT(biasResults.targetType == biasResults.targetType & biasResults.signalResponse == biasResults.signalResponse))-(RT_SDs*(std(biasResults.RT(biasResults.targetType == biasResults.targetType & biasResults.signalResponse == biasResults.signalResponse)))))) = NaN;

            % Make sure CR & Miss trials have the same RT

            biasResults.RT(biasResults.signalResponse == 2 | biasResults.signalResponse == 3) = 800;

            % Now we can remove all of these NaN rows from our analyses

            biasResults = rmmissing(biasResults);

            % Not enough trials to trim switch costs, but lets do the analysis here before we forget!

            % Create blank array

            switch_struct = [];

            hit_count = nnz(switchResults.signalResponse == 1);
            miss_count = nnz(switchResults.signalResponse == 3);
            FA_count = nnz(switchResults.signalResponse == 0);
            CR_count = nnz(switchResults.signalResponse == 2);

            HitRate = hit_count / (hit_count+miss_count);
            FalseAlarmRate = FA_count / (FA_count+CR_count);

            if HitRate == 0
                CalcHitRate = 0.01;
            elseif HitRate == 1
                CalcHitRate = 0.99;
            else
                CalcHitRate = HitRate;
            end

            if FalseAlarmRate == 0
                CalcFalseAlarmRate = 0.01;
            elseif FalseAlarmRate == 1
                CalcFalseAlarmRate = 0.99;
            else
                CalcFalseAlarmRate = FalseAlarmRate;
            end

            % Calculate d prime

            d_prime = norminv(CalcHitRate, 0, 1) - norminv(CalcFalseAlarmRate, 0, 1);

            % Calculate hit RT

            mean_hit_RT = mean(switchResults.RT(switchResults.signalResponse == 1));

            switch_struct.d = d_prime;
            switch_struct.RT = mean_hit_RT;

            % Now we need to look at the full data (including the 8 task switch trials)

            % Create blank array

            results_struct = [];

            % Set up a loop to create d' and hit RT for each emotion type

            for thisEmotion = 0:1

                hit_count = nnz(biasResults.targetType == thisEmotion & biasResults.signalResponse == 1);
                miss_count = nnz(biasResults.targetType == thisEmotion & biasResults.signalResponse == 3);
                FA_count = nnz(biasResults.targetType == thisEmotion & biasResults.signalResponse == 0);
                CR_count = nnz(biasResults.targetType == thisEmotion & biasResults.signalResponse == 2);

                % Calculate RTs

                mean_hit_RT = mean(biasResults.RT(biasResults.targetType == thisEmotion & biasResults.signalResponse == 1));
                mean_FA_RT = mean(biasResults.RT(biasResults.targetType == thisEmotion & biasResults.signalResponse == 0));


                HitRate = hit_count / (hit_count+miss_count);
                FalseAlarmRate = FA_count / (FA_count+CR_count);

                if HitRate == 0
                    CalcHitRate = 0.01;
                elseif HitRate == 1
                    CalcHitRate = 0.99;
                else
                    CalcHitRate = HitRate;
                end

                if FalseAlarmRate == 0
                    CalcFalseAlarmRate = 0.01;
                elseif FalseAlarmRate == 1
                    CalcFalseAlarmRate = 0.99;
                else
                    CalcFalseAlarmRate = FalseAlarmRate;
                end

                % Calculate d prime

                d_prime = norminv(CalcHitRate, 0, 1) - norminv(CalcFalseAlarmRate, 0, 1);

                % Store this information in a sensible way for later

                if thisEmotion == 0
                    results_struct.happy.d = d_prime;
                    results_struct.happy.RT = mean_hit_RT;
                    results_struct.happy.FA_RT = mean_FA_RT;
                else
                    results_struct.fearful.d = d_prime;
                    results_struct.fearful.RT = mean_hit_RT;
                    results_struct.fearful.FA_RT = mean_FA_RT;
                end

                d_prime = []; % Reset d_prime
                mean_hit_RT = []; % Reset mean_hit_RT
                mean_FA_RT = []; % Reset mean_FA_RT

            end


            % Calculate overall d prime

            overall_d_prime = (results_struct.happy.d + results_struct.fearful.d) / 2

            % Work out the accuracy, RTs, and other values and save data to associated participant, day, and session

            RespMat{count+1,1} = current_p;
            RespMat{count+1,2} = current_d;
            RespMat{count+1,3} = current_s;
            RespMat{count+1,4} = round(switch_struct.d, 3);
            RespMat{count+1,5} = round(switch_struct.RT, 0);
            RespMat{count+1,6} = round(results_struct.happy.d, 3);
            RespMat{count+1,7} = round(results_struct.fearful.d, 3);
            RespMat{count+1,8} = round(results_struct.happy.RT, 0);
            RespMat{count+1,9} = round(results_struct.fearful.RT, 0);
            RespMat{count+1,10} = round(results_struct.happy.FA_RT, 0);
            RespMat{count+1,11} = round(results_struct.fearful.FA_RT, 0);
            RespMat{count+1,12} = round(overall_d_prime, 3);

            count = count + 1; % Increase count for writing data

        end % Next session
    end % Next day
end % Next participant

% Delete rows where all d-prime contains NaN (This will catch all participants who do not have data for session 2 etc.)

RespMat( cellfun( @(C) isnumeric(C) && isnan(C), RespMat(:,12) ), :) = [];

% Save .xlsx

VarNames = RespMat(1,:);
RespMatNew = RespMat(2:end,:);
Data =  cell2table(RespMatNew);
Data.Properties.VariableNames = VarNames;

writetable(Data, 'ERT_Results.xlsx')

% End !
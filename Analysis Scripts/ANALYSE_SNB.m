
% function ANALYSE_SNB_ExposureRoutesclear
%
%% Script created to analyse n-back and output associated metrics %%
%
% Tom Faherty, 18th April 2023
%
% Counts number of missed trials (To check Ps are doing task). Creates the dʹ metric using signal detection theory
% i.e., Hit rate [#Hits / (#Hits + #Misses)] minus False Alarm rate [#FA / (#FA + #CR)].
% Data populated for each session for each participant for each n for later statistical analysis
%
%% SET UP SOME VARIABLES %%

merge_SNB % Creates 'Merged_SNB.xlsx' for later use

clear all
close all
clc

count = 1;

% Set up results file

RespMat{1,1} = 'Participant ID';
RespMat{1,2} = 'Day';
RespMat{1,3} = 'Session';

results_table = readtable('Merged_SNB.xlsx'); % load results table

%% Readme for CSV file %%

% Trial type = 0        This trial was different to 1-back (not a match)
% Trial type = 1        This trial was the same as 1-back (match)

% n = 2                 This was a 2-back

% Correct response      This was the expected key press for a correct response

% Response              This was the key pressed [NA indicates empty trial, i.e., Correct? = 3]

% Correct? = 0          This trial was correct
% Correct? = 1          This trial was incorrect
% Correct? = 2          This trial was missed
% Correct? = 3          This trial is empty and does not count (start trial which no response is needed for)

% Raw RT                This is the response time for the trial

%% Analysis loop %%

% Start loop

for current_p = min(results_table.ParticipantID):max(results_table.ParticipantID) % i.e., For participant number 1:X
    for current_d = min(results_table.DayNumber):max(results_table.DayNumber) % i.e., For day number 0:X
        for current_s = min(results_table.SessionNumber):max(results_table.SessionNumber) % i.e., For session number 1:2

            current_p % Print current participant (So we know the code is running)
            current_d % Print current day (So we know the code is running)
            current_s % Print current session (So we know the code is running)

            % In other codes here is where we would do data trimming

            for current_n = min(results_table.n):max(results_table.n) % For each n

                % Reset our temporary rows

                accuracy = [];
                RT = [];
                trial_type = [];

                % Reset our counts

                missedtrials = 0;

                FA_count = 0;
                hit_count = 0;
                CR_count = 0;
                miss_count = 0;

                % Find the results for this participant, session, day, and n within the table

                % This no longer works for some reason... accuracy = double(results_table.Correct_((results_table.n == current_n * (results_table.SessionNumber == current_s * (results_table.DayNumber == current_d * (results_table.ParticipantID == current_p * (results_table.Correct_ < 3)))))) == 1);
                % This no longer works for some reason... RT = results_table.RawRT((results_table.ParticipantID == current_p*(results_table.DayNumber == current_d*(results_table.SessionNumber == current_s*(results_table.n == current_n*(results_table.Correct_ < 2))))));
                % This no longer works for some reason... trial_type = double(results_table.TrialType((results_table.ParticipantID == current_p*(results_table.DayNumber == current_d*(results_table.SessionNumber == current_s*(results_table.n == current_n*(results_table.Correct_ < 3)))))) == 1);

                accuracy = results_table.Correct_(results_table.Correct_ < 3 & results_table.n == current_n & results_table.SessionNumber == current_s & results_table.DayNumber == current_d & results_table.ParticipantID == current_p);
                RT = results_table.RawRT(results_table.Correct_ < 3 & results_table.n == current_n & results_table.SessionNumber == current_s & results_table.DayNumber == current_d & results_table.ParticipantID == current_p);
                trial_type = results_table.TrialType(results_table.Correct_ < 3 & results_table.n == current_n & results_table.SessionNumber == current_s & results_table.DayNumber == current_d & results_table.ParticipantID == current_p);
                
                missedtrials = sum(results_table.Correct_(results_table.Correct_ < 3 & results_table.n == current_n & results_table.SessionNumber == current_s & results_table.DayNumber == current_d & results_table.ParticipantID == current_p) == 2);

                % This no longer works for some reason...  missedtrials = sum(double(results_table.Correct_((results_table.n == current_n*(results_table.ParticipantID == current_p*(results_table.DayNumber == current_d*(results_table.SessionNumber == current_s*(results_table.Correct_ < 3)))))) == 2));

                % Signal detection theory values

                FA_count = nnz(~accuracy & ~trial_type);
                hit_count = nnz(accuracy & trial_type);
                CR_count = nnz(accuracy & ~trial_type);
                miss_count = nnz(~accuracy & trial_type);

                % Calculate Hit Rate and False Alarm Rate

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

                % Let's find the average RT too just for fun (ignoring missed trials)

                mean_RT = mean(RT,'omitnan');

                % Save data to associated participant, day, and session

                RespMat{count+1,1} = current_p;
                RespMat{count+1,2} = current_d;
                RespMat{count+1,3} = current_s;
                RespMat{1,(1+((current_n-1)*10)+3)} = sprintf('n_%d', current_n);
                RespMat{1,(2+((current_n-1)*10)+3)} = sprintf('Missed trials_%d', current_n);
                RespMat{1,(3+((current_n-1)*10)+3)} = sprintf('False Alarms_%d', current_n);
                RespMat{1,(4+((current_n-1)*10)+3)} = sprintf('Hits_%d', current_n);
                RespMat{1,(5+((current_n-1)*10)+3)} = sprintf('Correct Rejections_%d', current_n);
                RespMat{1,(6+((current_n-1)*10)+3)} = sprintf('Misses_%d', current_n);
                RespMat{1,(7+((current_n-1)*10)+3)} = sprintf('Hit Rate_%d', current_n);
                RespMat{1,(8+((current_n-1)*10)+3)} = sprintf('FA Rate_%d', current_n);
                RespMat{1,(9+((current_n-1)*10)+3)} = sprintf('d prime_%d', current_n);
                RespMat{1,(10+((current_n-1)*10)+3)} = sprintf('RT_%d', current_n);
                RespMat{count+1,(1+((current_n-1)*10)+3)} = current_n;
                RespMat{count+1,(2+((current_n-1)*10)+3)} = missedtrials;
                RespMat{count+1,(3+((current_n-1)*10)+3)} = FA_count;
                RespMat{count+1,(4+((current_n-1)*10)+3)} = hit_count;
                RespMat{count+1,(5+((current_n-1)*10)+3)} = CR_count;
                RespMat{count+1,(6+((current_n-1)*10)+3)} = miss_count;
                RespMat{count+1,(7+((current_n-1)*10)+3)} = HitRate;
                RespMat{count+1,(8+((current_n-1)*10)+3)} = FalseAlarmRate;
                RespMat{count+1,(9+((current_n-1)*10)+3)} = d_prime;
                RespMat{count+1,(10+((current_n-1)*10)+3)} = round(mean_RT);

            end % Next n

            count = count + 1; % Increase count for writing data

        end % Next session
    end % Next day
end % Next participant

% Delete rows containing NaN

RespMat(any(cellfun(@(x) any(isnan(x)),RespMat),2),:) = [];

% Save .xlsx

VarNames = RespMat(1,:);
RespMatNew = RespMat(2:end,:);
Data =  cell2table(RespMatNew);
Data.Properties.VariableNames = VarNames;

writetable(Data, 'SNB_Results_ExposureRoutes.xlsx')

% End !

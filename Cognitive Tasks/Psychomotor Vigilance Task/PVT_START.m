
% function PVT_START
%
%% Psychomotor Vigilance Task
%
%% Simple Psychomotor Vigilance Task %%
%
% Dr Tom Faherty, June 2022
% t.b.s.faherty@bham.ac.uk
%
% Participant task is to respond with a spacebar press when the red dot
% appears. Some dots appear in quick succession (400 - 1800 ms), others are
% seperated by a long break (25 - 35 s)
%
% Set up for Windows
%
%% SET UP SOME VARIABLES %%

clearvars -except pcarryover; % For running all tasks b2b
close all;
clc;

rng('default');
rng('shuffle'); % Randomise Random Number Generator
MainFolder = pwd;

%%%%%%%%%%%%%%%%%%%%

% Prompt to collect participant information

readyStart = 0;
while readyStart < 1
    prompt={'Participant ID', 'Testing Day', 'Session Number', 'Practice? [Y / N]'};
    if exist('pcarryover', 'var') == 1 % If carry over from previous task
        if pcarryover{2} == "1" && pcarryover{3} == "1"
            defaults = {pcarryover{1},pcarryover{2},pcarryover{3}, 'Y'};
        else
            defaults = {pcarryover{1},pcarryover{2},pcarryover{3}, 'N'};
        end
    else
        defaults = {'XX','1','1', 'Y'};
    end
    ANSWER = inputdlg(prompt, 'Psychomotor Vigilance Task', 1, defaults);
    if isempty(ANSWER)
        % User clicked cancel. Bail out! Bail out!
        close all;
        readyStart = 1;
        clearvars -except pcarryover;
        error('User Clicked Cancel')
    elseif upper(ANSWER{4}) ~= 'Y' && upper(ANSWER{4}) ~= 'N'
        close all;
        readyStart = 1;
        clearvars -except pcarryover;
        error('Must choose Y or N for practice')
    else
        readyStart = 1;
    end
end

subjectInitials = (ANSWER{1});
dayNumber = (ANSWER{2});
sessionNumber = (ANSWER{3});
pcarryover = {subjectInitials,dayNumber, sessionNumber}; % Temporarily save participant ID and session number
practice = (ANSWER{4}); % Save practice

if practice == 'Y'
    practice = 0;
else
    practice = 1;
end

%% Keyboard Setup %%

KbName('UnifyKeyNames');
KbCheckList = [KbName('space'), KbName('q')];
RestrictKeysForKbCheck(KbCheckList);

%% SET SOME VARIABLES %%

numTrialsPrac = 5;
numTrialsMain = 85;
showInstructions = 1;
fixMinQuick = 400;
fixMaxQuick = 1800;
fixMinSlow = 25000; % 25 s
fixMaxSlow = 35000; % 35 s

ListenChar(2); % Avoid key presses affecting code
HideCursor; % Remove cursor from screen

formatDate = 'dd-mm-yy'; % Set date format
formatTime = 'HH:MM:SS'; % Set time format
todays_date = datestr(now, formatDate); % Today's date in correct format

% Set up screen

WaitSecs(5) % Pause

WhichScreen = max(Screen('Screens'));
black = BlackIndex(WhichScreen); % Black is 0
white = WhiteIndex(WhichScreen); % White is 255
BackgroundColour = black; % Background is set to black

TextSize = 35;
TextFont = 'Arial';
TextNormal = [255 255 255]; % normal (white) text colour
TextRed = [255 60 0]; % warning text colour

window = PsychImaging('OpenWindow', WhichScreen, 0, []);  % Open up a screen

%

Screen('FillRect', window, BackgroundColour); % Create screen background
Screen('Flip', window);
Priority(MaxPriority(window));
[ScreenXPixels, ScreenYPixels] = Screen('WindowSize', window);
Screen('TextSize', window, 100);

% Set up screen timings

ifi = Screen('GetFlipInterval',window); % How long is a frame in ms
ScreenRefreshRate = 1/ifi; % Calculate refresh rate

% Stimulus timings in s

TargetTime = 0.4; % Time that stim is shown
OverTime = 0.4; % Add 400 ms to catch late responses
FeedbackTime = 0.4; % Time that feedback is shown

% Stimulus timings in frames (for best timings)

NumFramesFeedback = round(FeedbackTime / ifi);

% Randomise short fixation times

FixationTimeShortMill = randi([fixMinQuick,fixMaxQuick], 75 ,1); % Creates fixation time in ms (400, 1800)
FixationTimeShort = FixationTimeShortMill/1000; % Changes fixation time to s

% Randomise long fixation times

FixationTimeLongMill = randi([fixMinSlow,fixMaxSlow],10 ,1); % Creates fixation time in ms (25000, 35000)
FixationTimeLong = FixationTimeLongMill/1000; % Changes fixation time to s

try %try, catch, end -- To stop code if there is an error
    
    % Load image stimuli
    
    if ispc == 1
        ImageFolder = sprintf('%s\\Stimuli', MainFolder);
    elseif ismac == 1
        ImageFolder = sprintf('%s/Stimuli', MainFolder);
    end
    
    cd(ImageFolder); % The location where image files are
    all_images = dir('*.png'); % Load all images
    
    % Set up log file
    
    RespMat{1,1} = 'Participant ID';
    RespMat{1,2} = 'Day Number';
    RespMat{1,3} = 'Session Number';
    RespMat{1,4} = 'Date'; % Todays Date
    RespMat{1,5} = 'Time'; % Time of each trial
    RespMat{1,6} = 'ifi'; % Time of each trial
    RespMat{1,7} = 'Trial number';
    RespMat{1,8} = 'Number of frames fixation';
    RespMat{1,9} = 'Fixation time';
    RespMat{1,10} = 'Trial type';
    RespMat{1,11} = 'Response?'; % 0 = Miss; 1 = Hit
    RespMat{1,12} = 'Start time';
    RespMat{1,13} = 'End time';
    RespMat{1,14} = 'Raw RT'; % End time minus start time
    RespMat{1,15} = 'Warning?'; % Record any warnings for 'cheating'
    
    % Open offscreen windows for drawing prior to presentation
    
    FixationScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
    TargetScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
    FeedbackScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
    
    % Set up parameters for offscreen windows
    
    Screen('TextFont', FixationScreen, TextFont);
    Screen('TextColor', FixationScreen, TextNormal);
    Screen('TextSize', FixationScreen, TextSize);
    Screen('TextFont', TargetScreen, TextFont);
    Screen('TextColor', TargetScreen, TextNormal);
    Screen('TextSize', TargetScreen, TextSize);
    
    % Load the image files into the workspace
    
    isRed = regexp({all_images.name}, regexptranslate('wildcard', 'Red*')); % Where is red dot
    redIndex = find(not(cellfun('isempty',isRed)));
    
    target_dot = all_images(redIndex).name; % Load image
    big_dot = imread(target_dot);
    resized_dot = imresize(big_dot, 0.075);
    TargetPicture = Screen('MakeTexture',window,resized_dot);
    Screen('DrawTexture', TargetScreen, TargetPicture, [], []);
    
    isCorrect = regexp({all_images.name}, regexptranslate('wildcard', 'Correct*')); % Where is green dot
    correctIndex = find(not(cellfun('isempty',isCorrect)));
    
    feedback_dot = all_images(correctIndex).name; % Load image
    big_dot2 = imread(feedback_dot);
    resized_dot2 = imresize(big_dot2, 0.075);
    FeedbackPicture = Screen('MakeTexture',window,resized_dot2);
    Screen('DrawTexture', FeedbackScreen, FeedbackPicture, [], []);
    
    isFix = regexp({all_images.name}, regexptranslate('wildcard', 'Fixation*')); % Where is fixation cross
    fixIndex = find(not(cellfun('isempty',isFix)));
    
    fixation_image = all_images(fixIndex).name; % Load image
    fix_cross = imread(fixation_image);
    resized_fix = imresize(fix_cross, 0.1);
    FixationPicture = Screen('MakeTexture',window,resized_fix);
    Screen('DrawTexture', FixationScreen, FixationPicture, [], []);
    
    %% Start of experimental loop %%
    
    while practice < 2
        
        check_accuracy = 0; % Reset accuracy check
        trial = 1; % Reset trial counter
        warning = 0; % Reset warning
        
        if practice == 0
            numTrials = numTrialsPrac;
            FixationTime = [10, 2, 0.5, 1, 2];
        elseif practice == 1
            fixationCount = 1;
            ShortFixationCell = {};
            numTrials = numTrialsMain;
            shortStim = 3:12;
            
            for longStim = 1:10
                ShortFixationCell{longStim} = FixationTimeShort(fixationCount:(fixationCount+shortStim(longStim)-1));
                fixationCount = (fixationCount + shortStim(longStim)-1);
            end
            
            ShortFixationCellShuffled = ShortFixationCell(randperm(numel(ShortFixationCell)));
            
            % Now we need to make our final array
            
            trialCount = 1;
            for longStim = 1:10
                FixationTime(trialCount) = FixationTimeLong(longStim);
                FixationTime(trialCount+1:trialCount+length(ShortFixationCellShuffled{longStim})) = ShortFixationCellShuffled{longStim};
                trialCount = trialCount + 1 + length(ShortFixationCellShuffled{longStim});
            end
        end
        
        while trial < numTrials + 1
            
            NumFramesFixation = round(FixationTime(trial) / ifi);
            
            if trial == 1 && showInstructions == 1 % If first trial, show start screen
                
                KbReleaseWait;
                
                Screen('TextSize', window, TextSize);
                Screen('TextColor', window, TextNormal);
                
                DrawFormattedText(window, 'Please press the spacebar to see the task instructions', 'center', 'center', white)
                Screen('Flip', window);
                
                % Wait for participant to press spacebar
                
                while 1
                    [~,~,keyCode] = KbCheck;
                    if keyCode(KbName('space')) == 1
                        break
                    end
                end
                
                KbReleaseWait;
                
                Screen('TextSize', window, TextSize);
                Screen('TextColor', window, TextNormal);
                
                if practice == 1
                    DrawFormattedText(window, 'Read the following instructions carefully \n \n Press the spacebar as quickly as possible when the red dot appears \n \n The dot will turn white if you are fast enough \n \n Try to be as quick as possible and respond to every red dot \n \n Press the spacebar to begin the task', 'center', 'center', white)
                else
                    DrawFormattedText(window, 'Read the following instructions carefully \n \n Press the spacebar as quickly as possible when the red dot appears \n \n The dot will turn white if you are fast enough \n \n Try to be as quick as possible and respond to every red dot \n \n Press the spacebar to begin a short practice', 'center', 'center', white)
                end
                Screen('Flip', window);
                
                % Wait for participant to press spacebar
                
                while 1
                    [~,~,keyCode] = KbCheck;
                    if keyCode(KbName('space')) == 1
                        break
                    end
                end
                showInstructions = 0; % Don't show instructions next time (if appropriate)
            else
                % Do nothing if not trial 1
            end
            
            if trial == 1
                Countdown = 5;
                for i = 1:Countdown % Countdown
                    DrawFormattedText(window,sprintf('%d',Countdown),'center','center', white);
                    Screen('Flip',window);
                    WaitSecs(1);
                    Countdown = Countdown - 1;
                end
            else
                % Do nothing if not trial 1
            end
            
            % Copy windows at the right time (for best timing)
            
            Screen('Flip', window); % Flip to nothing
            Screen('CopyWindow', FixationScreen, window);
            % Screen('Flip', window);
            % WaitSecs(.01);
            time = Screen('Flip', window);
            for a = 1:NumFramesFixation
                Screen('CopyWindow', FixationScreen, window);
                time = Screen('Flip', window, time + .5 *ifi);
            end
            
            % If participant is trying to cheat (Keep key pushed down through
            % fixation for an easy win), give them a warning!
            
            KbCheck;
            if KbCheck == 1
                Screen('TextSize', window, 35);
                DrawFormattedText(window, 'Spacebar must be released during the fixation cross \n \n This trial will now be repeated', 'center', 'center', TextRed);
                Screen('Flip', window);
                WaitSecs(5);
                
                warning = 1;
            end
            
            if warning == 0 % Skip trial if warning has been given
                
                keyIsDown = 0;
                ResponseTimeOnset = GetSecs;
                Resp1 = '.';
                Screen('CopyWindow', TargetScreen, window);
                Screen('Flip', window);
                while keyIsDown == 0 && GetSecs - ResponseTimeOnset < (TargetTime)
                    if ~ismember(upper(Resp1(1)),KbCheckList)
                        [keyIsDown, TimeT1Response, keyCode] = KbCheck; % Waiting for key press
                        if keyIsDown
                            kb = KbName(find(keyCode)); % Label key pressed
                            Resp1 = kb(1); % Recode as uppercase
                            if Resp1 == 'q'
                                KbReleaseWait;
                                cd(MainFolder);
                                ListenChar(0);
                                error('Quit experiment by pressing q key')
                            end
                        end
                    end
                end
                
                Response(trial) = Resp1(1);
                RespondTime = TimeT1Response;
                
                if Resp1 == '.' % If no response
                    Resp2 = '.';
                    Screen('CopyWindow', FixationScreen, window);
                    % Screen('Flip', window);
                    while keyIsDown == 0 && GetSecs - ResponseTimeOnset < (TargetTime + OverTime)
                        if ~ismember(upper(Resp2(1)),KbCheckList)
                            [keyIsDown, TimeT2Response, keyCode] = KbCheck; % Waiting for key press
                            if keyIsDown
                                kb = KbName(find(keyCode)); % Label key pressed
                                Resp2 = kb(1); % Recode as uppercase
                                if Resp2 == 'q'
                                    KbReleaseWait;
                                    cd(MainFolder);
                                    ListenChar(0);
                                    error('Quit experiment by pressing q key')
                                end
                            end
                        end
                    end
                    Response(trial) = Resp2(1);
                    RespondTime = TimeT2Response;
                end
                
                % Check if a response is given and present feedback if yes
                
                if Resp1 ~= '.'
                    check_accuracy = 1;
                    for d = 1:NumFramesFeedback % Should amount to 0.3s
                        Screen('CopyWindow', FeedbackScreen, window);
                        time = Screen('Flip', window,time + .5*ifi);
                    end
                else
                    check_accuracy = 0;
                end
                
                if round((NumFramesFixation*ifi)*1000) < 2500
                    trialType = 'Short';
                else
                    trialType = 'Long';
                end
                this_time = datestr(now, formatTime);
                
                %%%%%%%%%%%%%%%%
                % SAVE RESULTS %
                %%%%%%%%%%%%%%%%
                
                RespMat{trial+1,1} = subjectInitials;
                RespMat{trial+1,2} = dayNumber;
                RespMat{trial+1,3} = sessionNumber;
                RespMat{trial+1,4} = todays_date;
                RespMat{trial+1,5} = this_time;
                RespMat{trial+1,6} = ifi;
                RespMat{trial+1,7} = trial;
                RespMat{trial+1,8} = NumFramesFixation;
                RespMat{trial+1,9} = round((NumFramesFixation*ifi)*1000); % Time in ms
                RespMat{trial+1,10} = trialType;
                RespMat{trial+1,11} = check_accuracy; % 0 = Correct; 1 = Incorrect
                RespMat{trial+1,12} = ResponseTimeOnset;
                RespMat{trial+1,13} = RespondTime;
                RespMat{trial+1,14} = round((RespondTime - ResponseTimeOnset)*1000); % End time minus start time converted to ms
                
            end
            
            if warning == 1
                warning = 0;
                RespMat{trial+1,15} = 1; % Record warning for original trial
            else
                trial = trial + 1; % Increase trial count
            end
        end
        
        KbReleaseWait;
        
        %% End %%
        
        % Save the data to a csv file                                                                                  v
        
        Data = dataset(RespMat);
        
        if practice == 0 % If practice
            savename = sprintf('%s-%s-%s-PRACTICE_PVT.csv', subjectInitials, dayNumber, sessionNumber);
        elseif practice == 1 % If main task
            savename = sprintf('%s-%s-%s-%s-PVT.csv', subjectInitials, dayNumber, sessionNumber, datestr(datetime('now'),'ddmmyy-HHMM'));
        end
        
        if ispc == 1
            ResultsFolder = sprintf('%s\\Results', MainFolder);
        elseif ismac == 1
            ResultsFolder = sprintf('%s/Results', MainFolder);
        end
        cd(ResultsFolder); % The location where the file should be saved
        export(Data, 'file', savename, 'Delimiter', ',');
        cd(MainFolder);
        
        
        KbReleaseWait;
        Screen('TextSize', window, 35);
        
        if practice == 0
            DrawFormattedText(window, 'Practice finished! \n \n Ask the experimenter now if you have any questions \n \n There will still be feedback (white circle) in the main task \n \n When ready, please press the spacebar to start the main task', 'center', 'center', white)
            Screen('Flip', window);
        elseif practice == 1
            DrawFormattedText(window, 'Task complete! \n \n Please let the experimenter know', 'center', 'center', white);
            Screen('Flip', window);
        else
        end
        
        % Wait for spacebar press
        while 1
            [~,~,keyCode] = KbCheck;
            if keyCode(KbName('space'))== 1
                break
            end
        end
        
        practice = practice + 1; % Increase practice count
        
    end
    
catch % Closes psyschtoolbox if there is an error and saves whatever data has been collected so far
    
    ShowCursor;
    ListenChar(0);
    Screen('CloseAll');
    psychrethrow(psychlasterror); % Tells you the error in the command window
    Priority(0);
    sca;
    
    Data = dataset(RespMat);
    savename = sprintf('%s-%s-%s-%s-PVT-ERROR.csv', subjectInitials, dayNumber, sessionNumber, datestr(datetime('now'),'ddmmyy-HHMM'));
    if ispc == 1
        ResultsFolder = sprintf('%s\\Results', MainFolder);
    elseif ismac == 1
        ResultsFolder = sprintf('%s/Results', MainFolder);
    end
    cd(ResultsFolder); % The location where the file should be saved
    export(Data, 'file', savename, 'Delimiter', ',');
    cd(MainFolder);
    
end % End of try, catch,

cd(MainFolder);

ShowCursor;

ListenChar(0); % Allow key presses to affect code

clearvars -except pcarryover;
sca; % Clear screen
close all;
clc;

% function ERT_START
%
%% Expression Recognition Task
%
%% Go / No-go task utilising facial expression (happy or fearful) as block targets %%
%
% Dr Tom Faherty, June 2022
% t.b.s.faherty@bham.ac.uk
%
% Participants are presented with one image. Their task is to respond with a spacebar press if
% the image matches the target expression (e.g., happy) and inhibit response if the expression
% does not match the target classifier. Classifier changes in each block
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
    ANSWER = inputdlg(prompt, 'Emotion Recognition Task', 1, defaults);
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
practice = (ANSWER{4}); % Save practice value

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

check_accuracy = 0; % Reset accuracy check
block = 1; % Reset block counter
trial = 1; % Reset trial counter
blockTrial = 1; % Reset blockTrial counter
trials_per_block = 44; % Number of trials per block
Numblocks = 6;
block_target = 0;
trials_practice = 8; % Number of practice trials

ListenChar(2); % Avoid key presses affecting code

formatDate = 'dd-mm-yy'; % Set date format
formatTime = 'HH:MM:SS'; % Set time format
todays_date = datestr(now, formatDate); % Today's date in correct format

% Set up screen

WaitSecs(5) % Pause

WhichScreen = max(Screen('Screens'));
black = BlackIndex(WhichScreen); % Black is 0
white = WhiteIndex(WhichScreen); % White is 255
BackgroundColour = white; % Background is set to white (n.b. white/2 = grey)

TextSize = 35;
TextFont = 'Arial';
TextNormal = [0 0 0]; % normal (black) text colour
TextGreen = [35 230 90]; % correct text colour
TextRed = [255 60 0]; % incorrect text colour

window = PsychImaging('OpenWindow', WhichScreen, 0, []);  % Open up a screen

%

Screen('FillRect', window, BackgroundColour); % Create screen background
Screen('Flip', window);
Priority(MaxPriority(window));
[ScreenXPixels, ScreenYPixels] = Screen('WindowSize', window);
Screen('TextSize', window, 35);

% Set up screen timings

ifi = Screen('GetFlipInterval',window); % How long is a frame in ms
ScreenRefreshRate = 1/ifi; % Calculate refresh rate

% Stimulus timings in s

TargetTime = 0.1; % Time that stim is shown
BlankTime = 0.7; % Extra time after response (allowing for responses up to 700ms)
FeedbackTime = 1; % Time that feedback is shown (Practice only, otherwise fixation screen)

FixationTimeMill = randi([550,950],(trials_per_block*Numblocks) ,1); % Creates jittered fixation time in ms
JitFixationTime = FixationTimeMill/1000; % Changes jittered fixation time to s

% Stimulus timings in frames (for best timings)

NumFramesFeedback = round(FeedbackTime / ifi);

try %try, catch, end -- To stop code if there is an error
    
    HideCursor;
    
    % Create image arrays
    
    if ispc == 1
        ImageFolder = sprintf('%s\\Stimuli', MainFolder);
    elseif ismac == 1
        ImageFolder = sprintf('%s/Stimuli', MainFolder);
    end

    %
    % Aside from the fixation image, all images are taken from the RADIATE
    % database (https://doi.org/10.1016/j.psychres.2018.04.066)
    %
    % Face images saved in the format EthnicityGenderIdentifier_EmotionExpressivity
    % i.e., HM03_HO is HispanicMaleNumber3_HappyOpenmouth
    %
    % Contact t.b.s.faherty@bham.ac.uk with any queries or for files
    %

    cd(ImageFolder); % The location where image files are
    all_images = dir('*.jpg'); % Load all images
    all_images = all_images(randperm(length(all_images))); % Randomise order
    fixation_image = dir('*.bmp'); % Load fixation cross
    
    while practice < 2
        
        warning = 0; % Reset warning
        
        if practice == 0 % If practice
            readyPrac = 0;
            while readyPrac == 0
                evenCheck = 0;
                prac_array = {};
                for praci = 1:trials_practice
                    prac_array{praci} = all_images(praci).name;
                end
                
                for checkPrac = 1:trials_practice
                    if prac_array{checkPrac}(6) == 'H'
                        evenCheck = evenCheck + 1;
                    else
                    end
                end
                
                if evenCheck > 4 || evenCheck < 4
                    all_images = all_images(randperm(length(all_images))); % Randomise order
                    readyPrac = 0; % Reset and try again
                else
                    readyPrac = 1;
                end
            end
        elseif practice == 1 % If main task
            
            % Randomise Stim again
            
            all_images = all_images(randperm(length(all_images))); % Randomise order
            
            % Create index of stimuli features
            
            for i = 1:length(all_images)
                Expression_Matrix(i) = contains(all_images(i).name, '_F'); % 0 = Happy; 1 = Fearful
                Gender_Matrix(i) = contains(all_images(i).name, 'M'); % 0 = Female; 1 = Male
                Mouth_Matrix(i) = contains(all_images(i).name, 'C.'); % 0 = Open; 1 = Closed
                Ethnicity_Matrix(i) = contains(all_images(i).name, ["A","B"]); % 0 = A/B; 1 = W/H
            end
            
            % For consistency: 0 Male and 1 Female
            
            Gender_Matrix(:) = ~Gender_Matrix;
            
            % Create truth table
            
            N = 4;
            L = 2^N;
            stim_type_matrix = zeros(L,N);
            for i = 1:N
                temp = [zeros(L/2^i,1); ones(L/2^i,1)];
                stim_type_matrix(:,i) = repmat(temp,2^(i-1),1);
            end
            
            % Start identification loop
            
            for loop = 1:16 % 16 is amount of possible combinations re. gender, expression, mouth, and ethnicity (2x2x2x2)
                
                % Reset counter for next loop
                z = 1;
                
                for n = 1:length(all_images) % For all 264 images
                    if Expression_Matrix(n) == stim_type_matrix(loop,1) % expression criteria
                        if Gender_Matrix(n) == stim_type_matrix(loop,2) % gender criteria
                            if Mouth_Matrix(n) == stim_type_matrix(loop,3) % mouth criteria
                                if Ethnicity_Matrix(n) == stim_type_matrix(loop,4) % ethnicity criteria
                                    current_array(loop,z) = n; % Save index of image in a new array. Each row should correspond to each matrix line
                                    z = z+1; % increase counter to ensure no images are overwritten
                                end
                            end
                        end
                    end
                end
            end
            
            % Set 8 block start images, which remain constant for each

            % This is done so we can assess switch-costs if we wish
            
            start_array = zeros(1,8);
            start_array_expression = zeros(1,8);
            for b = 1:8
                start_array(b) = [current_array(b*2,11)];
                start_array_expression(b) = [stim_type_matrix(b*2,1)];
            end
            
            % Set up 6 arrays (because 6 blocks)
            
            new_array = [];
            pick_startValue = ones(16,1);
            array_startValue = 1;
            stim_call = {};
            
            for v = 1:(Numblocks/2) % Repeat array population 3 times (for 6 blocks)
                for target = 0:1 % Populate happy array first
                    cond_cycle = 1; % Reset conditions cycle
                    for cond_cycle = 1:16 % Cycle through all conditions
                        if stim_type_matrix(cond_cycle,1) == target % If the condition is a target
                            multiplier = 2; % include double the stimuli in the array
                        else
                            multiplier = 1;
                        end
                        if mod(cond_cycle,2) == 1 % if condition matrix number is odd (W/H images)
                            multiplier = multiplier*2; % Take double the images
                        end % do not change multiplier
                        picked_stim = []; % Reset collected values
                        picked_stim = current_array(cond_cycle,pick_startValue(cond_cycle,1):pick_startValue(cond_cycle,:)+multiplier-1);
                        pick_startValue(cond_cycle,1) = pick_startValue(cond_cycle,1)+multiplier; % remember the position of the last stim taken
                        new_array(1, array_startValue:array_startValue+multiplier-1) = picked_stim;
                        new_array(2, array_startValue:array_startValue+multiplier-1) = stim_type_matrix(cond_cycle,1);
                        array_startValue = array_startValue + multiplier;
                    end
                    array_startValue = 1; % Reset array start value
                    
                    stim_call{(v*2)+target-1,1} = new_array(1,:); % Bind current stim into cell
                    stim_call{(v*2)+target-1,2} = new_array(2,:);
                    stim_call{(v*2)+target-1,3} = target; % Save target
                    
                    swap = randperm(length(new_array(1,:))); % Randperm, reset each loop
                    
                    stim_call{(v*2)+target-1,1} = stim_call{(v*2)+target-1,1}(swap);
                    stim_call{(v*2)+target-1,2} = stim_call{(v*2)+target-1,2}(swap);
                    
                    novel_swap = randperm(8); % Set up randomiser for first 8 trials
                    new_order_start = start_array(novel_swap);
                    new_order_start_expression = start_array_expression(novel_swap);
                    
                    % Bind start stim into cell
                    
                    stim_call{(v*2)+target-1,1}(9:44) = stim_call{(v*2)+target-1,1}(1:36);% Shift array along 8
                    stim_call{(v*2)+target-1,2}(9:44) = stim_call{(v*2)+target-1,2}(1:36); % Shift array along 8
                    stim_call{(v*2)+target-1,1}(1:8) = new_order_start; % Replace first 8
                    stim_call{(v*2)+target-1,2}(1:8) = new_order_start_expression; % Replace first 8
                    
                    new_array = []; % Reset new array
                end
            end
        end
        % Target reset
        
        target = 0;
        
        % Set up log file
        
        RespMat{1,1} = 'Participant ID';
        RespMat{1,2} = 'Day number';
        RespMat{1,3} = 'Session number';
        RespMat{1,4} = 'Date'; % Todays Date
        RespMat{1,5} = 'Time'; % Time of each trial
        RespMat{1,6} = 'Trial number';
        RespMat{1,7} = 'Block number';
        RespMat{1,8} = 'Block trial number';
        RespMat{1,9} = 'Trial type'; % 0 = No-go; 1 = Go
        RespMat{1,10} = 'Target classifier'; % 0 = Happy; 1 = Fearful
        RespMat{1,11} = 'Stimulus expression'; % 0 = Happy; 1 = Fearful
        RespMat{1,12} = 'Stimulus gender'; % 0 = Male; 1 = Female
        RespMat{1,13} = 'Stimulus mouth'; % 0 = Open; 1 = Closed
        RespMat{1,14} = 'Stimuli ethnicity'; % 0 = A; 1 = B; 2 = W; 3 = H
        RespMat{1,15} = 'Filename'; % Image name
        RespMat{1,16} = 'Correct response'; % 0 = No-go; 1 = Go
        RespMat{1,17} = 'KeyCode Output'; % '.' = No response; 's' = Response
        RespMat{1,18} = 'FA Hit CR or Miss?'; % 0 = False Alarm; 1 = Hit; 2 = Correct Rejection; 3 = Miss
        RespMat{1,19} = 'Correct?'; % 0 = Correct; 1 = Incorrect
        RespMat{1,20} = 'Start time';
        RespMat{1,21} = 'End time';
        RespMat{1,22} = 'Raw RT'; % End time minus start time
        RespMat{1,23} = 'Warning?'; % Record any warnings for 'cheating'
        
        %% Start of experimental loop %%
        
        while block < Numblocks+1
            if block < 2 % If first block, show start screen
                
                Screen('TextSize', window, 35);
                
                StartText = sprintf('Please press the spacebar to see task instructions');
                StartTextBounds = Screen('TextBounds', window, StartText);
                Screen('DrawText',window,StartText, ScreenXPixels*.5-StartTextBounds(3)*.5, ScreenYPixels*.5-StartTextBounds(4)*.5), black;
                Screen('Flip', window);
                while 1
                    [~,~,keyCode] = KbCheck;
                    if keyCode(KbName('space'))==1
                        break
                    end
                end
            else
            end
            KbReleaseWait;
            
            % Create block instruction text
            
            hText = 'happy';
            fText = 'fearful';
            
            if block_target == 0 % Block target is happy
                targetText = hText;
                distractorText = fText;
            else % Block target is fearful
                targetText = fText;
                distractorText = hText;
            end
            
            Screen('TextSize', window, 35);
            
            StartText = sprintf('Read the following instructions carefully');
            BlockNotesText2 = sprintf('Press the spacebar when a %s\t face is shown', targetText);
            BlockNotesText3 = sprintf('Do not respond when a %s\t face is shown', distractorText);
            BlockNotesText4 = sprintf('Be as quick and accurate as possible');
            if practice == 0
                BlockNotesText5 = sprintf('Press the spacebar to begin a short practice');
            elseif practice == 1
                BlockNotesText5 = sprintf('Press the spacebar to begin the block');
            end
            BlockNotesBounds1 = Screen('TextBounds', window, StartText);
            BlockNotesBounds2 = Screen('TextBounds', window, BlockNotesText2);
            BlockNotesBounds3 = Screen('TextBounds', window, BlockNotesText3);
            BlockNotesBounds4 = Screen('TextBounds', window, BlockNotesText4);
            BlockNotesBounds5 = Screen('TextBounds', window, BlockNotesText5);
            Screen('DrawText', window, StartText, ScreenXPixels*.5-BlockNotesBounds1(3)*.5, ScreenYPixels*.3-BlockNotesBounds1(4)*.5), black;
            Screen('DrawText', window, BlockNotesText2, ScreenXPixels*.5-BlockNotesBounds2(3)*.5, ScreenYPixels*.4-BlockNotesBounds2(4)*.5), black;
            Screen('DrawText', window, BlockNotesText3, ScreenXPixels*.5-BlockNotesBounds3(3)*.5, ScreenYPixels*.5-BlockNotesBounds3(4)*.5), black;
            Screen('DrawText', window, BlockNotesText4, ScreenXPixels*.5-BlockNotesBounds4(3)*.5, ScreenYPixels*.6-BlockNotesBounds4(4)*.5), black;
            Screen('DrawText', window, BlockNotesText5, ScreenXPixels*.5-BlockNotesBounds5(3)*.5, ScreenYPixels*.7-BlockNotesBounds5(4)*.5), black;
            Screen('Flip', window);
            
            % Wait for participant to press spacebar
            
            while 1
                [~,~,keyCode] = KbCheck;
                if keyCode(KbName('space'))== 1
                    break
                end
            end
            
            % Start block
            if practice == 0
                totalTrials = trials_practice;
                thisManyTrials = trials_practice;
            elseif practice == 1
                totalTrials = trials_per_block * block;
                thisManyTrials = trials_per_block;
            end
            
            while trial < totalTrials + 1
                while blockTrial < thisManyTrials + 1 % Present images
                    
                    % Get time
                    
                    this_time = datestr(now, formatTime); % Time start in correct format
                    
                    % Stimulus timings in frames (for best timings)
                    
                    NumFramesJitFixation = round(JitFixationTime(trial) / ifi);
                    
                    % Open offscreen windows for drawing prior to presentation
                    
                    FixationScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
                    TargetScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
                    BlankScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
                    FeedbackScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
                    
                    % Set up parameters for offscreen windows
                    
                    Screen('TextFont', FixationScreen, TextFont);
                    Screen('TextColor', FixationScreen, TextNormal);
                    Screen('TextSize', FixationScreen, TextSize);
                    Screen('TextFont', TargetScreen, TextFont);
                    Screen('TextColor', TargetScreen, TextNormal);
                    Screen('TextSize', TargetScreen, TextSize);
                    Screen('TextFont', BlankScreen, TextFont);
                    Screen('TextColor', BlankScreen, TextNormal);
                    Screen('TextSize', BlankScreen, TextSize);
                    
                    % Load the current image file into the workspace
                    
                    if practice == 0
                        current_image = all_images(blockTrial).name;
                    elseif practice == 1
                        current_image = all_images(stim_call{block, 1}(blockTrial)).name; % Load image
                    end
                    big_image = imread(current_image);
                    resized_image = imresize(big_image, 0.2);
                    TargetPicture = Screen('MakeTexture',window,resized_image);
                    Screen('DrawTexture', TargetScreen, TargetPicture, [], []);
                    
                    % Draw fixation screen
                    
                    fix_cross = imread(fixation_image.name);
                    resized_fix = imresize(fix_cross, 0.1);
                    FixationPicture = Screen('MakeTexture',window,resized_fix);
                    Screen('DrawTexture', FixationScreen, FixationPicture, [], []);
                    
                    % Set up whether a response is needed %
                    
                    if practice == 0
                        
                        if current_image(6) == 'H' % If current image is a target (practice only)
                            correct_response = 1; % Looking for Hit
                        else
                            correct_response = 0; % Looking for Correct Rejection
                        end
                        
                    else
                        
                        if stim_call{block,2}(blockTrial) == block_target % If current image is a target
                            correct_response = 1; % Looking for Hit
                        else
                            correct_response = 0; % Looking for Correct Rejection
                        end
                    end
                    
                    if blockTrial == 1 % If first trial
                        Countdown = 5;
                        for i = 1:Countdown % Countdown
                            DrawFormattedText(window,sprintf('%d',Countdown),'center','center', black);
                            Screen('Flip',window);
                            WaitSecs(1);
                            Countdown = Countdown - 1;
                        end
                    end
                    
                    % Ensure participant has let go of any keys
                    
                    KbReleaseWait;
                    
                    % Copy windows at the right time (for best timing)
                    
                    Screen('CopyWindow', FixationScreen, window);
                    time = Screen('Flip', window);
                    for a = 1:NumFramesJitFixation % Should amount to 0.8s for total 1000 ms
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
                        
                        KbReleaseWait;
                        keyIsDown = 0; % Reset if key has been pressed
                        ResponseTimeCont = GetSecs;
                        Resp2 = '.';
                        Screen('CopyWindow', BlankScreen, window);
                        Screen('Flip', window);
                        while keyIsDown == 0 && GetSecs - ResponseTimeCont < BlankTime % While there is still blank time remaining
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
                        
                        % Save response as first key pressed
                        
                        if Resp1 ~= '.'
                            Response(trial) = Resp1(1);
                            RespondTime = TimeT1Response;
                        elseif Resp1 == '.'
                            Response(trial) = Resp2(1);
                            RespondTime = TimeT2Response;
                        end
                        
                        %%%%%%%%%%%%%%%%%%
                        % CHECK ACCURACY %
                        %%%%%%%%%%%%%%%%%%
                        
                        % Check for accuracy when response is given
                        
                        % 0 = False Alarm
                        % 1 = Hit
                        % 2 = Correct Rejection
                        % 3 = Miss
                        
                        if Response(trial) == '.'
                            if correct_response == 0 % No-go trial
                                check_accuracy = 2; % Correct Rejection
                                count_accuracy = 1;
                            elseif correct_response == 1 % Go trial
                                check_accuracy = 3; % Miss
                                count_accuracy = 0;
                            end
                        else
                            if correct_response == 0 % No-go trial
                                check_accuracy = 0; % False Alarm
                                count_accuracy = 0;
                            elseif correct_response == 1 % Go trial
                                check_accuracy = 1; % Hit
                                count_accuracy = 1;
                            end
                        end
                        
                        % If practice, present feedback
                        
                        Screen('TextFont', FeedbackScreen, TextFont);
                        Screen('TextSize', FeedbackScreen, TextSize);
                        if practice == 0
                            if count_accuracy == 1
                                DrawFormattedText(FeedbackScreen, 'Correct', 'center', 'center', TextGreen);
                            elseif count_accuracy == 0
                                DrawFormattedText(FeedbackScreen, 'Incorrect', 'center', 'center', TextRed);
                            end
                        else
                            Screen('DrawTexture', FeedbackScreen, FixationPicture, [], []); % Draw fixation cross if main task
                        end
                        
                        KbReleaseWait;
                        
                        for d = 1:NumFramesFeedback % Should amount to 0.8s
                            Screen('CopyWindow', FeedbackScreen, window);
                            time = Screen('Flip', window,time + .5*ifi);
                        end
                        
                        % Identify face ethnicity
                        
                        if current_image(1) == "A"
                            stim_ethnicity = 0;
                        elseif current_image(1) == "B"
                            stim_ethnicity = 1;
                        elseif current_image(1) == "H"
                            stim_ethnicity = 2;
                        elseif current_image(1) == "W"
                            stim_ethnicity = 3;
                        end
                        
                        % Identify expression
                        
                        if current_image(6) == "H"
                            stim_expression = 0;
                        elseif current_image(6) == "F"
                            stim_expression = 1;
                        end
                        
                        % Identify mouth
                        
                        if current_image(7) == "O"
                            stim_mouth = 0;
                        elseif current_image(7) == "C"
                            stim_mouth = 1;
                        end
                        
                        % Identify gender
                        
                        if current_image(2) == "M"
                            stim_gender = 0;
                        elseif current_image(2) == "F"
                            stim_gender = 1;
                        end
                        
                        KbReleaseWait;
                        
                        Screen('Close');
                        
                        %%%%%%%%%%%%%%%%
                        % SAVE RESULTS %
                        %%%%%%%%%%%%%%%%
                        
                        RespMat{trial+1,1} = subjectInitials;
                        RespMat{trial+1,2} = dayNumber;
                        RespMat{trial+1,3} = sessionNumber;
                        RespMat{trial+1,4} = todays_date;
                        RespMat{trial+1,5} = this_time;
                        RespMat{trial+1,6} = trial;
                        RespMat{trial+1,7} = block;
                        RespMat{trial+1,8} = blockTrial;
                        RespMat{trial+1,9} = correct_response; % 0 = No-go; 1 = Go
                        RespMat{trial+1,10} = block_target; % 0 = Happy; 1 = Fearful
                        RespMat{trial+1,11} = stim_expression; % 0 = Fearful; 1 = Happy
                        RespMat{trial+1,12} = stim_gender; % 0 = Male; 1 = Female
                        RespMat{trial+1,13} = stim_mouth; % 0 = Open; 1 = Closed
                        RespMat{trial+1,14} = stim_ethnicity; % 0 = A; 1 = B; 2 = W; 3 = H
                        RespMat{trial+1,15} = current_image;
                        RespMat{trial+1,16} = correct_response; % 0 = Correct Rejection; 1 = Hit
                        RespMat{trial+1,17} = Response(trial); % Response key
                        RespMat{trial+1,18} = check_accuracy; % 0 = False Alarm; 1 = Hit; 2 = Correct Rejection; 3 = Miss
                        RespMat{trial+1,19} = count_accuracy; % 0 = Correct; 1 = Incorrect
                        RespMat{trial+1,20} = ResponseTimeOnset;
                        RespMat{trial+1,21} = RespondTime;
                        RespMat{trial+1,22} = round((RespondTime - ResponseTimeOnset)*1000); % End time minus start time converted to ms
                        
                    end
                    
                    if warning == 1
                        warning = 0;
                        RespMat{trial+1,23} = 1; % Record warning for original trial
                    else
                        trial = trial + 1; % Increase trial count
                        blockTrial = blockTrial + 1; % Increase blockTrial count
                    end
                    
                end
                blockTrial = 1; % Reset blockTrial count
            end
            
            KbReleaseWait;
            
            if practice ~= 0
                if block < Numblocks
                    
                    BlockNotesText = sprintf('Block %d of %d complete', block, Numblocks);
                    BlockNotesText2 = sprintf('Take a break and press the spacebar to move on');
                    BlockNotesBounds1 = Screen('TextBounds', window, BlockNotesText);
                    BlockNotesBounds2 = Screen('TextBounds', window, BlockNotesText2);
                    Screen('DrawText', window, BlockNotesText, ScreenXPixels*.5-BlockNotesBounds1(3)*.5, ScreenYPixels*.4-BlockNotesBounds1(4)*.5, black);
                    Screen('DrawText', window, BlockNotesText2, ScreenXPixels*.5-BlockNotesBounds2(3)*.5, ScreenYPixels*.6-BlockNotesBounds2(4)*.5, black);
                    Screen('Flip', window);
                    
                    KbReleaseWait;
                    
                    % Wait for participant to press spacebar
                    
                    while 1
                        [~,~,keyCode] = KbCheck;
                        if keyCode(KbName('space'))== 1
                            break
                        end
                    end
                    
                else
                end
                
                KbReleaseWait;
                
                block = block + 1; % Move to next block
                if block_target == 0 % Change target expression
                    block_target = 1;
                else
                    block_target = 0;
                end
                
            else
                % If practice, go to last block
                block = Numblocks+1;
            end
        end
        %% End %%
        
        % Save the data to a csv file
        
        ShowCursor;
        ListenChar(0);
        Data = dataset(RespMat);
        
        if practice == 0 % If practice
            savename = sprintf('%s-%s-%s-PRACTICE_ERT.csv', subjectInitials, dayNumber, sessionNumber);
        elseif practice == 1 % If main task
            savename = sprintf('%s-%s-%s-%s-ERT.csv', subjectInitials, dayNumber, sessionNumber, datestr(datetime('now'),'ddmmyy-HHMM'));
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
            DrawFormattedText(window, 'Practice finished! \n \n Ask the experimenter now if you have any questions \n \n Please note, there will be no feedback for the main task \n \n When ready, please press the spacebar to see the first instruction for the main task', 'center', 'center', black)
            Screen('Flip', window);
        elseif practice == 1
            DrawFormattedText(window, 'Task complete! \n \n Please let the experimenter know', 'center', 'center', black);
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
        
        check_accuracy = 0; % Reset accuracy check
        block = 1; % Reset block counter
        trial = 1; % Reset trial counter
        blockTrial = 1; % Reset blocktrial counter
        HideCursor;
        ListenChar(2);
        practice = practice + 1; % Increase practice count
        cd(ImageFolder); % Go to the image folder for main task
        
    end % End of 'while' practice loop
    
catch % Closes psyschtoolbox if there is an error and saves whatever data has been collected so far
    
    ShowCursor;
    ListenChar(0);
    Screen('CloseAll');
    psychrethrow(psychlasterror); % Tells you the error in the command window
    Priority(0);
    sca;
    
    Data = dataset(RespMat);
    savename = sprintf('%s-%s-%s-%s-ERT-ERROR.csv', subjectInitials, dayNumber, sessionNumber, datestr(datetime('now'),'ddmmyy-HHMM'));
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
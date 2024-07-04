
% function SNB_START
%
%% Spatial n-back Task
%
%% Spatial n-back task using 3x3 grid %%
%
% Tom Faherty, June 2022
% t.b.s.faherty@bham.ac.uk
%
% Participants are presented with a sequence of image locations. Their task
% is to report if the location matches the location presented 'n' trials
% ago. 1 block of 1-back, then 3-blocks of increasing n from 2-4.
%
%% SET UP SOME VARIABLES %%

clearvars -except pcarryover; % For running all tasks b2b
close all;
clc;

rng('default');
rng('shuffle'); % Randomise Random Number Generator
MainFolder = pwd;

% Prompt to collect participant information

%%%%%%%%%%%%%%%%%%%%

readyStart = 0;
while readyStart < 1
    prompt={'Participant ID', 'Testing Day', 'Session Number', 'Dominant Hand [L / R]', 'n-back [1 / 2]', 'Practice? [Y / N]'};
    if exist('pcarryover', 'var') == 1 % If carry over from previous task
        defaults = {pcarryover{1},pcarryover{2},pcarryover{3}, 'R', '1', 'Y'};
    else
        defaults = {'XX','1','1','R','1','Y'};
    end
    ANSWER = inputdlg(prompt, 'Spatial n-back Task', 1, defaults);
    if isempty(ANSWER)
        % User clicked cancel. Bail out! Bail out!
        close all;
        readyStart = 1;
        clearvars -except pcarryover;
        error('User Clicked Cancel')
    elseif upper(ANSWER{4}) ~= 'L' && upper(ANSWER{4}) ~= 'R'
        close all;
        readyStart = 1;
        clearvars -except pcarryover;
        error('Must choose L or R as dominant hand')
    elseif upper(ANSWER{5}) ~= '1' && upper(ANSWER{5}) ~= '2'
        close all;
        readyStart = 1;
        clearvars -except pcarryover;
        error('Must choose 1 or 2 as n-back value')
    elseif upper(ANSWER{6}) ~= 'Y' && upper(ANSWER{6}) ~= 'N'
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
dominantHand = upper(ANSWER{4});
nback_type = str2double(ANSWER{5});
nback_legacy = str2double(ANSWER{5});
pcarryover = {subjectInitials,dayNumber, sessionNumber, dominantHand}; % Temporarily save participant ID and session number

if ANSWER{6} == 'Y'
    practice = 0;
    practice_legacy = 0;
else
    practice = 1;
    practice_legacy = 1;
end

%% Keyboard Setup %%

KbName('UnifyKeyNames');
KbCheckList = [KbName('space'), KbName('q'), KbName('z'), KbName('m')];
KbCheckResp = [KbName('q'), KbName('z'), KbName('m')]; % Ensure space cannot be given as a response

%% SET SOME VARIABLES %%

check_accuracy = 0; % Reset accuracy check
block = 1; % Reset block counter
trial = 1; % Reset trial counter
if nback_type == 1
    n = 1; % Reset 'n' value
else
    n = 2; % Reset 'n' value
end
trials_per_block = 45; % Number of trials per block
Numblocks = 3;
numTrials = trials_per_block * Numblocks;
numMatches = 8; % Decide how many matches we want in each block

numTrialsPrac = 8;
numMatchesPrac = 2;
numBlocksPrac = 1;
showInstructions = 1;

formatDate = 'dd-mm-yy'; % Set date format
formatTime = 'HH:MM:SS'; % Set time format
todays_date = datestr(now, formatDate); % Today's date in correct format

% Set up screen

WaitSecs(5) % Pause

WhichScreen = max(Screen('Screens'));
black = BlackIndex(WhichScreen); % Black is 0
white = WhiteIndex(WhichScreen); % White is 255
BackgroundColour = white/2; % Background is set to grey)

TextSize = 35;
TextFont = 'Arial';
TextNormal = [255 255 255]; % normal (white) text colour
TextRed = [255 60 0]; % missed response text colour

window = PsychImaging('OpenWindow', WhichScreen, 0, []);  % Open up a screen

%

Screen('FillRect', window, BackgroundColour); % Create screen background
Screen('Flip', window);
Priority(MaxPriority(window));
[ScreenXPixels, ScreenYPixels] = Screen('WindowSize', window);
Screen('TextSize', window, 35);

% Set up stim size

sizeValue = 0.3;

% Set up screen timings

ifi = Screen('GetFlipInterval',window); % How long is a frame in ms
ScreenRefreshRate = 1/ifi; % Calculate refresh rate

% Stimulus timings in s

BlankTime = 0.6; % Time between stim
TargetTime = 1; % Time that stim is shown
ResponseTime = 10; % Waiting for response
FeedbackTime = 1; % 1 s

% Stimulus timings in frames (for best timings)

NumFramesBlank = round(BlankTime / ifi);
NumFramesTarget = round(TargetTime / ifi);
NumFramesFeedback = round(FeedbackTime / ifi);

% Set response keys

if dominantHand == 'R'
    sameKey = 'm';
    diffKey = 'z';
elseif dominantHand == 'L'
    sameKey = 'z';
    diffKey = 'm';
end

try %try, catch, end -- To stop code if there is an error
    
    RestrictKeysForKbCheck(KbCheckList);
    ListenChar(2); % Avoid key presses affecting code
    HideCursor;
    
    % Create image arrays
    
    if ispc == 1
        ImageFolder = sprintf('%s\\Stimuli', MainFolder);
    elseif ismac == 1
        ImageFolder = sprintf('%s/Stimuli', MainFolder);
    end
    
    cd(ImageFolder); % The location where image files are
    locationImages = [dir('Top*.jpg'); dir('Bottom*.jpg'); dir('Centre*.jpg')]; % Load all location images
    blank_image = dir('Blank.jpg'); % Load blank grid
    correct_image = dir('FeedbackCorrect.jpg'); % Load correct grid
    incorrect_image = dir('FeedbackIncorrect.jpg'); % Load incorrect grid
    slow_image = dir(['FeedbackSlow.jpg']); % Load incorrect (slow) grid
    
    while practice < 2
        
        if practice == 0
            if nback_type == 1
                
                % Create location presentation order
                
                numLocations = 1:length(locationImages); % Create list of locations to choose from
                
                trialList = nan(numTrialsPrac,1); % Create block trial list
                
                z = 0; % Reset iteration count
                pracListCompleted = 0; % Reset the while loop
                
                while not(pracListCompleted)
                    
                    z = z + 1;
                    
                    for trialIteration = 1:numTrialsPrac
                        
                        trialList(trialIteration) = randsample(numLocations,1); % Pick a random stimulus
                        
                    end
                    
                    % Note down location of matches
                    
                    trialList_shifted = [nan(1,1);trialList(1:numel(trialList)-1)];
                    nback_check = [trialList trialList_shifted];
                    matchLocations = find(diff(nback_check,1,2) == 0);
                    
                    % Check if conditions are met
                    
                    if numel(matchLocations) == numMatchesPrac % If we have the correct number of matches
                        pracListCompleted = 1; % Move on
                    else
                        pracListCompleted = 0; % Start loop again
                    end
                    
                    if z > 5000 % If too many iterations are attempted
                        error('Trial types could not be computed. Try again')
                    end
                end
                
                % Populate design
                
                design(1).matchLocations = matchLocations;
                design(1).imageOrder = trialList;
                
            else
                
                % Create location presentation order
                
                numLocations = 1:length(locationImages); % Create list of locations to choose from
                
                trialList = nan(numTrialsPrac,1); % Create block trial list
                
                z = 0; % Reset iteration count
                pracListCompleted = 0; % Reset the while loop
                
                while not(pracListCompleted)
                    
                    z = z + 1;
                    
                    for trialIteration = 1:numTrialsPrac
                        
                        trialList(trialIteration) = randsample(numLocations,1); % Pick a random stimulus
                        
                    end
                    
                    % Note down location of matches
                    
                    trialList_shifted = [nan(2,1);trialList(1:numel(trialList)-2)];
                    nback_check = [trialList trialList_shifted];
                    matchLocations = find(diff(nback_check,1,2) == 0);
                    
                    % Check if conditions are met
                    
                    if numel(matchLocations) == numMatchesPrac % If we have the correct number of matches
                        pracListCompleted = 1; % Move on
                    else
                        pracListCompleted = 0; % Start loop again
                    end
                    
                    if z > 5000 % If too many iterations are attempted
                        error('Trial types could not be computed. Try again')
                    end
                end
                
                % Populate design
                
                design(1).matchLocations = matchLocations;
                design(1).imageOrder = trialList;
                
            end
            
        elseif practice == 1
            if nback_type == 1
                
                % Create location presentation order
                
                numLocations = 1:length(locationImages); % Create list of locations to choose from
                
                trialList = nan(trials_per_block,1); % Create block trial list
                
                i = 0; % Reset iteration count
                listCompleted = 0; % Reset the while loop
                
                while not(listCompleted)
                    
                    i = i + 1;
                    
                    for trialIteration = 1:trials_per_block
                        
                        trialList(trialIteration) = randsample(numLocations,1); % Pick a random stimulus
                        
                    end
                    
                    % Note down location of matches
                    
                    trialList_shifted = [nan(1,1);trialList(1:numel(trialList)-1)];
                    nback_check = [trialList trialList_shifted];
                    matchLocations = find(diff(nback_check,1,2) == 0);
                    
                    % Check if conditions are met
                    
                    if numel(matchLocations) == numMatches % If we have the correct number of matches
                        if sum(diff(matchLocations) == 1 | diff(matchLocations) == 2) > 0 % Force gaps between matches
                            listCompleted = 0; % Try again matey
                        else
                            listCompleted = 1; % Move on
                        end
                    else
                        listCompleted = 0; % Start loop again
                    end
                    
                    if i > 5000 % If too many iterations are attempted
                        error('Trial types could not be computed. Try again')
                    end
                end
                
                % Populate design
                
                design(1).matchLocations = matchLocations;
                design(1).imageOrder = trialList;
                
            else
                
                % Create location presentation order
                
                for N = 2:Numblocks+1 % Count 'n' upwards from 2
                    
                    numLocations = 1:length(locationImages); % Create list of locations to choose from
                    
                    trialList = nan(trials_per_block,1); % Create block trial list
                    
                    i = 0; % Reset iteration count
                    listCompleted = 0; % Reset the while loop
                    
                    while not(listCompleted)
                        
                        i = i + 1;
                        
                        for trialIteration = 1:trials_per_block
                            
                            trialList(trialIteration) = randsample(numLocations,1); % Pick a random stimulus
                            
                        end
                        
                        % Note down location of matches
                        
                        trialList_shifted = [nan(N,1);trialList(1:numel(trialList)-N)];
                        nback_check = [trialList trialList_shifted];
                        matchLocations = find(diff(nback_check,1,2) == 0);
                        
                        % Check if conditions are met
                        
                        if numel(matchLocations) == numMatches % If we have the correct number of matches
                            if sum(diff(matchLocations) == 1 | diff(matchLocations) == 2) > 0 % Force gaps between matches
                                listCompleted = 0; % Try again matey
                            else
                                listCompleted = 1; % Move on
                            end
                        else
                            listCompleted = 0; % Start loop again
                        end
                        
                        if i > 5000 % If too many iterations are attempted
                            error('Trial types could not be computed. Try again')
                        end
                    end
                    
                    % Populate design
                    
                    design(N-1).matchLocations = matchLocations;
                    design(N-1).imageOrder = trialList;
                    
                end
            end
        end
        
        % Set up log file
        
        RespMat{1,1} = 'Participant ID';
        RespMat{1,2} = 'Day number';
        RespMat{1,3} = 'Session number';
        RespMat{1,4} = 'Dominant hand';
        RespMat{1,5} = 'Date'; % Todays Date
        RespMat{1,6} = 'Time'; % Time of each trial
        RespMat{1,7} = 'Trial number';
        RespMat{1,8} = 'Block number';
        RespMat{1,9} = 'Block trial number';
        RespMat{1,10} = 'n'; % Should be the same as block
        RespMat{1,11} = 'Trial type'; % 0 = Different; 1 = Same as 'n' back
        RespMat{1,12} = 'Stimulus x-coordinate'; % 1, 2, 3
        RespMat{1,13} = 'Stimulus y-coordinate'; % 1, 2, 3
        RespMat{1,14} = 'Filename'; % Image name
        RespMat{1,15} = 'Correct response'; % 0 = Different; 1 = Same
        RespMat{1,16} = 'Response'; % 0 = Different; 1 = Same
        RespMat{1,17} = 'Correct?'; % 0 = Correct; 1 = Incorrect
        RespMat{1,18} = 'Start time';
        RespMat{1,19} = 'End time';
        RespMat{1,20} = 'Raw RT'; % End time minus start time
        
        %% Start of experimental loop %%
        
        while block < Numblocks + 1
            if block < 2 % If first block, show start screen
                if showInstructions == 1
                    
                    Screen('TextSize', window, 35);
                    Screen('TextColor', window, white);
                    
                    StartText = sprintf('Please press the spacebar to see task instructions');
                    StartTextBounds = Screen('TextBounds', window, StartText);
                    Screen('DrawText',window,StartText, ScreenXPixels*.5-StartTextBounds(3)*.5, ScreenYPixels*.5-StartTextBounds(4)*.5), white;
                    Screen('Flip', window);
                    while 1
                        [~,~,keyCode] = KbCheck;
                        if keyCode(KbName('space')) == 1
                            break
                        end
                    end
                end
            else
            end
            KbReleaseWait;
            
            
            % Start block
            if practice == 0
                totalTrials = numTrialsPrac * numBlocksPrac;
                thisManyTrials = numTrialsPrac;
            elseif practice == 1
                if nback_type == 1
                    totalTrials = trials_per_block;
                elseif nback_type == 2
                    totalTrials = trials_per_block * Numblocks;
                end
                thisManyTrials = trials_per_block;
            end
            
            
            % Start block
            while trial < totalTrials
                for blockTrial = 1:thisManyTrials % Present images
                    
                    if blockTrial == 1 % If first trial
                        
                        Screen('TextSize', window, 35);
                        
                        StartText = sprintf('Read the following instructions carefully');
                        if nback_type == 1
                            BlockNotesText2 = sprintf('Press the ''%s'' key if the location is the same as the previous trial', upper(sameKey));
                            BlockNotesText3 = sprintf('Press the ''%s'' key if the location is different to the previous trial', upper(diffKey));
                        else
                            BlockNotesText2 = sprintf('Press the ''%s'' key if the location is the same as %s trials back', upper(sameKey), num2str(n));
                            BlockNotesText3 = sprintf('Press the ''%s'' key if the location is different to %s trials back', upper(diffKey), num2str(n));
                        end
                        BlockNotesText4 = sprintf('You have 5 seconds to make your decision when asked - Be as accurate as possible');
                        if practice == 0
                            BlockNotesText5 = sprintf('Press the spacebar to begin a short practice');
                        elseif practice == 1
                            BlockNotesText5 = sprintf('Press the spacebar to begin this ''block'' of 45 trials');
                        end
                        BlockNotesBounds1 = Screen('TextBounds', window, StartText);
                        BlockNotesBounds2 = Screen('TextBounds', window, BlockNotesText2);
                        BlockNotesBounds3 = Screen('TextBounds', window, BlockNotesText3);
                        BlockNotesBounds4 = Screen('TextBounds', window, BlockNotesText4);
                        BlockNotesBounds5 = Screen('TextBounds', window, BlockNotesText5);
                        Screen('DrawText', window, StartText, ScreenXPixels*.5-BlockNotesBounds1(3)*.5, ScreenYPixels*.3-BlockNotesBounds1(4)*.5), white;
                        Screen('DrawText', window, BlockNotesText2, ScreenXPixels*.5-BlockNotesBounds2(3)*.5, ScreenYPixels*.4-BlockNotesBounds2(4)*.5), white;
                        Screen('DrawText', window, BlockNotesText3, ScreenXPixels*.5-BlockNotesBounds3(3)*.5, ScreenYPixels*.5-BlockNotesBounds3(4)*.5), white;
                        Screen('DrawText', window, BlockNotesText4, ScreenXPixels*.5-BlockNotesBounds4(3)*.5, ScreenYPixels*.6-BlockNotesBounds4(4)*.5), white;
                        Screen('DrawText', window, BlockNotesText5, ScreenXPixels*.5-BlockNotesBounds5(3)*.5, ScreenYPixels*.7-BlockNotesBounds5(4)*.5), white;
                        Screen('Flip', window);
                        
                        % Wait for participant to press spacebar
                        
                        while 1
                            [~,~,keyCode] = KbCheck;
                            if keyCode(KbName('space'))== 1
                                break
                            end
                        end
                        
                    end
                    
                    % Get time
                    
                    this_time = datestr(now, formatTime); % Time start in correct format
                    
                    % Open offscreen windows for drawing prior to presentation
                    
                    BlankScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
                    TargetScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
                    ResponseScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
                    FeedbackScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
                    
                    % Set up parameters for offscreen windows
                    
                    Screen('TextFont', BlankScreen, TextFont);
                    Screen('TextColor', BlankScreen, TextNormal);
                    Screen('TextSize', BlankScreen, TextSize);
                    Screen('TextFont', TargetScreen, TextFont);
                    Screen('TextColor', TargetScreen, TextNormal);
                    Screen('TextSize', TargetScreen, TextSize);
                    Screen('TextFont', ResponseScreen, TextFont);
                    Screen('TextColor', ResponseScreen, TextNormal);
                    Screen('TextSize', ResponseScreen, TextSize);
                    Screen('TextFont', FeedbackScreen, TextFont);
                    Screen('TextSize', FeedbackScreen, 65);
                    
                    % Load the current image file into the workspace
                    
                    current_location = locationImages(design(block).imageOrder(blockTrial)).name; % Load image
                    big_image = imread(current_location);
                    resized_image = imresize(big_image, sizeValue);
                    TargetPicture = Screen('MakeTexture',window,resized_image);
                    Screen('DrawTexture', TargetScreen, TargetPicture, [], []);
                    
                    % Draw blank screen
                    
                    blank_grid = imread(blank_image.name);
                    resized_blank = imresize(blank_grid, sizeValue);
                    BlankPicture = Screen('MakeTexture',window,resized_blank);
                    Screen('DrawTexture', BlankScreen, BlankPicture, [], []);
                    
                    % Draw response screen
                    
                    Screen('DrawTexture', ResponseScreen, BlankPicture, [], []);
                    if dominantHand == 'L'
                        if nback_type == 1
                            ResponseText = sprintf('''%s'' = Same as previous          OR          ''%s'' = Different to previous', upper(sameKey), upper(diffKey));
                        else
                            ResponseText = sprintf('''%s'' = Same as %s back          OR          ''%s'' = Different to %s back', upper(sameKey), num2str(n), upper(diffKey), num2str(n));
                        end
                    else
                        if nback_type == 1
                            ResponseText = sprintf('''%s'' = Different to previous          OR          ''%s'' = Same as previous', upper(diffKey), upper(sameKey));
                        else
                            ResponseText = sprintf('''%s'' = Different to %s back          OR          ''%s'' = Same as %s back', upper(diffKey), num2str(n), upper(sameKey), num2str(n));
                        end
                    end
                    ResponseTextBounds = Screen('TextBounds', window, ResponseText);
                    Screen('DrawText', ResponseScreen, ResponseText, ScreenXPixels*0.5-ResponseTextBounds(3)*.5, ScreenYPixels*0.825, white);
                    
                    if blockTrial == 1 % If first trial
                        Countdown = 5;
                        for i = 1:Countdown % Countdown
                            DrawFormattedText(window,sprintf('%d',Countdown),'center','center', white);
                            Screen('Flip',window);
                            WaitSecs(1);
                            Countdown = Countdown - 1;
                        end
                    end
                    
                    % Ensure participant has let go of any keys
                    
                    KbReleaseWait;
                    
                    % Copy windows at the right time (for best timing)
                    
                    Screen('CopyWindow', BlankScreen, window);
                    time = Screen('Flip', window);
                    for a = 1:NumFramesBlank % Should amount to 1 s
                        Screen('CopyWindow', BlankScreen, window);
                        time = Screen('Flip', window, time + .5 *ifi);
                    end
                    
                    KbReleaseWait; % Do not progress if key is being pressed
                    
                    RestrictKeysForKbCheck(KbCheckResp);
                    
                    if blockTrial > n % Only ask for a response if trial > n-back number
                        
                        ResponseTimeOnset = GetSecs;
                        Resp1 = '.';
                        Screen('CopyWindow', TargetScreen, window);
                        Screen('Flip', window);
                        while GetSecs - ResponseTimeOnset < (TargetTime)
                            if ~ismember(upper(Resp1(1)),KbCheckResp)
                                [keyIsDown, TimeResponse, keyCode] = KbCheck; % Waiting for key press
                                if keyIsDown
                                    kb = KbName(find(keyCode)); % Label key pressed
                                    Resp1 = kb;
                                    if Resp1 == 'q'
                                        KbReleaseWait;
                                        cd(MainFolder);
                                        ListenChar(0);
                                        error('Quit experiment by pressing q key')
                                    end
                                end
                            end
                        end
                        
                        if Resp1 == '.' % If no response recorded, show response probe
                            keyIsDown = 0; % We keep this screen only until a response is recorded
                            Resp2 = '.';
                            Screen('CopyWindow', ResponseScreen, window);
                            Screen('Flip', window);
                            while keyIsDown == 0 && GetSecs - ResponseTimeOnset < (ResponseTime)
                                if ~ismember(upper(Resp2(1)),KbCheckResp)
                                    [keyIsDown, TimeResponse, keyCode] = KbCheck; % Waiting for key press
                                    if keyIsDown
                                        kb = KbName(find(keyCode)); % Label key pressed
                                        Resp2 = kb;
                                        if Resp2 == 'q'
                                            KbReleaseWait;
                                            cd(MainFolder);
                                            ListenChar(0);
                                            error('Quit experiment by pressing q key')
                                        end
                                    end
                                end
                            end
                        else % If Resp1 has been recorded
                            Resp2 = Resp1; % Save first response as Resp2 for ease
                        end
                        % Save response as first key pressed
                        
                        Response{trial} = upper(Resp2);
                        RespondTime = TimeResponse;
                        
                    else % If blocktrial < n just show stim and blank
                        
                        Screen('CopyWindow', TargetScreen, window);
                        time = Screen('Flip', window);
                        for a = 1:NumFramesTarget % Should amount to 1 s
                            Screen('CopyWindow', TargetScreen, window);
                            time = Screen('Flip', window, time + .5 *ifi);
                        end
                        
                        Screen('CopyWindow', BlankScreen, window);
                        time = Screen('Flip', window);
                        for a = 1:NumFramesBlank % Should amount to 600 ms
                            Screen('CopyWindow', BlankScreen, window);
                            time = Screen('Flip', window, time + .5 *ifi);
                        end
                        
                        Response{trial} = 'NA'; % Report no response asked
                    end
                    
                    if sum((design(block).matchLocations == blockTrial)) > 0 % If current trial is a match
                        trial_type = 1; % Same as n-back
                        correct_response = upper(sameKey);
                    else
                        trial_type = 0; % Different to n-back
                        correct_response = upper(diffKey);
                    end
                    
                    %%%%%%%%%%%%%%%%%%
                    % CHECK ACCURACY %
                    %%%%%%%%%%%%%%%%%%
                    
                    % Check for accuracy when response is given
                    
                    % 0 = Correct
                    % 1 = Incorrect
                    % 2 = Miss
                    
                    if Response{trial} == '.'
                        check_accuracy = 2; % Miss
                    elseif Response{trial} == 'NA'
                        check_accuracy = 3; % Not required
                    elseif Response{trial} == correct_response % If response is correct
                        check_accuracy = 1;
                    else
                        check_accuracy = 0; % Incorrect
                    end
                    
                    % Identify x-coordinate
                    
                    if regexp(current_location, regexptranslate('wildcard', '*Left')) == 1
                        x_coordinate = 1;
                    elseif regexp(current_location, regexptranslate('wildcard', '*Mid')) == 1
                        x_coordinate = 2;
                    elseif regexp(current_location, regexptranslate('wildcard', '*Right')) == 1
                        x_coordinate = 3;
                    end
                    
                    
                    % Identify y-coordinate
                    
                    if regexp(current_location, regexptranslate('wildcard', 'Top*')) == 1
                        y_coordinate = 1;
                    elseif regexp(current_location, regexptranslate('wildcard', 'Centre*')) == 1
                        y_coordinate = 2;
                    elseif regexp(current_location, regexptranslate('wildcard', 'Bottom*')) == 1
                        y_coordinate = 3;
                    end
                    
                    if blockTrial > n % Only show feedback if appropriate
                        if practice == 0
                            Screen('TextFont', ResponseScreen, TextFont);
                            Screen('TextSize', ResponseScreen, TextSize);
                            if check_accuracy == 1
                                feedback_grid = imread(correct_image.name);
                            elseif check_accuracy == 0
                                feedback_grid = imread(incorrect_image.name);
                            elseif check_accuracy == 2
                                feedback_grid = imread(slow_image.name);
                            end
                            resized_blank = imresize(feedback_grid, sizeValue);
                            FeedbackPicture = Screen('MakeTexture',window,resized_blank);
                            Screen('DrawTexture', FeedbackScreen, FeedbackPicture, [], []);
                            
                            Screen('CopyWindow', FeedbackScreen, window);
                            time = Screen('Flip', window);
                            for a = 1:NumFramesFeedback % Should amount to 1 s
                                Screen('CopyWindow', FeedbackScreen, window);
                                time = Screen('Flip', window, time + .5 *ifi);
                            end
                            
                        else
                        end
                    else
                    end
                    
                    Screen('Close');
                    
                    %%%%%%%%%%%%%%%%
                    % SAVE RESULTS %
                    %%%%%%%%%%%%%%%%
                    
                    RespMat{trial+1,1} = subjectInitials;
                    RespMat{trial+1,2} = dayNumber;
                    RespMat{trial+1,3} = sessionNumber;
                    RespMat{trial+1,4} = dominantHand;
                    RespMat{trial+1,5} = todays_date;
                    RespMat{trial+1,6} = this_time;
                    RespMat{trial+1,7} = trial;
                    RespMat{trial+1,8} = block;
                    RespMat{trial+1,9} = blockTrial;
                    RespMat{trial+1,10} = n;
                    RespMat{trial+1,11} = trial_type; % 0 = Different; 1 = Same as 'n' back
                    RespMat{trial+1,12} = x_coordinate; % 1 2 3
                    RespMat{trial+1,13} = y_coordinate; % 1 2 3
                    RespMat{trial+1,14} = current_location; % Image name
                    RespMat{trial+1,15} = correct_response; % 0 = Different; 1 = Same;
                    RespMat{trial+1,16} = Response{trial}; % 'M' or 'Z' or '.'
                    RespMat{trial+1,17} = check_accuracy; % 0 = Incorrect; 1 = Correct; 2 = Missed; 3 = Too early
                    
                    if blockTrial > n % Only record a response time if trial > n
                        
                        RespMat{trial+1,18} = ResponseTimeOnset;
                        RespMat{trial+1,19} = RespondTime;
                        RespMat{trial+1,20} = round((RespondTime - ResponseTimeOnset)*1000); % End time minus start time converted to ms
                        
                    end
                    
                    trial = trial + 1; % Increase trial count
                    
                end
                
                KbReleaseWait;
                RestrictKeysForKbCheck(KbCheckList);
                Screen('TextSize', window, 35);
                
                
                if practice == 1 % If not practice
                    if nback_type ~= 1 % And if not 1-back
                        if block < Numblocks
                            BlockNotesText = sprintf('Block %d of %d complete', block, Numblocks);
                            BlockNotesText2 = sprintf('Take a break and press the spacebar to view next instruction');
                            BlockNotesBounds1 = Screen('TextBounds', window, BlockNotesText);
                            BlockNotesBounds2 = Screen('TextBounds', window, BlockNotesText2);
                            Screen('DrawText', window, BlockNotesText, ScreenXPixels*.5-BlockNotesBounds1(3)*.5, ScreenYPixels*.4-BlockNotesBounds1(4)*.5), white;
                            Screen('DrawText', window, BlockNotesText2, ScreenXPixels*.5-BlockNotesBounds2(3)*.5, ScreenYPixels*.6-BlockNotesBounds2(4)*.5), white;
                            Screen('Flip', window);
                            
                            KbReleaseWait;
                            
                            % Wait for participant to press spacebar
                            
                            while 1
                                [~,~,keyCode] = KbCheck;
                                if keyCode(KbName('space'))== 1
                                    break
                                end
                            end
                            
                        end
                    end
                end
                
                KbReleaseWait;
                
                block = block + 1; % Move to next block
                n = n + 1; % Increase 'n'
                if practice == 0 || nback_type == 1
                    block = Numblocks+1; % End practice or 1-back
                end
                
            end
        end
        
        %% End %%
        
        % Save the data to a csv file
        
        ShowCursor;
        ListenChar(0);
        Data = dataset(RespMat);
        
        if nback_type == 1 % If 1-back
            if practice == 0 % If practice
                savename = sprintf('%s-%s-%s-PRACTICE_SNB_1back.csv', subjectInitials, dayNumber, sessionNumber);
            elseif practice == 1 % If main task
                savename = sprintf('%s-%s-%s-%s-SNB_1back.csv', subjectInitials, dayNumber, sessionNumber, datestr(datetime('now'),'ddmmyy-HHMM'));
            end
        else
            if practice == 0 % If practice
                savename = sprintf('%s-%s-%s-PRACTICE_SNB.csv', subjectInitials, dayNumber, sessionNumber);
            elseif practice == 1 % If main task
                savename = sprintf('%s-%s-%s-%s-SNB.csv', subjectInitials, dayNumber, sessionNumber, datestr(datetime('now'),'ddmmyy-HHMM'));
            end
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
        
        if nback_type == 1
            if practice == 0
                DrawFormattedText(window, 'Practice finished! \n \n Ask the experimenter now if you have any questions \n \n Please note, there will be no feedback in the main task \n \n Press the spacebar to see the instructions for the main task', 'center', 'center', white)
                Screen('Flip', window);
            elseif practice == 1
                DrawFormattedText(window, '1-back complete! \n \n Please let the experimenter know', 'center', 'center', white);
                Screen('Flip', window);
            else
            end
        elseif nback_type == 2
            if practice == 0
                DrawFormattedText(window, '2-back practice finished! \n \n Ask the experimenter now if you have any questions \n \n Please note, there will be no feedback in the main task \n \n Press the spacebar to see the instructions for the main task', 'center', 'center', white)
                Screen('Flip', window);
            elseif practice == 1
                DrawFormattedText(window, 'Task complete! \n \n Please let the experimenter know', 'center', 'center', white);
                Screen('Flip', window);
            else
            end
        else % If nback_type = 3 (because this means the end)
        end
        
        
        
        % Wait for spacebar press
        while 1
            [~,~,keyCode] = KbCheck;
            if keyCode(KbName('space'))== 1
                break
            end
        end
        
        clear RespMat % Clear the response matrix so it can be created from scratch next block (rather than overwritten)
        
        check_accuracy = 0; % Reset accuracy check
        block = 1; % Reset block counter
        trial = 1; % Reset trial counter
        if nback_type == 1
            n = 1; % Reset 'n'
        elseif nback_type == 2
            n = 2; % Reset 'n'
        end
        blockTrial = 1; % Reset blocktrial counter
        HideCursor;
        ListenChar(2);
        showInstructions = 0; % Do not show spacebar press again unecessarily
        if nback_legacy == 1 && practice == 1 % If nback_type WAS SET as 1, and practice is currently 1 (so main task has been completed)
            if practice_legacy == 0
                practice = 0; % Reset practice so that 2-back practice can happen
            end
            nback_legacy = 2; % Reset answer so this loop does not occur again
            nback_type = 2; % Increase nback_type
            n = 2; % Reset 'n' for 2-back
        else
            practice = practice + 1; % Otherwise increase practice count
            if nback_type == 2
                n = 2; % Reset 'n'
            end
        end
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
    savename = sprintf('%s-%s-%s-%s-SNB-ERROR.csv', subjectInitials, dayNumber, sessionNumber, datestr(datetime('now'),'ddmmyy-HHMM'));
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
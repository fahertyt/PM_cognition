
% function FIT_START
%
%% Face Identification Task
%
%% Selective Attention task with facial stimuli
%
% Dr Tom Faherty, June 2022
% t.b.s.faherty@bham.ac.uk
%
% Participants are presented with 2 images (one on each side of the fixation cross)
% An arrow tells them which side to pay attention to without moving their eyes
% Their task is to decide if the target presents as male or female
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
    prompt={'Participant ID', 'Testing Day', 'Session Number', 'User hand [L / R]', 'Response keys [0 / 1]', 'Practice? [Y / N]'};
    if exist('pcarryover', 'var') == 1 % If carry over from previous task
        if pcarryover{2} == "1" && pcarryover{3} == "1"
            defaults = {pcarryover{1},pcarryover{2},pcarryover{3},pcarryover{4},'0','Y'};
        else
            defaults = {pcarryover{1},pcarryover{2},pcarryover{3},pcarryover{4},'0','N'};
        end
    else
        defaults = {'XX','1','1','R','0','Y'};
    end
    ANSWER = inputdlg(prompt, 'Face Identification Task', 1, defaults);
    if isempty(ANSWER)
        % User clicked cancel. Bail out! Bail out!
        close all;
        readyStart = 1;
        clearvars -except pcarryover;
        error('User Clicked Cancel')
    elseif ANSWER{4} ~= 'L' && ANSWER{4} ~= 'R'
        close all;
        readyStart = 1;
        clearvars -except pcarryover;
        error('Must choose L or R as participant hand')
    elseif ANSWER{5} ~= "0" && ANSWER{5} ~= "1"
        close all;
        readyStart = 1;
        clearvars -except pcarryover;
        error('Must choose 0 or 1 as response keys')
    elseif ANSWER{6} ~= 'Y' && ANSWER{6} ~= 'N'
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
pcarryover = {subjectInitials, dayNumber, sessionNumber}; % Temporarily save participant ID and session number
practice = (ANSWER{6}); % Save practice

if practice == 'Y'
    practice = 0;
else
    practice = 1;
end

% Identify response keys

if ANSWER{4} == 'R'
    if ANSWER{5} == '0'
        responseKeys = {'p','l'};
    else
        responseKeys = {'l','p'};
    end
elseif ANSWER{4} == 'L'
    if ANSWER{5} == '0'
        responseKeys = {'a','z'};
    else
        responseKeys = {'z','a'};
    end
end

%% Keyboard Setup %%

KbName('UnifyKeyNames');
KbCheckList = [KbName('space'), KbName('t'), KbName(responseKeys{1}), KbName(responseKeys{2})];
KbCheckResp = [KbName('t'), KbName(responseKeys{1}), KbName(responseKeys{2})];

%% SET SOME VARIABLES %%

check_accuracy = 0; % Reset accuracy check
block = 1; % Reset block counter
trial = 1; % Reset trial counter
trials_per_block = 56; % Number of trials per block
dummy_trials = 4; % Number of trials to chuck at beginning of block
Numblocks = 4;
numTrials = Numblocks * trials_per_block;
trials_practice = 8; % Number of practice trials

formatDate = 'dd-mm-yy'; % Set date format
formatTime = 'HH:MM:SS'; % Set time format
todays_date = datestr(now, formatDate); % Today's date in correct format

% Set up screen

WaitSecs(5) % Pause

WhichScreen = max(Screen('Screens'));
black = BlackIndex(WhichScreen); % Black is 0
white = WhiteIndex(WhichScreen); % White is 255
BackgroundColour = black; % Background is set to black (n.b. white/2 = grey)

TextSize = 35;
TextFont = 'Arial';
TextNormal = [255 255 255]; % normal (white) text colour
TextGreen = [35 230 90]; % correct text colour
TextRed = [255 60 0]; % incorrect text colour

window = PsychImaging('OpenWindow', WhichScreen, 0, []);  % Open up a screen

%

Screen('FillRect', window, BackgroundColour); % Create screen background
Screen('Flip', window);
Priority(MaxPriority(window));
[ScreenXPixels, ScreenYPixels] = Screen('WindowSize', window);
Screen('TextSize', window, 100);

% Set coordinates for stim

ScreenLeftLeft = ScreenXPixels*.25;
ScreenLeftRight = ScreenXPixels*.425;
ScreenRightLeft = ScreenXPixels*.575;
ScreenRightRight = ScreenXPixels*.75;
ScreenTop = ScreenYPixels*.3;
ScreenBottom = ScreenYPixels*.7;
PlacementLeft = [ScreenLeftLeft ScreenTop ScreenLeftRight ScreenBottom];
PlacementRight = [ScreenRightLeft ScreenTop ScreenRightRight ScreenBottom];

% Set up screen timings

ifi = Screen('GetFlipInterval',window); % How long is a frame in ms
ScreenRefreshRate = 1/ifi; % Calculate refresh rate

% Stimulus timings in s

FixationTime = 0.5; % 500 ms
ArrowTime = 0.4; % Time that arrow is shown
FixationTimeMill = randi([350,850],numTrials ,1); % Creates jittered fixation time in ms
JitFixationTime = FixationTimeMill/1000; % Changes jittered fixation time to s
TargetTime = 0.075; % 75 ms
FeedbackTime = 1; % 1 s
ResponseWait = 1.5; % 1500 ms

% Stimulus timings in frames (for best timings)

NumFramesFixation = round(FixationTime / ifi);
NumFramesArrow = round(ArrowTime / ifi);
NumFramesTarget = round(TargetTime / ifi);
NumFramesFeedback = round(FeedbackTime / ifi);

try % try, catch, end -- To stop code if there is an error
    
    RestrictKeysForKbCheck(KbCheckList);
    ListenChar(2); % Avoid key presses affecting code
    HideCursor
    
    % Create image arrays
    
    if ispc == 1
        ImageFolder = sprintf('%s\\Stimuli', MainFolder);
    elseif ismac == 1
        ImageFolder = sprintf('%s/Stimuli', MainFolder);
    end
    
    %
    % Aside from the arrow images, all images are taken from the KDEF
    % database (https://kdef.se/home/aboutKDEF)
    %
    % Face images saved in the format GenderIdentifierEmotion
    % i.e., F31AFS is FemaleNumber31Anxious
    %
    % Contact t.b.s.faherty@bham.ac.uk with any queries or for files in
    % this format, and scrambled images
    %

    % Load the image files into workspace
    
    cd(ImageFolder); % The location where the file should be saved
    
    faceImages = [dir('M*.jpg'); dir('F*.jpg')];
    scrambledImages = dir('scrambled*');
    arrowLeftImage = dir('ArrowLeft.png');
    arrowRightImage = dir('ArrowRight.png');
    fixationImage = dir('FixationWhite.png');
    
    % Create index of stimuli features
    
    for i = 1:length(faceImages)
        stimProperties(i).identifier = faceImages(i).name(2:3); % Identifier
        stimProperties(i).gender = faceImages(i).name(1); % Gender
        stimProperties(i).expression = faceImages(i).name(4:5); % Expression
    end
    
    while practice < 2
        
        % Randomise the stimuli order ready for trial creation
        
        stimRandomise = randperm(length(stimProperties));
        faceImages = faceImages(stimRandomise);
        stimProperties = stimProperties(stimRandomise);
        scramRandomise = randperm(length(scrambledImages));
        scrambledImages = scrambledImages(scramRandomise);
        
        % Index location of each set of stim
        
        matrix_count = 1;
        row_count = 1;
        
        for gender_find = ['M', 'F']
            for expression_find = ["AF", "AN", "DI", "HA", "NE", "SA", "SU"]
                for i = 1:length(stimProperties)
                    if stimProperties(i).gender == gender_find
                        if stimProperties(i).expression == expression_find
                            save_array(matrix_count) = i;
                            save_array_empty(matrix_count) = 0;
                            matrix_count = matrix_count+1;
                        end
                    end
                end
                matrix_count = 1;
                indexStructure(row_count).index = save_array;
                indexStructure(row_count).gender = gender_find;
                indexStructure(row_count).expression = expression_find;
                indexStructure(row_count).used = save_array_empty;
                row_count = row_count + 1;
                save_array = [];
                save_array_empty = [];
            end
        end
        
        % Create indicies for one-face trials
        
        scram_count = 1;
        check = 2;
        matrix_count = 1;
        
        for thisblock = 1:(Numblocks*2)
            for gender_find = ["M", "F"]
                for expression_find = ["AF", "AN", "DI", "HA", "NE", "SA", "SU"]
                    for i = 1:length(indexStructure)
                        if indexStructure(i).gender == gender_find
                            if indexStructure(i).expression == expression_find % find correct row
                                array_count = 1; % reset array count
                                check = 2;
                                while check > 1 % keep in loop
                                    if  indexStructure(i).used(1,array_count) == 0 % If the current image has not be selected
                                        targetArray(matrix_count) = indexStructure(i).index(1,array_count); % select image
                                        distractorArray(matrix_count) = scram_count; % Select next scrambled face
                                        indexStructure(i).used(1,array_count) = 1; % Set this stim as used
                                        scram_count = scram_count + 1; % Increase distractor image count
                                        matrix_count = matrix_count + 1;
                                        check = 1; % escape while loop
                                    else
                                        array_count = array_count + 1; % search the next column in this array
                                    end
                                end
                            end
                        end
                    end
                    i = 1;
                end
            end
            oneFaceTrialIndex(thisblock).block = thisblock;
            oneFaceTrialIndex(thisblock).target = targetArray;
            oneFaceTrialIndex(thisblock).distractor = distractorArray;
            targetArray = []; % reset target array
            distractorArray = []; % reset distractor array
            matrix_count = 1; % reset count
        end
        
        % Create indicies for two-face trials
        
        check1 = 2;
        check2 = 2;
        targmatrix_count = 1;
        distmatrix_count = 1;
        all_expressions = ["AF", "AN", "DI", "HA", "NE", "SA", "SU"];
        
        for thisblock = 1:(Numblocks/2)
            for gender_find = ["M", "F"]
                for expression_find = ["AF", "AN", "DI", "HA", "NE", "SA", "SU"]
                    for gender_congruency = [0 1] % 0 = Congruent, 1 = Incongruent
                        for expression_congruency = [0 1] % 0 = Congruent, 1 = Incongruent
                            for i = 1:length(indexStructure) % for to find target
                                if indexStructure(i).gender == gender_find
                                    if indexStructure(i).expression == expression_find % find correct row
                                        targ_array_count = 1; % reset target array count
                                        check1 = 2;
                                        while check1 > 1 % keep in loop
                                            if  indexStructure(i).used(1,targ_array_count) == 0 % If the current image has not be selected
                                                targetArray(targmatrix_count) = indexStructure(i).index(1,targ_array_count); % select image
                                                indexStructure(i).used(1,targ_array_count) = 1; % Set this stim as used
                                                targmatrix_count = targmatrix_count + 1;
                                                
                                                % Now we select details of the distractor
                                                
                                                if gender_congruency == 0 % If distractor is the same gender
                                                    gender_new = gender_find;
                                                else
                                                    if gender_find == "M"
                                                        gender_new = "F";
                                                    elseif gender_find == "F"
                                                        gender_new = "M";
                                                    end
                                                end
                                                
                                                if expression_congruency == 0 % If distractor is the same expresssion
                                                    expression_new = expression_find;
                                                else
                                                    target_expression = expression_find; % Identify current expression
                                                    expression_options = ~strcmp(all_expressions, target_expression); % identify current possible options
                                                    expression_new = randsample(all_expressions(expression_options), 1); % randomly pick a new expression from those available
                                                end
                                                
                                                % Now we find the image similarly to before
                                                
                                                for j = 1:length(indexStructure) % for to find distractor
                                                    if indexStructure(j).gender == gender_new
                                                        if indexStructure(j).expression == expression_new % find correct row
                                                            
                                                            if indexStructure(j).used(1, length(indexStructure(j).used)) == 1 % If there is no image left
                                                                error('Unexpected error in trial coordination, please try again')
                                                            end
                                                            
                                                            dist_array_count = 1; % reset distractor array count
                                                            check2 = 2;
                                                            while check2 > 1 % keep in loop
                                                                if  indexStructure(j).used(1,dist_array_count) == 0 % If the current image has not be selected
                                                                    if stimProperties(indexStructure(j).index(1, dist_array_count)).identifier == stimProperties(targetArray(targmatrix_count-1)).identifier % If distrator image is same identifier as this
                                                                        if indexStructure(i).gender == indexStructure(j).gender % And same gender
                                                                            dist_array_count = dist_array_count + 1; % try again
                                                                        end
                                                                    end
                                                                    distractorArray(distmatrix_count) = indexStructure(j).index(1,dist_array_count); % select image
                                                                    indexStructure(j).used(1,dist_array_count) = 1; % Set this stim as use
                                                                    distmatrix_count = distmatrix_count + 1;
                                                                    check2 = 1; % escape while loop
                                                                else
                                                                    dist_array_count = dist_array_count + 1; % search the next column in this array
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                                check1 = 1; % escape while loop
                                            else
                                                targ_array_count = targ_array_count + 1;
                                            end
                                            j = 1;
                                        end
                                    end
                                end
                            end
                        end
                    end
                    i = 1;
                end
            end
            twoFaceTrialIndex(thisblock).block = thisblock;
            twoFaceTrialIndex(thisblock).target = targetArray;
            twoFaceTrialIndex(thisblock).distractor = distractorArray;
            targetArray = []; % reset target array
            distractorArray = []; % reset distractor array
            targmatrix_count = 1; % reset count
            distmatrix_count = 1; % reset count
        end
        
        % Decide whether stimuli are presented right or left
        
        % IMPORTANT. Must switch each block to ensure even stim mix %
        
        for whichblock = 1:Numblocks
            for whichtrial = 1:length(twoFaceTrialIndex(1).target)
                if mod(whichblock, 2) == 1
                    targetLocation(whichtrial) = mod(whichtrial,2);
                else
                    targetLocation(whichtrial) = ~mod(whichtrial,2);
                end
            end
            design(whichblock).targetLocation = targetLocation;
            targetLocation = []; % Reset target location
        end
        
        % Randomise two-face trial arrays
        
        rand1 = randperm(length(twoFaceTrialIndex(1).target));
        rand2 = randperm(length(twoFaceTrialIndex(2).target));
        
        twoFaceTrialIndex(1).target = twoFaceTrialIndex(1).target(rand1);
        twoFaceTrialIndex(1).distractor = twoFaceTrialIndex(1).distractor(rand1);
        
        twoFaceTrialIndex(2).target = twoFaceTrialIndex(2).target(rand2);
        twoFaceTrialIndex(2).distractor = twoFaceTrialIndex(2).distractor(rand2);
        
        % Split into (4) blocks
        
        for thisblock = 1:Numblocks
            findblock = round(thisblock/2);
            if mod(thisblock, 2) == 0
                twoFaceTrialIndexNew(thisblock).block = thisblock;
                twoFaceTrialIndexNew(thisblock).target = twoFaceTrialIndex(findblock).target(1:length(twoFaceTrialIndex(findblock).target)/2);
                twoFaceTrialIndexNew(thisblock).distractor = twoFaceTrialIndex(findblock).distractor(1:(length(twoFaceTrialIndex(findblock).distractor)/2));
            else
                twoFaceTrialIndexNew(thisblock).block = thisblock;
                twoFaceTrialIndexNew(thisblock).target = twoFaceTrialIndex(findblock).target(((length(twoFaceTrialIndex(findblock).target))/2)+1:length(twoFaceTrialIndex(findblock).target));
                twoFaceTrialIndexNew(thisblock).distractor = twoFaceTrialIndex(findblock).distractor(((length(twoFaceTrialIndex(findblock).distractor)/2)+1):length(twoFaceTrialIndex(findblock).distractor));
            end
        end
        
        % Create final design
        
        if practice == 0 % If practice
            
            design(1).targetImage(1:(trials_practice/2)) = oneFaceTrialIndex(1).target(1:(trials_practice/2));
            design(1).targetImage(((trials_practice/2)+1):trials_practice) = twoFaceTrialIndexNew(1).target(((trials_practice/2)+1):trials_practice);
            
            design(1).distractorImage(1:(trials_practice/2)) = oneFaceTrialIndex(1).distractor(1:(trials_practice/2));
            design(1).distractorImage(((trials_practice/2)+1):trials_practice) = twoFaceTrialIndexNew(1).distractor(((trials_practice/2)+1):trials_practice);
            
            
            design(1).trialType(1:(trials_practice/2)) = 1;
            design(1).trialType(((trials_practice/2)+1):trials_practice) = 2;
            
            pracRand = randperm(trials_practice);
            
            design(1).targetImage = design(1).targetImage(pracRand);
            design(1).distractorImage = design(1).distractorImage(pracRand);
            design(1).trialType = design(1).trialType(pracRand);
            
        elseif practice == 1 % If main task
            
            % Take 2 'blocks' from one-face arrays and 1/2 a 'block' of two-face arrays
            
            for thisblock = 1:Numblocks
                
                design(thisblock).targetImage(1:length(oneFaceTrialIndex(thisblock).target)) = oneFaceTrialIndex(thisblock).target;
                design(thisblock).targetImage(length(oneFaceTrialIndex(thisblock*2).target)+1:length(oneFaceTrialIndex(thisblock*2).target)*2) = oneFaceTrialIndex(thisblock*2).target;
                design(thisblock).targetImage(length(twoFaceTrialIndexNew(thisblock).target)+1:length(twoFaceTrialIndexNew(thisblock).target)*2) = twoFaceTrialIndexNew(thisblock).target;
                
                design(thisblock).distractorImage(1:length(oneFaceTrialIndex(thisblock).distractor)) = oneFaceTrialIndex(thisblock).distractor;
                design(thisblock).distractorImage(length(oneFaceTrialIndex(thisblock*2).distractor)+1:length(oneFaceTrialIndex(thisblock*2).distractor)*2) = oneFaceTrialIndex(thisblock*2).distractor;
                design(thisblock).distractorImage(length(twoFaceTrialIndexNew(thisblock).distractor)+1:length(twoFaceTrialIndexNew(thisblock).distractor)*2) = twoFaceTrialIndexNew(thisblock).distractor;
                
                design(thisblock).trialType(1:length(oneFaceTrialIndex(thisblock).distractor)) = 1;
                design(thisblock).trialType(length(oneFaceTrialIndex(thisblock*2).distractor)+1:length(oneFaceTrialIndex(thisblock*2).distractor)*2) = 1;
                design(thisblock).trialType(length(twoFaceTrialIndexNew(thisblock).distractor)+1:length(twoFaceTrialIndexNew(thisblock).distractor)*2) = 2;
                
            end
            
            % randomise each block
            
            for thisblock = 1:Numblocks
                
                design(thisblock).targetLocation = design(thisblock).targetLocation(randperm(length(design(1).targetLocation)));
                design(thisblock).targetImage = design(thisblock).targetImage(randperm(length(design(1).targetLocation)));
                design(thisblock).distractorImage = design(thisblock).distractorImage(randperm(length(design(1).targetLocation)));
                design(thisblock).trialType = design(thisblock).trialType(randperm(length(design(1).targetLocation)));
                
            end
            
        end
        
        TextSize = 30;
        TextFont = 'Arial';
        TextColour = [255 255 255];
        
        % Set font parameters
        Screen('TextFont', window, TextFont);
        Screen('TextColor', window, TextColour);
        Screen('TextSize', window, TextSize);
        
        % Set up log file
        
        RespMat{1,1} = 'Participant ID';
        RespMat{1,2} = 'Day Number';
        RespMat{1,3} = 'Session Number';
        RespMat{1,4} = 'User hand';
        RespMat{1,5} = 'Response keys';
        RespMat{1,6} = 'Date'; % Todays Date
        RespMat{1,7} = 'Time'; % Time of each trial
        RespMat{1,8} = 'Trial number';
        RespMat{1,9} = 'Block number';
        RespMat{1,10} = 'Block trial number';
        RespMat{1,11} = 'Trial type'; % 1 = one-face; 2 = two-face
        RespMat{1,12} = 'Target expression'; %
        RespMat{1,13} = 'Distractor type'; %
        RespMat{1,14} = 'Target gender'; % 0 = Female; 1 = Male
        RespMat{1,15} = 'Distractor gender'; % 0 = Female; 1 = Male
        RespMat{1,16} = 'Target filename'; % Target image name
        RespMat{1,17} = 'Distractor filename'; % Distractor image name
        RespMat{1,18} = 'Target location'; % 0 = Left; 1 = Right
        RespMat{1,19} = 'Response'; % 'a';'z';'k'; or 'm'
        RespMat{1,20} = 'Correct?'; % 0 = Incorrect; 1 = Correct
        RespMat{1,21} = 'Start time';
        RespMat{1,22} = 'End time';
        RespMat{1,23} = 'Raw RT'; % End time minus start time
        
        %% Start of experimental loop %%
        while block < Numblocks + 1
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
                
                KbReleaseWait;
                
                % Create block instruction text
                
                mKey = responseKeys{1};
                fKey = responseKeys{2};
                
                Screen('TextSize', window, 35);
                
                StartText = sprintf('Read the following instructions carefully');
                BlockNotesText2 = sprintf('Press the ''%s'' key when a male-presenting face is shown', upper(mKey));
                BlockNotesText3 = sprintf('Press the ''%s'' key when a female-presenting face is shown', upper(fKey));
                BlockNotesText4 = sprintf('Be as quick and accurate as possible');
                if practice == 0
                    BlockNotesText5 = sprintf('Press the spacebar to begin a short practice');
                elseif practice == 1
                    BlockNotesText5 = sprintf('Press the spacebar to begin the main task');
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

            RestrictKeysForKbCheck(KbCheckResp);
            
            % Start block
            if practice == 0
                totalTrials = trials_practice;
                thisManyTrials = trials_practice;
            elseif practice == 1
                totalTrials = (trials_per_block * block);
                thisManyTrials = trials_per_block;
            end
            
            while trial < totalTrials
                for blockTrial = 1:thisManyTrials % Present images
                    
                    % Get time
                    
                    this_time = datestr(now, formatTime); % Time start in correct format
                    
                    % Stimulus timings in frames (for best timings)
                    
                    NumFramesJitFixation = round(JitFixationTime(trial) / ifi);
                    
                    % Open offscreen windows for drawing prior to presentation
                    
                    FixationScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
                    ArrowScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
                    TargetScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
                    FeedbackScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
                    
                    % Set font parameters for each offscreen window
                    Screen('TextFont', FixationScreen, TextFont);
                    Screen('TextColor', FixationScreen, TextColour);
                    Screen('TextSize', FixationScreen, 100);
                    Screen('TextFont', ArrowScreen, TextFont);
                    Screen('TextColor', ArrowScreen, TextColour);
                    Screen('TextSize', ArrowScreen, TextSize);
                    Screen('TextFont', TargetScreen, TextFont);
                    Screen('TextColor', TargetScreen, TextColour);
                    Screen('TextSize', TargetScreen, TextSize);
                    
                    % Make target textures
                    
                    targetImage = faceImages(design(block).targetImage(blockTrial));
                    
                    if design(block).trialType(blockTrial) == 1 % If one face trial
                        distractorImage = scrambledImages(design(block).distractorImage(blockTrial)); % Select image from scrambled array
                    else
                        distractorImage = faceImages(design(block).distractorImage(blockTrial)); % Select image from face array
                    end
                    
                    % Draw fixation screen
                    
                    fix_cross = imread(fixationImage.name);
                    resized_fix = imresize(fix_cross, 0.1);
                    FixationPicture = Screen('MakeTexture',window,resized_fix);
                    Screen('DrawTexture', FixationScreen, FixationPicture, [], []);
                    
                    % Make textures for showing
                    
                    if design(block).targetLocation(blockTrial) == 0 % Left target
                        leftPicture = Screen('MakeTexture',window,imread(targetImage.name));
                        leftPictureName = targetImage;
                        rightPicture = Screen('MakeTexture',window,imread(distractorImage.name));
                        rightPictureName = distractorImage;
                        ArrowTexture = Screen('MakeTexture',window,imread(arrowLeftImage.name));
                    else % Right target
                        leftPicture = Screen('MakeTexture',window,imread(distractorImage.name));
                        leftPictureName = distractorImage;
                        rightPicture = Screen('MakeTexture',window,imread(targetImage.name));
                        rightPictureName = targetImage;
                        ArrowTexture = Screen('MakeTexture',window,imread(arrowRightImage.name));
                    end
                    
                    if blockTrial == 1 % If first trial
                        Countdown = 5;
                        for i = 1:Countdown
                            DrawFormattedText(window,sprintf('%d',Countdown),'center','center');
                            Screen('Flip',window);
                            WaitSecs(1);
                            Countdown = Countdown - 1;
                        end
                    end
                    
                    % Ensure participant has let go of any keys
                    
                    KbReleaseWait;
                    
                    % Draw using Textures (Pictures)
                    
                    Screen('DrawTexture', TargetScreen, leftPicture, [],PlacementLeft, 0);
                    Screen('DrawTexture', TargetScreen, rightPicture, [], PlacementRight, 0);
                    Screen('DrawTexture', TargetScreen, FixationPicture, [], []);
                    Screen('DrawTexture', ArrowScreen, ArrowTexture, [], [], 0);
                    
                    % Copy windows at the right time (for best timings)
                    
                    Screen('CopyWindow', FixationScreen, window);
                    time = Screen('Flip', window);
                    for a = 1:NumFramesFixation % Should amount to 500 ms
                        Screen('CopyWindow', FixationScreen, window);
                        time = Screen('Flip', window, time + .5 *ifi);
                    end
                    
                    KbReleaseWait; % Do not progress if key is being pressed
                    
                    % Flip to arrow screen
                    
                    Screen('CopyWindow', ArrowScreen, window);
                    time = Screen('Flip', window);
                    for a = 1:NumFramesArrow % Should amount to 400 ms
                        Screen('CopyWindow', ArrowScreen, window);
                        time = Screen('Flip', window, time + .5 *ifi);
                    end
                    
                    % Flip fixation cross back on
                    
                    Screen('CopyWindow', FixationScreen, window);
                    time = Screen('Flip', window);
                    for a = 1:NumFramesJitFixation % Should amount to between 350 and 800 ms
                        Screen('CopyWindow', FixationScreen, window);
                        time = Screen('Flip', window, time + .5 *ifi);
                    end
                    
                    % Flip target array on
                    
                    Screen('CopyWindow', TargetScreen, window);
                    time = Screen('Flip', window);
                    for a = 1:NumFramesTarget % Should amount to 75 ms
                        Screen('CopyWindow', TargetScreen, window);
                        time = Screen('Flip', window, time + .5 *ifi);
                    end
                    
                    %% FLip to fixation and record response %%
                    
                    keyIsDown = 0;
                    ResponseTimeOnset = GetSecs;
                    Resp = '.';
                    Screen('CopyWindow', FixationScreen, window);
                    Screen('Flip', window);
                    while keyIsDown == 0 && GetSecs - ResponseTimeOnset < (ResponseWait)
                        if ~ismember(upper(Resp(1)),KbCheckResp)
                            [keyIsDown, ResponseTimeEnd, keyCode] = KbCheck; % Waiting for key press
                            if keyIsDown
                                kb = KbName(find(keyCode)); % Label key pressed
                                Resp = kb(1); % Recode as uppercase
                                if Resp == 't'
                                    KbReleaseWait;
                                    cd(MainFolder);
                                    ListenChar(0);
                                    error('Terminate experiment by pressing t key')
                                end
                            end
                        end
                    end
                    
                    % Record trial accuracy
                    
                    if Resp ~='.' % If participant responded
                        if targetImage.name(1) == "M" % If target gender is male
                            if Resp == mKey % And mKey was pressed
                                trialAccuracy = 1; % Correct
                            else
                                trialAccuracy = 0;
                            end
                        elseif targetImage.name(1) == "F" % If target gender is female
                            if Resp == fKey % And fKey was pressed
                                trialAccuracy = 1; % Correct
                            else
                                trialAccuracy = 0;
                            end
                        end
                    else
                        trialAccuracy = 2; % Missed
                    end
                    
                    % If practice, present feedback
                    
                    if practice == 0
                        
                        Screen('TextFont', FeedbackScreen, TextFont);
                        Screen('TextSize', FeedbackScreen, TextSize);
                        
                        if trialAccuracy == 1
                            DrawFormattedText(FeedbackScreen, 'Correct', 'center', 'center', TextGreen);
                        elseif trialAccuracy == 0
                            DrawFormattedText(FeedbackScreen, 'Incorrect', 'center', 'center', TextRed);
                        elseif trialAccuracy == 2
                            DrawFormattedText(FeedbackScreen, 'Too slow!', 'center', 'center', TextRed);
                        end
                        
                        KbReleaseWait;
                        
                        for d = 1:NumFramesFeedback % Should amount to 1s
                            Screen('CopyWindow', FeedbackScreen, window);
                            time = Screen('Flip', window,time + .5*ifi);
                        end
                    else
                    end
                    
                    KbReleaseWait;
                    
                    Screen('Close');
                    
                    %%%%%%%%%%%%%%%%
                    % SAVE RESULTS %
                    %%%%%%%%%%%%%%%%
                    
                    RespMat{trial+1,1} = subjectInitials;
                    RespMat{trial+1,2} = dayNumber;
                    RespMat{trial+1,3} = sessionNumber;
                    RespMat{trial+1,4} = ANSWER{4};
                    RespMat{trial+1,5} = responseKeys;
                    RespMat{trial+1,6} = todays_date; % Todays Date
                    RespMat{trial+1,7} = this_time; % Time of each trial
                    RespMat{trial+1,8} = trial;
                    RespMat{trial+1,9} = block;
                    RespMat{trial+1,10} = blockTrial;
                    RespMat{trial+1,11} = design(block).trialType(blockTrial); % 1 = one-face; 2 = two-face
                    RespMat{trial+1,12} = targetImage.name(4:5);
                    if  design(block).trialType(blockTrial) == 1
                        RespMat{trial+1,13} = 'SCRAM';
                        RespMat{trial+1,15} = 'SCRAM';
                    else
                        RespMat{trial+1,13} = distractorImage.name(4:5);
                        RespMat{trial+1,15} = distractorImage.name(1);
                    end
                    RespMat{trial+1,14} = targetImage.name(1);
                    RespMat{trial+1,16} = targetImage.name; % Target image name
                    RespMat{trial+1,17} = distractorImage.name; % Distractor image name
                    RespMat{trial+1,18} = design(block).targetLocation(blockTrial); % 0 = Left; 1 = Right
                    RespMat{trial+1,19} = upper(Resp); % 'a';'z';'l'; or 'p'
                    RespMat{trial+1,20} = trialAccuracy; % 0 = Incorrect; 1 = Correct
                    RespMat{trial+1,21} = ResponseTimeOnset;
                    RespMat{trial+1,22} = ResponseTimeEnd;
                    RespMat{trial+1,23} = round((ResponseTimeEnd - ResponseTimeOnset)*1000); % End time minus start time converted to ms
                    
                    trial = trial + 1; % Increase trial count
                    
                end
            end
            
            KbReleaseWait

                        RestrictKeysForKbCheck(KbCheckList);
            
            if practice ~= 0
                if block < Numblocks
                    
                    BreakInfoText = sprintf('Block %d of %d complete',block, Numblocks);
                    BreakInfoBounds = Screen('TextBounds',window,BreakInfoText);
                    Screen('DrawText',window,BreakInfoText,ScreenXPixels*.5-BreakInfoBounds(3)*.5,ScreenYPixels*.25-BreakInfoBounds(4)*.5, white);
                    DrawFormattedText(window,'Take a Break!','center','center', white);
                    ContinueText = sprintf('Remember ''%s'' for male and ''%s'' for female.  Press space when ready', upper(mKey), upper(fKey));
                    ContinueBounds = Screen('TextBounds',window,ContinueText);
                    Screen('DrawText',window,ContinueText,ScreenXPixels*.5-ContinueBounds(3)*.5,ScreenYPixels*.75-ContinueBounds(4)*.5, white);
                    Screen('Flip',window);
                    
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
                
                % Increase block count
                
                block = block + 1; % Move to next block
                
            else
                % If practice, go to the last block
                block = Numblocks+1;
            end
            
        end
        
        %% End %%
        
        % Save the data to a csv file
        
        ShowCursor;
        ListenChar(0);
        Data = dataset(RespMat);
        
        if practice == 0 % If practice
            savename = sprintf('%s-%s-%s-PRACTICE_FIT.csv', subjectInitials, dayNumber, sessionNumber);
        elseif practice == 1 % If main task
            savename = sprintf('%s-%s-%s-%s-FIT.csv', subjectInitials, dayNumber, sessionNumber, datestr(datetime('now'),'ddmmyy-HHMM'));
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
            DrawFormattedText(window, 'Practice finished! \n \n Ask the experimenter now if you have any questions \n \n Please note, there will be no feedback for the main task \n \n When ready, please press the spacebar to start the main task', 'center', 'center', white)
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
    savename = sprintf('%s-%s-%s-%s-FIT-ERROR.csv', subjectInitials, dayNumber, sessionNumber, datestr(datetime('now'),'ddmmyy-HHMM'));
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
clc
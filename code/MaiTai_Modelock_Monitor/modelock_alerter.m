function modelock_alerter(varargin)

% Monitor MaiTai modelock stats and send send stop signal and/or a Slack notification in case of failure
%
% Purpose
% The TissueVision Orchestrator acquisition software is not able to monitor the modelock status
% of the excitation laser. If the laser loses modelock, the acquisition software will continue
% scanning regardless and the sample will be lost. To solve this issue, TV sent us a version 
% of Vivace that stops the acquisition if PFI15 on the NI board goes high. If the acquisition 
% has been stopped for more than about two minutes, it will time-out and you will have to 
% forcibly quit Orchestrator and re-start. So you can't use PFI15 to pause indefinitely. That's 
% the best it gets, apparently. 
%
%
% Hardware wiring instructions
% - In the right of the BNC 2090A break-out board, connect User 2 to PFI15 using a solid-core wire
%   (22AGW is good). You can now access PFI15 via the User 2 BNC connector. 
% - Connect User 2 to a digital output on a separate NI device that will be driven by this program. 
%   An NI USB-6008 is a good choice.
%
%
% Notes
% When everything is set up and you run this program, PFI15 will be set to 0V and the acquisition
% can proceed. If you reboot the machine performing the modelock monitoring or otherwise cause 
% PFI15 to receive +5V then the acquisition will not proceed and new acquisitions can not be started. 
% A pop-up window will appear saying "An external device has signaled an error condition"
%
%
%
% Configuring the modelock monitoring GUI
% There is no separate configuration file (sorry). To configure, do the following:
% a)  If the laser COM port is not 'COM1', create a variable called laserCom and assign to it
%     a string defining the laser COM port. Save this to a file called laserCom.mat and place it
%     in the system path. e.g.
%     >> laserCom='COM2'
%     >> save laserCom LaserCom
% b)  The NI DAQ device and digital output ports need to be set by changing the code below
%     at the line containing the comment string "%EDIT THIS LINE: NI"
% c)  If using the Slack notifications, edit the Slack hook at the line containing the 
%     comment string  "%EDIT THIS LINE: SLACK" 
%     You will also need SlackMATLAB from https://github.com/DylanMuir/SlackMatlab
%
%
%
% To start the monitoring GUI:
% 1. Start the Spectra GUI. Turn on the laser. Set to the desired wavelength.
% 2. Close the GUI, selecting the option to close the shutter but leave the
%    laser turned on.
% 3. Then run modelock_alerter. You will need a version of MATLAB with the data acquisition
%    toolbox.
%
%
% Using the GUI:
% 1. Pressing the monitor button will poll the laser for modelock status at the interval shown in the text box beneath it. 
% 2. The laser shutter can be opened using the button.
% 3. You can choose whether to send a Slack message and/or pause the laser in case of modelock failure. 
% 4. If failure was detected, you can set up the current section again then resume monitoring.
% 5. There is a manual pause button. TV acquisition software will time out if it is paused for more than 2 or 3 minutes.
% 
%
%
% Dependencies:
% SlackMATLAB - https://github.com/DylanMuir/SlackMatlab
% The session-based Data Acquisition Toolbox
%
%
%
% Rob Campbell - Basel 2015

% Last Modified by GUIDE v2.5 08-Aug-2015 15:39:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @modelock_alerter_OpeningFcn, ...
                   'gui_OutputFcn',  @modelock_alerter_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Outputs from this function are returned to the command line.
function varargout = modelock_alerter_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes just before modelock_alerter is made visible.
function modelock_alerter_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to modelock_alerter (see VARARGIN)

% Choose default command line output for modelock_alerter
handles.output = hObject;

%Ensure there are no serial ports hanging around that should not be
delete(instrfindall) 

%Connect to digital IO (edit next two lines)
handles.NI = daq.createSession('ni');
handles.NI.addDigitalChannel('usbaux','port0/line0','outputonly'); %EDIT THIS LINE: NI
outputSingleScan(handles.NI,0)

%Connect to serial device
if exist('laserCom.mat','file')
    fprintf('Loading laserCom.mat for laser COM port name\n')
    load('laserCom.mat') % <--- LASER COM PORT LOADED FROM HERE
    handles.laserCom=laserCom;
else
    defaultCom='COM1'; 
    fprintf('Guessing laser is on %s.\nIf not, create a laserCom .mat file\n',defaultCom)
    handles.laserCom=defaultCom;
end
fprintf('Attempting laser connection on %s\n',handles.laserCom);
handles.serial=serial(handles.laserCom','BaudRate',9600); 
fopen(handles.serial)

%Define SlackHook
MF_Lab_hook='https://hooks.slack.com/services/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  '; %EDIT THIS LINE: SLACK
handles.slackHook=MF_Lab_hook;

%Disable the slack notification check box if the notifier program isn't in the path
if isempty(which('SendSlackNotification.m'))
    fprintf('Disabling slack notifications. The notifier function is not in your path\nSee: https://github.com/DylanMuir/SlackMatlab\n\n')
    set(handles.sendSlackCheckBox,'Enable','Off','Value',0) 
end

handles.isModeLocked=checkModeLock(handles);
if handles.isModeLocked==-1
    gui_noLaserComms(handles)
elseif handles.isModeLocked==0
    fprintf('Connection to laser succeeded -- laser not modelocked\n')
    gui_notModeLocked(handles)
elseif handles.isModeLocked==1
     fprintf('Connection to laser succeeded -- laser is modelocked\n')
     gui_setModeLocked(handles)
end

% Update handles structure
guidata(hObject, handles);



function monModeLockButton_Callback(hObject, eventdata, handles)
% When enabled, poll the laser periodically to monitor the modelock status

showMessage(handles,'')
if get(hObject,'Value')==1
    %Begin monitoring
    set(handles.pollingTextBoxValue,'Enable','Off')
    set(handles.manualPause,'Enable','On')
    startMonitoring(handles)
else
    set(hObject,'String','Start Monitoring')
    set(handles.pollingTextBoxValue,'Enable','On')
    set(handles.manualPause,'Enable','On')
end


function shutter_Callback(hObject, eventdata, handles)
%Open and close the laser shutter
if get(hObject,'Value')==1
    %Open shutter
    set(hObject,'String','Shutter Open!')
    fprintf(handles.serial,'shutter 1');
else
    set(hObject,'String','Shutter Closed')
    fprintf(handles.serial,'shutter 0');
end


% ----------------------------------------------------------------
% Check box handling 
function sendSlackCheckBox_Callback(hObject, eventdata, handles)
    checker(handles)

function pauseAcqCheckBox_Callback(hObject, eventdata, handles)
    checker(handles)

function checker(handles)
%issue warning to console if nothing will happen on error.
%i.e. if both the checkboxes are unchecked
if get(handles.sendSlackCheckBox,'Value')==0 & get(handles.pauseAcqCheckBox,'Value')==0
    showMessage(handles,'Modelock fail will be ignored!')
    set(handles.sendSlackCheckBox,'ForegroundColor','r')
    set(handles.pauseAcqCheckBox,'ForegroundColor','r')
else
    set(handles.sendSlackCheckBox,'ForegroundColor','k')
    set(handles.pauseAcqCheckBox,'ForegroundColor','k')
    showMessage(handles,'')
end



function pollingTextBoxValue_Callback(hObject, eventdata, handles)
% Executes when the polling interval value is changed to keep it within range. 
val = str2num(get(hObject,'String'));
minVal=5;
if val<minVal
    val=minVal;
elseif val>270
    val=270;
end

val = round(val);

set(hObject,'String', num2str(val))
fprintf('Polling interval changed to %d seconds\n', val)


% ----------------------------------------------------------------
function startMonitoring(handles)
    %The main workhorse function. 
    outputSingleScan(handles.NI,0) %Ensure we're not sending a pause signal

    handles.isModeLocked=checkModeLock(handles);

    fprintf('\nPolling every %s seconds\n', get(handles.pollingTextBoxValue,'String'))

    %Stays in the following while loop as along as the mode lock monitoring toggle button is pressed
    currTime = 0;
    while get(handles.monModeLockButton,'Value')
        
        if ((now-currTime)*24*60^2) > str2num(get(handles.pollingTextBoxValue,'String'))
            if handles.isModeLocked
                 gui_setModeLocked(handles)
            elseif ~handles.isModeLocked %break if laser loses modelock
                gui_notModeLocked(handles)
                %set(handles.manualPause,'Enable','Off')
                break
            end

            currTime=now;
        end %if ((now-currTime)*24*60^2) >...

        pause(0.15) %A pause of some sort appears to be necessary

    end %while ...


    %When we enter this stage the above loop either broke because the user
    %stopped it or because the laser failed to modelock
    if handles.isModeLocked
        fprintf('User aborted monitoring and laser is modelocked\n')
    else
        fprintf('\n** Modelock failure caught **\n')
        %Pause acquisition on mode-lock failure if the appropriate checkbox is ticked
        if get(handles.pauseAcqCheckBox,'Value')==1
            pauseMessage = 'It has been paused.';
            pauseIssuer(handles,1)
        else
            pauseMessage = 'It has not been paused.';           
            pauseIssuer(handles,0)  %just for neatness
        end

        %Send a Slack notification if this was requested. 
        %If not, just print failure notification to screen.
        msg = sprintf('Laser lost modelock at %s. %s',...
                datestr(now), pauseMessage);
        if get(handles.sendSlackCheckBox,'Value')==1
            SendSlackNotification(handles.slackHook,msg);
            fprintf('Sent Slack message\n')
        else
            fprintf('%s\n',msg)         
        end

    end     


function showMessage(handles,msg)
    %Write string "msg" to the messageBox text box
    if isstr(msg)
        set(handles.messageBox,'String',msg)
    end


function pauseIssuer(handles,isPaused)
    %Send digital output HIGH if acquisition is to be paused and LOW otherwise.
    %Also update GUI to indicate if this has happened. 
    if isPaused
        set(handles.pauseState,'String','Paused','BackgroundColor','r')
        outputSingleScan(handles.NI,1)
    else
        set(handles.pauseState,'String','Running','BackgroundColor','g')
        outputSingleScan(handles.NI,0)
    end
        


function manualPause_Callback(hObject, eventdata, handles)
    %Send the state of the pause button to the pause issuer 
    pauseIssuer(handles,get(hObject,'Value'))

    


function R=sendAndReceiveSerial(handles,str)
    % Send a serial command and read back 
    % Only use this function if the serial command being sent should return something 
    fprintf(handles.serial,str);
    R=fgets(handles.serial);
    if ~isempty(R)
        R(end)=[];
    else
        fprintf('Laser serial command %s did not return a reply\n',str)
    end

function ml=checkModeLock(handles)
%return 1 if modelocked
    ml=sendAndReceiveSerial(handles,'*STB?'); %modelock state embedded in the second bit of this 8 bit number
    if isempty(ml)
        fprintf('checkModeLock - Unable to obtain response from laser\n');
         ml=-1;
        return
    end
       
    %extract modelock state
    bits = fliplr(dec2bin(str2num(ml),8));
    if strcmp(bits(2),'1')
        ml=1;
    else 
        ml=0;
    end

    
    
function gui_setModeLocked(handles)
    set(handles.isModelockedTextBox,'String','Locked','BackgroundColor','g')
    set(handles.monModeLockButton,'String','Stop monitoring')
    
function gui_notModeLocked(handles)
    set(handles.isModelockedTextBox,'String','FAILED!','BackgroundColor','r')
    set(handles.monModeLockButton,'Value',0,'String','Resume monitoring')
    showMessage(handles,['FAILED AT - ',datestr(now,'dd/mm HH:MM:SS')] )
    
function gui_laserCommsAvailable(handles)
    set(handles.monModeLockButton,'Enable','On')
    set(handles.shutter,'Enable','On')
    set(handles.pauseAcqCheckBox,'Enable','On')
    set(handles.sendSlackCheckBox,'Enable','On')
    set(handles.isModelockedTextBox,'Visible','On')
    set(handles.text3,'Visible','On')
    set(handles.pollingTextBoxValue,'Visible','On')

function gui_noLaserComms(handles)
    set(handles.monModeLockButton,'Enable','Off')
    set(handles.shutter,'Enable','Off')
    set(handles.pauseAcqCheckBox,'Enable','Off')
    set(handles.sendSlackCheckBox,'Enable','Off')
    set(handles.isModelockedTextBox,'Visible','Off')
    set(handles.text3,'Visible','Off')
    set(handles.pollingTextBoxValue,'Visible','Off')

    
    
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% Executes when user attempts to close figure1.

fclose(handles.serial)
outputSingleScan(handles.NI,0)
delete(handles.NI)
delete(hObject); % delete(hObject) closes the figure

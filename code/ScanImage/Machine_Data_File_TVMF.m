% Most Software Machine Data File


%% ScanImage

%Global microscope properties
objectiveResolution = 43.52;   % Resolution of the objective in microns/degree of scan angle

%Scanner systems
scannerNames = {'Galvo'};      % Cell array of string names for each scan path in the microscope
scannerTypes = {'Linear'};        % Cell array indicating the type of scanner for each name. Current options: {'Resonant' 'Linear'}

%Simulated mode
simulated = false;                  % Boolean for activating simulated mode. For normal operation, set to 'false'. For operation without NI hardware attached, set to 'true'.

%Optional components
components = {};                    % Cell array of optional components to load. Ex: {'dabs.thorlabs.ECU1' 'dabs.thorlabs.BScope2'}

%Data file location
dataDir = '[MDF]\ConfigData';       % Directory to store persistent configuration and calibration data. '[MDF]' will be replaced by the MDF directory

startUpScript = '';

%% Shutters
%Shutter(s) used to prevent any beam exposure from reaching specimen during idle periods. Multiple
%shutters can be specified and will be assigned IDs in the order configured below.
shutterNames = {'Main Shutter'};    % Cell array specifying the display name for each shutter eg {'Shutter 1' 'Shutter 2'}
shutterDaqDevices = {'scan'};  % Cell array specifying the DAQ device or RIO devices for each shutter eg {'PXI1Slot3' 'PXI1Slot4'}
shutterChannelIDs = {'port0/line7'};      % Cell array specifying the corresponding channel on the device for each shutter eg {'PFI12'}

shutterOpenLevel = true;               % Logical or 0/1 scalar indicating TTL level (0=LO;1=HI) corresponding to shutter open state for each shutter line. If scalar, value applies to all shutterLineIDs
shutterOpenTime = 0.1;              % Time, in seconds, to delay following certain shutter open commands (e.g. between stack slices), allowing shutter to fully open before proceeding.

%% Beams
beamDaqDevices = {};                            % Cell array of strings listing beam DAQs in the system. Each scanner set can be assigned one beam DAQ ex: {'PXI1Slot4'}

% Define the parameters below for each beam DAQ specified above, in the format beamDaqs(N).param = ...
beamDaqs(1).modifiedLineClockIn = '';           % one of {PFI0..15, ''} to which external beam trigger is connected. Leave empty for automatic routing via PXI/RTSI bus
beamDaqs(1).frameClockIn = '';                  % one of {PFI0..15, ''} to which external frame clock is connected. Leave empty for automatic routing via PXI/RTSI bus
beamDaqs(1).referenceClockIn = '';              % one of {PFI0..15, ''} to which external reference clock is connected. Leave empty for automatic routing via PXI/RTSI bus
beamDaqs(1).referenceClockRate = 1e+07;          % if referenceClockIn is used, referenceClockRate defines the rate of the reference clock in Hz. Default: 10e6Hz

beamDaqs(1).chanIDs = 0;                       % Array of integers specifying AO channel IDs, one for each beam modulation channel. Length of array determines number of 'beams'.
beamDaqs(1).displayNames = {'Beam DAQ 1 CH 1'};                  % Optional string cell array of identifiers for each beam
beamDaqs(1).voltageRanges = 1.25;                % Scalar or array of values specifying voltage range to use for each beam. Scalar applies to each beam.

beamDaqs(1).calInputChanIDs = 1;               % Array of integers specifying AI channel IDs, one for each beam modulation channel. Values of nan specify no calibration for particular beam.
beamDaqs(1).calOffsets = 0;                    % Array of beam calibration offset voltages for each beam calibration channel
beamDaqs(1).calUseRejectedLight = false;        % Scalar or array indicating if rejected light (rather than transmitted light) for each beam's modulation device should be used to calibrate the transmission curve 
beamDaqs(1).calOpenShutterIDs = [];             % Array of shutter IDs that must be opened for calibration (ie shutters before light modulation device).


%% FastZ
%FastZ hardware used for fast axial motion, supporting fast stacks and/or volume imaging
%fastZControllerType must be specified to enable this feature. 
%Specifying fastZControllerType='useMotor2' indicates that motor2 ControllerType/StageType/COMPort/etc will be used.
fastZControllerType = 'analog';           % If supplied, one of {'useMotor2', 'pi.e709', 'pi.e753', 'pi.e665', 'pi.e816', 'npoint.lc40x', 'analog'}. 
fastZCOMPort = [];                  % Integer identifying COM port for controller, if using serial communication
fastZBaudRate = [];                 % Value identifying baud rate of serial communication. If empty, default value for controller used.

%Some FastZ hardware requires or benefits from use of an analog output used to control sweep/step profiles
%If analog control is used, then an analog sensor (input channel) must also be configured
fastZDeviceName = 'PIFOC';               % String specifying device name used for FastZ control
frameClockIn = '';                  % One of {PFI0..15, ''} to which external frame trigger is connected. Leave empty for automatic routing via PXI/RTSI bus
fastZAOChanID = 0;                 % Scalar integer indicating AO channel used for FastZ control
fastZAIChanID = 0;                 % Scalar integer indicating AI channel used for FastZ sensor

%% LinScan (Galvo)
deviceNameAcq = 'scan';      % string identifying NI DAQ board for PMT channels input
deviceNameGalvo = 'scan';      % string identifying NI DAQ board for controlling X/Y galvo. leave empty if same as deviceNameAcq
deviceNameAux = 'PIFOC';      % string identifying NI DAQ board for outputting clocks. leave empty if unused. Must be a X-series board

%Optional
channelsInvert = [true true true true];             % scalar or vector identifiying channels to invert. if scalar, the value is applied to all channels
beamDaqID = [];                     % Numeric: ID of the beam DAQ to use with the linear scan system
shutterIDs = 1;                     % Array of the shutter IDs that must be opened for linear scan system to operate

referenceClockIn = '';              % one of {'',PFI14} to which 10MHz reference clock is connected on Aux board. Leave empty for automatic routing via PXI bus
enableRefClkOutput = 0;         % Enables/disables the export of the 10MHz reference clock on PFI14

%Acquisition
channelIDs = [0 1 2 3];                    % Array of numeric channel IDs for PMT inputs. Leave empty for default channels (AI0...AIN-1)

%Scanner position feedback
deviceNameGalvoFeedback = '';       % string identifying NI DAQ board that reads the galvo position feedback signals. Leave empty if they are on deviceNameGalvo. Cannot be the same as deviceNameAcq when using for line scanning
XMirrorPosChannelID = [];           % The numeric ID of the Analog Input channel to be used to read the X Galvo position (optional).
YMirrorPosChannelID = [];           % The numeric ID of the Analog Input channel to be used to read the y Galvo position (optional).

%Scanner control
XMirrorChannelID = 0;               % The numeric ID of the Analog Output channel to be used to control the X Galvo.
YMirrorChannelID = 1;               % The numeric ID of the Analog Output channel to be used to control the y Galvo.

xGalvoAngularRange = 20;            % max range in optical degrees (pk-pk) for x galvo
yGalvoAngularRange = 20;            % max range in optical degrees (pk-pk) for y galvo

voltsPerOpticalDegreeX = 1;         % galvo conversion factor from optical degrees to volts (negative values invert scan direction)
voltsPerOpticalDegreeY = 0.5;         % galvo conversion factor from optical degrees to volts (negative values invert scan direction)

scanParkAngleX = -2.15;              % Numeric [deg]: Optical degrees from center position for X galvo to park at when scanning is inactive
scanParkAngleY = -2.15;              % Numeric [deg]: Optical degrees from center position for Y galvo to park at when scanning is inactive

%Optional: mirror position offset outputs for motion correction
deviceNameOffset = '';              % string identifying NI DAQ board that hosts the offset analog outputs
XMirrorOffsetChannelID = 0;         % numeric ID of the Analog Output channel to be used to control the X Galvo offset.
YMirrorOffsetChannelID = 1;         % numeric ID of the Analog Output channel to be used to control the y Galvo offset.

XMirrorOffsetMaxVoltage = 0;        % maximum allowed voltage output for the channel specified in XMirrorOffsetChannelID
YMirrorOffsetMaxVoltage = 0;        % maximum allowed voltage output for the channel specified in YMirrorOffsetChannelID

% Most Software Machine Data File

internalRefClockSrc = '';



%% LSC Pure Analog
commandVoltsPerMicron = 0.025; % Conversion factor for command signal to analog linear stage controller
sensorVoltsPerMicron = 0.1;  % Conversion signal for sensor signal from analog linear stage controller. Leave empty for automatic calibration

commandVoltsOffset = 0; % Offset value, in volts, for command signal to analog linear stage controller
sensorVoltsOffset = 0;  % Offset value, in volts, for sensor signal from analog linear stage controller. Leave empty for automatic calibration

% Optional limits (any of these fields can be left blank; if ommited, default limits are +/-10V)
maxCommandVolts = 10;       % Maximum allowable voltage command
maxCommandPosn = 400;        % Maximum allowable position command in microns
minCommandVolts = 0;       % Minimum allowable voltage command
minCommandPosn = 0;        % Minimum allowable position command in microns

analogCmdBoardID = 'PIFOC'; % String specifying NI board identifier (e.g. 'Dev1') containing AO channel for LSC control
analogCmdChanIDs = 0; % Scalar indicating AO channel number (e.g. 0) used for analog LSC control
analogSensorBoardID = 'PIFOC'; % String specifying NI board identifier (e.g. 'Dev1') containing AI channel for LSC position sensor
analogSensorChanIDs = 0; % Scalar indicating AI channel number (e.g. 0) used for analog LSC position sensor

%% Motors
%Motor used for X/Y/Z motion, including stacks. 
%motorDimensions & motorControllerType must be specified to enable this feature.
motorControllerType = '';           % If supplied, one of {'sutter.mp285', 'sutter.mpc200', 'thorlabs.mcm3000', 'thorlabs.mcm5000', 'scientifica', 'pi.e665', 'pi.e816', 'npoint.lc40x'}.
motorDimensions = '';               % If supplied, one of {'XYZ', 'XY', 'Z'}. Defaults to 'XYZ'. To reassign physical axis, permute axis order (e.g. 'XZY')
motorStageType = '';                % Some controller require a valid stageType be specified
motorUSBName = '';                  % USB resource name if controller is connected via USB
motorCOMPort = [];                  % Integer identifying COM port for controller, if using serial communication
motorBaudRate = [];                 % Value identifying baud rate of serial communication. If empty, default value for controller used.
motorZDepthPositive = true;         % Logical indicating if larger Z values correspond to greater depth
motorPositionDeviceUnits = [];      % 1x3 array specifying, in meters, raw units in which motor controller reports position. If unspecified, default positionDeviceUnits for stage/controller type presumed.
motorVelocitySlow = [];             % Velocity to use for moves smaller than motorFastMotionThreshold value. If unspecified, default value used for controller. Specified in units appropriate to controller type.
motorVelocityFast = [];             % Velocity to use for moves larger than motorFastMotionThreshold value. If unspecified, default value used for controller. Specified in units appropriate to controller type.

%Secondary motor for Z motion, allowing either XY-Z or XYZ-Z hybrid configuration
motor2ControllerType = '';          % If supplied, one of {'sutter.mp285', 'sutter.mpc200', 'thorlabs.mcm3000', 'thorlabs.mcm5000', 'scientifica', 'pi.e665', 'pi.e816', 'npoint.lc40x'}.
motor2StageType = '';               % Some controller require a valid stageType be specified
motor2USBName = '';                 % USB resource name if controller is connected via USB
motor2COMPort = [];                 % Integer identifying COM port for controller, if using serial communication
motor2BaudRate = [];                % Value identifying baud rate of serial communication. If empty, default value for controller used.
motor2ZDepthPositive = true;        % Logical indicating if larger Z values correspond to greater depth
motor2PositionDeviceUnits = [];     % 1x3 array specifying, in meters, raw units in which motor controller reports position. If unspecified, default positionDeviceUnits for stage/controller type presumed.
motor2VelocitySlow = [];            % Velocity to use for moves smaller than motorFastMotionThreshold value. If unspecified, default value used for controller. Specified in units appropriate to controller type.
motor2VelocityFast = [];            % Velocity to use for moves larger than motorFastMotionThreshold value. If unspecified, default value used for controller. Specified in units appropriate to controller type.

%Global settings that affect primary and secondary motor
moveCompleteDelay = 0;              % Numeric [s]: Delay from when stage controller reports move is complete until move is actually considered complete. Allows settling time for motor


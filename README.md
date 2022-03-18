# Power
Power is an autohotkey script used to manage when a computer goes to sleep.  I have found that Windows sleep management is not reliable.  This script will ensure that your PC goes to sleep or stays awake when you want it.

## Features
* Control how long your computer is idle before sleeping
* Use Windows native power configuration for processes, drivers or services that prevent sleep
* Ability to prevent sleep when sharing files on the network by file extension (.mp3, .mkv, etc.)
* Blacklist programs from preventing your computer from sleeping (never prevent sleep)
* Whitelist programs that will prevent your computer from sleeping (always on)
* Separate whitelist and timing for media programs (longer idle before sleep)
* Forced sleep schedule per hour (always sleeps unless you are sharing files or have an always on process)
* Always on sleep schedule per hour (will always stay on even if idle)
* Debug mode to see what is prenting sleep
* Icon indicating the current system status
	* Green = The computer is scheduled to be always on at this time
	* Yellow = The computer has blockers preventing sleep
	* Red = The computer has no blockers and will sleep after the specfied interval

## Requirements
The script is provided as an AutoHotkey script or a Windows .exe.  You can use either, but the program must be run as Admin in order to access the Windows power configuration information.

## Settings
After you launch the program for the first time a power.ini configuration file will be created.  This controls the application settings.  Here are the options you can configure:

### Sleep
* Delay: Idle time before sleep is initiated.  The value is a 6 digit number indicating how many days, hours and minutes before sleep (DDHHMM).  By default this is set to 000010 (10 minutes).
* SharedFiles: (1/0) Prevents sleep if the system has open shared files.  Works in conjunction with the Extensions setting.
* Extensions: Comma separated list of file extensions that will prevent sleep if SharedFiles is enabled.  By default this is ".mkv,.avi,.wtv,.exe,.iso,.mp4,.wtv,.ts"
* Processes: Comma separated list of programs that will prevent sleep if they are running on the system.  Ex: "comskip.exe,ffmpeg.exe".
* IgnoreProcesses: Comma separated list of programs to ignore when using Windows power configuration requests .  Works in conjunction with PCFG_Process setting.
* PCFG_Process: (1/0) Use the out of the box Windows power request managment for preventing sleep per applications.  See the Power Requests section.
* PCFG_Service: (1/0) Use the out of the box Windows power request managment for preventing sleep per drivers.  See the Power Requests section.
* PCFG_Driver: (1/0) Use the out of the box Windows power request managment for preventing sleep per services.  See the Power Requests section.

### Always ON
* AlwaysOnWhenSharing: (1/0) When using the SharedFiles and Extensions settigns above, this setting will prevent sleep no matter the schedule configuration you have made (see Schedule section).
* AlwaysOnProcesses: List of processes that will prevent sleep no matter what scheduling configuration you have (see Schedule section).

### Display
* DebugMode: (1/0) When enabled, a tooltip will appear showing your settings, a list of any sleep blockers, and an idle count down timer.  Data is refreshed based on the RefreshInt setting
* RefreshInt: How long in milliseconds to recheck system state and refresh the UI when using debug mode.  By default set to 30 seconds.

### Media
* MediaIdleEnabled: (1/0) Toggle to enable media process idle blocking.  Media processes work the same as Processes except there is separate idle timeout.  Good for music, videos, and games.
* MediaProcesses: Comma separated list of media programs to hat will prevent sleep if they are running on the system.  Ex: "ehshell.exe,kodi.exe,spotify.exe".

## Power Requests
The PCFG_Process, PCFG_Service, PCFG_Driver work in conjunction with Windows application, driver and service [Power Requests](https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options#option_requests).  These settings will not modify the out of the box functionality within Windows.

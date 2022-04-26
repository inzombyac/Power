#NoEnv
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
#KeyHistory 0
#SingleInstance force
#Persistent

PowerAutoExec:
	if not A_IsAdmin {
	   ;Run *RunAs "%A_ScriptFullPath%"
	   MsgBox,16,Error,This script requires admin permission.  Right click and select "Run as Administrator",10
	   ExitApp
	}
	GoSub, InitializeSettings

	; Tray Menu
	GoSub, TrayMenu 
	GoSub, StatusCheck
	SetTimer, StatusCheck, %RefreshInt%
return

StatusCheck:
	running := 0
	blockingProcesses=
	GoSub, CheckPowerCFG
	GoSub, CheckRunningProcesses
	GoSub, CheckSharedFiles
	GoSub, CheckSchedules
	GoSub, CheckScripts
	
	TimeIdle := floor(A_TimeIdle*1/1000)
	;If always on processes are going, reset
	if (alwaysOnProcesses = 1) {
		GoSub, ResetIdleCounters
		Menu, Tray, Icon, %A_ScriptDir%\icons\running.ico
	; If Media player idle is enabled and a media player is running	
	} else If (mediaBlockers > 0 && MediaIdleEnabled = 1 && mediaBlockers = running){
		if (TimeIdle > (mediaDelay-Delaysec))
		{
			isIdle:=1
			SetTimer, UpdateOSD, 1000
			SetTimer, TimerLoop, 1000
			Menu, Tray, Icon, %A_ScriptDir%\icons\sleep.ico
			DllCall("SetThreadExecutionState","UInt",ES_CONTINUOUS)
		} else {
			GoSub, ResetIdleCounters
			if (scheduleBlockers > 0)
				Menu, Tray, Icon, %A_ScriptDir%\icons\running.ico
			else
				Menu, Tray, Icon, %A_ScriptDir%\icons\normal.ico
		}
	; Forced sleep schedule window
	} else if (ScheduledOn%cur_hour% = -1 && (A_TimeIdle >= 10000)) {
		; If always on processes are going, don't sleep
		if (AlwaysOnWhenSharing = 1 && temp_file > 0) {
			GoSub, ResetIdleCounters
			if (scheduleBlockers > 0)
				Menu, Tray, Icon, %A_ScriptDir%\icons\running.ico
			else 
				Menu, Tray, Icon, %A_ScriptDir%\icons\normal.ico
		; Otherwise go to sleep
		} else {
			FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm 
			;FileAppend, %timestart% - Force Sleep Schedule `r`n, %Settings_Path%\logging\power.log
			isIdle:=1
			SetTimer, UpdateOSD, 1000
			SetTimer, TimerLoop, 1000
			Menu, Tray, Icon, %A_ScriptDir%\icons\sleep.ico
			; Turn off system requested
			DllCall("SetThreadExecutionState","UInt",ES_CONTINUOUS)
		}
	; Normal hours, processes are running
	} else if ((running > 0) || (A_TimeIdle < 10000)) {
		GoSub, ResetIdleCounters
		if (scheduleBlockers > 0)
			Menu, Tray, Icon, %A_ScriptDir%\icons\running.ico
		else
			Menu, Tray, Icon, %A_ScriptDir%\icons\normal.ico

	; Otherwise time to sleep		
	} else {
		isIdle:=1
		SetTimer, UpdateOSD, 1000
		SetTimer, TimerLoop, 1000
		Menu, Tray, Icon, %A_ScriptDir%\icons\sleep.ico
		DllCall("SetThreadExecutionState","UInt",ES_CONTINUOUS)
	}
	Menu,Tray,Tip, Power: %running% blockers
	if (DebugMode = 1) {
		sched := ScheduledOn%cur_hour%
		ToolTip, Blockers: %running%  Idle: %isIdle%  Idle time: %TimeIdle%`r`nTimeout: %DelayH%(H) %DelayM%(M)   Media timeout: %MediaIdleTimeoutD%(D) %MediaIdleTimeoutH%(H) %MediaIdleTimeoutM%(M)`r`nPCFG/PROC/AON/SHARE/SCHED/MEDIA: %processRequest%/%processBlockers%/%alwaysOnProcesses%/%sharedFiles%/%scheduleBlockers%/%mediaBlockers%`r`n%blockingProcesses%`r`nSchedule: %sched%`r`nFullscreen: %isCurrentAppFullScreen%`r`n%Script1Output%,0,0
	} else {
		ToolTip
	}
return

TimerLoop:
	if idlePercent = 100
	{
		;MsgBox,0,Warning,Windows will now go to sleep,3
		GoSub, SLEEP
	}
return

SLEEP:
	FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm
	FileAppend, %timestart% - Sleep Activated`r`n, %Settings_Path%\logging\power.log
	if (MediaIdleEnabled = 1)
	{
		Loop, parse, MediaProcesses, `,
		{
			Process, Close, %A_LoopField%
		}
	}
	RunWait, %A_ScriptDir%\scripts\sleep.exe
	Sleep, %RefreshInt%
	FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm
	FileAppend, %timestart% - Resumed`r`n, %Settings_Path%\logging\power.log
	MouseMove, 1 , 1,, R
	MouseMove, -1,-1,, R
	GoSub, ResetIdleCounters
return

SleepNow:
	FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm
	FileAppend, %timestart% - Sleep Activated`r`n, %Settings_Path%\logging\power.log
	DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
	Sleep, %RefreshInt%
	FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm
	FileAppend, %timestart% - Resumed`r`n, %Settings_Path%\logging\power.log
	MouseMove, 1 , 1,, R
	MouseMove, -1,-1,, R
	GoSub, ResetIdleCounters
return

UpdateOSD:
	mysec := EndTime
	EnvSub, mysec, %A_Now%, seconds
	var := FormatSeconds( mysec )
	idlePercent := ((StartTime-mysec)/StartTime)*100
	idlePercent := Floor(idlePercent)
	if (idlePercent > 100 || idlePercent < 0) {
		return
	}
	If (isIdle = 1 or var < 30) {
		if (idleRound > 3 ) {
			; Change icon
		} else {
			idleRound++
		}
	} else {
		idleRound:= 0
	}
return

FormatSeconds(NumberOfSeconds)  ; Convert the specified number of seconds to hh:mm:ss format.
{
    time = 19990101  ; *Midnight* of an arbitrary date.
    time += %NumberOfSeconds%, seconds
    FormatTime, mmss, %time%, mm:ss
    hours := NumberOfSeconds // 3600 ; This method is used to support more than 24 hours worth of sections.
    hours := hours < 10 ? "0" . hours : hours
    return hours ":" mmss
}

ResetIdleCounters:
	SetTimer, UpdateOSD, off
	SetTimer, TimerLoop, off
	StringMid ,DelayD, Delay,1, 2
	StringMid ,DelayH, Delay,3, 2
	StringMid ,Delaym, Delay,5, 2
	Delaysec := (DelayD*86400)+(DelayH*3600)+(Delaym*60)

	StringMid ,MediaIdleTimeoutD, MediaIdleTimeout,1, 2
	StringMid ,MediaIdleTimeoutH, MediaIdleTimeout,3, 2
	StringMid ,MediaIdleTimeoutM, MediaIdleTimeout,5, 2
	mediaDelay := (MediaIdleTimeoutD*86400)+(MediaIdleTimeoutH*3600)+(MediaIdleTimeoutM*60)

	StartTime = %A_Now%
	EndTime = %A_Now%
	EnvAdd EndTime, Delaysec, seconds
	EnvSub StartTime, EndTime, seconds

	StartTime := Abs(StartTime)
	StartMediaTime := Abs(StartMediaTime)
	idlePercent := 0 ;Resets percentage to 0, otherwise this loop never sees the counter reset
	isIdle:=0
	idleRound:=0
	var:=
	DllCall("SetThreadExecutionState","UInt", ES_SYSTEM_REQUIRED | ES_CONTINUOUS)
return

; Functions related to the traymenu

TrayMenu:
	Suspend, Permit
	Menu,Tray,NoStandard 
	Menu,Tray,DeleteAll
	Menu,Tray,Add, Sleep, SLEEPNOW
	Menu,Tray,Add,Debug,DebugToggle
	if (DebugMode = 1)
	{
		Menu,Tray,Check,Debug
	}
	Menu,Tray,Add
	Menu,Tray,Add,Reload,Reload
	if (!A_iscompiled)
		Menu,Tray,Add,Edit Script, EditScript

	Menu,Tray,Add,Edit Settings, EditSettings
	Menu,Tray,Add, Exit, Exit
	Menu,Tray,Tip, Power: %running% blockers
	Menu,Tray, Icon, %A_ScriptDir%\icons\normal.ico,1
return

EditSettings:
	Run, notepad.exe %A_ScriptDir%\power.ini
return

DebugToggle:
	if (DebugMode = 1) {
		DebugMode = 0
		Menu,Tray,Uncheck,Debug
	} else {
		DebugMode = 1
		Menu,Tray,Check,Debug
	}
	IniWrite, %DebugMode%, %A_ScriptDir%\power.ini, Display, DebugMode
return	

InitializeSettings:
	ListLines Off
	Process, Priority, , A
	SetBatchLines, -1
	SetKeyDelay, -1, -1
	SetMouseDelay, -1
	SetDefaultMouseSpeed, 0
	SetWinDelay, -1
	CoordMode, Tooltip, Screen
	ES_CONTINUOUS :=0x80000000
	ES_SYSTEM_REQUIRED :=0x00000001
	ES_DISPLAY_REQUIRED := 0x00000002
	;ES_AWAYMODE_REQUIRED:=0x00000040 ; Don't use awaymode
	; Tell the OS to prevent automatic sleep until we say otherwise
	DllCall("SetThreadExecutionState","UInt", ES_SYSTEM_REQUIRED | ES_CONTINUOUS)
	SetWorkingDir %A_ScriptDir% 
	Settings_Path = %A_ScriptDir% 
	FileCreateDir, %Settings_Path%\logging
	FileCreateDir, %Settings_Path%\scripts
	FileCreateDir, %Settings_Path%\lib
	FileCreateDir, %Settings_Path%\icons
	idlePercent := 0
	isIdle:=0
	idleRound:=0
	OnMessage(0x404, "AHK_NOTIFYICON") ; WM_USER + 4

	IniRead, Delay, %Settings_Path%\power.ini, Sleep, Delay, 000010
	if (Delay < 0)
		Delay=000010
	IniWrite, %Delay%, %Settings_Path%\power.ini, Sleep, Delay
	IniRead, SharedFiles, %Settings_Path%\power.ini, Sleep, SharedFiles, 1
	IniWrite, %SharedFiles%, %Settings_Path%\power.ini, Sleep, SharedFiles

	IniRead, Processes, %Settings_Path%\power.ini, Sleep, Processes, postprocess.exe,comskip.exe
	IniWrite, %Processes%, %Settings_Path%\power.ini, Sleep, Processes

	IniRead, IgnoreProcesses, %Settings_Path%\power.ini, Sleep, IgnoreProcesses, EmbyServer.exe
	IniWrite, %IgnoreProcesses%, %Settings_Path%\power.ini, Sleep, IgnoreProcesses

	IniRead, AlwaysOnProcesses, %Settings_Path%\power.ini, Always ON, AlwaysOnProcesses, teracopy.exe,ffmpeg.exe
	IniWrite, %AlwaysOnProcesses%, %Settings_Path%\power.ini, Always ON, AlwaysOnProcesses

	IniRead, Extensions, %Settings_Path%\power.ini, Sleep, Extensions, .mkv,.avi,.wtv,.exe,.iso,.mp4,.wtv,.ts
	IniWrite, %Extensions%, %Settings_Path%\power.ini, Sleep, Extensions

	IniRead, PCFG_Process, %Settings_Path%\power.ini, Sleep, PCFG_Process, 1
	IniWrite, %PCFG_Process%, %Settings_Path%\power.ini, Sleep, PCFG_Process

	IniRead, PCFG_Service, %Settings_Path%\power.ini, Sleep, PCFG_Service, 0
	IniWrite, %PCFG_Service%, %Settings_Path%\power.ini, Sleep, PCFG_Service

	IniRead, PCFG_Driver, %Settings_Path%\power.ini, Sleep, PCFG_Driver, 0
	IniWrite, %PCFG_Driver%, %Settings_Path%\power.ini, Sleep, PCFG_Driver

	; Always On
	IniRead, AlwaysOnWhenSharing, %Settings_Path%\power.ini, Always ON, AlwaysOnWhenSharing, 1
	IniWrite, %AlwaysOnWhenSharing%, %Settings_Path%\power.ini, Always ON, AlwaysOnWhenSharing

	; Enable tooltip with DebugMode
	IniRead, DebugMode, %A_ScriptDir%\power.ini, Display, DebugMode, 0
	IniWrite, %DebugMode%, %A_ScriptDir%\power.ini, Display, DebugMode
	; How ofter to poll idle status
	IniRead, RefreshInt, %Settings_Path%\power.ini, Display, RefreshInt, 30000
	IniWrite, %RefreshInt%, %Settings_Path%\power.ini, Display, RefreshInt

	; Media Watching idle settings
	IniRead, MediaIdleEnabled, %Settings_Path%\power.ini, Media, MediaIdleEnabled, 1
	IniWrite, %MediaIdleEnabled%, %Settings_Path%\power.ini, Media, MediaIdleEnabled
	IniRead, MediaProcesses, %Settings_Path%\power.ini, Media, MediaProcesses, ehshell.exe,kodi.exe,spotify.exe
	IniWrite, %MediaProcesses%, %Settings_Path%\power.ini, Media, MediaProcesses
	IniRead, MediaIdleTimeout, %Settings_Path%\power.ini, Media, MediaIdleTimeout, 000200
	if (MediaIdleTimeout < 0)
		MediaIdleTimeout=000200
	IniWrite, %MediaIdleTimeout%, %Settings_Path%\power.ini, Media, MediaIdleTimeout
	
	; Secondary script
	IniRead, ScriptsEnabled, %Settings_Path%\power.ini, Scripts, ScriptsEnabled, 0
	IniWrite, %ScriptsEnabled%, %Settings_Path%\power.ini, Scripts, ScriptsEnabled
	IniRead, Script1, %Settings_Path%\power.ini, Scripts, Script1
	IniWrite, %Script1%, %Settings_Path%\power.ini, Scripts, Script1

	; Schedule
	Loop, 24
	{
		IniRead, ScheduledOn%A_Index%, %Settings_Path%\power.ini, Schedule, ScheduledOn%A_Index%, 0
		IniWrite, % ScheduledOn%A_Index%, %Settings_Path%\power.ini, Schedule, ScheduledOn%A_Index%	
	}

	; Display variables
	blockingProcesses=
	processRequest:=0
	sharedFiles:= 0
	scheduleBlockers:=0
	FormatTime, cur_hour,,HH
	filelist=
	processBlockers:=0
	alwaysOnProcesses:=0
	requests=
	Script1Output=

	StringMid ,DelayD, Delay,1, 2
	StringMid ,DelayH, Delay,3, 2
	StringMid ,Delaym, Delay,5, 2
	Delaysec := (DelayD*86400)+(DelayH*3600)+(Delaym*60)

	StringMid ,MediaIdleTimeoutD, MediaIdleTimeout,1, 2
	StringMid ,MediaIdleTimeoutH, MediaIdleTimeout,3, 2
	StringMid ,MediaIdleTimeoutM, MediaIdleTimeout,5, 2
	mediaDelay := (MediaIdleTimeoutD*86400)+(MediaIdleTimeoutH*3600)+(MediaIdleTimeoutM*60)

	StartTime = %A_Now%
	EndTime = %A_Now%
	EnvAdd EndTime, Delaysec, seconds
	EnvSub StartTime, EndTime, seconds

	StartTime := Abs(StartTime)
	
	isCurrentAppFullScreen := isFullScreen()

	FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm
	FileAppend, %timestart% - Application Started`r`n, %Settings_Path%\logging\power.log
return

isFullScreen() {
    WinGetClass, currentClass, A
	WinGet, activeId, ID, A
	WinGet, activeProcess, ProcessName, ahk_id %activeId%
	WinGetPos,,, winWidth, winHeight, A
	winHSize:= winWidth  / A_ScreenWidth 
	winVSize:= winHeight / A_ScreenHeight
	if (!activeId or activeProcess = "explorer.exe")
        return false
    WinGet style, Style, ahk_id %activeId%
    ; Bordeless and not minimized and window size is screen dimensions
    return ((style & 0x20800000) or winHeight < A_ScreenHeight or winWidth < A_ScreenWidth) ? false : true
}

CheckPowerCFG:
	processRequest:=0
	tempProcessList=
	runwait,%comspec% /c powercfg -requests > requests.txt,%Settings_Path%\logging,hide,
	FileRead, requests_raw, %Settings_Path%\logging\requests.txt
	Loop, read, %Settings_Path%\logging\requests.txt
	{
		IfInString, A_LoopReadLine, [PROCESS]
		{
			If (PCFG_Process = 1)
			{			
				; Any process requesting the system is allowed.  Exclude for this application
				if (!A_iscompiled)
				{
					IfNotInstring, A_LoopReadLine, autohotkey.exe
					{
						StringSplit, Array, A_LoopReadLine,\,
						LastItem:=Array%Array0%
						IfNotInstring, tempProcessList, %LastItem% 
						{
							If IgnoreProcesses not contains %LastItem% 
							{
								running++
								tempProcessList=%LastItem%`r`n%tempProcessList%
								processRequest++
								blockingProcesses = %blockingProcesses% %LastItem%
							}
						}
					}
				} else {
					IfNotInstring, A_LoopReadLine, Power.exe
					{
						StringSplit, Array, A_LoopReadLine,\,
						LastItem:=Array%Array0%
						IfNotInstring, tempProcessList, %LastItem% 
						{
							If IgnoreProcesses not contains %LastItem% 
							{
								running++
								tempProcessList=%LastItem%`r`n%tempProcessList%
								processRequest++
								blockingProcesses = %blockingProcesses% %LastItem%
							}
						}
					}
				}
			}
		}
		IfInString, A_LoopReadLine, [SERVICE]
		{
			If (PCFG_Service = 1)
			{
				If tempProcessList not contains %A_LoopReadLine% 
				{
					running++
					tempProcessList=%A_LoopReadLine%`r`n%tempProcessList%
					processRequest++
				}
			}
		}
		IfInString, A_LoopReadLine, [DRIVER]
		{
			If (PCFG_Driver = 1)
			{
				If tempProcessList not contains %A_LoopReadLine% 
				{
					running++
					tempProcessList=%A_LoopReadLine%`r`n%tempProcessList%
					processRequest++
				}
			}
		}
	}
	requests:=Trim(tempProcessList)
return

CheckRunningProcesses:
	alwaysOnProcesses:=0
	Loop, parse, AlwaysOnProcesses, `,
	{
		Process, Exist,  %A_LoopField%
		if (Errorlevel > 0) {
			alwaysOnProcesses:=1
			If blockingProcesses not contains %A_LoopField% 
			{
				running++
				blockingProcesses = %blockingProcesses% %A_LoopField%
				requests =%requests%`r`n[ALWAYS ON] %A_LoopField%
			}
		}
	}

	processBlockers:=0
	Loop, parse, Processes, `,
	{
		Process, Exist,  %A_LoopField%
		if (Errorlevel > 0) {
			If blockingProcesses not contains %A_LoopField% 
			{
				running++
				processBlockers++
				blockingProcesses = %blockingProcesses% %A_LoopField%
				requests =%requests%`r`n[PROCESS] %A_LoopField%
			}
		}
	}

	mediaBlockers:=0
	if (MediaIdleEnabled = 1)
	{
		Loop, parse, MediaProcesses, `,
		{
			Process, Exist, %A_LoopField%
			if (Errorlevel > 0) {
				mediaBlockers++
				If blockingProcesses not contains %A_LoopField% 
				{
					running++
					blockingProcesses = %blockingProcesses% %A_LoopField%
					requests =%requests%`r`n[MEDIA] %A_LoopField%
				}
			}
		}
		isCurrentAppFullScreen := isFullScreen()
		if (isCurrentAppFullScreen) {
			mediaBlockers++
			running++
		}
	}
return

CheckSharedFiles:
	runwait,%comspec% /c %A_ScriptDir%\lib\psfile.exe > files.txt, %Settings_Path%\logging,hide,	
	tempFileList=
	Loop,Read,%Settings_Path%\logging\files.txt 
	{
		if A_LoopReadLine contains %Extensions%
		{
			ts := SubStr(A_LoopReadLine, 13)
			If tempFileList not contains %ts% 
				tempFileList = %ts%`r`n%tempFileList%
		}
	}

	Sort, tempFileList, U
	filelist=%tempFileList%
	temp_file:=0
	Loop, parse, filelist, `n, `r  ; Specifying `n prior to `r allows both Windows and Unix files to be parsed.
	{
		ifInstring, A_LoopField, .
		{
			running++
			temp_file++
		}
	}
	sharedFiles=%temp_file%
return

CheckSchedules:
	scheduleBlockers:=0
	FormatTime, cur_hour,,HH
	cur_hour := cur_hour * 1
	if (cur_hour=0)
		cur_hour=24
	if (ScheduledOn%cur_hour% = 1) {
		scheduleBlockers++
		running++
	}
return

CheckScripts:
	if (ScriptsEnabled = 1) {
		runwait,%comspec% /c %Script1% > script1.txt,%Settings_Path%\logging,hide,
		FileRead, Script1Output, %Settings_Path%\logging\script1.txt
		if not ErrorLevel 
		{
			if (Script1Output != "") {
				running++
			}
		}
	}
return

EditScript()
{
	Edit
	return
}

Reload() 
{
	Suspend, Permit
	Reload
	return
}

Exit()
{
	DllCall("SetThreadExecutionState","UInt",ES_CONTINUOUS)
	ExitApp
	return
}

AHK_NOTIFYICON(wParam, lParam)
{
   if (lParam = 0x201 or lParam = 0x203) ; Click or double click
   {
      GoSub, DebugToggle
      Return 0
   }
}

; Disable ALT+F4
#IfWinActive Power ahk_class AutoHotkeyGUI
!F4::
#IfWinActive
;
#NoEnv
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
#KeyHistory 0
#SingleInstance force
ListLines Off
Process, Priority, , A
SetBatchLines, -1
SetKeyDelay, -1, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetWinDelay, -1
#Persistent
if not A_IsAdmin {
   Run *RunAs "%A_ScriptFullPath%"  ; Requires v1.0.92.01+
   ExitApp
}

ES_CONTINUOUS :=0x80000000
ES_SYSTEM_REQUIRED :=0x00000001
ES_DISPLAY_REQUIRED := 0x00000002
;ES_AWAYMODE_REQUIRED:=0x00000040 ; Don't use awaymode
; Tell the OS to prevent automatic sleep until we say otherwise
DllCall("SetThreadExecutionState","UInt", ES_SYSTEM_REQUIRED | ES_CONTINUOUS)
SetWorkingDir %A_ScriptDir% 
Settings_Path = %A_ScriptDir% 
FileCreateDir, %Settings_Path%\logging
IdlePercent := 0
ScheduledOn:=0
IdleRound:=0
OnMessage(0x404, "AHK_NOTIFYICON") ; WM_USER + 4

; Sleep Settings
IniRead, Delay, %Settings_Path%\power.ini, Sleep, Delay, 000010
if (Delay < 0)
	Delay=000010
IniWrite, %Delay%, %Settings_Path%\power.ini, Sleep, Delay
IniRead, SharedFiles, %Settings_Path%\power.ini, Sleep, SharedFiles, 1
IniWrite, %SharedFiles%, %Settings_Path%\power.ini, Sleep, SharedFiles

IniRead, Processes, %Settings_Path%\power.ini, Sleep, Processes, postprocess.exe,comskip.exe,ffmpeg.exe
IniWrite, %Processes%, %Settings_Path%\power.ini, Sleep, Processes

IniRead, IgnoreProcesses, %Settings_Path%\power.ini, Sleep, IgnoreProcesses, EmbyServer.exe
IniWrite, %IgnoreProcesses%, %Settings_Path%\power.ini, Sleep, IgnoreProcesses

IniRead, AONProcesses, %Settings_Path%\power.ini, Sleep, AONProcesses, teracopy.exe
IniWrite, %AONProcesses%, %Settings_Path%\power.ini, Sleep, AONProcesses

IniRead, Extensions, %Settings_Path%\power.ini, Sleep, Extensions, .mkv,.avi,.wtv,.exe,.iso,.mp4,.wtv,.ts
IniWrite, %Extensions%, %Settings_Path%\power.ini, Sleep, Extensions

IniRead, WHS_Backup, %Settings_Path%\power.ini, Sleep, WHS_Backup, 1
IniWrite, %WHS_Backup%, %Settings_Path%\power.ini, Sleep, WHS_Backup

IniRead, PCFG_Process, %Settings_Path%\power.ini, Sleep, PCFG_Process, 1
IniWrite, %PCFG_Process%, %Settings_Path%\power.ini, Sleep, PCFG_Process

IniRead, PCFG_Service, %Settings_Path%\power.ini, Sleep, PCFG_Service, 0
IniWrite, %PCFG_Service%, %Settings_Path%\power.ini, Sleep, PCFG_Service

IniRead, PCFG_Driver, %Settings_Path%\power.ini, Sleep, PCFG_Driver, 0
IniWrite, %PCFG_Driver%, %Settings_Path%\power.ini, Sleep, PCFG_Driver

; Schedule
Loop, 24
{
	IniRead, ScheduledOn%A_Index%, %Settings_Path%\power.ini, Schedule, ScheduledOn%A_Index%, 0
	IniWrite, % ScheduledOn%A_Index%, %Settings_Path%\power.ini, Schedule, ScheduledOn%A_Index%	
	IniRead, ForcedSleep%A_Index%, %Settings_Path%\power.ini, Schedule, ForcedSleep%A_Index%, 0
	IniWrite, % ForcedSleep%A_Index%, %Settings_Path%\power.ini, Schedule, ForcedSleep%A_Index%
}

; Always On
IniRead, aonshare, %Settings_Path%\power.ini, Always ON, aonshare, 1
IniWrite, %aonshare%, %Settings_Path%\power.ini, Always ON, aonshare

;Gui settings
IniRead, debugMode, %A_ScriptDir%\power.ini, Display, debugMode, 0
IniWrite, %debugMode%, %A_ScriptDir%\power.ini, Display, debugMode
IniRead, RefreshInt, %Settings_Path%\power.ini, GUI, RefreshInt, 60000
IniWrite, %RefreshInt%, %Settings_Path%\power.ini, GUI, RefreshInt

IniRead, xPos, %Settings_Path%\power.ini, GUI, XPos, 145
IniRead, yPos, %Settings_Path%\power.ini, GUI, YPos, 100
IniWrite, %xPos%, %Settings_Path%\power.ini, GUI, XPos
IniWrite, %yPos%, %Settings_Path%\power.ini, GUI, YPos

; Video Watching idle settings
IniRead, VPIdle, %Settings_Path%\power.ini, Video, VPIdle, 1
IniWrite, %VPIdle%, %Settings_Path%\power.ini, Video, VPIdle
IniRead, WMCProcesses, %Settings_Path%\power.ini, Video, WMCProcesses, ehshell.exe,kodi.exe
IniWrite, %WMCProcesses%, %Settings_Path%\power.ini, Video, WMCProcesses
IniRead, WMCIdle, %Settings_Path%\power.ini, Video, WMCIdle, 000200
if (WMCIdle < 0)
	WMCIdle=000200
IniWrite, %WMCIdle%, %Settings_Path%\power.ini, Video, WMCIdle
VPI = No

; Display variables
FormatTime, last_refresh,,MM/dd HH:mm
plist=
proc_req = No
psfile:= 0
schedule = No
WHS = No
MB = No
FormatTime, cur_hour,,HH
filelist=
proc_block=No
proc_block_aon=No
last_log=
Max_Width=%A_ScreenWidth%
Max_Height=%A_ScreenHeight%
requests=

; Tray Menu
GoSub, TrayMenu 
; TODO: Move to function
StringMid ,DelayD, Delay,1, 2
StringMid ,DelayH, Delay,3, 2
StringMid ,Delaym, Delay,5, 2
Delaysec := (DelayD*86400)+(DelayH*3600)+(Delaym*60)

StringMid ,WMCIdleD, WMCIdle,1, 2
StringMid ,WMCIdleH, WMCIdle,3, 2
StringMid ,WMCIdlem, WMCIdle,5, 2
WMCDelay := (WMCIdleD*86400)+(WMCIdleH*3600)+(WMCIdlem*60)

StartTime = %A_Now%
EndTime = %A_Now%
EnvAdd EndTime, Delaysec, seconds
EnvSub StartTime, EndTime, seconds

StartTime := Abs(StartTime)
GoSub, StatusCheck
SetTimer, StatusCheck, %RefreshInt%

FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm
FileAppend, %timestart% - Application Started`r`n, %Settings_Path%\logging\power.log
return

StatusCheck:
	runwait,%comspec% /c powercfg -requests > requests.txt,%Settings_Path%\logging,hide,
	runwait,%comspec% /c %A_ScriptDir%\bin\psfile.exe > files.txt,%Settings_Path%\logging,hide,
	FileRead, requests_raw, %Settings_Path%\logging\requests.txt

	; Any process requesting the system is allowed.  Exclude for this application
	running := 0
	plist=
	requests_temp=
	proc_req = No
	Loop, read, %Settings_Path%\logging\requests.txt
	{
		IfInString, A_LoopReadLine, [PROCESS]
		{
			If (PCFG_Process = 1)
			{			
				if (!A_iscompiled)
				{
					IfNotInstring, A_LoopReadLine, autohotkey.exe
					{
						StringSplit, Array, A_LoopReadLine,\,
						LastItem:=Array%Array0%
						IfNotInstring, requests_temp, %LastItem% 
						{
							If IgnoreProcesses not contains %LastItem% 
							{
								running++
								requests_temp=[POWERCFG] %LastItem%`r`n%requests_temp%
								proc_req = Yes
								plist = %plist% %LastItem%
							}
						}
					}
				} else {
					IfNotInstring, A_LoopReadLine, Power.exe
					{
						StringSplit, Array, A_LoopReadLine,\,
						LastItem:=Array%Array0%
						IfNotInstring, requests_temp, %LastItem% 
						{
							If IgnoreProcesses not contains %LastItem% 
							{
								running++
								requests_temp=[POWERCFG] %LastItem%`r`n%requests_temp%
								proc_req = Yes
								plist = %plist% %LastItem%
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
				If requests_temp not contains %A_LoopReadLine% 
				{
					running++
					requests_temp=%A_LoopReadLine%`r`n%requests_temp%
					proc_req = Yes
				}
			}
		}
		IfInString, A_LoopReadLine, [DRIVER]
		{
			If (PCFG_Driver = 1)
			{
				If requests_temp not contains %A_LoopReadLine% 
				{
					running++
					requests_temp=%A_LoopReadLine%`r`n%requests_temp%
					proc_req = Yes
				}
			}
		}
	}
	requests:=Trim(requests_temp)

	if (WHS_Backup = 1) 
	{
		IfInstring, requests_raw, WSS_ComputerBackupProviderSvc
		{
			running++
			WHS = Yes
		} else {
			WHS = No
		}
	} else {
		WHS = No
	}


	Lastline:=
	Loop, read, %Settings_Path%\logging\power.log
	{
		LastLine := A_LoopReadLine
	}
	last_log =  %LastLine%

	proc_block_aon=No
	Loop, parse, AONProcesses, `,
	{
		Process, Exist,  %A_LoopField%
		if (Errorlevel > 0) {
			proc_block_aon=Yes
			If plist not contains %A_LoopField% 
			{
				running++
				plist = %plist% %A_LoopField%
				requests =%requests%`r`n[ALWAYS ON] %A_LoopField%
			}
		}
	}

	proc_block=No
	Loop, parse, Processes, `,
	{
		Process, Exist,  %A_LoopField%
		if (Errorlevel > 0) {
			If plist not contains %A_LoopField% 
			{
				running++
				plist = %plist% %A_LoopField%
				requests =%requests%`r`n[PROCESS] %A_LoopField%
			}
			proc_block=Yes
		}
	}


	vpproc:=0
	VPI=No
	if (VPIdle = 1)
	{
		Loop, parse, WMCProcesses, `,
		{
			Process, Exist, %A_LoopField%
			if (Errorlevel > 0) {
				VPI=Yes
				vpproc++
				If plist not contains %A_LoopField% 
				{
					running++
					plist = %plist% %A_LoopField%
					requests =%requests%`r`n[MEDIA] %A_LoopField%
				}
			}
		}
	}


	tfilelist=
	Loop,Read,%Settings_Path%\logging\files.txt 
	{
		if A_LoopReadLine contains %Extensions%
		{
			ts := SubStr(A_LoopReadLine, 13)
			If tfilelist not contains %ts% 
				tfilelist = %ts%`r`n%tfilelist%
		}
	}

	Sort, tfilelist, U
	filelist=%tfilelist%
	temp_file:=0
	Loop, parse, filelist, `n, `r  ; Specifying `n prior to `r allows both Windows and Unix files to be parsed.
	{
		ifInstring, A_LoopField, .
		{
			running++
			temp_file++
		}
	}
	psfile=%temp_file%

	schedule= No
	FormatTime, cur_hour,,HH
	cur_hour := cur_hour * 1
	if (cur_hour=0)
		cur_hour=24
	if (ScheduledOn%cur_hour% = 1) {
		schedule=Yes
		running++
	}
	TimeIdle := floor(A_TimeIdle*1/1000)
	FormatTime, last_refresh,,MM/dd HH:mm
	;MsgBox, WMCDelay: %WMCDelay% WMCIdle %WMCIDleD%:%WMCIDleH%:%WMCIDlem% / %WMCIDle%
	;If always on processes are going, reset
	if (proc_block_aon = "Yes") {
		GoSub, Reset
		Menu, Tray, Icon, %A_ScriptDir%\icons\running.ico

	; If Media player idle is enabled and a media player is running	
	} else If ((vpproc > 0 ) && (VPIdle = 1) && (vpproc = running)){
		if (TimeIdle > (WMCDelay-Delaysec))
		{
			ScheduledOn:=1
			SetTimer, UpdateOSD, 1000
			SetTimer, TimerLoop, 1000
			Menu, Tray, Icon, %A_ScriptDir%\icons\sleep.ico
			DllCall("SetThreadExecutionState","UInt",ES_CONTINUOUS)
		} else {
			GoSub, Reset
			if (schedule = "Yes")
				Menu, Tray, Icon, %A_ScriptDir%\icons\running.ico
			else
				Menu, Tray, Icon, %A_ScriptDir%\icons\normal.ico
		}
	} else if (ForcedSleep%cur_hour% = 1 && (A_TimeIdle >= 10000)) {
		;MsgBox, %proc_block_aon%
		; If always on processes are going, don't sleep
		if (aonshare = 1 && temp_file > 0) {
			GoSub, Reset
			if (schedule = "Yes")
				Menu, Tray, Icon, %A_ScriptDir%\icons\running.ico
			else 
				Menu, Tray, Icon, %A_ScriptDir%\icons\normal.ico
		; Otherwise go to sleep
		} else {
			FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm 
			;FileAppend, %timestart% - Force Sleep Schedule `r`n, %Settings_Path%\logging\power.log
			ScheduledOn:=1
			SetTimer, UpdateOSD, 1000
			SetTimer, TimerLoop, 1000
			Menu, Tray, Icon, %A_ScriptDir%\icons\sleep.ico
			; Turn off system requested
			DllCall("SetThreadExecutionState","UInt",ES_CONTINUOUS)
		}
	; Normal hours, processes are running
	} else if ((running > 0) || (A_TimeIdle < 10000)) {
		GoSub, Reset
		if (schedule = "Yes")
			Menu, Tray, Icon, %A_ScriptDir%\icons\running.ico
		else
			Menu, Tray, Icon, %A_ScriptDir%\icons\normal.ico

	; Otherwise time to sleep		
	} else {
		ScheduledOn:=1
		SetTimer, UpdateOSD, 1000
		SetTimer, TimerLoop, 1000
		Menu, Tray, Icon, %A_ScriptDir%\icons\sleep.ico
		DllCall("SetThreadExecutionState","UInt",ES_CONTINUOUS)
	}
	Menu,Tray,Tip, Power: %running% blockers
	if (debugMode = 1) {
		ToolTip, Running: %running% / PCFG/PROC/AON: %proc_req%/%proc_block%/%proc_block_aon% Sharing: %psfile% Schedule: %schedule% Backup: %WHS% Video: %VPI%,0,0
	} else {
		ToolTip
	}
return

TimerLoop:
	if IdlePercent = 100
	{
		;MsgBox,0,Warning,Windows will now go to sleep,3
		GoSub, SLEEP
	}
return

SLEEP:
	FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm
	FileAppend, %timestart% - Sleep Activated`r`n, %Settings_Path%\logging\power.log
	if (VPIdle = 1)
	{
		Loop, parse, WMCProcesses, `,
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
	GoSub, Reset
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
	GoSub, Reset
return

UpdateOSD:
	mysec := EndTime
	EnvSub, mysec, %A_Now%, seconds
	var := FormatSeconds( mysec )
	IdlePercent := ((StartTime-mysec)/StartTime)*100
	IdlePercent := Floor(IdlePercent)
	if (IdlePercent > 100 || IdlePercent < 0) {
		return
	}
	If (ScheduledOn = 1 or var < 30) {
		if (IdleRound > 3 ) {
			; Change icon
		} else {
			IdleRound++
		}
	} else {
		IdleRound:= 0
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

Reset:
	SetTimer, UpdateOSD, off
	SetTimer, TimerLoop, off
	StringMid ,DelayD, Delay,1, 2
	StringMid ,DelayH, Delay,3, 2
	StringMid ,Delaym, Delay,5, 2
	Delaysec := (DelayD*86400)+(DelayH*3600)+(Delaym*60)

	StringMid ,WMCIdleD, WMCIdle,1, 2
	StringMid ,WMCIdleH, WMCIdle,3, 2
	StringMid ,WMCIdlem, WMCIdle,5, 2
	WMCDelay := (WMCIdleD*86400)+(WMCIdleH*3600)+(WMCIdlem*60)

	StartTime = %A_Now%
	EndTime = %A_Now%
	EnvAdd EndTime, Delaysec, seconds
	EnvSub StartTime, EndTime, seconds

	StartTime := Abs(StartTime)
	StartVideoTime := Abs(StartVideoTime)
	IdlePercent := 0 ;Resets percentage to 0, otherwise this loop never sees the counter reset
	ScheduledOn:=0
	IdleRound:=0
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
	if (debugMode = 1)
	{
		Menu,Tray,Check,Debug
	}
	Menu,Tray,Add
	Menu,Tray,Add,Reset,Reload
	if (!A_iscompiled)
		Menu,Tray,Add,Edit Script, EditScript

	Menu,Tray,Add, Exit, Exit
	Menu,Tray,Tip, Power: %running% blockers
	Menu,Tray, Icon, %A_ScriptDir%\icons\normal.ico,1
return

DebugToggle:
	if (debugMode = 1) {
		debugMode = 0
		Menu,Tray,Uncheck,Debug
	} else {
		debugMode = 1
		Menu,Tray,Check,Debug
	}
	IniWrite, %debugMode%, %A_ScriptDir%\power.ini, Display, debugMode
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
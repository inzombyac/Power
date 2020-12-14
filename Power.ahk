#NoEnv
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
#KeyHistory 0
#SingleInstance force
#Include %A_ScriptDir%\lib\emby.ahk
#Include %A_ScriptDir%\lib\traymenu.ahk
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

IniRead, Emby, %Settings_Path%\power.ini, Sleep, Emby, 1
IniWrite, %Emby%, %Settings_Path%\power.ini, Sleep, Emby
IniRead, Emby_URL, %Settings_Path%\power.ini, Sleep, Emby_URL, http://localhost:8096
IniWrite, %Emby_URL%, %Settings_Path%\power.ini, Sleep, Emby_URL
IniRead, Emby_API, %Settings_Path%\power.ini, Sleep, Emby_API, 
IniWrite, %Emby_API%, %Settings_Path%\power.ini, Sleep, Emby_API

IniRead, Processes, %Settings_Path%\power.ini, Sleep, Processes, postprocess.exe,comskip.exe,ffmpeg.exe
IniWrite, %Processes%, %Settings_Path%\power.ini, Sleep, Processes

IniRead, IgnoreProcesses, %Settings_Path%\power.ini, Sleep, IgnoreProcesses, MediaBrowser.ServerApplication.exe
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
IniRead, aonSAB, %Settings_Path%\power.ini, Always ON, aonSAB, 0
IniWrite, %aonSAB%, %Settings_Path%\power.ini, Always ON, aonSAB

;Gui settings
IniRead, Visible, %Settings_Path%\power.ini, GUI, Visible, 1
IniWrite, %Visible%, %Settings_Path%\power.ini, GUI, Visible
IniRead, RefreshInt, %Settings_Path%\power.ini, GUI, RefreshInt, 60000
IniWrite, %RefreshInt%, %Settings_Path%\power.ini, GUI, RefreshInt
IniRead, ShowTray, %Settings_Path%\power.ini, GUI, ShowTray, 1
IniWrite, %ShowTray%, %Settings_Path%\power.ini, GUI, ShowTray

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
psfile = 0 files
schedule = No
SAB = No
WHS = No
MB = No
EMBYREC = No
FormatTime, cur_hour,,HH
filelist=
proc_block=No
proc_block_aon=No
last_log=
Max_Width=%A_ScreenWidth%
Max_Height=%A_ScreenHeight%
requests=
Emby_Sessions=
Emby_Recordings=

; Tray Menu
BuildTrayMenu() 
GoSub, SETTINGS
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

if (Emby = 1) {
	EmbyStatus(Emby_URL, Emby_API, Settings_Path)
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

IfInstring, SAB_state, <state>Downloading</state>
{
	running++
	SAB = Yes
}
else
	SAB = No

; Emby server status
EmbySessions=
temp_MB=
Emby_Sessions=
Emby_Recordings= 
if (Emby = 1) {
	;GoSub, ExtractEmbyData
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
psfile=%temp_file% files

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
	Menu, Tray, Icon, running.ico

; If Media player idle is enabled and a media player is running	
} else If ((vpproc > 0 ) && (VPIdle = 1) && (vpproc = running)){
	if (TimeIdle > (WMCDelay-Delaysec))
	{
		ScheduledOn:=1
		SetTimer, UpdateOSD, 1000
		SetTimer, TimerLoop, 1000
		Menu, Tray, Icon, sleep.ico
		DllCall("SetThreadExecutionState","UInt",ES_CONTINUOUS)
	} else {
		GoSub, Reset
		if (schedule = "Yes")
			Menu, Tray, Icon, running.ico
		else
			Menu, Tray, Icon, normal.ico
	}
} else if (ForcedSleep%cur_hour% = 1 && (A_TimeIdle >= 10000)) {
	;MsgBox, %proc_block_aon%
	; If always on processes are going, don't sleep
	if (aonshare = 1 && temp_file > 0) {
		GoSub, Reset
		if (schedule = "Yes")
			Menu, Tray, Icon, running.ico
		else 
			Menu, Tray, Icon, normal.ico
	} else if ((aonSAB = 1) && (SAB = "Yes")) {
		GoSub, Reset
		if (schedule = "Yes")
			Menu, Tray, Icon, running.ico
		else 
			Menu, Tray, Icon, normal.ico
	; Otherwise go to sleep
	} else {
		FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm 
		;FileAppend, %timestart% - Force Sleep Schedule `r`n, %Settings_Path%\logging\power.log
		ScheduledOn:=1
		SetTimer, UpdateOSD, 1000
		SetTimer, TimerLoop, 1000
		Menu, Tray, Icon, sleep.ico
		; Turn off system requested
		DllCall("SetThreadExecutionState","UInt",ES_CONTINUOUS)
	}
; Normal hours, processes are running
} else if ((running > 0) || (A_TimeIdle < 10000)) {
	GoSub, Reset
	if (schedule = "Yes")
		Menu, Tray, Icon, running.ico
	else
		Menu, Tray, Icon, normal.ico

; Otherwise time to sleep		
} else {
	ScheduledOn:=1
	SetTimer, UpdateOSD, 1000
	SetTimer, TimerLoop, 1000
	Menu, Tray, Icon, sleep.ico
	DllCall("SetThreadExecutionState","UInt",ES_CONTINUOUS)
}
if (Visible = 1)
{
	GuiControl,, Update, Updated: %last_refresh%
	GuiControl,, plistT,%plist%
	GuiControl,, proc_reqT,%proc_req%
	GuiControl,, aonprocessT,%proc_block%/%proc_block_aon%
	GuiControl,, SABT,%SAB%
	GuiControl,, EmbySessionsT,%EmbySessions%
	GuiControl,, VPIT,%VPI%
	GuiControl,, WHST,%WHS%
	GuiControl,, EmbyRecordingsT,%EmbyRecordings%
	GuiControl,, psfileT,%psfile%
	GuiControl,, scheduleT,%schedule%
	GuiControl,, MyEdit,%requests%
	GuiControl,, FileListGUI,%filelist%
	GuiControl,, EmbyList,%Emby_Sessions%
	GuiControl,, EmbyRecList,%Emby_Recordings%
	GuiControl,, IdleStatus,Idle %TimeIdle% seconds
	GuiControl,, RunStatus,%running% blockers
	GuiControl,, LastEvent,%last_log%
	WinGetPos, xPos, yPos, winW, winH, Power
	IniWrite, %xPos%, %Settings_Path%\power.ini, GUI, XPos
	IniWrite, %yPos%, %Settings_Path%\power.ini, GUI, YPos
}
Menu,Tray,Tip, Power: %running% blockers

return

TimerLoop:
if IdlePercent = 100
{
	;MsgBox,0,Warning,Windows will now go to sleep,3
	if (Visible = 1)
	{
		WinGetPos, xPos, yPos, winW, winH, Power
		IniWrite, %xPos%, %Settings_Path%\power.ini, GUI, XPos
		IniWrite, %yPos%, %Settings_Path%\power.ini, GUI, YPos
	}
	GoSub, SLEEP
}
Return

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
	RunWait, sleep.exe
	Sleep, %RefreshInt%
	FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm
	FileAppend, %timestart% - Resumed`r`n, %Settings_Path%\logging\power.log
	MouseMove, 1 , 1,, R
	MouseMove, -1,-1,, R
	GoSub, Reset
Return

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
	TrayTip
	return
}
If (ScheduledOn = 1 or var < 30) {
	if (IdleRound > 3 ) {
		if (ShowTray = 1) {
			TrayTip, Power, Time Remaining: %var%, 30,2
			;FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm
			;FileAppend, %timestart% - Idle detected`r`n, %Settings_Path%\logging\power.log
		}
		;
	} else {
		IdleRound++
	}
} else {
	IdleRound:= 0
	;DllCall("SetThreadExecutionState","UInt", ES_SYSTEM_REQUIRED | ES_CONTINUOUS)
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
TrayTip
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

~LButton::
MouseGetPos,,, ID,,2
WinGetClass, Class, ahk_id %ID%
IfNotEqual, Class, tooltips_class32, Return
WinGet, style, style, ahk_id %ID% 
If ! ( style & 0x40 )
     Return
GoSub, Reset
Return

SETTINGS:
Gui, destroy
if (Visible =1) {
	;FileRead, requests, %Settings_Path%\logging\requests.txt
	Gui, +ToolWindow

	Gui, Add, Tab2,w580 h603 vmytab,Wake Status|Settings|Emby
	Gui, Font,,
	Gui, Font,Bold,
	Gui, Add, Text,section,Last Event: 
	Gui, Font,,
	Gui, Add, Text,xm+100 yp vLastEvent w400,%last_log%
	Gui, Font,,
	;Gui, Add, Text,xs,Processes: 
	;Gui, Add, Edit,w490 r1 +Readonly xm+80 yp-2 vplistT,%plist%
	;Gui, Font,,
	Gui, Add, Text,xs,PowerCfg Processes: 
	Gui, Font,,
	Gui, Add, Text,xm+180 yp vproc_reqT w50,%proc_req%
	Gui, Font,,
	Gui, Add, Text,xs,Custom/Always on Processes: 
	Gui, Font,,
	Gui, Add, Text,xm+180 yp vaonprocessT w50,%proc_block%/%proc_block_aon%
	Gui, Font,,
	Gui, Add, Text,xs,Shared Media: 
	Gui, Font,,
	Gui, Add, Text,xm+180 yp vpsfileT w50,%psfile%
	Gui, Font,,
	Gui, Add, Text,xs,Emby Sessions: 
	Gui, Font,,
	Gui, Add, Text,xm+180 yp vEmbySessionsT w150,%EmbySessions%
	Gui, Add, Text,xs,Emby Recordings: 
	Gui, Font,,
	Gui, Add, Text,xm+180 yp vEmbyRecordingsT w50,%EmbyRecordings%
	Gui, Font,Bold,
	Gui, Add, Text,xs yp+20,Process blocking: 
	Gui, Font,,
	Gui, Font,, Consolas
	Gui, Add, Edit, xs w560 r16 +Readonly -VScroll vMyEdit section, %requests%
	Gui, Font,,
	Gui, Font,Bold,
	Gui, Add, Text,xs,File Requests:
	Gui, Font,,
	Gui, Font,, Consolas
	Gui, Add, Edit, w560 r14 +Readonly -VScroll vFileListGUI section, %filelist%
	Gui, Font,,

	; Column 2
	Gui, Font,,
	Gui, Add, Text,section xp+360 ym+62,Schedule: 
	Gui, Font,,
	Gui, Add, Text, xp+150 yp vscheduleT w50,%schedule%
	Gui, Font,,
	Gui, Add, Text,xs,WHS backup on: 
	Gui, Font,,
	Gui, Add, Text,xp+150 yp vWHST w50,%WHS%
	Gui, Font,,
	Gui, Add, Text,xs,Media player processes: 
	Gui, Font,,
	Gui, Add, Text,xp+150 yp vVPIT w50,%VPI%
	Gui, Font,,

	Gui, Tab, 2
	Gui, Font,Bold,
	Gui, Add, Text,,Scheduling:
	Gui, Font,,
	Gui, Add, Text,,Always On Schedule:
	Gui, Add, Text,yp+43,Forced Sleep Schedule:
	Gui, Add, Text,,
	Gui, Font,Bold,
	Gui, Add, Text,,Keep Awake Monitoring Settings:
	Gui, Font,,
	Gui, Add, Text,section,powercfg /requests:
	Gui, Add, Text,,Idle before standby: 
	Gui, Add, Text,,Monitor shared files:
	Gui, Add, Text,,Extensions to monitor:
	Gui, Add, Text,,Processes:
	Gui, Add, Text,,Ignore processes:
	Gui, Add, Text,,Always on processes:
	Gui, Add, Text,,Monitor Emby playstate:
	Gui, Add, Text,,Emby URL:
	Gui, Add, Text,,Media Players:
	Gui, Add, Text,,Media idle before standby:
	Gui, Font,Bold,
	Gui, Add, Text,,Other:
	Gui, Font,,
	Gui, Add, Button, default xm+13 yp+30 gButtonSave, Save Settings
	Gui, Add, Button, default xm+150 yp gButtonLog, Wake Log

	;Gui, Add, Button, yp+30 gRESTARTMYSQL, Restart MySQL
		

	; Column 2
	;Gui, Add, Edit, vUpHours r1 w400 xm+150 ym+25, %UpHours%

	ab:= 1
	xx:= 150
	While ab < 13
	{
		if (ScheduledOn%ab%=1)
			Gui, Add, Checkbox, x%xx% ym+47 vScheduledOn%ab% checked, %ab%
		else 
			Gui, Add, Checkbox, x%xx% ym+47 vScheduledOn%ab%, %ab%
		ab++
		xx+=35
	}
	xx:= 150
	While ab < 25
	{
		if (ScheduledOn%ab%=1)
			Gui, Add, Checkbox, x%xx% ym+67 vScheduledOn%ab% checked, %ab%
		else 
			Gui, Add, Checkbox, x%xx% ym+67 vScheduledOn%ab%, %ab%
		ab++
		xx+=35
	}
	; Sleep Hours
	ab:= 1
	xx:= 150
	While ab < 13
	{
		if (ForcedSleep%ab%=1)
			Gui, Add, Checkbox, x%xx% ym+92 vForcedSleep%ab% checked, %ab%
		else 
			Gui, Add, Checkbox, x%xx% ym+92 vForcedSleep%ab%, %ab%
		ab++
		xx+=35
	}
	xx:= 150
	While ab < 25
	{
		if (ForcedSleep%ab%=1)
			Gui, Add, Checkbox, x%xx% ym+112 vForcedSleep%ab% checked, %ab%
		else 
			Gui, Add, Checkbox, x%xx% ym+112 vForcedSleep%ab%, %ab%
		ab++
		xx+=35
	}
	; Power Config Settings
	if (PCFG_Process=1)
		Gui, Add, Checkbox, xs+130 ys vPCFG_Process checked, Processes
	else 
		Gui, Add, Checkbox, xs+130 ys vPCFG_Process, Processes
	if (PCFG_Service=1)
		Gui, Add, Checkbox, xp+100 yp vPCFG_Service checked, Services
	else 
		Gui, Add, Checkbox, xp+100 yp vPCFG_Service, Services
	if (PCFG_Driver=1)
		Gui, Add, Checkbox, xp+100 yp vPCFG_Driver checked, Drivers
	else 
		Gui, Add, Checkbox, xp+100 yp vPCFG_Driver, Drivers
	if (WHS_Backup=1)
		Gui, Add, Checkbox, xp+100 yp vWHS_Backup checked, Backup Service (WHS)
	else 
		Gui, Add, Checkbox, xp+100 yp vWHS_Backup, Backup Service (WHS)

	; Idle
	Gui, Add, Edit, vDelay r1 w100 xs+130 yp+25, %Delay%
	Gui, Add, Text, yp+3 xs+255, (DDHHMM)              Refresh Interval (ms):
	Gui, Add, Edit, vRefreshInt r1 w100 xp+200 yp-2, %RefreshInt%

	if (SharedFiles=1)
		Gui, Add, Checkbox, xs+130 yp+28 vSharedFiles checked,
	else 
		Gui, Add, Checkbox, xs+130 yp+28 vSharedFiles, 	
	Gui, Add, Text,xs+330 yp,Always on when sharing:
	if (aonshare=1)
		Gui, Add, Checkbox, xm+470 yp+2 vaonshare checked,
	else 
		Gui, Add, Checkbox, xm+470 yp+2 vaonshare, 	
	Gui, Add, Edit, vExtensions r1 w425 xs+130 yp+20, %Extensions%
		
	Gui, Add, Edit, vProcesses r1 w425 yp+28 xs+130, %Processes%
	Gui, Add, Edit, vIgnoreProcesses r1 w425 yp+28, %IgnoreProcesses%
	Gui, Add, Edit, vAONProcesses r1 w425 yp+28, %AONProcesses%

	if (Emby=1)
		Gui, Add, Checkbox,xs+130 yp+28 vEmby checked,
	else 
		Gui, Add, Checkbox,xs+130 yp+28 vEmby, 

	Gui, Add, Edit, vEmby_URL r1 w180 yp+25 xs+130, %Emby_URL%
	Gui, Add, Text, xp+190 yp+3, API:
	Gui, Add, Edit, vEmby_API r1 w210 xp+25 yp-3, %Emby_API%

	Gui, Add, Edit, vWMCProcesses r1 w425 xs+130 yp+28, %WMCProcesses%
	Gui, Add, Edit, vWMCIdle r1 w100 xs+130 yp+26, %WMCIdle%
	Gui, Add, Text, yp+6 xs+255, (DDHHMM)                Monitor Video Idle:
	if (VPIdle=1)
		Gui, Add, Checkbox, xm+470 yp vVPIdle checked,
	else 
		Gui, Add, Checkbox, xm+470 yp vVPIdle, 

	if (ShowTray=1)
		Gui, Add, Checkbox, xs+130 yp+24 vShowTray checked, Enable Tray tip
	else 
		Gui, Add, Checkbox, xs+130 yp+24 vShowTray, Enable Tray tip

	Gui, Tab, 3
	Gui, Font,Bold,
	Gui, Add, Text,section,Emby Sessions:
	Gui, Font,,
	Gui, Font,, Consolas
	Gui, Add, Edit, xs w560 r20 +Readonly -VScroll vEmbyList section, %Emby_Sessions%
	Gui, Font,,
	Gui, Font,Bold,
	Gui, Add, Text,section,Emby Recordings:
	Gui, Font,,
	Gui, Font,, Consolas
	Gui, Add, Edit, xs w560 r19 +Readonly -VScroll vEmbyRecList section, %Emby_Recordings%
	Gui, Font,,
	;Close tab 
	Gui, Tab

	Gui, Add, Text, ym x200 w100 vIdleStatus, Idle %TimeIdle% seconds
	Gui, Add, Text, ym x325 w100 vRunStatus, %running% blocking
	Gui, Add, Text, ym x475 vUpdate, Updated: %last_refresh%
	;Gui, Add, Button, yp xm+475 w50 gKILL vKillBtn disabled, Restart

	if (xPos > 0 && yPos > 0)
		Gui, Show, x%xPos% y%yPos% h620 w600, Power
	else
		Gui, Show, x145 y100 h620 w600, Power
}
return

GuiClose:
WinGetPos, xPos, yPos, winW, winH, Power
IniWrite, %xPos%, %Settings_Path%\power.ini, GUI, XPos
IniWrite, %yPos%, %Settings_Path%\power.ini, GUI, YPos
Visible = 0
IniWrite, %Visible%, %Settings_Path%\power.ini, GUI, Visible
Gui, destroy
return

ButtonLog:
Run, %Settings_Path%\logging\power.log
return

ButtonSave:
WinGetPos, xPos, yPos, winW, winH, Power
IniWrite, %xPos%, %Settings_Path%\power.ini, GUI, XPos
IniWrite, %yPos%, %Settings_Path%\power.ini, GUI, YPos
Gui, Submit

IniWrite, %Delay%, %Settings_Path%\power.ini, Sleep, Delay
IniWrite, %SharedFiles%, %Settings_Path%\power.ini, Sleep, SharedFiles
IniWrite, %Emby%, %Settings_Path%\power.ini, Sleep, Emby
IniWrite, %Emby_URL%, %Settings_Path%\power.ini, Sleep, Emby_URL
IniWrite, %Emby_API%, %Settings_Path%\power.ini, Sleep, Emby_API
StringReplace, Processes, Processes, `,%A_Space%,`,,ALL
StringReplace, Processes, Processes, %A_Space%`,,`,,ALL
StringLower, Processes, Processes
IniWrite, %Processes%, %Settings_Path%\power.ini, Sleep, Processes
IniWrite, %IgnoreProcesses%, %Settings_Path%\power.ini, Sleep, IgnoreProcesses
IniWrite, %AONProcesses%, %Settings_Path%\power.ini, Sleep, AONProcesses
IniWrite, %Extensions%, %Settings_Path%\power.ini, Sleep, Extensions
;IniWrite, %UpHours%, %Settings_Path%\power.ini, Sleep, UpHours
;Gui settings
IniWrite, %RefreshInt%, %Settings_Path%\power.ini, GUI, RefreshInt
IniWrite, %ShowTray%, %Settings_Path%\power.ini, GUI, ShowTray
; Video Watching idle settings
IniWrite, %VPIdle%, %Settings_Path%\power.ini, Video, VPIdle
IniWrite, %WMCProcesses%, %Settings_Path%\power.ini, Video, WMCProcesses
IniWrite, %WMCIdle%, %Settings_Path%\power.ini, Video, WMCIdle
IniWrite, %WHS_Backup%, %Settings_Path%\power.ini, Sleep, WHS_Backup
IniWrite, %PCFG_Process%, %Settings_Path%\power.ini, Sleep, PCFG_Process
IniWrite, %PCFG_Service%, %Settings_Path%\power.ini, Sleep, PCFG_Service
IniWrite, %PCFG_Driver%, %Settings_Path%\power.ini, Sleep, PCFG_Driver

Loop, 24
{
	IniWrite, % ScheduledOn%A_Index%, %Settings_Path%\power.ini, Schedule, ScheduledOn%A_Index%
	IniWrite, % ForcedSleep%A_Index%, %Settings_Path%\power.ini, Schedule, ForcedSleep%A_Index%
}
IniWrite, %aonshare%, %Settings_Path%\power.ini, Always ON, aonshare
IniWrite, %aonSAB%, %Settings_Path%\power.ini, Always ON, aonSAB

temp_proc_parse=
Loop, parse, Processes, `,
{
	IfNotInstring, AONProcesses, %A_LoopField% 
		temp_proc_parse=%temp_proc_parse%,%A_LoopField% 
}
Processes := SubStr(temp_proc_parse, 2)
IniWrite, %Processes%, %Settings_Path%\power.ini, Sleep, Processes

GoSub, Reload
return

RELOAD: 
	Suspend, Permit
	Reload
return

AHK_NOTIFYICON(wParam, lParam)
{
   Global click

   If lParam = 0x201 ; WM_LBUTTONUP
   {
      click = 1
      SetTimer, clickcheck, -250
      Return 0
   }
   Else If lParam = 0x203 ; WM_LBUTTONDBLCLK   
   {
      click = 2
      Return 0
   }
}

clickcheck:
If (GetKeyState("Shift", "P") && click = 1)
{
   ;Msgbox Shift+1
}   
Else If (GetKeyState("Shift", "P") && click = 2)
{
   ;
}   
Else If click = 1
{
   if (Visible = 1){
	WinActivate, Power ahk_class AutoHotkeyGUI
   }
}
Else If click = 2
{
   GoSub, TOGGLE
}
return
;


TOGGLE:
;menu, Tray, ToggleCheck, Show GUI
if (Visible = 1) {
	Visible = 0
	WinGetPos, xPos, yPos, winW, winH, Power
	IniWrite, %xPos%, %Settings_Path%\power.ini, GUI, XPos
	IniWrite, %yPos%, %Settings_Path%\power.ini, GUI, YPos
}
else {
	Visible = 1
}
IniWrite, %Visible%, %Settings_Path%\power.ini, GUI, Visible
GoSub, SETTINGS
Return



Exit:
DllCall("SetThreadExecutionState","UInt",ES_CONTINUOUS)
ExitApp
Return

; Disable ALT+F4
#IfWinActive Power ahk_class AutoHotkeyGUI
!F4::
#IfWinActive

;
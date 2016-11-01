#SingleInstance force
#Persistent
if not A_IsAdmin {
   Run *RunAs "%A_ScriptFullPath%"  ; Requires v1.0.92.01+
   ExitApp
}

ES_CONTINUOUS:=0x80000000
ES_SYSTEM_REQUIRED:=0x00000001
ES_AWAYMODE_REQUIRED:=0x00000040
; Tell the OS to prevent automatic sleep
; Don't use awaymode
DllCall("SetThreadExecutionState","UInt",ES_CONTINUOUS | ES_SYSTEM_REQUIRED)

;DllCall( "SetThreadExecutionState", UInt,0x80000003 )
;  Need to run  Openfiles.exe /local on first to see files that are open
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
Settings_Path=%A_ScriptDir%
FileCreateDir, %Settings_Path%\logging
perc 	:= 0
;			DDHHMM
;Delay 	= 	000010
on:=0
round:=0
OnMessage(0x404, "AHK_NOTIFYICON") ; WM_USER + 4


; Sleep Settings
IniRead, Delay, %Settings_Path%\power.ini, Sleep, Delay, 000010
if (Delay < 0)
	Delay=000010
IniWrite, %Delay%, %Settings_Path%\power.ini, Sleep, Delay
IniRead, remote, %Settings_Path%\power.ini, Sleep, remote, 1
IniWrite, %remote%, %Settings_Path%\power.ini, Sleep, remote

IniRead, SABnzbd, %Settings_Path%\power.ini, Sleep, SABnzbd, 1
IniWrite, %SABnzbd%, %Settings_Path%\power.ini, Sleep, SABnzbd
IniRead, SABnzbd_URL, %Settings_Path%\power.ini, Sleep, SABnzbd_URL, http://localhost:8080
IniWrite, %SABnzbd_URL%, %Settings_Path%\power.ini, Sleep, SABnzbd_URL
IniRead, SABnzbd_API, %Settings_Path%\power.ini, Sleep, SABnzbd_API, 
IniWrite, %SABnzbd_API%, %Settings_Path%\power.ini, Sleep, SABnzbd_API

IniRead, Emby, %Settings_Path%\power.ini, Sleep, Emby, 1
IniWrite, %Emby%, %Settings_Path%\power.ini, Sleep, Emby
IniRead, Emby_URL, %Settings_Path%\power.ini, Sleep, Emby_URL, http://localhost:8096
IniWrite, %Emby_URL%, %Settings_Path%\power.ini, Sleep, Emby_URL
IniRead, Emby_API, %Settings_Path%\power.ini, Sleep, Emby_API, 
IniWrite, %Emby_API%, %Settings_Path%\power.ini, Sleep, Emby_API

IniRead, Processes, %Settings_Path%\power.ini, Sleep, Processes, php.exe,postprocess.exe,comskip.exe,teracopy.exe
IniWrite, %Processes%, %Settings_Path%\power.ini, Sleep, Processes

IniRead, AONProcesses, %Settings_Path%\power.ini, Sleep, AONProcesses, teracopy.exe
IniWrite, %AONProcesses%, %Settings_Path%\power.ini, Sleep, AONProcesses

IniRead, Extensions, %Settings_Path%\power.ini, Sleep, Extensions, .mkv,.avi,.wtv,.exe,.iso,.mp4,.wtv
IniWrite, %Extensions%, %Settings_Path%\power.ini, Sleep, Extensions

IniRead, WHS_Backup, %Settings_Path%\power.ini, Sleep, WHS_Backup, 1
IniWrite, %WHS_Backup%, %Settings_Path%\power.ini, Sleep, WHS_Backup

;IniRead, UpHours, %Settings_Path%\power.ini, Sleep, UpHours, 7,8,12,17,18,19,20,21,22
;IniWrite, %UpHours%, %Settings_Path%\power.ini, Sleep, UpHours

; Schedule
aa:= 1
While aa < 25
{
	IniRead, on%aa%, %Settings_Path%\power.ini, Schedule, on%aa%, 0
	IniWrite, % on%aa%, %Settings_Path%\power.ini, Schedule, on%aa%
	
	IniRead, sleep%aa%, %Settings_Path%\power.ini, Schedule, sleep%aa%, 0
	IniWrite, % sleep%aa%, %Settings_Path%\power.ini, Schedule, sleep%aa%
	aa++
}

; Always On
IniRead, aonshare, %Settings_Path%\power.ini, Always ON, aonshare, 1
IniWrite, %aonshare%, %Settings_Path%\power.ini, Always ON, aonshare
IniRead, aonSAB, %Settings_Path%\power.ini, Always ON, aonSAB, 0
IniWrite, %aonSAB%, %Settings_Path%\power.ini, Always ON, aonSAB

;Gui settings
IniRead, Visible, %Settings_Path%\power.ini, GUI, Visible, 1
IniWrite, %Visible%, %Settings_Path%\power.ini, GUI, Visible
IniRead, RefreshInt, %Settings_Path%\power.ini, GUI, RefreshInt, 15000
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
IniRead, WMCIdle, %Settings_Path%\power.ini, Video, WMCIdle, 000300
IniWrite, %WMCIdle%, %Settings_Path%\power.ini, Video, WMCIdle
VPI = No

; Add settings for these

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


; Tray Menu
GoSub, TRAYMENU

GoSub, SETTINGS
StringMid ,DelayD, Delay,1, 2
StringMid ,DelayH, Delay,3, 2
StringMid ,Delaym, Delay,5, 2
Delaysec := (DelayD*86400)+(DelayH*3600)+(Delaym*60)
StartTime = %A_Now%
EndTime = %A_Now%
EnvAdd EndTime, Delaysec, seconds
EnvSub StartTime, EndTime, seconds

; WMC Idle
StringMid ,WMCIdleD, WMCIdle,1, 2
StringMid ,WMCIdleH, WMCIdle,3, 2
StringMid ,WMCIdleM, WMCIdle,5, 2
WMCDelay := (WMCIdleD*86400)+(WMCIdleH*3600)+(WMCIdleM*60)
EnvAdd EndTime, WMCDelay, seconds

StartTime := Abs(StartTime)
GoSub, StatusCheck
SetTimer, StatusCheck, %RefreshInt%

FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm
FileAppend, %timestart% - Application Started`r`n, %Settings_Path%\logging\power.log
return

StatusCheck:
runwait,%comspec% /c powercfg -requests > requests.txt,%Settings_Path%\logging,hide,
runwait,%comspec% /c %A_ScriptDir%\bin\psfile.exe > files.txt,%Settings_Path%\logging,hide,
FileRead, requests, %Settings_Path%\logging\requests.txt

if (SABnzbd = 1) {
	UrlDownloadToFile, %SABnzbd_URL%/api?mode=qstatus&output=xml&apikey=%SABnzbd_API%, %Settings_Path%\logging\sab.xml
	FileRead, SAB_state, %Settings_Path%\logging\sab.xml
}

if (Emby = 1) {
	UrlDownloadToFile, %Emby_URL%/emby/emby/Sessions?api_key=%Emby_API%&format=json, %Settings_Path%\logging\emby.txt
	FileRead, Emby_state, %Settings_Path%\logging\emby.txt
	UrlDownloadToFile, %Emby_URL%/LiveTv/Recordings?api_key=%Emby_API%&format=json&IsInProgress=1, %Settings_Path%\logging\emby_rec.txt
	FileRead, Emby_rec_state, %Settings_Path%\logging\emby_rec.txt
}


Lastline:=
Loop, read, %Settings_Path%\logging\power.log
{
	LastLine := A_LoopReadLine
}
last_log =  %LastLine%

running := 0
plist=
proc_block=No
Loop, parse, Processes, `,
{
	Process, Exist,  %A_LoopField%
	if (Errorlevel > 0) {
		running++
		plist = %plist% %A_LoopField%
		proc_block=Yes
	}
}
proc_block_aon=No
Loop, parse, AONProcesses, `,
{
	Process, Exist,  %A_LoopField%
	if (Errorlevel > 0) {
		proc_block_aon=Yes
		plist = %plist% %A_LoopField%
		running++
	}
}
if (VPIdle =1) {
	Loop, parse, WMCProcesses, `,
	{
		Process, Exist,  %A_LoopField%
		if (Errorlevel > 0) {
			VPI=Yes
		} else {
			VPI=No
		}
		
	}
}

if (WHS_Backup = 1) 
{
	IfInstring, requests, WSS_ComputerBackupProviderSvc
	{
		running++
		WHS = Yes
	} else {
		WHS = No
	}
} else {
	WHS = No
}

IfInstring, SAB_state, <state>Downloading</state>
{
	running++
	SAB = Yes
}
else
	SAB = No

MB=No
temp_MB=
Loop, parse, Emby_state, `,
{
	IfInstring, A_LoopField, UserName
	{
		StringSplit, word_array, A_LoopField, :
		running++
		StringReplace, temp_temp_MB, word_array2,",, All 
		;"
		if (temp_MB != "")
			temp_MB=%temp_temp_MB%/%temp_MB%
		else
			temp_MB=%temp_temp_MB%
	}
}
if (temp_MB != "")
	MB=%temp_MB%

recordingcount:=0	
Loop, parse, Emby_rec_state, `,
{
	IfInstring, A_LoopField, TotalRecordCount
	{
		StringReplace, recordingcount, A_Loopfield,`},
		Loop, parse, recordingcount, :
		{
			recordingcount=%A_LoopField%
		}
		;MsgBox, %recordingcount%
	}
}
if (recordingcount != 0) 
{
	running++
	EMBYREC=Yes
} else {
	EMBYREC=No
}

	
tfilelist=
Loop,Read,%Settings_Path%\logging\files.txt 
{
	if A_LoopReadLine contains %Extensions%
	{
		if A_LoopReadLine not contains Scripts 
			tfilelist = %A_LoopReadLine%`r`n%tfilelist%
	}
}

; Any process requesting the system is allowed.  Exclude for this application
proc_req = No
Loop,Read,%Settings_Path%\logging\requests.txt 
{
	if A_LoopReadLine contains %Extensions%
	{
		if A_LoopReadLine contains A file has been opened across the network
		{
			StringReplace, temp, A_LoopReadLine, A file has been opened across the network. File name: ,,All
			StringReplace, temp, temp, [\,\\,All
			StringReplace, temp, temp,] Process ID: ,,All
			temp := RegExReplace(temp, "\[(.*)", "")
			tfilelist = %temp%`r`n%tfilelist%
		}
	}
	if A_LoopReadLine contains [PROCESS]
	{
		if (!A_iscompiled)
		{
			IfNotInstring, A_LoopReadLine, autohotkey.exe
			{
				running++
				proc_req = Yes
				StringSplit, Array, A_LoopReadLine,\,
				LastItem:=Array%Array0%
				plist = %plist% %LastItem%
			}
		} else {
			IfNotInstring, A_LoopReadLine, Power.exe
			{
				running++
				proc_req = Yes
				StringSplit, Array, A_LoopReadLine,\,
				LastItem:=Array%Array0%
				plist = %plist% %LastItem%
			}
		}
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
if (on%cur_hour% = 1) {
	schedule=Yes
	running++
}

if (VPIdle = 1) {
	vpproc:=0
	Loop, parse, WMCProcesses, `,
	{
		Process, Exist,  %A_LoopField%
		if (Errorlevel > 0 ) 
			vpproc++
	}
	if ((vpproc = 0 )&& (TimeIdle > WMCDelay)) 
	{
		MsgBox,0,Warning,Windows will now go to sleep,3
		GoSub, SLEEP	
	} else if (vpproc >0)
		running++
}
if (proc_block_aon = "Yes") {
	GoSub, Reset
	if (schedule = "Yes")
		Menu, Tray, Icon, running.ico
	else if (running > 0)
		Menu, Tray, Icon, normal.ico

} else if (sleep%cur_hour% = 1 && (A_TimeIdle >= 10000)) 
{
	;MsgBox, %proc_block_aon%
	if (aonshare = 1 && temp_file > 0) {
		GoSub, Reset
		if (schedule = "Yes")
			Menu, Tray, Icon, running.ico
		else if (running > 0)
			Menu, Tray, Icon, normal.ico
	} else if ((aonSAB = 1) && (SAB = "Yes")) {
		GoSub, Reset
		if (schedule = "Yes")
			Menu, Tray, Icon, running.ico
		else if (running > 0)
			Menu, Tray, Icon, normal.ico
	} else {
		FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm 
		;FileAppend, %timestart% - Force Sleep Schedule `r`n, %Settings_Path%\logging\power.log
		on:=1
		SetTimer, UpdateOSD, 1000
		SetTimer, TimerLoop, 1000
		Menu, Tray, Icon, sleep.ico
	}
} else if ((running > 0) || (A_TimeIdle < 10000)) {
	GoSub, Reset
	if (schedule = "Yes")
		Menu, Tray, Icon, running.ico
	else if (running > 0)
		Menu, Tray, Icon, normal.ico
	
} else {
	on:=1
	SetTimer, UpdateOSD, 1000
	SetTimer, TimerLoop, 1000
	Menu, Tray, Icon, sleep.ico
}
TimeIdle := floor(A_TimeIdle*1/1000)
FormatTime, last_refresh,,MM/dd HH:mm
if (Visible = 1)
{
	GuiControl,, Update, Updated: %last_refresh%
	GuiControl,, plistT,%plist%
	GuiControl,, proc_reqT,%proc_req%
	GuiControl,, aonprocessT,%proc_block%/%proc_block_aon%
	GuiControl,, SABT,%SAB%
	GuiControl,, MBT,%MB%
	GuiControl,, VPIT,%VPI%
	GuiControl,, WHST,%WHS%
	GuiControl,, EMBYRECT,%EMBYREC%
	GuiControl,, psfileT,%psfile%
	GuiControl,, scheduleT,%schedule%
	GuiControl,, MyEdit,%requests%
	GuiControl,, FileListGUI,%filelist%
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
if perc = 100
{
	MsgBox,0,Warning,Windows will now go to sleep,3
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
RunWait, sleep.exe
Sleep, %RefreshInt%
FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm
FileAppend, %timestart% - Resumed`r`n, %Settings_Path%\logging\power.log
GoSub, Reset
Return

UpdateOSD:
mysec := EndTime
EnvSub, mysec, %A_Now%, seconds
var := FormatSeconds( mysec )
perc := ((StartTime-mysec)/StartTime)*100
perc := Floor(perc)
if (perc > 100 || perc < 0) {
	TrayTip
	return
}
If (on = 1 or var < 30) {
	if (round > 3 ) {
		if (ShowTray = 1) {
			TrayTip, Power, Time Remaining: %var%, 30,2
		}
	} else {
		round++
	}
} else {
	round:= 0
}
Return

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
StartTime = %A_Now%
EndTime = %A_Now%
EnvAdd EndTime, Delaysec, seconds
EnvSub StartTime, EndTime, seconds
StartTime := Abs(StartTime)
perc := 0 ;Resets percentage to 0, otherwise this loop never sees the counter reset
on:=0
round:=0
var:=
If (VPI = "No") {
	MouseMove, 1 , 1,, R
	MouseMove, -1,-1,, R
}
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
FileRead, requests, %Settings_Path%\logging\requests.txt
Gui, destroy
If (Visible =1) {
	Gui, Add, Tab2,w580 h603 vmytab,Wake Status|Settings
	Gui, Font,,
	Gui, Font,Bold,
	Gui, Add, Text,section,Last Event: 
	Gui, Font,,
	Gui, Add, Text,xm+100 yp vLastEvent w400,%last_log%
	Gui, Font,,
	Gui, Add, Text,xs,Processes: 
	Gui, Add, Edit,w490 r1 +Readonly xm+80 yp-2 vplistT,%plist%
	Gui, Font,,
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
	Gui, Add, Text,xs,Emby sessions: 
	Gui, Font,,
	Gui, Add, Text,xm+180 yp vMBT w50,%MB%
	Gui, Add, Text,xs,Emby Recordings: 
	Gui, Font,,
	Gui, Add, Text,xm+180 yp vEMBYRECT w50,%EMBYREC%
	Gui, Font,Bold,
	Gui, Add, Text,xs yp+20,PowerCfg: 
	Gui, Font,,
	Gui, Font,, Consolas
	Gui, Add, Edit, xs w560 r16 +Readonly -VScroll vMyEdit section, %requests%
	Gui, Font,,
	Gui, Font,Bold,
	Gui, Add, Text,xs,File Requests:
	Gui, Font,,
	Gui, Font,, Consolas
	Gui, Add, Edit, w560 r7 +Readonly -VScroll vFileListGUI section, %filelist%
	Gui, Font,,
	
	; Column 2
	Gui, Font,,
	Gui, Add, Text,section xp+280 ym+72,Schedule: 
	Gui, Font,,
	Gui, Add, Text, xp+150 yp vscheduleT w50,%schedule%
	Gui, Font,,
	Gui, Add, Text,xs,WHS backup on: 
	Gui, Font,,
	Gui, Add, Text,xp+150 yp vWHST w50,%WHS%
	Gui, Font,,
	Gui, Add, Text,xs,SABnzbd downloading: 
	Gui, Font,,
	Gui, Add, Text,xp+150 yp vSABT w50,%SAB%
	Gui, Font,,
	Gui, Add, Text,xs,Video player on: 
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
	Gui, Add, Text,section,Monitor WHS Backups:
	Gui, Add, Text,,Idle Before Standby: 
	Gui, Add, Text,,Show Tray Tip:
	Gui, Add, Text,,Monitor Shared Files:
	Gui, Add, Text,,Extensions to Monitor:
	Gui, Add, Text,,Processes:
	Gui, Add, Text,,Always On Processes:
	Gui, Add, Text,,Monitor SABnzbd D/L's:
	Gui, Add, Text,,SABnzbd URL:
	Gui, Add, Text,,Monitor Emby Sessions:
	Gui, Add, Text,,Emby URL:
	Gui, Add, Text,,Video processes:
	Gui, Add, Text,,Video player on:
	Gui, Add, Button, default xm+13 yp+60 gButtonSave, Save Settings
	Gui, Add, Button, default xm+150 yp gButtonLog, Wake Log
	
	;Gui, Add, Button, yp+30 gRESTARTMYSQL, Restart MySQL
		
	
	; Column 2
	;Gui, Add, Edit, vUpHours r1 w400 xm+150 ym+25, %UpHours%
	
	ab:= 1
	xx:= 150
	While ab < 13
	{
		if (on%ab%=1)
			Gui, Add, Checkbox, x%xx% ym+47 von%ab% checked, %ab%
		else 
			Gui, Add, Checkbox, x%xx% ym+47 von%ab%, %ab%
		ab++
		xx+=35
	}
	xx:= 150
	While ab < 25
	{
		if (on%ab%=1)
			Gui, Add, Checkbox, x%xx% ym+67 von%ab% checked, %ab%
		else 
			Gui, Add, Checkbox, x%xx% ym+67 von%ab%, %ab%
		ab++
		xx+=35
	}
	; Sleep Hours
	ab:= 1
	xx:= 150
	While ab < 13
	{
		if (sleep%ab%=1)
			Gui, Add, Checkbox, x%xx% ym+92 vsleep%ab% checked, %ab%
		else 
			Gui, Add, Checkbox, x%xx% ym+92 vsleep%ab%, %ab%
		ab++
		xx+=35
	}
	xx:= 150
	While ab < 25
	{
		if (sleep%ab%=1)
			Gui, Add, Checkbox, x%xx% ym+112 vsleep%ab% checked, %ab%
		else 
			Gui, Add, Checkbox, x%xx% ym+112 vsleep%ab%, %ab%
		ab++
		xx+=35
	}
	if (WHS_Backup=1)
		Gui, Add, Checkbox,xs+130 ys vWHS_Backup checked,
	else 
		Gui, Add, Checkbox,xs+130 ys vWHS_Backup,
	Gui, Add, Edit, vDelay r1 w100 yp+25, %Delay%
	Gui, Add, Text, yp+3 xs+255, (DDHHMM)              Refresh Interval (s):
	Gui, Add, Edit, vRefreshInt r1 w100 xp+200 yp-2, %RefreshInt%
	
	if (ShowTray=1)
		Gui, Add, Checkbox, xs+130 yp+28 vShowTray checked,
	else 
		Gui, Add, Checkbox, xs+130 yp+28 vShowTray, 
	
	if (remote=1)
		Gui, Add, Checkbox, xs+130 yp+28 vremote checked,
	else 
		Gui, Add, Checkbox, xs+130 yp+28 vremote, 	
	Gui, Add, Text,xs+330 yp,Always on when sharing:
	if (aonshare=1)
		Gui, Add, Checkbox, xm+470 yp+2 vaonshare checked,
	else 
		Gui, Add, Checkbox, xm+470 yp+2 vaonshare, 	
	Gui, Add, Edit, vExtensions r1 w425 xs+130 yp+20, %Extensions%
		
	Gui, Add, Edit, vProcesses r1 w425 yp+28 xs+130, %Processes%
	Gui, Add, Edit, vAONProcesses r1 w425 yp+28, %AONProcesses%

	 
	if (SABnzbd=1)
		Gui, Add, Checkbox, yp+28 vSABnzbd checked,
	else 
		Gui, Add, Checkbox, yp+28 vSABnzbd, 
	Gui, Add, Text,xs+300 yp,Always on when downloading:
	if (aonSAB=1)
		Gui, Add, Checkbox, xm+470 yp+2 vaonSAB checked,
	else 
		Gui, Add, Checkbox, xm+470 yp+2 vaonSAB, 
	Gui, Add, Edit, vSABnzbd_URL r1 w180 yp+24 xs+130, %SABnzbd_URL%
	Gui, Add, Text, xp+190 yp+3, API:
	Gui, Add, Edit, vSABnzbd_API r1 w210 xp+25 yp-3, %SABnzbd_API%
	
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
	
	;Close tab 
	Gui, Tab
	Gui, Add, Text, ym x200 w100 vIdleStatus, Idle %TimeIdle% seconds
	Gui, Add, Text, ym x325 w100 vRunStatus, %running% blocking
	Gui, Add, Text, ym x475 vUpdate, Updated: %last_refresh%
	;Gui, Add, Button, yp xm+475 w50 gKILL vKillBtn disabled, Restart
	
	if (xPos > 0 && yPos > 0)
		Gui, Show, x%xPos% y%yPos% h620 w600, Power
	Else
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
IniWrite, %remote%, %Settings_Path%\power.ini, Sleep, remote
IniWrite, %SABnzbd%, %Settings_Path%\power.ini, Sleep, SABnzbd
IniWrite, %SABnzbd_URL%, %Settings_Path%\power.ini, Sleep, SABnzbd_URL
IniWrite, %SABnzbd_API%, %Settings_Path%\power.ini, Sleep, SABnzbd_API
IniWrite, %Emby%, %Settings_Path%\power.ini, Sleep, Emby
IniWrite, %Emby_URL%, %Settings_Path%\power.ini, Sleep, Emby_URL
IniWrite, %Emby_API%, %Settings_Path%\power.ini, Sleep, Emby_API
StringReplace, Processes, Processes, `,%A_Space%,`,,ALL
StringReplace, Processes, Processes, %A_Space%`,,`,,ALL
StringLower, Processes, Processes
IniWrite, %Processes%, %Settings_Path%\power.ini, Sleep, Processes
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


ac:= 1
While ac < 25
{
	IniWrite, % on%ac%, %Settings_Path%\power.ini, Schedule, on%ac%
	IniWrite, % sleep%ac%, %Settings_Path%\power.ini, Schedule, sleep%ac%
	ac++
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

GoSub, SETTINGS
return


TRAYMENU:
Suspend, Permit
Menu,Tray,NoStandard 
Menu,Tray,DeleteAll
Menu,Tray,Add, Sleep, SLEEP
;Menu,Tray, Add, Settings, SETTINGS
Menu,Tray,Add
Menu,Tray,Add,Reset,Reload
if (!A_iscompiled)
	Menu,Tray,Add,Edit This Script, EDIT

Menu,Tray,Add, Exit, Exit
Menu,Tray,Tip, Power: %running% blockers
Menu,Tray, Icon, normal.ico,1
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
   ;Msgbox 1
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
GoSub, SETTINGS
IniWrite, %Visible%, %Settings_Path%\power.ini, GUI, Visible
Return

; Reload option in tray
RELOAD:
Suspend, Permit
Reload
return

; Edit this script
EDIT:
Edit
return

Exit:
DllCall("SetThreadExecutionState","UInt",ES_CONTINUOUS)
ExitApp
Return
;
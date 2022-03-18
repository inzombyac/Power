#SingleInstance force
#Persistent
Process, Exist, Power.exe
PID = %ErrorLevel% 
if PID = 0
{
	if not A_IsAdmin {
	   Run *RunAs "%A_ScriptFullPath%"  ; Requires v1.0.92.01+
	   ExitApp
	}
	SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

	Run, %A_ScriptDir%\..\Power.exe
}
ExitApp
;

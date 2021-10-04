#SingleInstance force
#Persistent
if not A_IsAdmin {
   Run *RunAs "%A_ScriptFullPath%"  ; Requires v1.0.92.01+
   ExitApp
}
SetWorkingDir %A_ScriptDir%\..  ; Ensures a consistent starting directory.
Run, Power.exe
ExitApp
;

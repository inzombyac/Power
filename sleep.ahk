#SingleInstance force
#Persistent
time:=10

SetTimer, UpdateOSD, 1000
return

UpdateOSD:
if (time < 1 AND A_TimeIdle < 10000)
{
	ExitApp
} else if (time < 1) 
{
	;MsgBox,0,Warning,Windows will now go to sleep,3
	DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
	ExitApp
} else {
	TrayTip, Power, Going to sleep in %time% seconds, 10,2
	time-=1
}
return

ExitApp
;
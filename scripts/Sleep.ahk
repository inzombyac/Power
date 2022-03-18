#SingleInstance force
#Persistent
time:=10

TrayTip, Power, Going to sleep in %time% seconds, 5,18	
SetTimer, UpdateOSD, 1000
return

UpdateOSD:
if (time < 5 AND A_TimeIdle < 5000)
{
	ExitApp
} else if (time < 1) {
	DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
	ExitApp
} else if (time = 5) {
	TrayTip, Power, Going to sleep in %time% seconds, 5,18	
}
time-=1
return

ExitApp
;
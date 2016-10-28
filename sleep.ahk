DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
Sleep, 5000
;MsgBox,0,Warning,Windows will now go to sleep,3
ExitApp
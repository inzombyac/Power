; Functions related to the traymenu

BuildTrayMenu() 
{
	Suspend, Permit
	Menu,Tray,NoStandard 
	Menu,Tray,DeleteAll
	Menu,Tray,Add, Sleep, SLEEPNOW
	;Menu,Tray, Add, Settings, SETTINGS
	Menu,Tray,Add
	Menu,Tray,Add,Reset,Reload
	if (!A_iscompiled)
		Menu,Tray,Add,Edit Script, EditScript

	Menu,Tray,Add, Exit, Exit
	Menu,Tray,Tip, Power: %running% blockers
	Menu,Tray, Icon, normal.ico,1
	return
}


EditScript()
{
	Edit
	return
}

Exit()
{
	DllCall("SetThreadExecutionState","UInt",ES_CONTINUOUS)
	ExitApp
	return
}


;


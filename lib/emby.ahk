#Include %A_ScriptDir%\lib\JSON.ahk

EmbyStatus(Emby_URL, Emby_API, Settings_Path) 
{
	UrlDownloadToFile, %Emby_URL%/Sessions?api_key=%Emby_API%&format=json, %Settings_Path%\logging\emby.json
	FileRead, Emby_state, %Settings_Path%\logging\emby.json
	UrlDownloadToFile, %Emby_URL%/LiveTv/Timers?api_key=%Emby_API%&format=json, %Settings_Path%\logging\emby_rec.json
	FileRead, Emby_rec_state, %Settings_Path%\logging\emby_rec.json
	return
}

ExtractEmbyData(Emby_URL, Emby_API, Settings_Path, ByRef running) 
{
	url := Emby_URL "/Sessions?api_key=" Emby_API
	Result :=
	try
	{
		HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		HttpObj.Open("GET",url)
		HttpObj.Send()
		Result := HttpObj.ResponseText
	} catch e {
		FormatTime, timestart, A_Now, yyyy-MM-dd HH:mm
		FileAppend, %timestart% - Unable to contact Emby server`r`n, %Settings_Path%\logging\power.log
	}

	; Parse Emby State
	Loop, Parse, Result, `,
	{
		IfInString, A_LoopField, {"Playstate":
		{
			UserName:=
			NowPlayingItem :=
			Length:= 
			Position:= 
			State :=
		}
		IfInString, A_LoopField, "UserName"
		{
			Array := StrSplit(A_LoopField , ":")
			UserName:= Array[2]
			UserName := StrReplace(UserName,"""","")
			;MsgBox,  %A_LoopField% UserName: %UserName%
		}
		IfInString, A_LoopField, "NowPlayingItem"
		{
			Array := StrSplit(A_LoopField , ":")
			NowPlayingItem:= Array[3]
			NowPlayingItem := StrReplace(NowPlayingItem,"""","")
			;MsgBox,  %A_LoopField% UserName: %UserName% Now Playing: %NowPlayingItem%
		}
		IfInString, A_LoopField, "RunTimeTicks"
		{
			Array := StrSplit(A_LoopField , ":")
			Length:= Array[2]
			Length := StrReplace(Length,"""","")
			;MsgBox,  %A_LoopField% UserName: %UserName% Now Playing: %NowPlayingItem% Length: %Length%
		}
		IfInString, A_LoopField, "PositionTicks"
		{
			Array := StrSplit(A_LoopField , ":")
			Position:= Array[3]
			Position := StrReplace(Position,"""","")
			;MsgBox,  %A_LoopField% UserName: %UserName% Now Playing: %NowPlayingItem% Position: %Position%
		}
		If (UserName != "" && NowPlayingItem != "" && Position != "" && Length != "") 
		{
			running++		
			if (temp_MB = "")
				temp_MB=%UserName%
			else if temp_MB not contains %UserName%
				temp_MB=%temp_MB%, %UserName%	
			if (Length > 0 && Position > 0)
				State := floor((Position/Length)*100)
			if (State > 0)
				Emby_Sessions = %Emby_Sessions%%UserName%: `t%NowPlayingItem% (%State%`%)`r`n
			else if (NowPlayingItem != "")
				Emby_Sessions = %Emby_Sessions%%UserName%: `t%NowPlayingItem%`r`n
			else
				Emby_Sessions = %Emby_Sessions%%UserName%: :`r`n		
			;MsgBox,  %UserName% is watching: %NowPlayingItem% (%State%`%)
			UserName:=
			NowPlayingItem :=
			Length:= 
			Position:=
			State:=
			Continue
		}
	}
	MB=%temp_MB%

	recordingcount:=0	
	Loop, parse, Emby_rec_state, `,
	{
		IfInstring, A_LoopField, InProgress
		{
			StringReplace, recordingcount, A_Loopfield,`},
			Loop, parse, recordingcount, :
			{
				recordingcount=%A_LoopField%
			}
			;MsgBox, %recordingcount%
			; Set Emby_Recordings to something to show status
		}
	}
	if (recordingcount != 0) 
	{
		running++
		EMBYREC=Yes
	} else {
		EMBYREC=No
	}
	return
}
;
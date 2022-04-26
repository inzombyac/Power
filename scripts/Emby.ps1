$url = $args[0]
$key = $args[1]

$sessions = Invoke-RestMethod -Uri $url"/Sessions?api_key="$key"&format=json"
$microseconds = 10000000

foreach($session in $sessions) { 
	$playstate 		= $session.PlayState
	$username 		= $session.UserName
	
	if ($session.NowPlayingItem) {
		$runtime = [timespan]::fromseconds($session.NowPlayingItem.RunTimeTicks/$microseconds)
		$position = [timespan]::fromseconds($session.PlayState.PositionTicks/ $microseconds)
		$percent = 0
		if ($session.NowPlayingItem.RunTimeTicks) {
			$percent = $session.PlayState.PositionTicks/$session.NowPlayingItem.RunTimeTicks
		}

		Write-Host $session.UserName - $session.NowPlayingItem.name "(" ("{0:hh\:mm\:ss}" -f $position) $percent.tostring("P") ")"
	}

}
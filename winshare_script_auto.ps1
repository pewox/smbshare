$execute = Add-Content 'G:\powershell_skripte\scripte_automatisch\datei.txt' -Value (Get-Date) -Force
$tspan = (New-TimeSpan -minutes 1)
$action = New-ScheduledTaskAction -execute {$execute}
$trigger = New-ScheduledTaskTrigger -Once -At 13:25 -RepetitionInterval $tspan -RepetitionDuration (New-TimeSpan -days 1)
Register-ScheduledTask -Action $action -Trigger $trigger -taskname 'winshare' -force

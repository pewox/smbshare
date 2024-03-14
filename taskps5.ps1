# script for Cmk to readout win-shares from text-file for status-output
# created by Peter Wohlfarth

$action = New-ScheduledTaskAction -Execute 'powershell' '-ExecutionPolicy Bypass -File C:\PSScripte\WinShare\winsharecmk.ps1'
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek 1,2,3,4,5 -At 2am -RandomDelay 01:00:00
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -RunLevel Highest #-LogonType ServiceAccount  
Register-ScheduledTask -taskname weekly_bla -Action $action -Trigger $trigger -Principal $principal -AsJob -Force | Out-Null


# NT AUTHORITY\SYSTEM
# LOCALSERVICE

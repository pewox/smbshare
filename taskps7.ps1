# Autor: P.Wohlfarth

$action = New-ScheduledTaskAction -Execute 'pwsh' '-ExecutionPolicy Bypass -File C:\PSScripte\WinShare\winsharecmk.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At 5am
$principal = New-ScheduledTaskPrincipal -UserId "LOCALSERVICE" -LogonType ServiceAccount  -RunLevel Highest
Register-ScheduledTask -taskname winshare_cmk -Action $action -Trigger $trigger -Principal $principal -AsJob -Force | Out-Null

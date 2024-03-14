
$server_gesamt = "C:\ServError\task\server_gesamt.txt"
$task_run_ok = "C:\ServError\task\" + '{0}_task_run_ok.log' -f (Get-Date -Format 'yyyy_MM_dd-HH_mm_ss')
$task_run_fail = "C:\ServError\task\" + '{0}_task_run_fail.log' -f (Get-Date -Format 'yyyy_MM_dd-HH_mm_ss')
$task_register_fail = "C:\ServError\task\" + '{0}_task_register_fail.log' -f (Get-Date -Format 'yyyy_MM_dd-HH_mm_ss')
$task_abfrage_error = "C:\ServError\task\" + '{0}_task_abfrage_error.log' -f (Get-Date -Format 'yyyy_MM_dd-HH_mm_ss')
New-Item $task_run_ok, $task_run_fail, $task_abfrage_error, $server_gesamt, $task_register_fail -Force | Out-Null

$server_list = (Get-ADComputer -Filter {OperatingSystem -like '*Windows Server*' -and Enabled -eq 'True'}).Name
$server_count = $server_list.Count
Add-Content $server_gesamt -Value $server_count -Force

$ErrorActionPreference = 'Stop'
foreach($server in $server_list){
    try{
        $info = invoke-command -ComputerName $server -ScriptBlock {Get-ScheduledTask | Where-Object {$_.TaskName -eq 'winshare_cmk' -and $_.State -eq 'Ready'} | Get-ScheduledTaskInfo}
        if($null -ne $info){
            if($info.lastTaskResult -eq '0'){
            Add-Content $task_run_ok -Value ('{0} {1} ...Task Run OK lastRuntime={2} lastTaskResult={3}' -f (Get-Date), $server, $info.lastRuntime, $info.lastTaskResult)
            } else {Add-Content $task_run_fail -Value ('{0} {1} ...Task Run Fail lastRuntime={2} lastTaskResult={3}' -f (Get-Date), $server, $info.lastRuntime, $info.lastTaskResult)}
        } else {Add-Content $task_register_fail -Value ('{0} {1} ...Task Register Fail' -f (Get-Date), $server)}
    } catch {Add-Content $task_abfrage_error -Value ('{0} {1} ... {2}' -f (Get-Date), $server, $_)}
}

# (Get-ComputerInfo).OsLastBootUpTime

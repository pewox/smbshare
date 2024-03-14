$last_boot = "C:\ServError\boot\last_boot.log"
$last_boot_err = "C:\ServError\boot\last_boot_err.log"
New-Item $last_boot, $last_boot_err -Force | Out-Null
$server_list = (Get-ADComputer -Filter {OperatingSystem -like '*Windows Server*' -and Enabled -eq 'True'}).Name

$ErrorActionPreference = 'Stop'
foreach ($server in $server_list){
    try {
        $info = invoke-command -ComputerName $server -ScriptBlock{(Get-ComputerInfo).OsLastBootUpTime}
        Add-Content $last_boot -Value ('{0} ...last boot {1}' -f $server, $info)
    } catch {add-content $last_boot_err -value ('{0} {1} ..err {2}' -f (Get-Date), $server, $_)}
}

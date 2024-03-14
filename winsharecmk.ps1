# script for lokal machine to readout win-shares in background
# created by Peter Wohlfarth

Import-Module SmbShare
$date_vor = get-date
$include = 'Jeder', 'Everyone', 'VORDEFINIERT\Benutzer', 'BUILTIN\Users','VORDEFINIERT\Users', $($env:USERDOMAIN + '\gast'), $($env:USERDOMAIN + '\guest')
$benutzer = 'VORDEFINIERT\Benutzer', 'BUILTIN\Users', 'VORDEFINIERT\Users'
$path = 'C:\PSScripte\WinShare\win_share_ntfs.txt'
$temp = 'C:\PSScripte\WinShare\temp.txt'                           
$zeit = 'C:\PSScripte\WinShare\zeit_share_auslesen.txt'
$error_path = 'C:\PSScripte\WinShare\error.log'

$ErrorActionPreference = 'Stop'
try {
    New-Item -Path $path, $zeit, $temp, $error_path -Force | Out-Null

    $shares = get-smbshare | Where-Object {$_.Sharetype -eq 'FileSystemDirectory' -and $_.Special -ne 'True'} | Where-Object Name -ne 'print$'
    # Objekt für alle Freigabeberechtigungen anlegen; ID aus Sharename und Benutzerkontoname für Vergleiche bilden
    if($null -ne $shares){
        $share_obj = ($shares | get-smbshareaccess) | Where-Object({$_.AccessControlType -eq 'Allow' -and $_.AccountName -in $include}) | ForEach-Object{
            $t1 = if($_.AccountName -eq 'Everyone'){'Jeder'}
                elseif($_.AccountName -in $benutzer){'Benutzer'}
                elseif ($_.AccountName -eq $($env:USERDOMAIN + '\guest')) {$($env:USERDOMAIN + '\gast')}
                else{$_.AccountName}
            [PSCustomObject]@{
                Server = $env:COMPUTERNAME         
                Share = $_.Name
                Account = $t1
                Share_Right = $_.AccessRight
                ID = $_.Name + ':' + $t1
            }
        }
    }
} catch {Add-Content $error_path -Value ('{0} {1} {2} ...Get-SmbShare' -f (Get-Date), $env:COMPUTERNAME, $_) -Force}

    # Objekt für alle NTFS-Berechtigungen anlegen; ID aus Sharename und Benutzerkontoname für Vergleiche bilden
try{
    if($null -ne $shares) {
        $ntfs_obj = foreach($share in $shares){($share | Get-Acl).Access | where-Object ({$_.IdentityReference -in $include}) | ForEach-Object {
            if($_.filesystemrights -match '268435456' -or $_.filesystemrights -match 'FullControl'){$f_right = 'Full'}
            else{$f_right = $_.filesystemrights}
            $t2 = if($_.IdentityReference -eq 'Everyone'){'Jeder'}
            elseif($_.IdentityReference -in $benutzer){'Benutzer'}
            elseif($_.IdentityReference -eq $($env:USERDOMAIN + '\guest')) {$($env:USERDOMAIN + '\gast')}
            else{$_.IdentityReference}
            [PSCustomObject]@{
                Server = $env:COMPUTERNAME
                Share = $share.Name
                Account = $t2
                NTFS_Right = $f_right
                ID = $share.Name + ':' + $t2
                }
            }
        }
    }
} catch {Add-Content $error_path -Value ('{0} {1} {2} ...Get-Acl' -f (Get-Date), $env:COMPUTERNAME, $_) -Force}
function line {
    param($status)
    $__ = ($ntfs_obj | Select-Object ID, NTFS_Right | Where-Object ID -eq $val.ID).NTFS_Right
    $ntfs_r = if($null -ne $__){$__} else {'not defined'}
    Add-Content -Path $temp -Value ('{0} "Share {1}" - Account={2}; ShareRight={3}; NTFSRight={4}' -f $status, $val.Share, $val.Account, $val.Share_Right, $ntfs_r) -Force
}
try{
    if($null -ne $shares) {
        foreach($val in $share_obj){
            # prüfen effektive Berechtigung Jeder:Full; Status=2
            if($val.Account -eq 'Jeder'){
                line(2)
            }
            # prüfen Berechtigung Benutzer
	        elseif($val.Account -eq 'Benutzer'){
		        line(1)
            }
            # prüfen Berechtigung Gast
            elseif($val.Account -eq $($env:USERDOMAIN + '\gast')){
                line(1)
            }	
        }
    }
} catch {Add-Content $error_path -Value ('{0} {1} {2} ...Add-Content $temp' -f (Get-Date), $env:COMPUTERNAME, $_) -Force}

    $zeitaufwand = 'Zeitaufwand Freigaben auslesen: {0:N1} min' -f ((Get-Date) - $date_vor).TotalMinutes

try {
    Set-Content $zeit -Value ('{0}; {1}' -f $zeitaufwand, (Get-Date)) -Force
    Set-Content $path -Value (Get-Content $temp -Force) -Force
} catch {Add-Content $error_path -Value ('{0} {1} {2} ...Set-Content $zeit, $path' -f (Get-Date), $env:COMPUTERNAME, $_) -Force}

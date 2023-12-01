$change = '-536805376', 'modify', 'Write', 'Change'
$full = '268435456', 'FullControl', 'Full'
$read = '-1610612736', 'ReadAndExecute', 'Read'
$exclude = 'VORDEFINIERT\Administratoren', 'NT-AUTORITÄT\SYSTEM', 'NT-AUTORITÄT\Authentifizierte Benutzer', 'NT SERVICE\TrustedInstaller', 'ERSTELLER-BESITZER',
'NT AUTHORITY\SYSTEM', 'BUILTIN\Administrators', 'CREATOR OWNER'
$alle = 'Jeder', 'Everyone', $($env:USERDOMAIN + '\Users'), $($env:USERDOMAIN + '\Benutzer'), $($env:USERDOMAIN + '\gast'), $($env:USERDOMAIN + '\guest') , 'VORDEFINIERT\Benutzer', 'BUILTIN\Users'

$path = '.\out.txt'  # Ausgabedatei
New-Item -Path $path -Force | Out-Null
$winserver = (Get-ADComputer -Filter {OperatingSystem -like '*Windows Server*' -and Enabled -eq 'True'}).Name # alle Windows Server auslesen

foreach($server in $winserver){
    $shares = (Get-SmbShare -CimSession $server -Special $false).where({$_.Name -notin $exclude})
    # Objekt für Freigabeberechtigungen anlegen; ID aus Sharename und Benutzerkontoname für Vergleiche bilden
    $share_obj = ($shares | get-smbshareaccess -CimSession $server).Where({$_.AccessControlType -eq 'Allow' -and $_.AccountName -in $alle -and $_.AccountName -notin $exclude}).ForEach{
            $t1 = if($_.AccountName -eq 'Everyone'){'Jeder'}
            elseif($_.AccountName -eq $($env:USERDOMAIN + '\Users')){$($env:USERDOMAIN + '\Benutzer')}
            elseif ($_.AccountName -eq $($env:USERDOMAIN + '\guest')) {$($env:USERDOMAIN + '\gast')}
            else{$_.AccountName}
            [PSCustomObject]@{
            Server = $server
            Share = $_.Name
            Account = $t1
            Share_Right = $_.AccessRight
            ID = $_.Name + ':' + $t1
        }
    }
    # Objekt für NTFS-Berechtigungen anlegen; ID aus Sharename und Benutzerkontoname für Vergleiche bilden
    $ntfs_obj = foreach($share in $shares){
        $share_path = $share.Path
        (Invoke-Command -ComputerName $server -ScriptBlock{Get-Acl -Path $using:share_path}).Access.where({$_.IdentityReference -notin $exclude -and $_.IdentityReference -in $alle}).foreach{
        $t2 = if($_.IdentityReference -eq 'Everyone'){'Jeder'}
        elseif($_.IdentityReference -eq $($env:USERDOMAIN + '\Users')){$($env:USERDOMAIN + '\Benutzer')}
        elseif($_.IdentityReference -eq $($env:USERDOMAIN + '\guest')) {$($env:USERDOMAIN + '\gast')}
        else{$_.IdentityReference}
        [PSCustomObject]@{
        Server = $server
        Share = $share.Name
        Account = $t2
        NTFS_Right = $_.filesystemrights    
        ID = $share.Name + ':' + $t2
            }
        }
    } 
    # Accounts nach Freigabeberechtigungen Full, Change, Read sortieren
    $full_share_j = $share_obj.Where({$_.Share_Right -in $full })
    $change_share_j = $share_obj.Where({$_.Share_Right -in $change})
    $read_share_j = $share_obj.Where({$_.Share_Right -in $read })

    foreach($val in $ntfs_obj){
        # prüfen Freigabe- und NTFS-Berechtigung ob effektiv Jeder:Full
        if($val.id -in $full_share_j.id -and $val.Account -eq 'Jeder' -and ($val.NTFS_Right -like '*Full*' -or $val.NTFS_Right -like '*268435456*')){
            Add-Content -Path $path -Value ('2 "{1}:Share={2}" {0} {3}' -f $val.id, $server, $val.Share, $val.NTFS_Right)
        } # prüfen Freigabe- und NTFS-Berechtigung ob effektiv Jeder:Read, Change; also kein Full
        elseif (($val.Account -eq 'Jeder' -and $val.id -in $change_share_j.id -or $val.id -in $read_share_j.id -or $val.id -in $full_share_j.id) -and ($val.NTFS_Right -notlike '*Full*' -or $val.NTFS_Right -notlike '*268435456*'))
        {Add-Content -Path $path -Value ('0 "{1}:Share={2}" {0} {3}' -f $val.id, $server, $val.Share, $val.NTFS_Right)}
        
        # prüfen Freigabe- und NTFS-Berechtigung ob effektiv Benutzer:Full
        elseif ($val.Account -eq $($env:USERDOMAIN + '\Benutzer') -and $val.id -in $full_share_j.id -and ($val.NTFS_Right -like '*Full*' -or $val.NTFS_Right -like '*268435456*')) {
            Add-Content -Path $path -Value ('2 "{1}:Share={2}" {0} {3}' -f $val.id, $server, $val.Share, $val.NTFS_Right)
        } # prüfen Freigabe- und NTFS-Berechtigung ob effektiv Benutzer:Change, Read; also kein Full
        elseif (($val.Account -eq $($env:USERDOMAIN + '\Benutzer') -and $val.id -in $change_share_j.id -or $val.id -in $read_share_j.id -or $val.id -in $full_share_j.id) -and ($val.NTFS_Right -notlike '*Full*' -or $val.NTFS_Right -notlike '*268435456*'))
        {Add-Content -Path $path -Value ('0 "{1}:Share={2}" {0} {3}' -f $val.id, $server, $val.Share, $val.NTFS_Right)}
    
        # prüfen Freigabe- und NTFS-Berechtigung ob effektiv Gast:Full
        elseif ($val.Account -eq $($env:USERDOMAIN + '\Gast') -and $val.id -in $full_share_j.id -and ($val.NTFS_Right -like '*Full*' -or $val.NTFS_Right -like '*268435456*')) {
            Add-Content -Path $path -Value ('2 "{1}:Share={2}" {0} {3}' -f $val.id, $server, $val.Share, $val.NTFS_Right)
        } # prüfen Freigabe- und NTFS-Berechtigung ob effektiv Gast:Change, Read; also kein Full
        elseif (($val.Account -eq $($env:USERDOMAIN + '\Gast') -and $val.id -in $change_share_j.id -or $val.id -in $read_share_j.id -or $val.id -in $full_share_j.id) -and ($val.NTFS_Right -notlike '*Full*' -or $val.NTFS_Right -notlike '*268435456*'))
        {Add-Content -Path $path -Value ('0 "{1}:Share={2}" {0} {3}' -f $val.id, $server, $val.Share, $val.NTFS_Right)}
    }   
}

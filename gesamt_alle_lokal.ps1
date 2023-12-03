
$exclude = 'VORDEFINIERT\Administratoren', 'NT-AUTORITÄT\SYSTEM', 'NT-AUTORITÄT\Authentifizierte Benutzer', 'NT SERVICE\TrustedInstaller', 'ERSTELLER-BESITZER',
'NT AUTHORITY\SYSTEM', 'BUILTIN\Administrators', 'CREATOR OWNER'
$include = 'Jeder', 'Everyone', $($env:USERDOMAIN + '\User'), $($env:USERDOMAIN + '\Benutzer'), $($env:USERDOMAIN + '\gast'), $($env:USERDOMAIN + '\guest'), 'BUILTIN\Users', $($env:USERDOMAIN + '\' + $env:USERNAME), 'VORDEFINIERT\Benutzer'

$path = '.\out1.txt'
New-Item -Path $path -Force | Out-Null

$shares = (Get-SmbShare -Special $false).where({$_.Name -notin $exclude})
# Objekt für alle Freigabeberechtigungen anlegen; ID aus Sharename und Benutzerkontoname für Vergleiche bilden
$share_obj = ($shares | get-smbshareaccess).Where({$_.AccessControlType -eq 'Allow' -and $_.AccountName -in $include -and $_.AccountName -notin $exclude}).ForEach{
    $t1 = if($_.AccountName -eq 'Everyone'){'Jeder'}
        elseif($_.AccountName -eq $($env:USERDOMAIN + '\User')){$($env:USERDOMAIN + '\Benutzer')}
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
# Objekt für alle NTFS-Berechtigungen anlegen; ID aus Sharename und Benutzerkontoname für Vergleiche bilden
$ntfs_obj = foreach($share in $shares){($share | Get-Acl).Access.where({$_.IdentityReference -notin $exclude -and $_.IdentityReference -in $include}).foreach{
    if($_.filesystemrights -match '268435456' -or $_.filesystemrights -match 'FullControl'){$f_right = 'Full'}
    elseif($_.filesystemrights -match '-536805376' -or $_.filesystemrights -match 'Modify' -or $_.filesystemrights -match 'Write'){$f_right = 'Change'}
    elseif($_.filesystemrights -match '-1610612736' -or ($_.filesystemrights -match 'Read' -and $_.filesystemrights -notmatch 'Write')){$f_right = 'Read'}
    $t2 = if($_.IdentityReference -eq 'Everyone'){'Jeder'}
    elseif($_.IdentityReference -eq $($env:USERDOMAIN + '\User')){$($env:USERDOMAIN + '\Benutzer')}
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
# Jeder-Accounts nach Freigabeberechtigungen Full, Change, Read sortieren
$full_share_j = $share_obj.Where({$_.Account -eq 'Jeder' -and $_.Share_Right -eq 'Full' })
$change_share_j = $share_obj.Where({$_.Account -eq 'Jeder' -and $_.Share_Right -eq 'Change'})
$read_share_j = $share_obj.Where({$_.Account -eq 'Jeder' -and $_.Share_Right -eq 'Read'})

# Benutzer(allgemein) nach Freigabeberechtigungen Full, Change, Read sortieren
$full_share_u = $share_obj.Where({$_.Account -eq 'VORDEFINIERT\Benutzer' -and $_.Share_Right -eq 'Full'})
$change_share_u = $share_obj.Where({$_.Account -eq 'VORDEFINIERT\Benutzer' -and $_.Share_Right -eq 'Change'})
$read_share_u = $share_obj.Where({$_.Account -eq 'VORDEFINIERT\Benutzer' -and $_.Share_Right -eq 'Read'})
    
# Gast nach Freigabeberechtigungen Full, Change, Read sortieren
$full_share_g = $share_obj.Where({$_.Account -eq $($env:USERDOMAIN + '\Gast') -and $_.Share_Right -eq 'Full'})
$change_share_g = $share_obj.Where({$_.Account -eq $($env:USERDOMAIN + '\Gast') -and $_.Share_Right -eq 'Change'})
$read_share_g = $share_obj.Where({$_.Account -eq $($env:USERDOMAIN + '\Gast') -and $_.Share_Right -eq 'Read'})

# Jeder-Accounts nach NTFS-Berechtigungen Full, Change, Read sortieren
$full_ntfs_j = $ntfs_obj.Where({$_.Account -eq 'Jeder' -and $_.NTFS_Right -eq 'Full'})
$change_ntfs_j = $ntfs_obj.Where({$_.Account -eq 'Jeder' -and $_.NTFS_Right -eq 'Change'})
$read_ntfs_j = $ntfs_obj.Where({$_.Account -eq 'Jeder' -and $_.NTFS_Right -eq 'Read'})

# Benutzer(allgemein)-Accounts nach NTFS-Berechtigungen Full, Change, Read sortieren
$full_ntfs_u = $ntfs_obj.Where({$_.Account -eq 'VORDEFINIERT\Benutzer' -and $_.NTFS_Right -eq 'Full'})
$change_ntfs_u = $ntfs_obj.Where({$_.Account -eq 'VORDEFINIERT\Benutzer' -and $_.NTFS_Right -eq 'Change'})
$read_ntfs_u = $ntfs_obj.Where({$_.Account -eq 'VORDEFINIERT\Benutzer' -and $_.NTFS_Right -eq 'Read'})
    
# Gast-Accounts nach NTFS-Berechtigungen Full, Change, Read sortieren
$full_ntfs_g = $ntfs_obj.Where({$_.Account -eq $($env:USERDOMAIN + '\Gast') -and $_.NTFS_Right -eq 'Full'})
$change_ntfs_g = $ntfs_obj.Where({$_.Account -eq $($env:USERDOMAIN + '\Gast') -and $_.NTFS_Right -eq 'Change'})
$read_ntfs_g = $ntfs_obj.Where({$_.Account -eq $($env:USERDOMAIN + '\Gast') -and $_.NTFS_Right -eq 'Read'})




foreach($val in $share_obj){
    # prüfen effektive Berechtigung Jeder:Full; Status=2
    if($val.Account -eq 'Jeder'){
        if(($val.ID -in $full_share_j.ID -and $val.ID -in $full_ntfs_j.ID)){
        Add-Content -Path $path -Value ('2 "{0}" - Share:{1} Account:{2} ShareRight:Full NTFSRight:Full' -f $env:COMPUTERNAME, $val.Share, $val.Account)}
         
        # prüfen effektive Berechtigung Jeder: Change oder Read; Status=0
        elseif(($val.ID -in $change_share_j.ID -and $val.ID -in $change_ntfs_j.ID) -or ($val.ID -in $read_share_j.ID -and $val.ID -in $read_ntfs_j.ID)){
        $__ = ($ntfs_obj | Select-Object ID, NTFS_Right | Where-Object ID -eq $val.ID).NTFS_Right
        $ntfs_r = if($null -ne $__){$__} else {'not defined'}
        Add-Content -Path $path -Value ('0 "{0}" - Share:{1} Account:{2} ShareRight:{3} NTFSRight:{4}' -f $env:COMPUTERNAME, $val.Share, $val.Account, $val.Share_Right, $ntfs_r)}
    }
    # prüfen effektive Berechtigung Benutzer:Full; Status=2
    elseif($val.Account -eq 'VORDEFINIERT\Benutzer'){
        if (($val.ID -in $full_share_u.id -and $val.ID -in $full_ntfs_u.id) -or ($val.id -in $full_share_j.id -and $val.ID -in $full_ntfs_j.ID)){
        Add-Content -Path $path -Value ('2 "{0}" - Share:{1} Account:{2} ShareRight:Full NTFSRight:Full' -f $env:COMPUTERNAME, $val.Share, $val.Account)
        }
        # prüfen effektive Berechtigung Benutzer: Change oder Read; Status=0
        elseif ((($val.ID -in $change_share_u.id -and $val.ID -in $change_ntfs_u.id) -or ($val.ID -in $read_share_u.ID -and $val.ID -in $read_ntfs_u.ID)) -and ($val.ID -notin $full_share_j.ID -and $val.ID -notin $full_ntfs_j.ID)) {
            $__ = ($ntfs_obj | Select-Object ID, NTFS_Right | Where-Object ID -eq $val.ID).NTFS_Right
            $ntfs_r = if($null -ne $__){$__} else {'not defined'}
            Add-Content -Path $path -Value ('0 "{0}" - Share:{1} Account:{2} ShareRight:{3} NTFSRight:{4}' -f $env:COMPUTERNAME, $val.Share, $val.Account, $val.Share_Right, $ntfs_r)
        }
    }

    # prüfen effektive Berechtigung Gast:Full; Status=2
    elseif($val.Account -eq $($env:USERDOMAIN + '\Gast')){
        if (($val.ID -in $full_share_g.id -and $val.ID -in $full_ntfs_g.id) -or ($val.id -in $full_share_j.id -and $val.ID -in $full_ntfs_j.ID)){
        Add-Content -Path $path -Value ('2 "{0}" - Share:{1} Account:{2} ShareRight:Full NTFSRight:Full' -f $env:COMPUTERNAME, $val.Share, $val.Account)
        }
        # prüfen effektive Berechtigung Gast:Change oder Read; Status=0
        elseif ((($val.ID -in $change_share_g.id -and $val.ID -in $change_ntfs_g.id) -or ($val.ID -in $read_share_g.ID -and $val.ID -in $read_ntfs_g.ID)) -and ($val.ID -notin $full_share_j.ID -and $val.ID -notin $full_ntfs_j.ID)) {
            $__ = ($ntfs_obj | Select-Object ID, NTFS_Right | Where-Object ID -eq $val.ID).NTFS_Right
            $ntfs_r = if($null -ne $__){$__} else {'not defined'}
            Add-Content -Path $path -Value ('0 "{0}" - Share:{1} Account:{2} ShareRight:{3} NTFSRight:{4}' -f $env:COMPUTERNAME, $val.Share, $val.Account, $val.Share_Right, $ntfs_r)
        }
    }
}   

$share_obj | Format-Table
$ntfs_obj | Format-Table



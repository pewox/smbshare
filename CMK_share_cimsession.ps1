
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

$path = '.\out.txt'
New-Item -Path $path -Force | Out-Null
$exclude = 'VORDEFINIERT\Administratoren', 'NT-AUTORITÄT\SYSTEM', 'NT-AUTORITÄT\Authentifizierte Benutzer', 'NT SERVICE\TrustedInstaller', 'ERSTELLER-BESITZER',
'NT AUTHORITY\SYSTEM', 'BUILTIN\Administrators', 'CREATOR OWNER'
$include = 'Jeder', 'Everyone', 'VORDEFINIERT\Benutzer', 'BUILTIN\Users','VORDEFINIERT\Users', $($env:USERDOMAIN + '\gast'), $($env:USERDOMAIN + '\guest')
$benutzer = 'VORDEFINIERT\Benutzer', 'BUILTIN\Users', 'VORDEFINIERT\Users'

$shares = (Get-SmbShare -Special $false).where({$_.Name -in $include -and $_.Name -notmatch '[DF][3]' -and $_.Name -ne 'print$'})
# Objekt für alle Freigabeberechtigungen anlegen; ID aus Sharename und Benutzerkontoname für Vergleiche bilden
$share_obj = ($shares | get-smbshareaccess).Where({$_.AccessControlType -eq 'Allow' -and $_.AccountName -in $include}).ForEach{
    $t1 = if($_.AccountName -eq 'Everyone'){'Jeder'}
        elseif($_.AccountName -in $benutzer){'Benutzer'}
        elseif ($_.AccountName -in $($env:USERDOMAIN + '\guest')) {$($env:USERDOMAIN + '\gast')}
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

$full_share_j = $share_obj.Where({$_.Account -eq 'Jeder' -and $_.Share_Right -match 'Full' })   # Jeder-Accounts nach Freigabeberechtigungen Full, Change, Read sortieren
$full_share_u = $share_obj.Where({$_.Account -eq 'Benutzer' -and $_.Share_Right -match 'Full'}) # Benutzer(allgemein) nach Freigabeberechtigungen Full, Change, Read sortieren
$full_share_g = $share_obj.Where({$_.Account -eq $($env:USERDOMAIN + '\Gast') -and $_.Share_Right -match 'Full'})   # Gast nach Freigabeberechtigungen Full, Change, Read sortieren
$full_ntfs_j = $ntfs_obj.Where({$_.Account -eq 'Jeder' -and $_.NTFS_Right -match 'Full'})   # Jeder-Accounts nach NTFS-Berechtigungen Full, Change, Read sortieren
$full_ntfs_u = $ntfs_obj.Where({$_.Account -eq 'Benutzer' -and $_.NTFS_Right -match 'Full'})    # Benutzer(allgemein)-Accounts nach NTFS-Berechtigungen Full, Change, Read sortieren
$full_ntfs_g = $ntfs_obj.Where({$_.Account -eq $($env:USERDOMAIN + '\Gast') -and $_.NTFS_Right -match 'Full'})  # Gast-Accounts nach NTFS-Berechtigungen Full, Change, Read sortieren

foreach($val in $share_obj){
    # prüfen effektive Berechtigung Jeder:Full; Status=2
    if($val.Account -eq 'Jeder'){
        if(($val.ID -in $full_share_j.ID -and $val.ID -in $full_ntfs_j.ID)){
        Add-Content -Path $path -Value ('2 "{0}" - {1} Account:{2} ShareRight:Full NTFSRight:Full' -f $val.Share, $env:COMPUTERNAME, $val.Account)}
         
        else {	# wenn Freigabe- und NTFS- Berechtigung beide nicht Full, dann Status=0
            $__ = ($ntfs_obj | Select-Object ID, NTFS_Right | Where-Object ID -eq $val.ID).NTFS_Right
            $ntfs_r = if($null -ne $__){$__} else {'not defined'}
            Add-Content -Path $path -Value ('0 "{0}" - {1} Account:{2} Share-Right:{3} NTFS-Right:{4}' -f $val.Share, $env:COMPUTERNAME, $val.Account, $val.Share_Right, $ntfs_r)	
        }
    }
    # prüfen effektive Berechtigung Benutzer:Full; Status=2; dabei auch Accounts Jeder mit einbeziehen
		elseif($val.Account -eq 'Benutzer'){
			if (($val.ID -in $full_share_u.id -and $val.ID -in $full_ntfs_u.id) -or ($val.id -in $full_share_j.id -and $val.ID -in $full_ntfs_j.ID)){
					Add-Content -Path $path -Value ('2 "{0}" - {1} Account:{2} Share-Right:Full NTFS-Right:Full' -f $val.Share, $env:COMPUTERNAME, $val.Account)
			}
        # wenn Freigabe- und NTFS- Berechtigung beide nicht Full, dann Status=0
			else {
				$__ = ($ntfs_obj | Select-Object ID, NTFS_Right | Where-Object ID -eq $val.ID).NTFS_Right
				$ntfs_r = if($null -ne $__){$__} else {'not defined'}
				Add-Content -Path $path -Value ('0 "{0}" - {1} Account:{2} Share-Right:{3} NTFS-Right:{4}' -f $val.Share, $env:COMPUTERNAME, $val.Account, $val.Share_Right, $ntfs_r)
			}
    }
    # prüfen effektive Berechtigung Gast:Full; Status=2
    elseif($val.Account -eq $($env:USERDOMAIN + '\gast')){
        if (($val.ID -in $full_share_g.id -and $val.ID -in $full_ntfs_g.id) -or ($val.id -in $full_share_j.id -and $val.ID -in $full_ntfs_j.ID)){
            Add-Content -Path $path -Value ('2 "{0}" - {1} Account:{2} Share-Right:Full NTFS-Right:Full' -f $val.Share, $env:COMPUTERNAME, $val.Account)
        }
        # wenn Freigabe- und NTFS- Berechtigung beide nicht Full, dann Status=0
        else {
            $__ = ($ntfs_obj | Select-Object ID, NTFS_Right | Where-Object ID -eq $val.ID).NTFS_Right
            $ntfs_r = if($null -ne $__){$__} else {'not defined'}
            Add-Content -Path $path -Value ('0 "{0}" - {1} Account:{2} Share-Right:{3} NTFS-Right:{4}' -f $val.Share, $env:COMPUTERNAME, $val.Account, $val.Share_Right, $ntfs_r)
        }
    }	
}   

#$share_obj | Format-Table
#$ntfs_obj | Format-Table

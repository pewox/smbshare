$path = '.\out.txt'  # Ausgabedatei
New-Item -Path $path -Force | Out-Null

$include = 'Jeder', 'Everyone', 'VORDEFINIERT\Benutzer', 'BUILTIN\Users','VORDEFINIERT\Users', $($env:USERDOMAIN + '\gast'), $($env:USERDOMAIN + '\guest')
$benutzer = 'VORDEFINIERT\Benutzer', 'BUILTIN\Users', 'VORDEFINIERT\Users'
$winserver = (Get-ADComputer -Filter {OperatingSystem -like '*Windows Server*' -and Enabled -eq 'True'}).Name # alle Windows Server auslesen

foreach($server in $winserver){

	$shares = Get-SmbShare -CimSession $server -Special $false
	# Objekt für Freigabeberechtigungen anlegen; ID aus Sharename und Benutzerkontoname bilden
	ForEach($share in $shares){
		$share_obj = ($share | get-smbshareaccess -CimSession $server).Where({$_.AccessControlType -eq 'Allow' -and $_.AccountName -in $include}).ForEach{
            $t1 = if($_.AccountName -eq 'Everyone'){'Jeder'}
            elseif($_.AccountName -in $benutzer){'Benutzer'}
            elseif ($_.AccountName -eq $($env:USERDOMAIN + '\guest')) {$($env:USERDOMAIN + '\gast')}
            else{$_.AccountName}
				[PSCustomObject]@{
				Server = $server
				Share = $_.Name
				Account = $t1
				Share_Right = $_.AccessRight
				ID = $_.Name + ':' + $t1
				}
			# Objekt für NTFS-Berechtigungen anlegen; ID aus Sharename und Benutzerkontoname bilden
			$share_path = $share.Path
			$ntfs_obj = (Invoke-Command -ComputerName $server -ScriptBlock{(Get-Acl -Path $using:share_path).Access.Where({$_.IdentityReference -in $using:include})}) | foreach{
			if($_.filesystemrights -match '268435456'){$f_right = 'FullControl'}
			else{$f_right = $_.filesystemrights}
			$t2 = if($_.IdentityReference -eq 'Everyone'){'Jeder'}
			elseif($_.IdentityReference -in $benutzer){'Benutzer'}
			elseif($_.IdentityReference -eq $($env:USERDOMAIN + '\guest')) {$($env:USERDOMAIN + '\gast')}
			else{$_.IdentityReference}
				[PSCustomObject]@{
				Server = $server
				Share = $share.Name
				Account = $t2
				NTFS_Right = $f_right
				ID = $share.Name + ':' + $t2
				}
			}
		}
		#$share_obj | Format-Table
		#$ntfs_obj | Format-Table
		$full_share_j = $share_obj.Where({$_.Account -eq 'Jeder' -and $_.Share_Right -match 'Full' }) 	# alle Jeder-Accounts nach Freigabeberechtigungen Full
		$full_ntfs_j = $ntfs_obj.Where({$_.Account -eq 'Jeder' -and $_.NTFS_Right -match 'Full'})		# alle Jeder-Accounts nach NTFS-Berechtigungen Full
		$full_share_u = $share_obj.Where({$_.Account -eq 'Benutzer' -and $_.Share_Right -match 'Full'})	# alle Benutzer(allgemein)-Accounts nach Freigabeberechtigungen Full
		$full_ntfs_u = $ntfs_obj.Where({$_.Account -eq 'Benutzer' -and $_.NTFS_Right -match 'Full'})	# alle Benutzer(allgemein)-Accounts nach NTFS-Berechtigungen Full
		$full_share_g = $share_obj.Where({$_.Account -eq $($env:USERDOMAIN + '\Gast') -and $_.Share_Right -match 'Full'})	# alle Gast-Accounts nach Freigabeberechtigungen Full
		$full_ntfs_g = $ntfs_obj.Where({$_.Account -eq $($env:USERDOMAIN + '\Gast') -and $_.NTFS_Right -match 'Full'})		# alle Gast-Accounts nach NTFS-Berechtigungen Full
		foreach($val in $share_obj){
		# prüfen effektive Berechtigung Jeder:Full; Status=2
			if($val.Account -eq 'Jeder'){
				if(($val.ID -in $full_share_j.ID -and $val.ID -in $full_ntfs_j.ID)){
					Add-Content -Path $path -Value ('2 "{0}" - {1} Account:{2} Share-Right:Full NTFS-Right:Full' -f $val.Share, $server, $val.Account)}
				else {	# wenn Freigabe- und NTFS- Berechtigung beide nicht Full, dann Status=0
					$__ = ($ntfs_obj | Select-Object ID, NTFS_Right | Where-Object ID -eq $val.ID).NTFS_Right
					$ntfs_r = if($null -ne $__){$__} else {'not defined'}
					Add-Content -Path $path -Value ('0 "{0}" - {1} Account:{2} Share-Right:{3} NTFS-Right:{4}' -f $val.Share, $server, $val.Account, $val.Share_Right, $ntfs_r)	
				}
			}
			# prüfen effektive Berechtigung Benutzer:Full; Status=2; dabei auch Accounts Jeder mit einbeziehen
			elseif($val.Account -eq 'Benutzer'){
				if (($val.ID -in $full_share_u.id -and $val.ID -in $full_ntfs_u.id) -or ($val.id -in $full_share_j.id -and $val.ID -in $full_ntfs_j.ID)){
					Add-Content -Path $path -Value ('2 "{0}" - {1} Account:{2} Share-Right:Full NTFS-Right:Full' -f $val.Share, $server, $val.Account)
				}
				# wenn Freigabe- und NTFS- Berechtigung beide nicht Full, dann Status=0
				else {
					$__ = ($ntfs_obj | Select-Object ID, NTFS_Right | Where-Object ID -eq $val.ID).NTFS_Right
					$ntfs_r = if($null -ne $__){$__} else {'not defined'}
					Add-Content -Path $path -Value ('0 "{0}" - {1} Account:{2} Share-Right:{3} NTFS-Right:{4}' -f $val.Share, $server, $val.Account, $val.Share_Right, $ntfs_r)
				}
			}
			# prüfen effektive Berechtigung Gast:Full; Status=2; dabei auch Accounts Jeder mit einbeziehen
			elseif($val.Account -eq $($env:USERDOMAIN + '\gast')){
				if (($val.ID -in $full_share_g.id -and $val.ID -in $full_ntfs_g.id) -or ($val.id -in $full_share_j.id -and $val.ID -in $full_ntfs_j.ID)){
					Add-Content -Path $path -Value ('2 "{0}" - {1} Account:{2} Share-Right:Full NTFS-Right:Full' -f $val.Share, $server, $val.Account)
				}
				# wenn Freigabe- und NTFS- Berechtigung beide nicht Full, dann Status=0
				else {
					$__ = ($ntfs_obj | Select-Object ID, NTFS_Right | Where-Object ID -eq $val.ID).NTFS_Right
					$ntfs_r = if($null -ne $__){$__} else {'not defined'}
					Add-Content -Path $path -Value ('0 "{0}" - {1} Account:{2} Share-Right:{3} NTFS-Right:{4}' -f $val.Share, $server, $val.Account, $val.Share_Right, $ntfs_r)
				}
			}	
		}
	}
}

$change = '-536805376', 'modify', 'Write', 'Change'
$full = '268435456', 'FullControl', 'Full'
$read = '-1610612736', 'ReadAndExecute', 'Read'
$exclude = 'VORDEFINIERT\Administratoren', 'VORDEFINIERT\Benutzer', 'NT-AUTORITÄT\SYSTEM', 'NT-AUTORITÄT\Authentifizierte Benutzer', 'NT SERVICE\TrustedInstaller', 'ERSTELLER-BESITZER',
'NT AUTHORITY\SYSTEM', 'BUILTIN\Administrators', 'BUILTIN\Users', 'CREATOR OWNER'
$jeder = 'Jeder', 'Everyone'
$users = 'Users', 'Benutzer'
$gast = 'Gast', 'Guest'
$alle = 'Jeder', 'Everyone', 'Users', 'Benutzer', 'Gast', 'Guest'

$path = '.\out.txt'
New-Item -Path $path -Force | Out-Null

$shares = (Get-SmbShare -Special $false).where({$_.Name -notin $exclude})
$share_obj = ($shares | get-smbshareaccess).Where({$_.AccessControlType -eq 'Allow' -and $_.AccountName -in $alle -and $_.AccountName -notin $exclude}).ForEach{
    $t1 = if($_.AccountName -eq 'Everyone'){'Jeder'}
        elseif($_.AccountName -eq 'Users'){'Benutzer'}
        elseif ($_.AccountName -eq 'Guest') {'Gast'}
        else{$_.AccountName}
    [PSCustomObject]@{
        Server = $env:COMPUTERNAME
        Share = $_.Name
        Account = $t1
        Share_Right = $_.AccessRight
        ID = $_.Name + ':' + $t1
    }
}

$ntfs_obj = foreach($share in $shares){($share | Get-Acl).Access.where({$_.IdentityReference -notin $exclude -and $_.IdentityReference -in $alle}).foreach{
    $t2 = if($_.IdentityReference -eq 'Everyone'){'Jeder'}
        elseif($_.IdentityReference -eq 'Users'){'Benutzer'}
        elseif($_.IdentityReference -eq 'Guest'){'Gast'}
        else{$_.IdentityReference}
    [PSCustomObject]@{
        Server = $env:COMPUTERNAME
        Share = $share.Name
        Account = $t2
        NTFS_Right = $_.filesystemrights    
        ID = $share.Name + ':' + $t2
        }
    }
} 

$full_share_j = $share_obj.Where({$_.Share_Right -in $full })
$full_share_j
$change_share_j = $share_obj.Where({$_.Share_Right -in $change})
$read_share_j = $share_obj.Where({$_.Share_Right -in $read })

foreach($val in $ntfs_obj){
    
    if($val.id -in $full_share_j.id -and ($val.NTFS_Right -like '*Full*')){
        Add-Content -Path $path -Value ('2 "{1}:Share={2}" {0} {3}' -f $val.id, $env:COMPUTERNAME, $val.Share, $val.NTFS_Right)
    } 
    elseif ($val.id -in $change_share_j.id -or $val.id -in $read_share_j.id -or $val.id -in $full_share_j.id -and $val.NTFS_Right -notlike '*Full*') 
    {Add-Content -Path $path -Value ('0 "{1}:Share={2}" {0} {3}' -f $val.id, $env:COMPUTERNAME, $val.Share, $val.NTFS_Right)}
}
$ntfs_obj | Format-Table
$share_obj | Format-Table

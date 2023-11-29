$change = '-536805376', 'modify', 'Write', 'Change'
$full = '268435456', 'FullControl', 'Full'
$read = '-1610612736', 'ReadAndExecute', 'Read'
$exclude = 'VORDEFINIERT\Administratoren', 'VORDEFINIERT\Benutzer', 'NT-AUTORITÄT\SYSTEM', 'NT-AUTORITÄT\Authentifizierte Benutzer', 'NT SERVICE\TrustedInstaller', 'Users', 'ERSTELLER-BESITZER',
'NT AUTHORITY\SYSTEM', 'BUILTIN\Administrators', 'BUILTIN\Users', 'CREATOR OWNER'
$jeder = 'Jeder', 'everyone'

$path = '.\out.txt'
New-Item -Path $path -Force | Out-Null

$shares = (Get-SmbShare -Special $false).where({$_.Name -notin $exclude})
$share_obj = ($shares | get-smbshareaccess).Where({$_.AccessControlType -eq 'Allow' -and $_.AccountName -in $jeder -and $_.AccountName -notin $exclude}).ForEach{
    [PSCustomObject]@{
        Server = $env:COMPUTERNAME
        Share = $_.Name
        Account = if($_.AccountName -eq 'Everyone'){'Jeder'}else{$_.AccountName}
        Share_Right = $_.AccessRight
        ID = $_.Name + ':' + $(if($_.AccountName -eq 'Everyone'){'Jeder'}else{$_.AccountName})
    }
}

$ntfs_obj = foreach($share in $shares){($share | Get-Acl).Access.where({$_.IdentityReference -notin $exclude -and $_.IdentityReference -in $jeder}).foreach{
    [PSCustomObject]@{
        Server = $env:COMPUTERNAME
        Share = $share.Name
        Account = if($_.IdentityReference -eq 'Everyone'){'Jeder'}else{$_.IdentityReference}
        NTFS_Right = $_.filesystemrights
        ID = $share.Name + ':' + $(if($_.IdentityReference -eq 'Everyone'){'Jeder'}else{$_.IdentityReference})
        }
    }
} 

$full_share = $share_obj.Where({$_.Share_Right -in $full })
$change_share = $share_obj.Where({$_.Share_Right -in $change})
$read_share = $share_obj.Where({$_.Share_Right -in $read })

foreach($val in $ntfs_obj){
    #$val | Format-Table
    if($val.id -in $full_share.id -and ($val.NTFS_Right -notlike '*Read*' -or $val.NTFS_Right -notlike '*modify*' -or $val.NTFS_Right -notlike '*Write*' -or $val.NTFS_Right -notlike '*Change*')){
        Add-Content -Path $path -Value ('2 "{1}:Share={2}" {0}' -f $val.id, $env:COMPUTERNAME, $val.Share)
    } 
    if($val.id -in $change_share.id -and ($val.NTFS_Right -notlike '*Read*')){
        Add-Content -Path $path -Value ('2 "{1}:Share={2}" {0}' -f $val.id, $env:COMPUTERNAME, $val.Share)
    }
    if($val.id -in $read_share.id){
        Add-Content -Path $path -Value ('1 "{1}:Share={2}" {0}' -f $val.id, $env:COMPUTERNAME, $val.Share)
    }
}


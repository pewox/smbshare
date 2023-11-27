$write = '-536805376', 'modify', 'Write', 'Change'
$full = '268435456', 'FullControl', 'Full'
$read = '-1610612736', 'ReadAndExecute', 'Read'
$exclude = 'NT-AUTORITÄT\SYSTEM', 'VORDEFINIERT\Administratoren', 'NT-AUTORITÄT\Authentifizierte Benutzer', 'VORDEFINIERT\Benutzer', 'ERSTELLER-BESITZER',
'NT AUTHORITY\SYSTEM', 'BUILTIN\Administrators', 'BUILTIN\Users', 'CREATOR OWNER'
$jeder = 'Jeder', 'Everyone'

$shares = Get-SmbShare -Special $false
$share_obj = ($shares | get-smbshareaccess).Where({$_.AccessControlType -eq 'Allow' -and $_.AccountName -notin $exclude}).ForEach{
    [PSCustomObject]@{
        Computer = $env:COMPUTERNAME
        Share = $_.Name
        Account = $_.AccountName
        Access_Right = $_.AccessRight
        id = $_.Name + ':' + $_.AccountName
    }
}
$ntfs_obj = foreach($share in $shares){($share | Get-Acl).Access.where({$_.IdentityReference -notin $exclude -and $_.IdentityReference -notlike 'S-*-*-*-*'}).foreach{
    [PSCustomObject]@{
        Computer = $env:COMPUTERNAME
        Share = $share.Name
        Account = $_.IdentityReference
        NTFS_Right = $_.FileSystemRights
        id = $share.Name + ':' + $_.IdentityReference
        
        }
    }
} 

$full_share_everyone = $share_obj.Where({$_.account -in $jeder -and $_.Access_Right -in $full })
$write_share_everyone = $share_obj.Where({$_.account -in $jeder -and $_.Access_Right -in $write })
$read_share_everyone = $share_obj.Where({$_.account -in $jeder -and $_.Access_Right -in $read })

foreach($val in $ntfs_obj){
    if($val.id -in $full_share_everyone.id){
        $val.id + ' status=2'
    } else {'NO'}
}


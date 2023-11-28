$write = '-536805376', 'modify', 'Write', 'Change'
$full = '268435456', 'FullControl', 'Full'
$read = '-1610612736', 'ReadAndExecute', 'Read'
$exclude = 'NT-AUTORITÄT\SYSTEM', 'VORDEFINIERT\Administratoren', 'NT-AUTORITÄT\Authentifizierte Benutzer', 'VORDEFINIERT\Benutzer', 'ERSTELLER-BESITZER',
'NT AUTHORITY\SYSTEM', 'BUILTIN\Administrators', 'BUILTIN\Users', 'CREATOR OWNER'

$path = '.\Freigaben_auslesen\out.txt'
New-Item -Path $path -Force | Out-Null
$ntfs_obj = foreach($share in $shares){($share | Get-Acl).Access.where({$_.IdentityReference -notin $exclude -and $_.IdentityReference -in $jeder}).foreach{
    [PSCustomObject]@{
        Computer = $env:COMPUTERNAME
        Share = $share.Name
        Account = $_.IdentityReference
        NTFS_Right = $_.filesystemrights
        ID = $share.Name + ':' + $_.IdentityReference
        }
    }
} 
$ntfs_obj | Format-Table

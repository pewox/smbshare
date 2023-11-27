$write = '-536805376', 'modify', 'Write', 'Change'
$full = '268435456', 'FullControl', 'Full'
$read = '-1610612736', 'ReadAndExecute', 'Read'
$exclude = 'VORDEFINIERT\Administratoren', 'VORDEFINIERT\Benutzer', 'NT-AUTORITÄT\SYSTEM', 'NT-AUTORITÄT\Authentifizierte Benutzer', 'NT SERVICE\TrustedInstaller', 'Users'

$shares = (Get-SmbShare -Special $false).where({$_.Name -notin $exclude})
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
$ntfs_obj | Format-Table

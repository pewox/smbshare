$write = '-536805376', 'modify', 'Write', 'Change'
$full = '268435456', 'FullControl', 'Full'
$read = '-1610612736', 'ReadAndExecute', 'Read'
$exclude = 'VORDEFINIERT\Administratoren', 'VORDEFINIERT\Benutzer', 'NT-AUTORITÄT\SYSTEM', 'NT-AUTORITÄT\Authentifizierte Benutzer', 'NT SERVICE\TrustedInstaller'

$shares = Get-SmbShare -Special $false
$j = 0
$ntfs_obj = foreach($share in $shares){($share | Get-Acl | Sort-Object Path).Access.where({$_.IdentityReference -notin $exclude -and $_.IdentityReference -notlike 'S-*-*-*-*'}).foreach{
    [PSCustomObject]@{
        computer = $env:COMPUTERNAME
        share = $share.Name
        account = $_.IdentityReference
        right = $_.FileSystemRights
        id = 'n_'+$j
        }
        $j++
    }
}
$ntfs_obj | Format-Table

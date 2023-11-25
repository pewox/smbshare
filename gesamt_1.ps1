$write = '-536805376', 'modify', 'Write', 'Change'
$full = '268435456', 'FullControl', 'Full'
$read = '-1610612736', 'ReadAndExecute', 'Read'
$exclude = 'VORDEFINIERT\Administratoren', 'VORDEFINIERT\Benutzer', 'NT-AUTORITÄT\SYSTEM', 'NT-AUTORITÄT\Authentifizierte Benutzer', 'NT SERVICE\TrustedInstaller'

$share_obj = (Get-SmbShare -Special $false | get-smbshareaccess).Where{$_.AccessControlType -eq 'Allow' -and $_.AccountName -notin $exclude}.ForEach{
        [PSCustomObject]@{
            computer = $env:COMPUTERNAME
            share = $_.Name
            account = $_.AccountName
            share_right = $_.AccessRight
        }
    }

$shares = Get-SmbShare -Special $false
$ntfs_obj = foreach($share in $shares){($share | Get-Acl).Access.where{$_.IdentityReference -notin $exclude -and $_.IdentityReference -notlike 'S-*-*-*-*'}.foreach{
    [PSCustomObject]@{
        computer = $env:COMPUTERNAME
        share = $share.Name
        account = $_.IdentityReference
        NTFS_right = $_.FileSystemRights
        }
    }
}
#$ntfs_obj
#$share_obj
$ntfs_obj.Where{$_.share -eq 'test2'}.foreach{
    $_.NTFS_right
}
$share_obj.Where{$_.share -eq 'test2'}.foreach{
    $_.share_right
}

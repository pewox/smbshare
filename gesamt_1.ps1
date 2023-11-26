$write = '-536805376', 'modify', 'Write', 'Change'
$full = '268435456', 'FullControl', 'Full'
$read = '-1610612736', 'ReadAndExecute', 'Read'
$exclude = 'VORDEFINIERT\Administratoren', 'VORDEFINIERT\Benutzer', 'NT-AUTORITÄT\SYSTEM', 'NT-AUTORITÄT\Authentifizierte Benutzer', 'NT SERVICE\TrustedInstaller'
$jeder = 'Jeder', 'everyone'

$shares = Get-SmbShare -Special $false
$i = 0
$share_obj = ($shares | get-smbshareaccess | sort Name).Where({$_.AccessControlType -eq 'Allow' -and $_.AccountName -notin $exclude}).ForEach{
    [PSCustomObject]@{
        Computer = $env:COMPUTERNAME
        Share = $_.Name
        Account = $_.AccountName
        Access_Right = $_.AccessRight
        id = 's_'+$i
    }
    $i++
}


$j = 0
$ntfs_obj = foreach($share in $shares){($share | Get-Acl | sort Path).Access.where({$_.IdentityReference -notin $exclude -and $_.IdentityReference -notlike 'S-*-*-*-*'}).foreach{
    [PSCustomObject]@{
        Computer = $env:COMPUTERNAME
        Share = $share.Name
        Account = $_.IdentityReference
        NTFS_Right = $_.FileSystemRights
        id = 'n_'+$j
        }
        $j++
    }
} 
$full_share = $share_obj.Where({$_.account -in $jeder -and $_.Access_Right -in $full })
$read_share = $share_obj.Where({$_.account -in $jeder -and $_.Access_Right -in $read })
$write_share = $share_obj.Where({$_.account -in $jeder -and $_.Access_Right -in $write })
#$read_share | Format-Table
#$write_share
#$full_share
$ntfs_obj | Format-Table
$share_obj | Format-Table

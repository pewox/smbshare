$change = '-536805376', 'modify', 'Write', 'Change'
$full = '268435456', 'FullControl', 'Full'
$read = '-1610612736', 'ReadAndExecute', 'Read'
$exclude = 'VORDEFINIERT\Administratoren', 'VORDEFINIERT\Benutzer', 'NT-AUTORITÄT\SYSTEM', 'NT-AUTORITÄT\Authentifizierte Benutzer', 'NT SERVICE\TrustedInstaller', 'Users'
$jeder = 'Jeder', 'everyone'

New-Item -Path '.\Freigaben_auslesen\out.txt' -Force

$shares = (Get-SmbShare -Special $false).where({$_.Name -notin $exclude})
$share_obj = ($shares | get-smbshareaccess).Where({$_.AccessControlType -eq 'Allow' -and $_.AccountName -notin $exclude}).ForEach{
    [PSCustomObject]@{
        Computer = $env:COMPUTERNAME
        Share = $_.Name
        Account = $_.AccountName
        Access_Right = $_.AccessRight
        ID = $_.Name + ':' + $_.AccountName
    }
}
$ntfs_obj = foreach($share in $shares){($share | Get-Acl).Access.where({$_.IdentityReference -notin $exclude -and $_.IdentityReference -notlike 'S-*-*-*-*'}).foreach{
    [PSCustomObject]@{
        Computer = $env:COMPUTERNAME
        Share = $share.Name
        Account = $_.IdentityReference
        NTFS_Right = $_.filesystemrights
        ID = $share.Name + ':' + $_.IdentityReference
        }
    }
} 

$full_share = $share_obj.Where({$_.Access_Right -in $full })
$write_share = $share_obj.Where({$_.Access_Right -in $change})
$read_share = $share_obj.Where({$_.Access_Right -in $read })
#$full_share | Format-Table
foreach($val in $ntfs_obj){
    if($val.id -in $full_share.id){
        Add-Content -Path '.\Freigaben_auslesen\out.txt' -Value ('status=2 {0}' -f $val.id)
    } #else {'NO'}
}
$ntfs_obj | Format-Table

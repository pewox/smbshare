$change = '-536805376', 'modify', 'Write', 'Change'
$full = '268435456', 'FullControl', 'Full'
$read = '-1610612736', 'ReadAndExecute', 'Read'
$exclude = 'VORDEFINIERT\Administratoren', 'VORDEFINIERT\Benutzer', 'NT-AUTORITÄT\SYSTEM', 'NT-AUTORITÄT\Authentifizierte Benutzer', 'NT SERVICE\TrustedInstaller', 'Users'
$jeder = 'Jeder', 'everyone'

$path = '.\Freigaben_auslesen\out.txt'
New-Item -Path $path -Force | Out-Null

$shares = (Get-SmbShare -Special $false).where({$_.Name -notin $exclude})
$share_obj = ($shares | get-smbshareaccess).Where({$_.AccessControlType -eq 'Allow' -and $_.AccountName -in $jeder -and $_.AccountName -notin $exclude}).ForEach{
    [PSCustomObject]@{
        Computer = $env:COMPUTERNAME
        Share = $_.Name
        Account = $_.AccountName
        Access_Right = $_.AccessRight
        ID = $_.Name + ':' + $_.AccountName
    }
}
#$share_obj | Format-Table
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
$full_share = $share_obj.Where({$_.Access_Right -in $full })
$change_share = $share_obj.Where({$_.Access_Right -in $change})
$read_share = $share_obj.Where({$_.Access_Right -in $read })

foreach($val in $ntfs_obj){
    if($val.id -in $full_share.id){
        Add-Content -Path $path -Value ('status=2 {0}' -f $val.id)
        'FULL', $val.id | Format-Table
    } 
    if($val.id -in $change_share.id){
        Add-Content -Path $path -Value ('status=2 {0}' -f $val.id)
        'Change', $val.id | Format-Table
    }
    if($val.id -in $read_share.id){
        Add-Content -Path $path -Value ('status=2 {0}' -f $val.id)
        'Read', $val.id | Format-Table
    }
}

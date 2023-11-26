$write = '-536805376', 'modify', 'Write', 'Change'
$full = '268435456', 'FullControl', 'Full'
$read = '-1610612736', 'ReadAndExecute', 'Read'
$exclude = 'VORDEFINIERT\Administratoren', 'VORDEFINIERT\Benutzer', 'NT-AUTORITÄT\SYSTEM', 'NT-AUTORITÄT\Authentifizierte Benutzer', 'NT SERVICE\TrustedInstaller'

$i = 0
$share_obj = (Get-SmbShare -Special $false | get-smbshareaccess | Sort-Object Name).Where({$_.AccessControlType -eq 'Allow' -and $_.AccountName -notin $exclude}).ForEach{
        [PSCustomObject]@{
            computer = $env:COMPUTERNAME
            share = $_.Name
            account = $_.AccountName
            right = $_.AccessRight
            id = 's_'+$i
        }
        $i++
    }
$share_obj | Format-Table

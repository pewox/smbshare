$change = '-536805376', 'modify', 'Write', 'Change'
$full = '268435456', 'FullControl', 'Full'
$read = '-1610612736', 'ReadAndExecute', 'Read'


$prior = @()
foreach($val in $filesystemrights){
    if ($val -in $full){
        $prior += 3
    }
    elseif($val -in $change){
        $prior += 2
    }
    elseif($val -in $read){
        $prior += 1
    } else {$filesystemrights = $null}
}
($prior | measure -Maximum).Maximum


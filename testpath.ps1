
$testpath = Test-Path -Path 'c:\test\test.txt'
if($testpath){
    $content = Get-Content -Path 'c:\test\test.txt'
	if ($content){
		Write-Host 'Inhalt vorhanden'
	} else {
		Write-Host 'kein Inhalt'
	}
}

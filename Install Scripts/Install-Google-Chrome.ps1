$Url = "http://dl.google.com/chrome/install/latest/chrome_installer.exe"
$FilePath = $env:TEMP
$FileName = "ChromeLatest.exe"
Invoke-WebRequest -Uri $Url -Outfile "$Filepath\$FileName"
Start-Process "$FilePath\$FileName" -args "/silent /install" -Wait
Remove-Item $FilePath\$FileName

$apps = @()
$AppName = "PDFCreator"

# Search registry for installed apps
$Apps += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
$Apps += Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"


# Look through apps for PDFCreator
foreach ($app in $apps) {
    if ($app.DisplayName -like "*$AppName*") {
        $AppFound = 1
        # The uninstall exe is uninst000.exe, so "/VERYSILENT" has to be specified for silent removal
        Start-Process $app.UninstallString -args "/VERYSILENT /NORESTART"
    }
}

# Tell the user if PDFCreator was found or not.
if (!$AppFound) {
    Write-Host "PDFCreator is not installed!"
} ELSE {
    Write-Host "PDFCreator has been removed."
}

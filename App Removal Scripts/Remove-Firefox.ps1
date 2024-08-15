$apps = @()
$AppName = "Firefox"


# Search registry for installed apps
$Apps += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
$Apps += Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"


# Look through apps for the specified app
foreach ($app in $apps) {
    if ($app.DisplayName -like "*$AppName*") {
        $AppFound = 1
        # Firefox uses helper.exe to uninstall, which uses /s for silent uninstall
        Start-Process $App.UninstallString -args "/s"
    }
}

# Tell the user if the app was found or not.
if (!$AppFound) {
    Write-Host "$AppName is not installed!"
} ELSE {
    Write-Host "$AppName has been removed."
}

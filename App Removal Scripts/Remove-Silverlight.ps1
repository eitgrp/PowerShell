$apps = @()
$AppName = "Microsoft Silverlight"


# Search registry for installed apps
$Apps += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
$Apps += Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"


# Look through apps for the specified app
foreach ($app in $apps) {
    if ($app.DisplayName -like "*$AppName*") {
        $AppFound = 1
        # Splitting the string to seperate the argument
        $Uninstall = $App.UninstallString.split(" ")
        Start-Process $Uninstall[0].Trim() -args $Uninstall[1].Trim(), " /quiet /norestart"
    }
}

# Tell the user if the app was found or not.
if (!$AppFound) {
    Write-Host "$AppName is not installed!"
} ELSE {
    Write-Host "$AppName has been removed."
}

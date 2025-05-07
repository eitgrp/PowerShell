$Pathx64 = "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\"
$installedx64 = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\*"
$PackagesToCheck = @()
$VersionsToCheck = @()

 if ($installedx64.PSChildName.Contains("Microsoft.WindowsDesktop.App")) {
        $PackageName = "Microsoft.WindowsDesktop.App"
        $PackagesToCheck += 
        $Versions = (get-item "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\$PackageName").Property
        if ($Versions.count -gt 1) {
            foreach ($Version in $Versions) {
                $PackagesToCheck += $PackageName
                $VersionsToCheck += $Version
            }
        } ELSE {
            $VersionsToCheck += (get-item "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\$PackageName").Property
        }
    } ELSE {
        if ($installedx64.PSChildName.Contains("Microsoft.NETCore.App")) {
            $PackageName = "Microsoft.NETCore.App"
            $PackagesToCheck += 
            $Versions = (get-item "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\$PackageName").Property
            if ($Versions.count -gt 1) {
                foreach ($Version in $Versions) {
                    $PackagesToCheck += $PackageName
                    $VersionsToCheck += $Version
                }
            } ELSE {
                $VersionsToCheck += (get-item "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\$PackageName").Property
            }
    }
    if ($installedx64.PSChildName.Contains("Microsoft.AspNetCore.App")) {
        $PackageName = "Microsoft.WindowsDesktop.App"
        $PackagesToCheck += 
        $Versions = (get-item "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\$PackageName").Property
        if ($Versions.count -gt 1) {
            foreach ($Version in $Versions) {
                $PackagesToCheck += $PackageName
                $VersionsToCheck += $Version
            }
        } ELSE {
            $VersionsToCheck += (get-item "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\$PackageName").Property
        }
    }
}
$i = 0
foreach ($Package in $PackagesToCheck) {
    Switch ($VersionsToCheck[$i].Split(".")[0]) {
        (8) {
            $url = "https://dotnet.microsoft.com/en-us/download/dotnet/8.0"
        }
        (9) {
            $url = "https://dotnet.microsoft.com/en-us/download/dotnet/9.0"
        }
    }
    Switch ($Package) {
        ("MicrosoftWindowsDesktop.App") {
            
            $dotnetVersionWebAddress = (Invoke-WebRequest $url -usebasicparsing).links.href
            $runtimeDesktop8 = ($dotnetVersionWebAddress | Select-String -Pattern 'runtime-Desktop-\d.\d.\d+-windows-x64-installer').Matches.Value[0]
            $VerString = ($runtimeDesktop8 | select-string -pattern '\d.\d.\d+').matches.value
            $LatestVer = [system.version]::Parse($VerString)
            $installedVer = [system.version]::Parse($VersionstoCheck[$i])
            if ($installedVer -lt $latestVer) {
                Invoke-WebRequest "https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/$VerString/windowsdesktop-runtime-$VerString-win-x64.exe" -OutFile C:\source\dotnet8-$VerString.exe
                Start-Process C:\source\Dotnet8-$VerString.exe -args "/install /Quiet"
            }
        }
    }
}

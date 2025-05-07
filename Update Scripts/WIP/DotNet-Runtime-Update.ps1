$installed = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\*") + (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x86\sharedfx\*").Property 
$PackagesToCheck = @()

 if ($installed.PSChildName -Contains "Microsoft.WindowsDesktop.App") {
    $PackageName = "Microsoft.WindowsDesktop.App"
    $Versions = (get-item "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\$PackageName" -erroraction silentlycontinue).Property + (get-item "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x86\sharedfx\$PackageName" -erroraction silentlycontinue).Property 
    foreach ($Version in $Versions) {
        $Package = New-Object -TypeName pscustomobject
        $Package | Add-Member -MemberType NoteProperty -Name "PackageName" -value $PackageName
        $Package | Add-Member -MemberType NoteProperty -Name "Version" -value $Version
        $PackagesToCheck += $Package
    }
} ELSEif ($installed.PSChildName -contains "Microsoft.NETCore.App") {
    $PackageName = "Microsoft.NETCore.App"
    $Versions = (get-item "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\$PackageName" -erroraction silentlycontinue).Property + (get-item "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x86\sharedfx\$PackageName" -erroraction silentlycontinue).Property
    foreach ($Version in $Versions) {
        $Package = New-Object -TypeName pscustomobject
        $Package | Add-Member -MemberType NoteProperty -Name "PackageName" -value $PackageName
        $Package | Add-Member -MemberType NoteProperty -Name "Version" -value $Version
        $PackagesToCheck += $Package
    }
} if ($installed.PSChildName -Contains "Microsoft.AspNetCore.App") {
    $PackageName = "Microsoft.AspNetCore.App"
    $Versions = (get-item "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\$PackageName" -ErrorAction SilentlyContinue).Property + (get-item "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x86\sharedfx\$PackageName" -ErrorAction SilentlyContinue).Property
    foreach ($Version in $Versions) {
        $Package = New-Object -TypeName pscustomobject
        $Package | Add-Member -MemberType NoteProperty -Name "PackageName" -value $PackageName
        $Package | Add-Member -MemberType NoteProperty -Name "Version" -value $Version
        $PackagesToCheck += $Package
    }
}

foreach ($Package in $PackagesToCheck | where Version -like "*.*") {
    $pattern = 'runtime-Desktop-\d.\d.\d+'
    Switch ($Package.Version.Split(".")[0]) {
        (8) {
            $url = "https://dotnet.microsoft.com/en-us/download/dotnet/8.0"
        }
        (9) {
            $url = "https://dotnet.microsoft.com/en-us/download/dotnet/9.0"
        }
        (10) {
            $url = "https://dotnet.microsoft.com/en-us/download/dotnet/10.0"
            $Pattern = 'runtime-Desktop-\d\d.\d.\d+'
        }
    }
    $dotnetVersionWebAddress = (Invoke-WebRequest $url -usebasicparsing).links.href
    $VerString = ($dotnetVersionWebAddress | Select-String -Pattern $Pattern).Matches.Value[0].Trim("runtime-desktop-")
    $LatestVer = [system.version]::Parse($VerString)
    $installedVer = [system.version]::Parse($Package.Version)
    if ($installedVer -lt $latestVer) {
        New-Item "C:\source\Software" -ItemType Directory -ErrorAction SilentlyContinue
        Switch ($Package.PackageName) {
            ("Microsoft.WindowsDesktop.App") {
                $urls = @(
                    "https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/$VerString/windowsdesktop-runtime-$VerString-win-x64.exe",
                    "https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/$VerString/windowsdesktop-runtime-$VerString-win-x86.exe"
                )
            }
            ("Microsoft.AspNetCore.App") {
                $urls = @(
                    "https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/$VerString/aspnetcore-runtime-$VerString-win-x64.exe",
                    "https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/$VerString/aspnetcore-runtime-$VerString-win-x86.exe"
                )
                }
            ("Microsoft.NETCore.App") {
                $urls = @(
                    "https://builds.dotnet.microsoft.com/dotnet/Runtime/$VerString/dotnet-runtime-$VerString-win-x64.exe",
                    "https://builds.dotnet.microsoft.com/dotnet/Runtime/$VerString/dotnet-runtime-$VerString-win-x86.exe"
                )
            }
        }
        foreach ($DLUrl in $urls) {
            $Split = $DLUrl.Split("/").count
            $filepath = "C:\source\Software\" + ($DLUrl.Split("/")[$split - 1])
            Invoke-WebRequest $DLUrl -OutFile $filepath
            Start-Process $filepath -args "/install /quiet" -Wait
        }
    }
}




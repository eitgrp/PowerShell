[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

import-module evergreen

################################
#           Variables          #
#          Start here          #
#..............................#

$Apps64 = @()
$Apps32 = @()
$AppName = "Java 8"

$latestJava32 = (get-evergreenapp OracleJava8 | where {$_.architecture -eq "x86"}).URI
$latestJava64 = (get-evergreenapp OracleJava8 | where {$_.architecture -eq "x64"}).URI 
$temp = $env:TEMP


#...............................#
#         END Varibles          # 
#################################
#################################
#         Your functions        #
#          Start here           #
#...............................#



function FindJava64 {
    # Search registry for installed apps
    $Apps64 += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    # Look through apps for the specified app
    foreach ($app in $Apps64) {
        if ($app.DisplayName -like "$AppName*") {
            # Grabbing the information we need to check for updates and specifying the scope of these variables
            $script:Java64Version = [System.Version]::Parse($app.DisplayVersion)
            $script:Uninstall64 = $App.UninstallString.split(" ")
            Return $true
        }
    }
    return $null
}

function FindJava32 {
    # Search registry for installed apps
    $Apps32 += Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    # Look through apps for the specified app
    foreach ($app in $Apps32) {
        if ($app.DisplayName -like "$AppName*") {
            # Grabbing the information we need to check for updates and specifying the scope of these variables
            $script:Java32Version = [System.Version]::Parse($app.DisplayVersion)
            $script:Uninstall32 = $App.UninstallString.split(" ")
            return $True
        }
    }
    return $null
}

function CheckUpdate64 {
    # This bit could be replaced with Evergreen code so downloading the installer isn't needed, however I wanted to avoid it as the version format is not 1:1 like it is in this method
    Invoke-WebRequest $latestJava64 -OutFile $Temp\Java8Latest64.exe
    $script:latestVersion64 = [System.Version]::Parse((Get-ItemProperty $Temp\Java8Latest64.exe).VersionInfo.ProductVersion)
	# Checking the installed version against the latest version
    if ($latestVersion64 -lt $Java64Version) {
        Remove-item -Path $Temp\Java8Latest64.exe
        return $null
    } elseif ($Java64Version -eq $latestVersion64) {
        Write-Host "Java 8 64Bit is already up to date."
        Remove-item -Path $Temp\Java8Latest64.exe
        return $null
    } else { return $true }

}

function CheckUpdate32 {
# This bit could be replaced with Evergreen code so downloading the installer isn't needed, however I wanted to avoid it as the version format is not 1:1 like it is in this method
    Invoke-WebRequest $latestJava32 -OutFile $Temp\Java8Latest32.exe
    $script:latestVersion32 = [System.Version]::Parse((Get-ItemProperty $Temp\Java8Latest32.exe).VersionInfo.ProductVersion)
    # Checking the installed version against the latest version 
    if ($latestVersion32 -lt $Java32Version ) {
        Remove-item -Path $Temp\Java8Latest32.exe
        return $null
    } elseif ($Java32Version -eq $latestVersion32) {
        Write-Host "Java 8 32Bit is already up to date."
        Remove-item -Path $Temp\Java8Latest32.exe
        return $null
    } else { return $true }    
}


function UpdateJava64 {
        # Uninstalling the previous version
        Start-Process $Uninstall64[0].Trim() -args $Uninstall64[1].Trim(), " /quiet /norestart" -Wait
        # Installing the new version
        Start-Process $Temp\Java8Latest64.exe -args "/s" -Wait
        # Checking the installed version after the installer has finished running
        $CheckVersion64 = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | where {$_.displayname -like "Java 8*"}).DisplayVersion

        if (!$CheckVersion64) {return "No Java 8 64Bit version found after updating! It's possible the installation did not complete properly."}

        If ($CheckVersion64 -eq $latestVersion64) { 
            Remove-item -Path $Temp\Java8Latest64.exe
            Return "Java 8 64Bit successfully updated from $Java64Version to $CheckVersion64"
        }
        else { 
            if ($Checkversion64 -eq $Java64Version) {
                return "Java 8 64Bit version is the same after updating! It's possible the original installation did not get removed properly. Version found: $CheckVersion64"
            }
            else { return "Java 8 64Bit is not at the expected version after updating. The installed version is $CheckVersion64 and the latest version is $latestVersion64" }
        }
    }


function UpdateJava32 {
    # Uninstalling the previous version
    Start-Process $Uninstall32[0].Trim() -args $Uninstall32[1].Trim(), " /quiet /norestart" -Wait
    # Installing the new version
    Start-Process $Temp\Java8Latest32.exe -args "/s" -Wait
    # Checking the installed version after the installer has finished running
    $CheckVersion32 = (Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | where {$_.displayname -like "Java 8*"}).DisplayVersion

    if (!$CheckVersion32) {return "No Java 8 32Bit version found after updating! It's possible the installation did not complete properly."}

    If ($CheckVersion32 -eq $latestVersion32) { 
        Remove-item -Path $Temp\Java8Latest32.exe
        Return "Java 8 32Bit successfully updated from $Java32Version to $CheckVersion32"
    }
    else { 
        if ($Checkversion32 -eq $Java32Version) {
            return "Java 8 32Bit version is the same after updating! It's possible the original installation did not get removed properly. Version found: $CheckVersion32"
        }
        else { return "Java 8 32Bit is not at the expected version after updating. The installed version is $CheckVersion32 and the latest version is $latestVersion32" }
    }
}

#...............................#
#      END your Functions       #
#################################
#################################
#           Your code           #
#          Start here           #
#...............................#

$FindJava32 = FindJava32
$FindJava64 = FindJava64


if ((!$FindJava32) -and (!$FindJava64)) {
    return "No Java 8 installation found in 32 bit or 64 bit registry. Please double check Java is present on the machine"
}

if ($FindJava32) {
    $CheckUpdates32 = CheckUpdate32
    if ($CheckUpdates32) {
        UpdateJava32
    }
} else { Write-Host "Java 8 32Bit not found, moving on to 64Bit..." }

if ($FindJava64) {
    $CheckUpdates64 = CheckUpdate64
    if ($CheckUpdates64) {
        UpdateJava64
    }
}  else { Write-Host "Java 8 64Bit not found..."}

#...............................#
#       END of your code        #
#################################
#  ----====== !!!!! ======----  #

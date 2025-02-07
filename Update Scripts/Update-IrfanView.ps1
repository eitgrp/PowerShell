[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
################################
#           Variables          #
#          Start here          #
#..............................#

$AppName = "IrfanView"

$latestApp32 = "http://static.desktopservice.eu/downloads/IrfanView/iview470_setup.exe"
$latestApp64 = "http://static.desktopservice.eu/downloads/IrfanView/iview470_x64_setup.exe"
$temp = $env:TEMP


#...............................#
#         END Varibles          # 
#################################
#################################
#         Your functions        #
#          Start here           #
#...............................#



function FindApp64 {
    # Search registry for installed apps
    $App64 = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | where {$_.DisplayName -like "*$AppName*"}
    # Look through apps for the specified app
    if ($App64) {
        # Grabbing the information we need to check for updates and specifying the scope of these variables
        $script:Installed64Version = [System.Version]::Parse($App64.DisplayVersion)
        $script:Uninstall64 = $App64.UninstallString
        Return $true
    }
    else {
        return $null
    }
}

function FindApp32 {
    # Search registry for installed apps
    $App32 = Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"  | where {$_.DisplayName -like "*$AppName*"}
    # Look through apps for the specified app
    if ($App32) {
        # Grabbing the information we need to check for updates and specifying the scope of these variables
        $script:Installed32Version = [System.Version]::Parse($App32.DisplayVersion)
        $script:Uninstall32 = $App32.UninstallString.split(" ")
        return $True
    }
    Else {
        return $null
    }
}

function CheckUpdate64 {
    # This bit could be replaced with Evergreen code so downloading the installer isn't needed, however I wanted to avoid it as the version format is not 1:1 like it is in this method
    Invoke-WebRequest $latestApp64 -OutFile $Temp\AppLatest64.exe
    $script:latestVersion64 = [System.Version]::Parse((Get-ItemProperty $Temp\AppLatest64.exe).VersionInfo.ProductVersion)
	# Checking the installed version against the latest version
    if ($latestVersion64 -lt $Installed64Version) {
        Remove-item -Path $Temp\AppLatest64.exe
        return $null
    } elseif ($Installed64Version -eq $latestVersion64) {
        Write-Host "$AppName 64Bit is already up to date."
        Remove-item -Path $Temp\AppLatest64.exe
        return $null
    } else { return $true }
}

function CheckUpdate32 {
# This bit could be replaced with Evergreen code so downloading the installer isn't needed, however I wanted to avoid it as the version format is not 1:1 like it is in this method
    Invoke-WebRequest $latestApp32 -OutFile $Temp\AppLatest32.exe
    $script:latestVersion32 = [System.Version]::Parse((Get-ItemProperty $Temp\AppLatest32.exe).VersionInfo.ProductVersion)
    # Checking the installed version against the latest version 
    if ($latestVersion32 -lt $Installed32Version ) {
        Remove-item -Path $Temp\AppLatest32.exe
        return $null
    } elseif ($Installed32Version -eq $latestVersion32) {
        Write-Host "$AppName 32Bit is already up to date."
        Remove-item -Path $Temp\AppLatest32.exe
        return $null
    } else { return $true }    
}


function UpdateApp64 {
        # Uninstalling the previous version
        Start-Process $Uninstall64 -args "/silent" -Wait
        # Installing the new version
        Start-Process $Temp\AppLatest64.exe -args "/silent /desktop=1 /group=1 /allusers=1``" -Wait
        # Checking the installed version after the installer has finished running
        $CheckVersion64 = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | where {$_.displayname -like "$AppName*"}).DisplayVersion

        if (!$CheckVersion64) {return "No $AppName 64Bit version found after updating! It's possible the installation did not complete properly."}

        If ($CheckVersion64 -eq $latestVersion64) { 
            Remove-item -Path $Temp\AppLatest64.exe
            Return "$AppName 64Bit successfully updated from $Installed64Version to $CheckVersion64"
        }
        else { 
            if ($Checkversion64 -eq $Installed64Version) {
                return "$AppName 64Bit version is the same after updating! It's possible the original installation did not get removed properly. Version found: $CheckVersion64"
            }
            else { return "$AppName 64Bit is not at the expected version after updating. The installed version is $CheckVersion64 and the latest version is $latestVersion64" }
        }
    }


function UpdateApp32 {
    # Uninstalling the previous version
    Start-Process $Uninstall32 -args " /Silent /norestart" -Wait
    # Installing the new version
    Start-Process $Temp\AppLatest32.exe -args "/silent /desktop=1 /group=1 /allusers=1``" -Wait
    # Checking the installed version after the installer has finished running
    $CheckVersion32 = (Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | where {$_.displayname -like "$AppName*"}).DisplayVersion

    if (!$CheckVersion32) {return "No $AppName 32Bit version found after updating! It's possible the installation did not complete properly."}

    If ($CheckVersion32 -eq $latestVersion32) { 
        Remove-item -Path $Temp\AppLatest32.exe
        Return "$AppName 32Bit successfully updated from $Installed32Version to $CheckVersion32"
    }
    else { 
        if ($Checkversion32 -eq $Installed32Version) {
            return "$AppName 32Bit version is the same after updating! It's possible the original installation did not get removed properly. Version found: $CheckVersion32"
        }
        else { return "$AppName 32Bit is not at the expected version after updating. The installed version is $CheckVersion32 and the latest version is $latestVersion32" }
    }
}

#...............................#
#      END your Functions       #
#################################
#################################
#           Your code           #
#          Start here           #
#...............................#

$FindApp32 = FindApp32
$FindApp64 = FindApp64


if ((!$FindApp32) -and (!$FindApp64)) {
    return "No $AppName installation found in 32 bit or 64 bit registry. Please double check $AppName is present on the machine"
}

if ($FindApp32) {
    $CheckUpdates32 = CheckUpdate32
    if ($CheckUpdates32) {
        UpdateApp32
    }
} else { Write-Host "$AppName 32Bit not found, moving on to 64Bit..." }

if ($FindApp64) {
    $CheckUpdates64 = CheckUpdate64
    if ($CheckUpdates64) {
        UpdateApp64
    }
}  else { Write-Host "$AppName 64Bit not found..."}

#...............................#
#       END of your code        #
#################################
#  ----====== !!!!! ======----  #

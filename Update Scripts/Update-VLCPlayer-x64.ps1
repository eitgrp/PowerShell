param ([switch]$Install)
# Variables for pulling data from VLC latest release directory
$WebUrl = "https://download.videolan.org/pub/videolan/vlc/last/win64/"
$WebDir = iwr $WebUrl -usebasicparsing
$filename = (($WebDir.links |?{$_.href -match ".exe"}).outerHTML[0] | select-string -pattern '"(.*?)"').Matches.Value.Trim('"')
$LatestVLCVersion = [System.Version]::Parse(($filename | select-string -pattern '[0-9]\.[0-9]\.[0-9]*').Matches.Value)


# Setting the path to download the installer to
$InstallerPath = "C:\Source\Software\VLC-Installer.exe"

# What to do if -Install is specified
if ($Install) {
        # This try/catch is to ensure compatibility with both PWSH 5.1 and PWSH 7, as 7 needs -AllowInsecureRedirect which does not exist in 5.1.
    try {
        iwr ($WebUrl + $FileName) -OutFile $InstallerPath
    } catch {
        iwr ($WebUrl + $FileName) -OutFile $InstallerPath -AllowInsecureRedirect
    }
        Start-Process $InstallerPath -args "/L=1033 /S" -Wait
        Return "Successfully installed VLC $LatestVLCVersion"
    }
# Grabbing the currently installed version
try { 
    $CurrentVLCVersion = [System.Version]::Parse((get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | where DisplayIcon -like "*vlc*").DisplayVersion)
} Catch {
        throw "VLC does not seem to be installed. Please use the -Install switch to run a fresh install using this script"
}


# What to do if VLC is installed but out of date
if ($CurrentVLCVersion -lt $LatestVLCVersion) {
    # This try/catch is to ensure compatibility with both PWSH 5.1 and PWSH 7, as 7 needs -AllowInsecureRedirect which does not exist in 5.1.
    try {
        iwr ($WebUrl + $FileName) -OutFile $InstallerPath
    } catch {
        iwr ($WebUrl + $FileName) -OutFile $InstallerPath -AllowInsecureRedirect
    }

    Start-Process $InstallerPath -args "/L=1033 /S" -Wait

    $CurrentVLCVersion = [System.Version]::Parse((get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | where DisplayIcon -like "*vlc*").DisplayVersion)
    if ($CurrentVLCVersion -eq $LatestVLCVersion) {
        Return "Successfully updated VLC to version $CurrentVLCVersion."
    }
    ELSE {
        if ($CurrentVLCVersion) {
            Return "Attempted to update VLC to $LatestVLCVersion, however the installed version is $CurrentVLCVersion after the attempted update."
        } ELSE {
            Return "Cannot detect VLC Version after attempting update! It's likely that VLC is no longer installed due to a failed update."
        }
    }
} ELSE {
    Return "VLC is already update to date (Installed Version: $CurrentVLCVersion)"
}

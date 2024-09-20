#!ps - THIS SCRIPT DOES NOT WORK IN SCREENCONNECT - NEEDS A LOGGED IN ADMIN USER
#timeout=1000000

<#
        .SYNOPSIS
            Installs the new Microsoft Teams x86 on Windows Server 2019, including the Outlook Add-in
            and sets required registry keys. The new Teams is based on EdgeWebView Runtime and will
            be installed as well. With Server 2019, additional updates and .NET 4.8.x are required.

            You must set per User registry keys to load the Outlook Add-in via GPO, WEM etc. For GPO
            find the xml file at https://www.koetzingit.de with the article to this script.

        
        .Author
            Thomas@koetzingit.de
            https://www.koetzingit.de
        
        .LINKS
        
            https://learn.microsoft.com/en-us/microsoftteams/new-teams-vdi-requirements-deploy
            https://learn.microsoft.com/en-us/microsoftteams/troubleshoot/meetings/resolve-teams-meeting-add-in-issues
            https://docs.citrix.com/en-us/citrix-virtual-apps-desktops/multimedia/opt-ms-teams.html
            
                        
        .NOTES
            - Sources are downloaded into the script location, make sure its writeable.
            - You must run the script as administrator but will be chechked by the script.
            - You need free internet access, because the script downloads the required sources.
            - If asked, you must install the PendingReboots Powershell module



        .Version
        - 1.0 Creation 04/10/24
        - 1.1 Include download of sources
        - 1.2 Check for .NET Framework and pending reboots
        - 1.3 Alternatve download because of dynmaic content for the nativ utility
        - 1.4 Extracting the MSU package to speedup the installation

        
    #>

Write-Host "Upgrade to Teams(New)"
#
# Set install path were the script is located
#
$InstallPath = (Get-Location).Path
$InstallPath = "C:\Source\Software\Teams(New)"
if (!(Test-Path $InstallPath -PathType Container)) {
    $Result = New-Item -ItemType Directory -Force -Path $InstallPath
}
[System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;


#
# Check Admin function
#
Function Check-RunAsAdministrator()
{
  #Get current user context
  $CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  
  #Check user is running the script is member of Administrator Group
  if($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
  {
       Write-host "...Script is running with Administrator privileges!"
  }
  else
    {
       #Create a new Elevated process to Start PowerShell
       $ElevatedProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
 
       # Specify the current script path and name as a parameter
       $ElevatedProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"
 
       #Set the Process to elevated
       $ElevatedProcess.Verb = "runas"
 
       #Start the new elevated process
       [System.Diagnostics.Process]::Start($ElevatedProcess)
 
       #Exit from the current, unelevated, process
       Exit
 
    }
}

# 
# Check Script is running with Elevated Privileges
#
Check-RunAsAdministrator | Out-Null


# 
# Check .NET Framework Version
#
$NetVersion = (Get-ItemProperty "HKLM:Software\Microsoft\NET Framework Setup\NDP\v4\Full").Version
if ($NetVersion -ge 4.8){

#
# Download and install Windows Update kb5035849
#
#Start-BitsTransfer -Source 'https://catalog.s.download.windowsupdate.com/c/msdownload/update/software/secu/2024/03/windows10.0-kb5035849-x64_eb960a140cd0ba04dd175df1b3268295295bfefa.msu' -Destination $InstallPath -Description "Download Windows Update KB5035849"
#Write-Host "`nExtract msu file to speedup the installtion of the Windoes Update`n"
#Start-Process "expand.exe" -ArgumentList @("-f:* ""$InstallPath\windows10.0-kb5035849-x64_eb960a140cd0ba04dd175df1b3268295295bfefa.msu"" $InstallPath") -Wait -NoNewWindow

#Write-Host "`nInstall Windows Update kb5035849. This takes somae time, 15min. Please wait. If reboot is required, say No and reboot after the script finished.`n"
#Add-WindowsPackage -Online -PackagePath "$InstallPath\ssu-17763.5568-x64.cab" -LogPath "$InstallPath\ssu-17763.5568-x64.log" -PreventPending -NoRestart -WarningAction SilentlyContinue | Out-Null
#Add-WindowsPackage -Online -PackagePath "$InstallPath\Windows10.0-KB5035849-x64.cab" -LogPath "$InstallPath\Windows10.0-KB5035849-x64.log" -PreventPending -NoRestart -WarningAction SilentlyContinue | Out-Null

#
# Download and install Teams VDI Classic at current release for machine-wide to come up to most current release
(New-Object Net.WebClient).DownloadFile("https://statics.teams.cdn.office.net/production-windows-x64/1.7.00.21751/Teams_windows_x64.msi","$InstallPath\MSTeamsClassic-1.7.msi")
Write-Host "...Updating MS Teams Classic to last release"
Start-Process "msiexec.exe" -ArgumentList @("/I ""$InstallPath\MSTeamsClassic-1.7.msi""","/qn","/l*v $InstallPath\TeamsClassicUpdate.log","/Passive","OPTIONS=""noAutoStart=true""","ALLUSER=1 ALLUSERS=1") -Wait

Write-Host "...waiting 45 seconds timeout for the Teams Classic update package to fully register."
Start-Sleep -Seconds 45
Write-Host ".....continuing"


# Remove all Teams Machine-Wide Installers
Write-Host "Removing Teams Machine-wide Installer"
## Get all subkeys and match the subkey that contains "Teams Machine-Wide Installer" DisplayName.
$registryPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$MachineWide = Get-ItemProperty -Path $registryPath | Where-Object -Property DisplayName -eq "Teams Machine-Wide Installer"

if ($MachineWide) {
    ForEach ($TMWinstaller in $MachineWide) {
        Write-Host ".....removing ""$($TMWInstaller.PSChildName)"""
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/x ""$($TMWInstaller.PSChildName)"" /qn" -NoNewWindow -Wait
    }
}
else {
    Write-Host "Teams Machine-Wide Installer not found"
}


#
# Set Appx Keyes to not block the teams installation
#
Write-Host "...Set Appx Keys"
Start-Process "reg.exe" -ArgumentList @("add HKLM\Software\Policies\Microsoft\Windows\Appx /v AllowAllTrustedApps /t REG_DWORD /d 0x00000001 /f") -Wait -NoNewWindow | Out-Null
Start-Process "reg.exe" -ArgumentList @("add HKLM\Software\Policies\Microsoft\Windows\Appx /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 0x00000001 /f") -Wait -NoNewWindow | Out-Null
Start-Process "reg.exe" -ArgumentList @("add HKLM\Software\Policies\Microsoft\Windows\Appx /v BlockNonAdminUserInstall /t REG_DWORD /d 0x00000000 /f") -Wait -NoNewWindow | Out-Null


#
# Enable feature Overwrite
#
Write-Host "...Enable Feature Overwrite"
Start-Process "reg.exe" -ArgumentList @("add HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides /v 191176410 /t REG_DWORD /d 0x00000001 /f") -Wait -NoNewWindow | Out-Null

#
# Install MS Teams native utility
#
#Start-BitsTransfer -Source 'https://statics.teams.cdn.office.net/evergreen-assets/DesktopClient/MSTeamsNativeUtility.msi'  -Destination $InstallPath -Description "Download MS Teams Nativ Utility"
(New-Object Net.WebClient).DownloadFile("https://statics.teams.cdn.office.net/evergreen-assets/DesktopClient/MSTeamsNativeUtility.msi","$InstallPath\MSTeamsNativeUtility.msi")
Write-Host "...Install MS Teams native utility"
Start-Process "msiexec" -ArgumentList @("/i ""$InstallPath\MSTeamsNativeUtility.msi""","/qn","/norestart ALLUSERS=1""") -Wait

#
# Install EdgeWebView Runtime (x64)
#
# Start-BitsTransfer -Source 'https://go.microsoft.com/fwlink/?linkid=2124701' -Destination "$InstallPath\MicrosoftEdgeWebView2RuntimeInstallerX64.exe" -Description "Download latest EdgeWebView Runtime"
#(New-Object Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2124701", "$InstallPath\MicrosoftEdgeWebView2RuntimeInstallerX64.exe")
#Write-Host "...Install EdgeWebView Runtime. Please wait."
#Start-Process -wait -FilePath "$InstallPath\MicrosoftEdgeWebView2RuntimeInstallerX64.exe" -Args "/silent /install"

#
# Install EdgeWebView Runtime (x86)
#
# Start-BitsTransfer -Source 'https://go.microsoft.com/fwlink/?linkid=2124701' -Destination "$InstallPath\MicrosoftEdgeWebView2RuntimeInstallerX64.exe" -Description "Download latest EdgeWebView Runtime"
(New-Object Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2099617", "$InstallPath\MicrosoftEdgeWebView2RuntimeInstallerX86.exe")
Write-Host "...Install EdgeWebView Runtime. Please wait."
Start-Process -wait -FilePath "$InstallPath\MicrosoftEdgeWebView2RuntimeInstallerX86.exe" -Args "/silent /install"


#
# Install new Teams (x64)
#
#Start-BitsTransfer -Source 'https://go.microsoft.com/fwlink/?linkid=2196106' -Destination "$InstallPath\MSTeams-x64.msix" -Description "Download latest Microsoft teams version"
#(New-Object Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2196106", "$InstallPath\MSTeams-x64.msix")
#Write-Host "...Install Teams (New)"
#Start-Process -wait -NoNewWindow -FilePath DISM.exe -Args "/Online /Add-ProvisionedAppxPackage /PackagePath:$InstallPath\MSTeams-x64.msix /SkipLicense"


#
# Install new Teams (x86)
#
(New-Object Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2196060", "$InstallPath\MSTeams-x86.msix")
Write-Host "...Install Teams (New)"
Start-Process -wait -NoNewWindow -FilePath DISM.exe -Args "/Online /Add-ProvisionedAppxPackage /PackagePath:$InstallPath\MSTeams-x86.msix /SkipLicense"


#
# Time to fully register MSIX package
#
Write-Host "...waiting 45 seconds timeout for the MSIX package to fully register."
Start-Sleep -Seconds 45
Write-Host ".....continuing"

# Create shortcut (All Users Desktop
$TargetFile = "shell:appsFolder\MSTeams_8wekyb3d8bbwe!MSTeams"
$DesktopPath = [Environment]::GetFolderPath("CommonDesktopDirectory")
$ShortcutFile = "$DesktopPath\Teams.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()
$Shortcut = $Null
# and to Shared Start Menu
$DesktopPath = [Environment]::GetFolderPath("CommonStartMenu")
$ShortcutFile = "$DesktopPath\Teams.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()
$Shortcut = $Null

#
# Set Registry values for VDI and Citrix
#
Write-Host "...Set registry keys for VDI and Citrix."
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Teams" -Force | Out-Null
New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Teams" -Name "disableAutoUpdate" -Type dword  -Value 1 -force | Out-Null
New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Teams" -Name "IsWVDEnvironment" -Type dword  -Value 1 -force | Out-Null
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Citrix\WebSocketService" -Force | Out-Null
New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Citrix\WebSocketService" -Name "ProcessWhitelist" -Type MultiString  -Value "msedgewebview2.exe" -force | Out-Null


#
# Install and register MS Teams Outlook Add-In

Write-Host "...Install Microsoft Teams Add-in for Outlook."
$MSTappx = (Get-AppxPackage | Where-Object -Property Name -EQ -Value MSTeams)
$MSTappVer = $MSTappx.Version
$MSTappxPath = $MSTappx.InstallLocation
 
# x64
# $MSIname = "MicrosoftTeamsMeetingAddinInstaller.msi"

# x86
$MSIname = "MicrosoftTeamsMeetingAddinInstallerx86.msi"

$MSTAddinMSI = "$MSTappxPath\$MSIName"
$applockerinfo = (Get-AppLockerFileInformation -Path $MSTAddinMSI | Select -ExpandProperty Publisher)
$MSTbinVer = $applockerinfo.BinaryVersion
$targetDir = "C:\Program Files (x86)\Microsoft\TeamsMeetingAddin\$MSTbinVer"

#
# Pre-creation of the log file and folder.
#
New-Item -ItemType Directory -Path "C:\Program Files (x86)\Microsoft\TeamsMeetingAddin" -Force | Out-Null
New-Item -ItemType File  "C:\Program Files (x86)\Microsoft\TeamsMeetingAddin\MSTMeetingAddin.log" -Force | Out-Null

Start-Process "msiexec" -ArgumentList @("/i ""$MSTAddinMSI""","/qn","/norestart ALLUSERS=1 TARGETDIR=""$targetDir"" /L*V ""C:\Program Files (x86)\Microsoft\TeamsMeetingAddin\MSTMeetingAddin.log""") -Wait
Start-Process "c:\windows\System32\regsvr32.exe" -ArgumentList @("/s","/n","/i:user ""$targetDir\x64\Microsoft.Teams.AddinLoader.dll""")  -wait

Write-Host "`nFinished! Reboot, if required by the Windows Udpate!`n"

}
 else
{
# 
# Import module
#
if ((Get-Module -Name "PendingReboot")) {
   
}
else {
   Install-Module PendingReboot -Confirm:$False -Force
}

# 
# Check for pendig reboots otherwise .NET Framework 4.8 will not install.
#
$PendReboot= Test-PendingReboot -SkipConfigurationManagerClientCheck
if ($PendReboot -eq "true") { 
  Write-Host "There is a pending reboot. Reboot the system first and run the script again!"
 } else { 

	#
	# Download and install .NET Framework 4.8
	#
	Start-BitsTransfer -Source 'https://go.microsoft.com/fwlink/?linkid=2088631' -Destination "$InstallPath\ndp48-x86-x64-allos-enu.exe" -Description "Download .NET Framework 4.8.x, required for the Outlook Add-in"
	Write-Host "...Install .NET Framework 4.8, this can take some time."
	Start-Process "$InstallPath\ndp48-x86-x64-allos-enu.exe" -ArgumentList @("/q /norestart /ChainingPackage ADMINDEPLOYMENT") -Wait

	#
	# Download and install Windows Update kb5035849
	#
	#Start-BitsTransfer -Source 'https://catalog.s.download.windowsupdate.com/c/msdownload/update/software/secu/2024/03/windows10.0-kb5035849-x64_eb960a140cd0ba04dd175df1b3268295295bfefa.msu' -Destination $InstallPath -Description "Download Windows Update KB5035849"
	#Write-Host "`nExtract msu file to speedup the installtion of the Windoes Update`n"
	#Start-Process "expand.exe" -ArgumentList @("-f:* ""$InstallPath\windows10.0-kb5035849-x64_eb960a140cd0ba04dd175df1b3268295295bfefa.msu"" $InstallPath") -Wait -NoNewWindow

	#Write-Host "`nInstall Windows Update kb5035849. This takes somae time, 15min. Please wait. If reboot is required, say No and reboot after the script finished.`n"
	#Add-WindowsPackage -Online -PackagePath "$InstallPath\ssu-17763.5568-x64.cab" -LogPath "$InstallPath\ssu-17763.5568-x64.log" -PreventPending -NoRestart -WarningAction SilentlyContinue | Out-Null
	#Add-WindowsPackage -Online -PackagePath "$InstallPath\Windows10.0-KB5035849-x64.cab" -LogPath "$InstallPath\Windows10.0-KB5035849-x64.log" -PreventPending -NoRestart -WarningAction SilentlyContinue | Out-Null


	#
	# Set Appx Keyes to not block the teams installation
	#
	Write-Host "...Set Appx Keys"
	Start-Process "reg.exe" -ArgumentList @("add HKLM\Software\Policies\Microsoft\Windows\Appx /v AllowAllTrustedApps /t REG_DWORD /d 0x00000001 /f") -Wait -NoNewWindow | Out-Null
	Start-Process "reg.exe" -ArgumentList @("add HKLM\Software\Policies\Microsoft\Windows\Appx /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 0x00000001 /f") -Wait -NoNewWindow | Out-Null
	Start-Process "reg.exe" -ArgumentList @("add HKLM\Software\Policies\Microsoft\Windows\Appx /v BlockNonAdminUserInstall /t REG_DWORD /d 0x00000000 /f") -Wait -NoNewWindow | Out-Null


	#
	# Enable feature Overwrite
	#
	Write-Host "...Enable Feature Overwrite"
	Start-Process "reg.exe" -ArgumentList @("add HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides /v 191176410 /t REG_DWORD /d 0x00000001 /f") -Wait -NoNewWindow | Out-Null

	#
	# Install MS Teams native utility
	#
	#Start-BitsTransfer -Source 'https://statics.teams.cdn.office.net/evergreen-assets/DesktopClient/MSTeamsNativeUtility.msi'  -Destination $InstallPath -Description "Download MS Teams Nativ Utility"
	(New-Object Net.WebClient).DownloadFile("https://statics.teams.cdn.office.net/evergreen-assets/DesktopClient/MSTeamsNativeUtility.msi","$InstallPath\MSTeamsNativeUtility.msi")
	Write-Host "...Install MS Teams native utility"
	Start-Process "msiexec" -ArgumentList @("/i ""$InstallPath\MSTeamsNativeUtility.msi""","/qn","/norestart ALLUSERS=1""") -Wait

	#
	# Install EdgeWebView Runtime (x64)
	#
	# Start-BitsTransfer -Source 'https://go.microsoft.com/fwlink/?linkid=2124701' -Destination "$InstallPath\MicrosoftEdgeWebView2RuntimeInstallerX64.exe" -Description "Download latest EdgeWebView Runtime"
	#(New-Object Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2124701", "$InstallPath\MicrosoftEdgeWebView2RuntimeInstallerX64.exe")
	#Write-Host "...Install EdgeWebView Runtime. Please wait."
	#Start-Process -wait -FilePath "$InstallPath\MicrosoftEdgeWebView2RuntimeInstallerX64.exe" -Args "/silent /install"

	#
	# Install EdgeWebView Runtime (x86)
	#
	# Start-BitsTransfer -Source 'https://go.microsoft.com/fwlink/?linkid=2124701' -Destination "$InstallPath\MicrosoftEdgeWebView2RuntimeInstallerX64.exe" -Description "Download latest EdgeWebView Runtime"
	(New-Object Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2099617", "$InstallPath\MicrosoftEdgeWebView2RuntimeInstallerX86.exe")
	Write-Host "...Install EdgeWebView Runtime. Please wait."
	Start-Process -wait -FilePath "$InstallPath\MicrosoftEdgeWebView2RuntimeInstallerX86.exe" -Args "/silent /install"


	#
	# Install new Teams (x64)
	#
	#Start-BitsTransfer -Source 'https://go.microsoft.com/fwlink/?linkid=2196106' -Destination "$InstallPath\MSTeams-x64.msix" -Description "Download latest Microsoft teams version"
	#(New-Object Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2196106", "$InstallPath\MSTeams-x64.msix")
	#Write-Host "...Install Teams (New)"
	#Start-Process -wait -NoNewWindow -FilePath DISM.exe -Args "/Online /Add-ProvisionedAppxPackage /PackagePath:$InstallPath\MSTeams-x64.msix /SkipLicense"


	#
	# Install new Teams (x86)
	#
	(New-Object Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2196060", "$InstallPath\MSTeams-x86.msix")
	Write-Host "...Install Teams (New)"
	Start-Process -wait -NoNewWindow -FilePath DISM.exe -Args "/Online /Add-ProvisionedAppxPackage /PackagePath:$InstallPath\MSTeams-x86.msix /SkipLicense"

	# Create shortcut (All Users Desktop
	$TargetFile = "shell:appsFolder\MSTeams_8wekyb3d8bbwe!MSTeams"
	$DesktopPath = [Environment]::GetFolderPath("CommonDesktopDirectory")
	$ShortcutFile = "$DesktopPath\Teams.lnk"
	$WScriptShell = New-Object -ComObject WScript.Shell
	$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
	$Shortcut.TargetPath = $TargetFile
	$Shortcut.Save()
	$Shortcut = $Null
	# and to Shared Start Menu
	$DesktopPath = [Environment]::GetFolderPath("CommonStartMenu")
	$ShortcutFile = "$DesktopPath\Teams.lnk"
	$WScriptShell = New-Object -ComObject WScript.Shell
	$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
	$Shortcut.TargetPath = $TargetFile
	$Shortcut.Save()
	$Shortcut = $Null

	#
	# Time to fully register MSIX package
	#
	Write-Host "...waiting 45 seconds timeout for the MSIX package to fully register."
	Start-Sleep -Seconds 45
	Write-Host ".....continuing"

	#
	# Set Registry values for VDI and Citrix
	#
	Write-Host "...Set registry keys for VDI and Citrix."
	New-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Teams" -Force | Out-Null
	New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Teams" -Name "disableAutoUpdate" -Type dword  -Value 1 -force | Out-Null
	New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Teams" -Name "IsWVDEnvironment" -Type dword  -Value 1 -force | Out-Null
	New-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Citrix\WebSocketService" -Force | Out-Null
	New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Citrix\WebSocketService" -Name "ProcessWhitelist" -Type MultiString  -Value "msedgewebview2.exe" -force | Out-Null


	#
	# Install and register MS Teams Outlook Add-In
	#
	Write-Host "...Install Microsoft Teams Add-in for Outlook."
	$MSTappx = (Get-AppxPackage | Where-Object -Property Name -EQ -Value MSTeams)
	$MSTappVer = $MSTappx.Version
	$MSTappxPath = $MSTappx.InstallLocation
	 
	# x64
	# $MSIname = "MicrosoftTeamsMeetingAddinInstaller.msi"

	# x86
	$MSIname = "MicrosoftTeamsMeetingAddinInstallerx86.msi"

	$MSTAddinMSI = "$MSTappxPath\$MSIName"
	$applockerinfo = (Get-AppLockerFileInformation -Path $MSTAddinMSI | Select -ExpandProperty Publisher)
	$MSTbinVer = $applockerinfo.BinaryVersion
	$targetDir = "C:\Program Files (x86)\Microsoft\TeamsMeetingAddin\$MSTbinVer"


	#
	# Pre-creation of the log file and folder.
	#
	New-Item -ItemType Directory -Path "C:\Program Files (x86)\Microsoft\TeamsMeetingAddin" -Force | Out-Null
	New-Item -ItemType File  "C:\Program Files (x86)\Microsoft\TeamsMeetingAddin\MSTMeetingAddin.log" -Force | Out-Null

	Start-Process "msiexec" -ArgumentList @("/i ""$MSTAddinMSI""","/qn","/norestart ALLUSERS=1 TARGETDIR=""$targetDir"" /L*V ""C:\Program Files (x86)\Microsoft\TeamsMeetingAddin\MSTMeetingAddin.log""") -Wait
	Start-Process "c:\windows\System32\regsvr32.exe" -ArgumentList @("/s","/n","/i:user ""$targetDir\x64\Microsoft.Teams.AddinLoader.dll""")  -wait

	Write-Host "`n Finished! Reboot, if required by the Windows Update!`n"

}


}


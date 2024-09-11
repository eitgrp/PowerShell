#!ps
#timeout=600000
## Install / Update 7-Zip
$Product="WinSCP"
$EvergreenName="WinSCP"
$EvergreenType="exe"  # msi or exe
$RestartRequired=$False

Import-Module Evergreen

#PREINSTALL CHECKS
Write-Host "Checking for existing installation of $Product here..."
$Prod = Get-WMIObject -Classname Win32_Product | Where-Object Name -Match $Product | Select-Object -First 1

# Look for installed apps
$Apps=@()
$Apps+=Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" # 32 Bit
$Apps+=Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"             # 64 Bit
$Prod=$Apps | Where-Object { $_.DisplayName -match $Product }

Write-Output "    $($Prod.DisplayName) v$($Prod.DisplayVersion) - Installed: $($Prod.InstallDate)"

#Get the current architecture
If ($Prod) {
    If ($($Prod.DisplayName) -match '64') {
        $targetarchitecture = 'x64'
    } else {
        $targetarchitecture = 'x86'
    }

    # Get the current release for the selected architecture
    $evergreenapp = get-evergreenapp -Name $EvergreenName | where-object {$_.Architecture -eq $targetarchitecture -and $_.Type -eq $EvergreenType } | Select-Object -First 1
    [version]$ProductVersion = [version]$evergreenapp.Version
    [version]$InstalledVersion = [version]$Prod.DisplayVersion

    If ([version]$InstalledVersion -ge [version]$ProductVersion) {
        Write-Host "    PREINSTALL CHECK: This product is already installed and at (or above) the version installed by this script, no action to take."
        Throw
    } elseif ([version]$InstalledVersion -lt [version]$ProductVersion) {
        Write-Host "   PREINSTALL CHECK: This product is already installed here but at a lower release ($InstalledVersion) than the current version ($ProductVersion), installer will execute"
    }
} else {
    Write-Host "    PREINSTALL CHECK: This product is not yet installed here, installer will exit."
    Throw
}

# check if this is an RDS server
If ((Get-WindowsFeature RDS-RD-Server).Installed) {
    $rds = $true
}

Write-Host "Updating $Product ($InstalledVersion) to $ProductVersion..."

$InstallerPath="C:\Source\Software\$Product"
If (!(Test-Path -Path $InstallerPath -PathType Container)) {
	New-Item -ItemType Directory -Force -Path $InstallerPath
}

#Download the install package
$DownloadPackage=$evergreenapp.URI
$InstallerPackage="$InstallerPath\$(Split-Path -Path $DownloadPackage -Leaf)"
[int]$Downloads=1

$DownloadSuccessful=$false
While ($true -and ($Downloads -lt 10)) {
    Write-Host "    Download attempt no. $Downloads - $DownloadPackage"
    Invoke-WebRequest -URI $DownloadPackage -OutFile $InstallerPackage
    [int]$Downloads = $Downloads+1

    If (((Get-Item $Installerpackage).Length/1024000) -gt 5) { 
        $DownloadSuccessful=$true
        Write-Host "        SUCCESS"
        Break #Succesful, leave loop
    } Else {
        $evergreenapp = get-evergreenapp -Name $EvergreenName | where-object {$_.Architecture -eq $targetarchitecture -and $_.Type -eq $EvergreenType } | Select-Object -First 1
        $DownloadPackage=$evergreenapp.URI
        Write-Host "        FAILED"
    }
}

If ($DownloadSuccessful -eq $false) {
    Write-Host "Download from Sourceforge has failed after 10 attempts, you may need to try again later"
    Throw
}

If (Test-Path -Path $InstallerPackage -PathType Leaf) {
	Write-Host "    Download completed, unpacking for installation..."
#    Expand-Archive -Path $InstallerPackage -DestinationPath $InstallerPath\$Product-$ProductVersion -Force
} else {
	Write-Host "    Download failed"
	Throw
}

# Test for installer file/executable
$Installer=$InstallerPackage
# $InstallMSI=$InstallerPackage
If (Test-Path $Installer -PathType Leaf) {
     If ($rds) {
        Start-Process 'change.exe' -ArgumentList "user /install" -NoNewWindow -Wait
     }
     $logfile = "$InstallerPath\$Product-$($evergreenapp.Architecture).log"
#    Start-Process "msiexec.exe" -ArgumentList  "/i $Installer /qn /l*v $logfile"
     Start-Process $Installer -ArgumentList "/VERYSILENT /LOG=$logfile /ALLUSERS /NORESTART" -NoNewWindow -Wait
     If ($rds) {
        Start-Process 'change.exe' -ArgumentList "user /execute" -NoNewWindow -Wait
     }
} else {
    Write-Host "    No installer found in install package - exiting."
}

If ($RestartRequired) {
    Write-Host "Install of $Product v$ProductVersion has completed, a restart is required to complete installation"
} else {
    Write-Host "Install of $Product v$ProductVersion has completed"
}

$Apps=@()
$Apps+=Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" # 32 Bit
$Apps+=Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"             # 64 Bit
$ProdCheck=$Apps | Where-Object { $_.DisplayName -match $Product }
[version]$UpdatedVersion = [version]$ProdCheck.DisplayVersion
Write-Output "This device now reports that $($ProdCheck.DisplayName) v$($ProdCheck.DisplayVersion) is installed: $($ProdCheck.InstallDate)"
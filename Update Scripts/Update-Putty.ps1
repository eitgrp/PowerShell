#!ps
#timeout=600000
## Install / Update 7-Zip
$Product="Putty"
$EvergreenName="Putty"
$EvergreenArchitecture=
$RestartRequired=$False

Import-Module Evergreen

#PREINSTALL CHECKS
Write-Host "Checking for existing installation of $Product here..."

# Look for installed apps
$Apps=@()
$Apps+=Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" # 32 Bit
$Apps+=Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"             # 64 Bit
$Prod=$Apps | Where-Object { $_.DisplayName -match $Product }

Write-Output "    $($Prod.Name) v$($Prod.Version) - Installed: $($Prod.InstallDate)"

#Get the current architecture
If ($Prod) {
    If ($($Prod.Name) -match '64') {
        $targetarchitecture = 'x64'
    } else {
        $targetarchitecture = 'x86'
    }

    # Get the current release for the selected architecture
    $evergreenapp = get-evergreenapp -Name $EvergreenName | where-object {$_.Architecture -eq $targetarchitecture -and $_.Type -eq 'msi'} | Select-Object -First 1
    [version]$ProductVersion = [version]$evergreenapp.Version

    If ($([version]$Prod.Version) -ge [version]$ProductVersion) {
        Write-Host "    PREINSTALL CHECK: This product is already installed and at (or above) the version installed by this script, no action to take."
        Throw
    } elseif ($([version]$Prod.Version) -lt [version]$ProductVersion) {
        Write-Host "   PREINSTALL CHECK: This product is already installed here but at a lower release than the current version ($ProductVersion), installer will execute"
    }
} else {
    Write-Host "    PREINSTALL CHECK: This product is not yet installed here, installer will exit."
    Throw
}

# check if this is an RDS server
If ((Get-WindowsFeature RDS-RD-Server).Installed) {
    $rds = $true
}


Write-Host "Updating $Product to $ProductVersion..."

$InstallerPath="C:\Source\Software\$Product"
If (!(Test-Path -Path $InstallerPath -PathType Container)) {
	New-Item -ItemType Directory -Force -Path $InstallerPath
	}

#Download the install package
$DownloadPackage = $evergreenapp.URI
$InstallerPackage = "$InstallerPath\$(Split-Path -Path $DownloadPackage -Leaf)"
Invoke-WebRequest -URI $DownloadPackage -OutFile $InstallerPackage

If (Test-Path -Path $InstallerPackage -PathType Leaf) {
	Write-Host "    Download completed, unpacking for installation..."
#    Expand-Archive -Path $InstallerPackage -DestinationPath $InstallerPath\$Product-$ProductVersion -Force
} else {
	Write-Host "    Download failed"
	Throw
}

# Test for installer file/executable
# $InstallEXE="$InstallerPath\$Product-$ProductVersion\??.exe"
$InstallMSI=$InstallerPackage
If (Test-Path $InstallMSI -PathType Leaf) {
#    Write-Host "    Install package contains installer - beginning installation..."
#    Start-Process $InstallEXE -ArgumentList "/quiet /norestart" -NoNewWindow -Wait
     If ($rds) {
        Start-Process 'change.exe' -ArgumentList "user /install" -NoNewWindow -Wait
     }
     $logfile = "$InstallerPath\$Product-$($evergreenapp.Architecture).log"
     Start-Process "msiexec.exe" -ArgumentList  "/i $InstallMSI /qn /l*v $logfile" -NoNewWindow -Wait
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

# Look for installed apps
$Apps=@()
$Apps+=Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" # 32 Bit
$Apps+=Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"             # 64 Bit
$ProdCheck=$Apps | Where-Object { $_.DisplayName -match $Product }

[version]$UpdatedVersion = $evergreenapp.Version -split '-',0,1 | Select-object -First 1
Write-Output "This device now reports that $($ProdCheck.Name) v$($ProdCheck.Version) is installed: $($ProdCheck.InstallDate)"
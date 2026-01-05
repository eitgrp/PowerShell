<# 

This is a rewrite of the current script to make it more reliable and maintainable,  I aim to get this working for multiple versions of WinServ.  as well.

aims of the script:

    Uninstall broken installation
    clear any temp and left over files
    download the machine-wide installer
    install the new version
    verify the installation.

#>

$testLogfile = test-path "C:\Source\Log-file.txt"
$testSource = test-path "C:\Source"
$log = "C:\Source\Log-file.txt"

if($testLogfile -eq $false){
    if($testSource -eq $false){
        New-Item -ItemType Directory -Path "C:\" -Name "Source"
    }
    new-item -Path "C:\Source" -ItemType File -Name "Log-file.txt"
}

Start-Transcript -NoClobber -Append -Path "C:\Source\Log-file.txt"

Uninstall-BrokenTeams

$CompArch = (get-ciminstance -ClassName Win32_OperatingSystem).OSArchitecture

if($CompArch -like "*32*"){
    Install-TeamsOn2019_32Bit
}else{
    Install-TeamsOn2019_64Bit
}

function Install-TeamsOn2019_32Bit {
    
}

function Install-TeamsOn2019_64Bit {
    
}

function Uninstall-BrokenTeams {
    "$(get-date) - uninstalling teams" | Add-Content $log
    try {
        Get-AppxPackage | where-object {$_.name -like "*teams*"} | Remove-AppxPackage -ErrorAction Stop
    }
    catch {
        "unable to uninstall teams with remove-appxpackage" | Add-Content $log
    }
}
<# 

This is a rewrite of the current script to make it more reliable and maintainable,  I aim to get this working for multiple versions of WinServ.  as well.

aims of the script:

    Uninstall broken installation
    clear any temp and left over files
    download the machine-wide installer
    install the new version
    verify the installation.

#>

##########################################################################################

# create the required logging files to makes sure that errors can be properly reported.

$testLogfile = test-path "C:\Source\Log-file.txt"
$testSource = test-path "C:\Source"
$log = "C:\Source\Log-file.txt"

if(!($testLogfile)){
    if(!($testSource)){
        New-Item -ItemType Directory -Path "C:\" -Name "Source"
    }
    new-item -Path "C:\Source" -ItemType File -Name "Log-file.txt"
}

Start-Transcript -NoClobber -Append -Path "C:\Source\Log-file.txt"

#########################################################################################

# create the prerequisite variables and folders for the script.

if(!(test-path "C:\Source\Software")){
    new-item -Path "C:\Source" -ItemType Directory -Name "Software"
}

$InstallPath = "C:\Source\Software" # Specifies the install path in the software 
$downloader = New-Object net.WebClient # create a web client that we are able to use to download the files effectively without using iwr repeatedly (lowers used resources and speeds up downloads)
$CompArch = (get-ciminstance -ClassName Win32_OperatingSystem).OSArchitecture # query the computer architecture to apply the correct installation.

if($CompArch -like "*32*"){
    Install-TeamsOn2019_32Bit
}else{
    Install-TeamsOn2019_64Bit
}

function Install-TeamsOn2019_32Bit {
    
}

function Install-TeamsOn2019_64Bit {
    "$(get-date) - Downloading the Teams bootstrapper and the MSIX..." | Add-Content $log

    $downloader.DownloadFile("https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409","$InstallPath\teamsbootstrapper.exe") # downloads the bootstrapper exe
    $downloader.DownloadFile("https://go.microsoft.com/fwlink/?linkid=2196106","$InstallPath\MSTeams-x64.msix") # downloads the msix for the bootstrapper to deploy.

    "$(get-date) - Start the bootstrapper" | Add-Content $log

    Start-Process "$InstallPath\teamsbootstrapper.exe" -ArgumentList "-p -o `"$InstallPath\MSTeams-x64.msix`""

}

function Uninstall-BrokenTeams {
    "$(get-date) - uninstalling teams" | Add-Content $log
    try {
        Get-AppxPackage -online | where-object {$_.name -like "*teams*"} | Remove-AppxPackage -AllUsers -ErrorAction Stop
        Get-AppxPackage *teams* -AllUsers | Remove-AppxPackage -AllUsers
    }
    catch {
        "unable to uninstall teams with remove-appxpackage" | Add-Content $log
    }
    "$(get-date) - Removing temp files"  | Add-Content $log
    try {
        Get-ChildItem "C:\Windows\Temp\" -Recurse -ErrorAction SilentlyContinue| Remove-Item -Recurse -Force -ErrorAction Inquire
        Get-ChildItem "C:\ProgramData\Temp\" -Recurse -ErrorAction SilentlyContinue| Remove-Item -Recurse -Force -ErrorAction Inquire
    }
    catch {
        "$(get-date) - unable to remove temp items" | Add-Content $log
    } 
    "$(get-date) - Removing Teams via ciminstance class" | Add-Content $log
    try {
        (get-ciminstance -class win32_product | Where-Object {$_.name -match "teams"}).uninstall
    }
    catch {
        "$(get-date) - unable to remove win32 class item" | add-content $log
    }
    "$(get-date) - removing final files and regkeys"
    try {
        Remove-Item "C:\Program Files (x86)\Microsoft\Teams" -Recurse -Force -ErrorAction Inquire
        Remove-Item "HKLM:\SOFTWARE\Microsoft\Teams" -Recurse -Force -ErrorAction Inquire
    }
    catch {
        "$(get-date) - Unable to remove final files or Regkeys" | add-content $log
    }
}

# Get the .NET Versions web address for Manipulation during the script.

$dotnetVersionWebAddress = (((Invoke-WebRequest "https://dotnet.microsoft.com/en-us/download/dotnet/8.0" -usebasicparsing).links).href )

# Create Each Types (SDK, Runtime, ASP.NET, Desktop Runtime) top level Array

$runtimeVersionFull8 = ($dotnetVersionWebAddress | Select-String -Pattern 'runtime-\d.\d.\d+-windows-x64-installer').Matches.Value
$sdkVersionFull8 = ($dotnetVersionWebAddress | Select-String -Pattern 'sdk-\d.\d.\d+-windows-x64-installer').Matches.Value

# Create the Array that includes the version ending for each .NET installation Type

$runtimeVersionEnd = ((($runtimeVersionFull8 | select-string -Pattern '\d.\d.\d+').Matches.Value).Substring(4)) | Sort-Object {[int]$_} -Descending
$sdkVersionEnd = ((($sdkVersionFull8 | select-string -Pattern '\d.\d.\d+').Matches.Value).Substring(4)) | Sort-Object {[int]$_} -Descending  ## will be working on these later

# Get the installed .NET Versions

$installedVer = (dotnet --list-runtimes | select-string -pattern "\d.\d.\d+")

# Create the arrays for the different installed versions

$installedAspDotnet = @()
[string[]]$installedRuntimeDotnet = @()
## $installedSdkDotnet = @()  ###  Commented as will be working on this on a later version
$installedCoreDotnet = @()

# Sort the different installed .NET versions so that they are in variables for SDK, Runtime(inc. Desktop) and ASP.NET

foreach ($i in $installedVer) {
    if ($i -match "aspnetcore"){
        $installedAspDotnet += $i
    } elseif ($i -match "NETCore") {
        $installedCoreDotnet += $i
    } else {
        $installedRuntimeDotnet += $i
    }
}

# Get the version Numbers for the currently installed .NET versions.

[string[]]$installedAspDotnet = ($installedAspDotnet | select-string -pattern "\d.\d.\d+").Matches.Value
[string[]]$installedRuntimeDotnet = ($installedRuntimeDotnet | select-string -pattern "\d.\d.\d+").Matches.Value
## $installedSdkDotnet = ($installedSdkDotnet | select-string -pattern "\d.\d.\d+").Matches.Value  ###  Commented as will be working on this on a later version
[string[]]$installedCoreDotnet = ($installedCoreDotnet | select-string -pattern "\d.\d.\d+").Matches.Value

## Note:  Will need to work on handling .NET 8 vs .NET 9
# Create Arrays to hold the different Versions

[string[]]$installedAspDotnet8 = @()
[string[]]$installedRuntimeDotnet8 = @()
[string[]]$installedCoreDotnet8 = @()
[string[]]$installedAspDotnet9 = @()
[string[]]$installedRuntimeDotnet9 = @()
[string[]]$installedCoreDotnet9 = @()

### Check for .NET 8 or .NET 9

# Function for filtering .NET 8 vs .NET 9

function filterDotnetMajor {
    param (
        [System.Object[]]$installedDotnet, # Select which version of .NET (ASP.NET, runtime, core...)
        $filteredDotnet8, # Output Variable for .NET 8
        $filteredDotnet9 # Output Variable for .NET 8
    )
    $x=0
    foreach ($i in $installedDotnet) {
        Write-Output($i)
        $dotnetMajorVersion = $i | Where-Object($_.substring(0,3))
        if ($dotnetMajorVersion -eq "8.0"){
            $filteredDotnet8 += $installedDotnet  
        } else {
            $filteredDotnet9 += $installedDotnet 
        }
        $x++
        write-output($x)
    }
}

filterDotnetMajor($installedRuntimeDotnet, $installedRuntimeDotnet8, $installedRuntimeDotnet9)

write-output($installedRuntimeDotnet8)

# For ASP.NET

# foreach ($i in $installedAspDotnet) {
#     $dotnetMajorVersion = ($i.substring(0,3))
#     if ( $dotnetMajorVersion -eq "8.0"){
#         $installedAspDotnet8 += $i  
#     } else {
#         $installedAspDotnet9 += $i 
#     }
# }


# # For Runtime

# foreach ($i in $installedRuntimeDotnet) {
#     $dotnetMajorVersion = ($i.substring(0,3))
#     if ( $dotnetMajorVersion -eq "8.0"){
#         $installedRuntimeDotnet8 += $i  
#     } else {
#         $installedRuntimeDotnet9 += $i 
#     }
# }


# # For Core

# foreach ($i in $installedCoreDotnet) {
#     $dotnetMajorVersion = ($i.substring(0,3))
#     if ( $dotnetMajorVersion -eq "8.0"){
#         $installedCoreDotnet8 += $i  
#     } else {
#         $installedCoreDotnet9 += $i 
#     }
# }




# ##  Select the Latest install on the device and Put it into a new variable

# #$latestAspDotnet8 = $installedAspDotnet8.substring(4) | sort-object {[int]$_} -Descending 
# [string[]]$latestRuntimeDotnet8 = $installedRuntimeDotnet8.substring(4) | sort-object {[int]$_} -Descending 
# # $latestSdkDotnet      ###  Commented as will be working on this on a later version
# $latestCoreDotnet8 = $installedCoreDotnet8.substring(4) | sort-object {[int]$_} -Descending 

# $latestAspDotnet9 = $installedAspDotnet9.substring(4) | sort-object {[int]$_} -Descending 
# $latestRuntimeDotnet9 = $installedRuntimeDotnet9.substring(4) | sort-object {[int]$_} -Descending 
# #  $latestSdkDotnet      ###  Commented as will be working on this on a later version
# $latestCoreDotnet9 = $installedCoreDotnet9.substring(4) | sort-object {[int]$_} -Descending 

# # Check if the Latest version is newer than the one on the machine.

# write-output($latestRuntimeDotnet8)

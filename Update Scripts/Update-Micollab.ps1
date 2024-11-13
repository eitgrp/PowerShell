###############################################################################################################
# The first part is defining all the variables we need, this is the scoping/info gathering part of the script #
###############################################################################################################

# URL to download the new version from
$Url = "https://fileshare.bistech.co.uk/fileshare/mitel/micollab/micollab_pc_9.8.204.msi"

# The version thats in the URL (micollab_pc_9.8.204.msi)
# The System.Version is basically saying "This number is a product version", so Powershell compares it properly
$NewVersion = [System.Version]::Parse('9.8.204')

# "Get-WmiObject -Class Win32_Product" will return all apps installed
# I'm using a "where" statement to say "I only want apps where the apps ($_) name property (.name) equals (-eq) "Micollab""
$InstalledApp = Get-WmiObject -Class Win32_Product | where {$_.name -eq "micollab"}

# $InstalledApp.Version will select the "Version" property of the app we stored in the $InstalledApp variable above. (Like how I searched for it by looking at the .name property of the app)
# This will return the version as a string, so same command as above to tell it "this is a version number"
$InstalledVersion = [System.Version]::Parse($InstalledApp.Version)



####################################################################
# Now all the variables are defined, this is where the code begins #
####################################################################



# If the version number installed is less than (-lt) the new version, then do {whatever is in these curly brackets}
if ($InstalledVersion -lt $NewVersion) {

    # Createing a new folder in Source\Software called "Micollab" (And specifying its a folder with ItemType Directory)
    New-Item -Path "C:\Source\Software\" -Name "Micollab" -ItemType Directory

    # Making a HTTP(s) request to that URL, which leads to the file. Telling it to save the output as this file/location
    Invoke-WebRequest -uri $Url -OutFile "C:\Source\Software\MiCollab\MiCollab-9.8.204.msi"

    # Start a new process (msiexec) -args specifies the arguments, equivilent to putting "msiexec /i C:\source\micollab.msi /qn /norestart" in CMD/Powershell
    Start-Process msiexec -args "/i C:\Source\Software\MiCollab\MiCollab-9.8.204.msi /qn /norestart"

    # ELSE means, if the original if statement isn't true, do { this } in all other scenarios
} ELSE {

    # Return means "stop running here and output this message", no code will run beyond here (Except if it's in a function or loop, but that's not covered in this script)
    Return "No update required."

}

# Reusing this to check the version after the change

$InstalledApp = Get-WmiObject -Class Win32_Product | where {$_.name -eq "micollab"}

$InstalledVersion = [System.Version]::Parse(($InstalledApp).Version)

# Now it's been updated, the installed version should equal the new version defined earlier. -ne means not equal, so if the version numbers don't match, do this
if ($InstalledVersion -ne $NewVersion) {

    return "The installed version is not as expected after the upgrade!"

    # If the installed version isn't *not* equal to the new version, it must mean it is equal, so must've upgrade must've been successful.
    # these could be switched around, eg "if ($InstalledVersion -eq $NewVersion) {SUCCESS}, ELSE {SOMETHING WENT WRONG} (that would be a little more intuitive)
} ELSE {

    Return "Micollab has been successfully updated!"

}

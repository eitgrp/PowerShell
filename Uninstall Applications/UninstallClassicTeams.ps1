################################################################################
# MIT License
#
# Copyright (c) 2024 Microsoft and Contributors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# 
# Filename: UninstallClassicTeams
# Version: 1.1.3
# Description: Script to cleanup old teams and corresponding regkeys for all users on machine.
#################################################################################


$applicationDefinitions = @(
    @{
        Name="Teams"
        DisplayName="Teams"
        Publisher="Microsoft"
        Exe="teams"
        IDs=@(
            ### Array of product ids to look for - unimplemented
            "731F6BAA-A986-45A4-8936-7C3AAAAA760B",
            "{731F6BAA-A986-45A4-8936-7C3AAAAA760B}"
        )
        RegistryKeys=@(
            ### Array of registry keys to match
            ### If a registry entry starts with the hive name the match is performed using StartsWith() - case insensitive 'hkey_\FooBar...' == 'hkey_\foobar...'
            ### If a registry entry lacks the hive name then the match is performed using EndsWith() - case insensitive '...FooBar' == '...foobar'
            "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
        )
        CleanUp=@(
            ### Array of cleanup steps
            @{
                RunUninstall=$true
                RemoveRegistryKeys=$true
                RemoveDirectory=$true
            }
        )
    }
)

$ScriptResult = @{
    NumProfiles = 0
	NumApplicationsFound = 0
	NumApplicationsRemoved = 0
    FindApplicationProfilesLoadedSuccessfully = 0
	FindApplicationProfilesLoadedFailed = 0
    FindApplicationProfilesUnloadedSuccessfully = 0
	FindApplicationProfilesUnloadedFailed = 0
    FindApplicationInstallationFound = 0
	RemoveApplicationProfilesLoadedSuccessfully = 0
	RemoveApplicationProfilesLoadedFailed = 0
	RemoveApplicationNumProfilesUnloadedSuccessfully = 0
	RemoveApplicationProfilesUnloadedFailed = 0
	RemoveApplicationUninstallionPerformed = 0
	StaleFileSystemEntryDeleted = 0
	AppDataEntryDeleted = 0
	StaleRegkeyEntryDeleted = 0
	TeamsMeetingAddinDeleted = 0
	TeamsWideInstallerRunKeyDeleted = 0
	StaleUserAssociationRegkeyEntryDeleted = 0
}

# Function that creates the unique file path
function Get-UniqueFilename {
    param (
        [string]$BaseName,
        [string]$Extension = "txt",
        [string]$DateTimeFormat = "yyyyMMddHHmmss"
    )
    
    # Get the current date and time in the specified format
    $timestamp = (Get-Date).ToString($DateTimeFormat)
    
    # Combine the base name, timestamp, and extension
    $uniqueFilename = "$BaseName-$timestamp.$Extension"
    
    # Return the unique filename
    return $uniqueFilename
}

$Logfile = Get-UniqueFilename("$($ENV:SystemDrive)\Windows\Temp\Classic_Teams_Uninstallation")
 
function write-teams-log
{
   Param ([string]$LogString)
   $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
   $LogMessage = "$Stamp $LogString"
   Add-content $LogFile -value $LogMessage
}


# Function to find SID for user
function Get-SIDFromAlias {
    param (
        [string]$userAlias
    )
    
    try {
        # Create a NTAccount object from the user alias
        $ntAccount = New-Object System.Security.Principal.NTAccount($userAlias)
        
        # Translate NTAccount to SecurityIdentifier
        $sid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])
        
        # Output the SID
        return $sid.Value
    }
    catch {
        Write-Error "Failed to convert alias to SID: $_"
    }
}

# Function to find application installed as per specifications for all user profiles
function Find-WindowsApplication
{
    param(
        [Parameter(Mandatory)]
        [psobject[]]$ApplicationDefinitions = $null,
        [switch]$AllUsers
    )

        
    if (
        (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) -or
        (-not ([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")))
    )
    {
        write-teams-log "Warning: $($MyInvocation.MyCommand): Running without elevated permissions will reduce functionality"
    }


    write-teams-log "$($MyInvocation.MyCommand): Searching for software..."
    $installedSoftware = Get-WmiObject -Class Win32_Product -ErrorAction SilentlyContinue
    $installedApps = Get-AppXPackage -ErrorAction SilentlyContinue
    $installed32bitComponents = @(Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | % { Get-ItemProperty $_.PsPath } | Select *)
    $installed64bitComponents = @(Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | % { Get-ItemProperty $_.PsPath } | Select *)
    $systemEnvironment = $(Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -ErrorAction SilentlyContinue)
    $userComponents = @{}
    
    $foundApplicationList = @()
    $foundApplicationEntry = @{
        AppDefinition=$null
        Location=@{
            Software=@()
            Apps=@()
            Components=@{}
        }
        Found=$false
    }

    
    $componentSourceList = @{}

    $componentSourceList["SYSTEM"] = [psobject]@{
        Installed32BitComponents=$installed32bitComponents
        Installed64BitComponents=$installed64bitComponents
        Environment=$systemEnvironment
        RegFile=$null
        Username=$null
    }

    $componentSourceList["CURRENTUSER"] = [psobject]@{
        Installed32BitComponents=@(Get-ChildItem "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | % { Get-ItemProperty $_.PsPath } | Select *)
        Installed64BitComponents=@(Get-ChildItem "HKCU:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | % { Get-ItemProperty $_.PsPath } | Select *)
        Environment=$(Get-ItemProperty "HKCU:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -ErrorAction SilentlyContinue)
        RegFile=$null
        Username="$($env:USERNAME)"
    }

    if ($AllUsers)
    {
        write-teams-log "$($MyInvocation.MyCommand): Getting list of installed software for each user..."
        
        foreach ($userDirectory in @(Get-ChildItem "$($ENV:SystemDrive)\users" -ErrorAction SilentlyContinue))
        {
            if ($userDirectory -ne $null)
            {
                $userName = "$($userDirectory.Name.ToLower())"
				$ScriptResult.NumProfiles++
                
                # write-teams-log "$($MyInvocation.MyCommand): Looking at user $($username) profile..."
				# write-teams-log "$($MyInvocation.MyCommand): Looking at user profile..."

                $userComponents["$($userName)"] = [psobject]@{
                    Installed32BitComponents=$null
                    Installed64BitComponents=$null
                    Environment=$null
                    RegFile=$null
                    Username=$null
                }
                $componentSourceList["$($userName)"] = $userComponents["$($userName)"]

                $process = $null
                try
                {
                    $command = "`"REG LOAD `"`"HKLM\$($userName)`"`" `"`"$($userDirectory.FullName)\NTUSER.DAT`"`""
                    $process = Start-Process "$($env:ComSpec)" -ArgumentList @("/c","$($command)") -Wait -WindowStyle Hidden  -PassThru
                    if ($process.ExitCode -eq 0)
                    {
						### good
						$ScriptResult.FindApplicationProfilesLoadedSuccessfully++
                    } else
                    {
						### ungood
						$ScriptResult.FindApplicationProfilesLoadedFailed++
						write-teams-log "Warning: $($MyInvocation.MyCommand): Profile loading failed with exit code $($process.ExitCode)"
                    }
                }
                catch
                {
					### ignore
					$ScriptResult.FindApplicationProfilesLoadedFailed++
					write-teams-log "Warning: $($MyInvocation.MyCommand): Profile loading caught exception. An error occurred: $_"
                }
                $userRegistry = Get-Item "HKLM:\$($userName)" -ErrorAction SilentlyContinue
                if ($userRegistry -ne $null)
                {
                    $userComponents["$($userName)"].RegFile="$($userDirectory.FullName)\NTUSER.DAT"
                    $userComponents["$($userName)"].Environment=$(Get-ItemProperty "HKLM:\$($userName)\Environment" -ErrorAction SilentlyContinue)
                    $userComponents["$($userName)"].Installed32BitComponents=@(Get-ChildItem "HKLM:\$($userName)\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | % { Get-ItemProperty $_.PsPath } | Select *)
                    $userComponents["$($userName)"].Installed64BitComponents=@(Get-ChildItem "HKLM:\$($userName)\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | % { Get-ItemProperty $_.PsPath } | Select *)
                    $componentSourceList["$($userName)"] = $userComponents["$($userName)"]
					
					$process = $null
					try
					{
						$command = "`"REG UNLOAD `"`"HKLM\$($userName)`"`""
						$process = Start-Process "$($env:ComSpec)" -ArgumentList @("/c","$($command)") -Wait -WindowStyle Hidden  -PassThru
						if ($process.ExitCode -eq 0)
						{
							### good
							$ScriptResult.FindApplicationProfilesUnloadedSuccessfully++
						} else
						{
							### ungood
							$ScriptResult.FindApplicationProfilesUnloadedFailed++
							write-teams-log "$($MyInvocation.MyCommand): Profile unloading failed with exit code $($process.ExitCode)"
						}
					}
					catch
					{
						### ignore
						$ScriptResult.FindApplicationProfilesUnloadedFailed++
						write-teams-log "$($MyInvocation.MyCommand): Profile loading caught exception. An error occurred: $_"
					}
                }
            }
        }
    }

    foreach ($appDef in $ApplicationDefinitions)
    {
        if ($appDef -ne $null)
        {
            $foundApplicationEntry = @{
                AppDefinition=$appDef
                Location=@{
                    Software=@()
                    Apps=@()
                    Components=@{}
                    Files=@()
                }
                Found=$false
            }

            if ($appDef.RegistryKeys -ne $null)
            {
                if ($appDef.RegistryKeys.Count -gt 0)
                {
                    
                    ### search components
                    foreach ($componentSource in $componentSourceList.Keys)
                    {
                        ### search each location
                        $currentRegFile = $($componentSourceList["$($componentSource)"].RegFile)
                        $currentSource = $componentSource
                        $currentRegKeys = @()

                        if ($componentSourceList["$($componentSource)"] -ne $null)
                        {
                            if ($componentSourceList["$($componentSource)"].Installed32BitComponents -ne $null)
                            {
                                if ($componentSourceList["$($componentSource)"].Installed32BitComponents.Count -gt 0)
                                {
                                    $currentRegKeys += @($componentSourceList["$($componentSource)"].Installed32BitComponents)
                                }
                            }
                            if ($componentSourceList["$($componentSource)"].Installed64BitComponents -ne $null)
                            {
                                if ($componentSourceList["$($componentSource)"].Installed64BitComponents.Count -gt 0)
                                {
                                    $currentRegKeys += @($componentSourceList["$($componentSource)"].Installed64BitComponents)
                                }
                            }
                        }
                        
                        for ($c = 0; $c -lt $currentRegKeys.Count; $c++)
                        {
                            $regList = @($currentRegKeys[$c])
                            for ($x = 0; $x -lt $regList.Count; $x++)
                            {
                                $appRegKey = $($regList[$x].PSPath.Replace('Microsoft.PowerShell.Core\Registry::',''))

                                for ($r = 0; $r -lt $appDef.RegistryKeys.Count; $r++)
                                {
                            
                                    $foundEntry = $false
                                    if ($appDef.RegistryKeys[$r].StartsWith("HKEY_"))
                                    {
                                        if ($appRegKey.ToLower().StartsWith($appDef.RegistryKeys[$r].ToLower()))
                                        {
                                            ### found
                                            $foundEntry = $true
                                        }
                                    } else
                                    {
                                        if ($appRegKey.ToLower().EndsWith($appDef.RegistryKeys[$r].ToLower()))
                                        {
                                            ### found
                                            $foundEntry = $true
                                        }
                                    }
                            
                                    if ($foundEntry -eq $true)
                                    {                                    
                                        write-teams-log "$($MyInvocation.MyCommand): Found application '$($appDef.Name)', adding in found application list"

										$componentKey = "$($regList[$x].DisplayName)" + ":" + "$($currentSource)"
                                        if ($foundApplicationEntry.Location.Components["$($componentKey)"] -eq $null)
                                        {
											$ScriptResult.FindApplicationInstallationFound++
                                            $foundApplicationEntry.Location.Components["$($componentKey)"] = @{
                                                Component=$($regList[$x])
                                                ComponentSource=$($currentSource)
                                                RegistryKeys=@()
                                                RegFile=$currentRegFile
                                            }
											
											$foundApplicationEntry.Location.Components["$($componentKey)"].RegistryKeys += $appRegKey
											$foundApplicationEntry.Found = $true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if ($foundApplicationEntry -ne $null)
            {
                if ($foundApplicationEntry.Found -eq $true)
                {
                    $foundApplicationList += $foundApplicationEntry
                }
            }
        }
    }

    return @($foundApplicationList)
}


# Function to remove application from the machine for all user profiles
# If application is already running, process shall be killed
# Uninstallation for user profiles is done based on Uninstall string
function Remove-WindowsApplication
{
    param(
        [Parameter(Mandatory)]
        [psobject[]]$Applications = $null
    )

        
    if (
        (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) -or
        (-not ([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")))
    )
    {
        write-teams-log "Warning: $($MyInvocation.MyCommand): Running without elevated permissions will reduce functionality"
    }


    write-teams-log "$($MyInvocation.MyCommand): Removing application(s)..."
	write-teams-log "-------------------"
    
    $removedApplicationList = $null
    $removedApplicationEntry = @{
        AppDefinition=$null
        Successful=$false
        Error=$null
    }

    if ($Applications)
    {
        $removedApplicationList = @()

		for ($a = 0; $a -lt $Applications.Count; $a++)
		{
                if ($Applications[$a] -ne $null)
                {
                    
                    if ([string]::IsNullOrEmpty($Applications[$a].AppDefinition.Exe) -eq $false)
                    {
                        ### look for running process
                        $processList = @(Get-Process -Name $($Applications[$a].AppDefinition.Exe) -ErrorAction SilentlyContinue)
                        if ($processList -ne $null)
                        {
                            if ($processList.Count -gt 0)
                            {
                                write-teams-log "$($MyInvocation.MyCommand): Stopping existing processes..." 
                                @($processList).Kill()
                            }
                        }
                    }

                    if ($Applications[$a].Found -eq $true)
                    {
                        $appEntry = $Applications[$a]
                        
                        if ($appEntry.AppDefinition -ne $null)
                        {
                            if ($appEntry.AppDefinition.CleanUp -ne $null)
                            {
                                write-teams-log "$($MyInvocation.MyCommand): Removing application '$($appEntry.AppDefinition.Name)'..."
                                if ($appEntry.Location -ne $null)
                                {
									if (
										($appEntry.Location.Apps) -or 
										($appEntry.Location.Components.Keys) -or 
										($appEntry.Location.Software) -or
										($appEntry.Location.Files)
									)
									{
										$removedApplicationEntry = $null

										if ($appEntry.Location.Components.Keys.Count -gt 0)
										{
											foreach ($componentName in $appEntry.Location.Components.Keys)
											{
												$componentObj = $($appEntry.Location.Components["$($componentName)"])
												if ($componentObj -ne $null)
												{
													if ($componentObj.Component -ne $null)
													{
														# write-teams-log "$($MyInvocation.MyCommand): Removing component for user..."

														if ([string]::IsNullOrEmpty($componentObj.Component.InstallLocation) -eq $false)
														{
															### have install path
															$installDir = Get-Item "$($componentObj.Component.InstallLocation)" -ErrorAction SilentlyContinue
															if ($installDir -ne $null)
															{
																### have actual path
																if ($appEntry.AppDefinition.CleanUp.RunUninstall -eq $true)
																{
																	$uninstallCommand = "$($componentObj.Component.UninstallString)"

																	if ([string]::IsNullOrEmpty($componentObj.Component.QuietUninstallString) -eq $false)
																	{
																		$uninstallCommand = "$($componentObj.Component.QuietUninstallString)"
																	}

																	# write-teams-log "Uninstall command : $uninstallCommand"
																	if ([string]::IsNullOrEmpty($uninstallCommand) -eq $false)
																	{
																		### Run uninstall
																		write-teams-log "$($MyInvocation.MyCommand): Running component uninstall..."

																		Start-Process "$($env:ComSpec)" -ArgumentList @("/c","$($uninstallCommand)") -Verb RunAs -Wait -WindowStyle Hidden
																		$ScriptResult.RemoveApplicationUninstallionPerformed++
																	} else
																	{
																		write-teams-log "Warning: $($MyInvocation.MyCommand): Component has no uninstall command."
																	}
																}

																### remove app path
																if ($appEntry.AppDefinition.CleanUp.RemoveDirectory -eq $true)
																{
																	write-teams-log "$($MyInvocation.MyCommand): Removing component directories..."
																	$ignore = Remove-Item "$($installDir.FullName)" -Recurse -Force -ErrorAction SilentlyContinue
																}

															} else
															{
																write-teams-log "Warning: $($MyInvocation.MyCommand): Component install path can't be found."
															}
														}


														### remove registry key(s)
														if ($appEntry.AppDefinition.CleanUp.RemoveRegistryKeys -eq $true)
														{                                                                    
															$regUser = $componentObj.ComponentSource

															if ($componentObj.RegistryKeys -ne $null)
															{
																if ($componentObj.RegistryKeys.Count -gt 0)
																{
																	write-teams-log "$($MyInvocation.MyCommand): Removing component registry key(s)..."

																	if ($componentObj.RegFile -ne $null)
																	{
																		### Load user's registry file
																		$regFile = $componentObj.RegFile

																		try
																		{
																			$output = Start-Process "$($env:ComSpec)" -ArgumentList @("/c","""REG LOAD """"HKLM\$($regUser)"""" """"$($regFile)"""" 1>NUL 2>NUL") -Wait -WindowStyle Hidden  -PassThru
																			$ScriptResult.RemoveApplicationProfilesLoadedSuccessfully++
																		}
																		catch
																		{
																			### ignore
																			$ScriptResult.RemoveApplicationProfilesLoadedFailed++
																			write-teams-log "Warning: $($MyInvocation.MyCommand): Profile loading caught exception. An error occurred: $_"
																		}
																	}

																	### Remove registry key(s)
																	for ($r = 0; $r -lt $componentObj.RegistryKeys.Count; $r++)
																	{
																		$regKey = "$($componentObj.RegistryKeys[$r].Replace('Microsoft.PowerShell.Core\Registry::',''))"
																		$ignore = Remove-Item "registry::$($regKey)" -Recurse -Force -ErrorAction SilentlyContinue
																	}

																	if ($componentObj.RegFile -ne $null)
																	{                                                                    
																		### Unload user's registry file
																		try
																		{
																			$output = Start-Process "$($env:ComSpec)" -ArgumentList @("/c","""REG UNLOAD """"HKLM\$($userName)"""" 1>NUL 2>NUL") -Wait -WindowStyle Hidden
																			$ScriptResult.RemoveApplicationNumProfilesUnloadedSuccessfully++
																		}
																		catch
																		{
																			### ignore
																			$ScriptResult.RemoveApplicationProfilesUnloadedFailed++
																			write-teams-log "Warning: $($MyInvocation.MyCommand): Profile unloading caught exception. An error occurred: $_"
																		}
																	}
																} else
																{
																	write-teams-log "Warning: $($MyInvocation.MyCommand): Component has no registry key(s)."
																}
															} else
															{
																write-teams-log "Warning: Warning: $($MyInvocation.MyCommand): Component has no registry key(s)."
															}
														}
													}
												}
											}
										}

										$removedApplicationEntry = @{
											AppDefinition=$appEntry.AppDefinition
											Successful=$true
											Error=$null
										}


										if ($removedApplicationEntry -ne $null)
										{
											$removedApplicationList += $removedApplicationEntry
										}
                                    }
                                }
                            }
                        }
                    }
                }
            }
    }

    if ($removedApplicationList -ne $null)
    {
        return @($removedApplicationList)
    }

    return $removedApplicationList
}

function Remove-DirectoryRecursively {
    param(
        [string]$dirPath
    )

    if (Test-Path $dirPath) {
        Remove-Item -Path $dirPath -Recurse -Force -ErrorAction SilentlyContinue
        return $true
    } else {
        return $false
    }
}

# Function to remove the stale user name entries whose entry is not present in HKLM/:{$username)
# Also cleans the Appdata folder
Function Remove-TeamsStaleUserProfileFileSystemEntries {
	$userProfiles = (Get-ChildItem "$($ENV:SystemDrive)\Users" -Directory -Exclude "Public", "Default", "Default User").FullName
	
	foreach($profile in $userProfiles) {
		# Removing the complete old teams directory
		$userProfileTeamsPath = Join-Path -Path $profile -ChildPath "\AppData\Local\Microsoft\Teams\"
		$result = Remove-DirectoryRecursively -dirPath $userProfileTeamsPath
		if ($result) {
			$ScriptResult.StaleFileSystemEntryDeleted++
			write-teams-log "Deleted stale file system entry successfully."
		}
		
		$userProfileTeamsAppDataPath = Join-Path -Path $profile -ChildPath "\AppData\Roaming\Microsoft\Teams"
		$result2 = Remove-DirectoryRecursively -dirPath $userProfileTeamsAppDataPath
		if ($result2) {
			$ScriptResult.AppDataEntryDeleted++
			write-teams-log "Deleted stale App data file system entry successfully."
		}
	}
}

# Function to remove TMA entries
Function Remove-TeamsMeetingAddin {
	$userProfiles = (Get-ChildItem "$($ENV:SystemDrive)\Users" -Directory -Exclude "Public", "Default", "Default User").FullName
	
	foreach($profile in $userProfiles) {
		# Removing the complete old teams directory
		$userProfileTMAPath = Join-Path -Path $profile -ChildPath "\AppData\Local\Microsoft\TeamsMeetingAddin"
		$result = Remove-DirectoryRecursively -dirPath $userProfileTMAPath
		if ($result) {
			$ScriptResult.TeamsMeetingAddinDeleted++
			write-teams-log "Deleted TMA successfully."
		}
	}
}

# Function to remove only stale regkey entries from the HKEY_USERS
Function Remove-TeamsStaleRegKeys {
	$subkeys = (Get-ChildItem -Path "registry::HKEY_USERS"  -Exclude .DEFAULT).Name
	
	foreach($subkey in $subkeys) {
		$regkey = "registry::$subkey\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
		if (Test-Path $regkey) {
			$ignore = Remove-Item "$regKey" -Recurse -Force -ErrorAction SilentlyContinue
			write-teams-log "Deleted stale regkey entry from HKEY_USERS successfully."
			$ScriptResult.StaleRegkeyEntryDeleted++
		}
		
		# Very Rare scenario, if classic teams is chosen delibrately by user as default for msteams.
		$associationKeyPath = "registry::$subkey\SOFTWARE\Microsoft\Office\Teams\Capabilities\URLAssociations"
		if (Test-Path $associationKeyPath) {
			$res = Get-ItemProperty -Path $regkey -Name 'msteams' -ErrorAction SilentlyContinue
			
			if ($res -ne $null) {
				$ignore = Remove-ItemProperty -Path $associationKeyPath -Name 'msteams' -ErrorAction SilentlyContinue
				write-teams-log "Deleted URL association msteams entry."
				$ScriptResult.StaleUserAssociationRegkeyEntryDeleted++
			}
		}
	}
}

# Function to remove machine wide installer 
Function Remove-TeamsMachineWideInstaller {
	$processorArchitecture = $env:PROCESSOR_ARCHITECTURE

	# Determine and output architecture
	if ($processorArchitecture -eq 'AMD64') {
		$msiProductCode = "{731F6BAA-A986-45A4-8936-7C3AAAAA760B}"
		Start-Process "msiexec.exe" -ArgumentList "/x $msiProductCode /qn ALLUSERS=1" -Wait
		write-teams-log "Uninstalled machine wide 64-bit installer"
	} elseif ($processorArchitecture -eq 'x86') {
		$msiProductCode = "{39AF0813-FA7B-4860-ADBE-93B9B214B914}"
		Start-Process "msiexec.exe" -ArgumentList "/x $msiProductCode /qn ALLUSERS=1" -Wait
		write-teams-log "Uninstalled machine wide x86 installer"
	}
	
	# if msiexec.exe is not uninstalling Teams wide installer from machine
	# Here performing following additional actions to remove Teams wide installer
	# 1. Removing the regkey "TeamsMachineInstaller" from Run key
	
	$regPathWOW6432Node = "registry::HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
	$valueName = 'TeamsMachineInstaller'
	if (Test-Path $regPathWOW6432Node) {
		$regValue = Get-ItemProperty -Path $regPathWOW6432Node -Name $valueName -ErrorAction SilentlyContinue

		if ($regValue -ne $null) {
			Remove-ItemProperty -Path $regPathWOW6432Node -Name $valueName -Force
			$ScriptResult.TeamsWideInstallerRunKeyDeleted++
			write-teams-log "Teams wide installer uninstall step. The registry value '$valueName' has been deleted."
		} else {
			write-teams-log "Teams wide installer uninstall step. The registry value '$valueName' does not exist."
		}
	}
	
	$regPath = "registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
	if (Test-Path $regPath) {
		$regValue = Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction SilentlyContinue

		if ($regValue -ne $null) {
			Remove-ItemProperty -Path $regPath -Name $valueName -Force
			$ScriptResult.TeamsWideInstallerRunKeyDeleted++
			write-teams-log "Teams wide installer uninstall step. The registry value '$valueName' has been deleted."
		} else {
			write-teams-log "Teams wide installer uninstall step. The registry value '$valueName' does not exist."
		}
	}
	
	# Uninstall Teams Machine-Wide Installer
	$msiExecPath = "${Env:ProgramFiles(x86)}\Teams Installer\"

	# Delete the Teams Installer folder if it exists
	if (Test-Path $msiExecPath) {
		Remove-Item -Path $msiExecPath -Recurse -Force
	}
}

Function Create-PostScriptExecutionRegkeyEntry {
	$registryPath = "registry::HKLM\Software\Microsoft\TeamsAdminLevelScript"
	$null = New-Item -Path $registryPath -Force -ErrorAction SilentlyContinue
}

write-teams-log "Looking for application(s): $($applicationDefinitions.Name -join ', ')"
$foundList = Find-WindowsApplication -ApplicationDefinitions $applicationDefinitions -AllUsers
if ($foundList)
{
	$ScriptResult.NumApplicationsFound = $foundList.Count
	write-teams-log "Found $(@($foundList).Count.ToString('#,###')) application(s)"
	#"Removing apps..."
	$removeList = Remove-WindowsApplication -Applications @($foundList)
	if ($removeList -ne $null)
	{
		$ScriptResult.NumApplicationsRemoved = $removeList.Count
		write-teams-log "Removed applications: $(@($removeList | Where-Object { $_.Successful -eq $true }).AppDefinition.Name -join ', ')"
	} else
	{
		write-teams-log "Warning: No application(s) were removed."
	}
} else
{
    write-teams-log "Warning: Didn't find any applications."
}

# Function to remove only stale regkey entries from the HKEY_USERS
Remove-TeamsStaleRegKeys

# Function to remove the stale user name entries whose entry is not present in HKLM/:{$username)
Remove-TeamsStaleUserProfileFileSystemEntries

# Function to remove TMA entries
Remove-TeamsMeetingAddin

# Function to remove machine wide installer 
Remove-TeamsMachineWideInstaller

Create-PostScriptExecutionRegkeyEntry

# Deleting the shortcuts
$TeamsIcon_old = "$($ENV:SystemDrive)\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Teams*.lnk"
Get-Item $TeamsIcon_old | Remove-Item -Force -Recurse

$ScriptResult | ConvertTo-Json -Compress
# SIG # Begin signature block
# MIIoVQYJKoZIhvcNAQcCoIIoRjCCKEICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDoBoKZoSQ5sWnY
# A5VImEt7ZINYJ/ZbCEaib+XNmLykkKCCDYUwggYDMIID66ADAgECAhMzAAAEA73V
# lV0POxitAAAAAAQDMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjQwOTEyMjAxMTEzWhcNMjUwOTExMjAxMTEzWjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCfdGddwIOnbRYUyg03O3iz19XXZPmuhEmW/5uyEN+8mgxl+HJGeLGBR8YButGV
# LVK38RxcVcPYyFGQXcKcxgih4w4y4zJi3GvawLYHlsNExQwz+v0jgY/aejBS2EJY
# oUhLVE+UzRihV8ooxoftsmKLb2xb7BoFS6UAo3Zz4afnOdqI7FGoi7g4vx/0MIdi
# kwTn5N56TdIv3mwfkZCFmrsKpN0zR8HD8WYsvH3xKkG7u/xdqmhPPqMmnI2jOFw/
# /n2aL8W7i1Pasja8PnRXH/QaVH0M1nanL+LI9TsMb/enWfXOW65Gne5cqMN9Uofv
# ENtdwwEmJ3bZrcI9u4LZAkujAgMBAAGjggGCMIIBfjAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQU6m4qAkpz4641iK2irF8eWsSBcBkw
# VAYDVR0RBE0wS6RJMEcxLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEWMBQGA1UEBRMNMjMwMDEyKzUwMjkyNjAfBgNVHSMEGDAW
# gBRIbmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDEx
# XzIwMTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIB
# AFFo/6E4LX51IqFuoKvUsi80QytGI5ASQ9zsPpBa0z78hutiJd6w154JkcIx/f7r
# EBK4NhD4DIFNfRiVdI7EacEs7OAS6QHF7Nt+eFRNOTtgHb9PExRy4EI/jnMwzQJV
# NokTxu2WgHr/fBsWs6G9AcIgvHjWNN3qRSrhsgEdqHc0bRDUf8UILAdEZOMBvKLC
# rmf+kJPEvPldgK7hFO/L9kmcVe67BnKejDKO73Sa56AJOhM7CkeATrJFxO9GLXos
# oKvrwBvynxAg18W+pagTAkJefzneuWSmniTurPCUE2JnvW7DalvONDOtG01sIVAB
# +ahO2wcUPa2Zm9AiDVBWTMz9XUoKMcvngi2oqbsDLhbK+pYrRUgRpNt0y1sxZsXO
# raGRF8lM2cWvtEkV5UL+TQM1ppv5unDHkW8JS+QnfPbB8dZVRyRmMQ4aY/tx5x5+
# sX6semJ//FbiclSMxSI+zINu1jYerdUwuCi+P6p7SmQmClhDM+6Q+btE2FtpsU0W
# +r6RdYFf/P+nK6j2otl9Nvr3tWLu+WXmz8MGM+18ynJ+lYbSmFWcAj7SYziAfT0s
# IwlQRFkyC71tsIZUhBHtxPliGUu362lIO0Lpe0DOrg8lspnEWOkHnCT5JEnWCbzu
# iVt8RX1IV07uIveNZuOBWLVCzWJjEGa+HhaEtavjy6i7MIIHejCCBWKgAwIBAgIK
# YQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEw
# OTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYD
# VQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+la
# UKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc
# 6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4D
# dato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+
# lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nk
# kDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6
# A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmd
# X4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL
# 5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zd
# sGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3
# T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS
# 4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRI
# bmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
# BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBD
# uRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEF
# BQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1h
# cnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkA
# YwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn
# 8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7
# v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0b
# pdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/
# KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvy
# CInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBp
# mLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJi
# hsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYb
# BL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbS
# oqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sL
# gOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtX
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGiYwghoiAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAQDvdWVXQ87GK0AAAAA
# BAMwDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIO+I
# c06q+Utfm74ukWjwsu368M4adGpPb+LVGQphKWCLMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAgnOO8ZAvbKda0SiM116X/gezqB8vXd7xatUL
# KNzDbTgI7Tt1VsSKPm16rOKJEPiCyMUBrmZZFN0Xp1D8xFWQBQSCz5P1dia2WluV
# 7Q7z7y/OXJDgvZOE0QFJ+gx6wQ3xYjohEu/m3Z5qoCrHWFf4SIdmuLBjtn0g/sQX
# HR1sWzGkbtuywKeLl2rObo1yf25o4cCgbtjnM4YKI/0r9qCxugC/TpBRBVmQXfYd
# JdZTn8vOLVEeYwpPC3vbcEl5bZqfzKmccmIHcJcmBRX0DdTtrO9Fzx5ytytojYsg
# myoU1s5m7z2vk1BGXMODiILEJrQMAEhTycX/GCNu+frOGpcKgaGCF7AwghesBgor
# BgEEAYI3AwMBMYIXnDCCF5gGCSqGSIb3DQEHAqCCF4kwgheFAgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFaBgsqhkiG9w0BCRABBKCCAUkEggFFMIIBQQIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCCvEno7MPqu+Hk4luma6zM+JD5EW34rV5lk
# UT/yoe7zlAIGZusqfVFSGBMyMDI0MTExMTE5NDMxNi4yMjFaMASAAgH0oIHZpIHW
# MIHTMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQL
# EyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJzAlBgNVBAsT
# Hm5TaGllbGQgVFNTIEVTTjozMjFBLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCEf4wggcoMIIFEKADAgECAhMzAAAB+KOh
# JgwMQEj+AAEAAAH4MA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMB4XDTI0MDcyNTE4MzEwOFoXDTI1MTAyMjE4MzEwOFowgdMxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jv
# c29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEnMCUGA1UECxMeblNoaWVs
# ZCBUU1MgRVNOOjMyMUEtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# xR23pXYnD2BuODdeXs2Cu/T5kKI+bAw8cbtN50Cm/FArjXyL4RTqMe6laQ/CqeMT
# xgckvZr1JrW0Mi4F15rx/VveGhKBmob45DmOcV5xyx7h9Tk59NAl5PNMAWKAIWf2
# 70SWAAWxQbpVIhhPWCnVV3otVvahEad8pMmoSXrT5Z7Nk1RnB70A2bq9Hk8wIeC3
# vBuxEX2E8X50IgAHsyaR9roFq3ErzUEHlS8YnSq33ui5uBcrFOcFOCZILuVFVTgE
# qSrX4UiX0etqi7jUtKypgIflaZcV5cI5XI/eCxY8wDNmBprhYMNlYxdmQ9aLRDcT
# KWtddWpnJtyl5e3gHuYoj8xuDQ0XZNy7ESRwJIK03+rTZqfaYyM4XSK1s0aa+mO6
# 9vo/NmJ4R/f1+KucBPJ4yUdbqJWM3xMvBwLYycvigI/WK4kgPog0UBNczaQwDVXp
# cU+TMcOvWP8HBWmWJQImTZInAFivXqUaBbo3wAfPNbsQpvNNGu/12pg0F8O/CdRf
# gPHfOhIWQ0D8ALCY+LsiwbzcejbrVl4N9fn2wOg2sDa8RfNoD614I0pFjy/lq1Ns
# Bo9V4GZBikzX7ZjWCRgd1FCBXGpfpDikHjQ05YOkAakdWDT2bGSaUZJGVYtepIpP
# TAs1gd/vUogcdiL51o7shuHIlB6QSUiQ24XYhRbbQCECAwEAAaOCAUkwggFFMB0G
# A1UdDgQWBBS9zsZzz57QlT5nrt/oitLv1OQ7tjAfBgNVHSMEGDAWgBSfpxVdAF5i
# XYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
# JTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRp
# bWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1Ud
# JQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsF
# AAOCAgEAYfk8GzzpEVnGl7y6oXoytCb42Hx6TOA0+dkaBI36ftDE9tLubUa/xMbH
# B5rcNiRhFHZ93RefdPpc4+FF0DAl5lP8xKAO+293RWPKDFOFIxgtZY08t8D9cSQp
# gGUzyw3lETZebNLEA17A/CTpA2F9uh8j84KygeEbj+bidWDiEfayoH2A5/5ywJJx
# IuLzFVHacvWxSCKoF9hlSrZSG5fXWS3namf4tt690UT6AGyWLFWe895coFPxm/m0
# UIMjjp9VRFH7nb3Ng2Q4gPS9E5ZTMZ6nAlmUicDj0NXAs2wQuQrnYnbRAJ/DQW35
# qLo7Daw9AsItqjFhbMcG68gDc4j74L2KYe/2goBHLwzSn5UDftS1HZI0ZRsqmNHI
# 0TZvvUWX9ajm6SfLBTEtoTo6gLOX0UD/9rrhGjdkiCw4SwU5osClgqgiNMK5ndk2
# gxFlDXHCyLp5qB6BoPpc82RhO0yCzoP9gv7zv2EocAWEsqE5+0Wmu5uarmfvcziL
# fU1SY240OZW8ld4sS8fnybn/jDMmFAhazV1zH0QERWEsfLSpwkOXaImWNFJ5lmcn
# f1VTm6cmfasScYtElpjqZ9GooCmk1XFApORPs/PO43IcFmPRwagt00iQSw+rBeIH
# 00KQq+FJT/62SB70g9g/R8TS6k6b/wt2UWhqrW+Q8lw6Xzgex/YwggdxMIIFWaAD
# AgECAhMzAAAAFcXna54Cm0mZAAAAAAAVMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3Nv
# ZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0yMTA5MzAxODIy
# MjVaFw0zMDA5MzAxODMyMjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA5OGmTOe0ciELeaLL1yR5
# vQ7VgtP97pwHB9KpbE51yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64
# NmeFRiMMtY0Tz3cywBAY6GB9alKDRLemjkZrBxTzxXb1hlDcwUTIcVxRMTegCjhu
# je3XD9gmU3w5YQJ6xKr9cmmvHaus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl
# 3GoPz130/o5Tz9bshVZN7928jaTjkY+yOSxRnOlwaQ3KNi1wjjHINSi947SHJMPg
# yY9+tVSP3PoFVZhtaDuaRr3tpK56KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I
# 5JasAUq7vnGpF1tnYN74kpEeHT39IM9zfUGaRnXNxF803RKJ1v2lIH1+/NmeRd+2
# ci/bfV+AutuqfjbsNkz2K26oElHovwUDo9Fzpk03dJQcNIIP8BDyt0cY7afomXw/
# TNuvXsLz1dhzPUNOwTM5TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtcodgLiMxhy
# 16cg8ML6EgrXY28MyTZki1ugpoMhXV8wdJGUlNi5UPkLiWHzNgY1GIRH29wb0f2y
# 1BzFa/ZcUlFdEtsluq9QBXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6H
# XtqPnhZyacaue7e3PmriLq0CAwEAAaOCAd0wggHZMBIGCSsGAQQBgjcVAQQFAgMB
# AAEwIwYJKwYBBAGCNxUCBBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQW
# BBSfpxVdAF5iXYP05dJlpxtTNRnpcjBcBgNVHSAEVTBTMFEGDCsGAQQBgjdMg30B
# ATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L0RvY3MvUmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYB
# BAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMB
# Af8wHwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBL
# oEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMv
# TWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggr
# BgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNS
# b29DZXJBdXRfMjAxMC0wNi0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1Vffwq
# reEsH2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEGk5c9MTO1OdfCcTY/2mRsfNB1OW27
# DzHkwo/7bNGhlBgi7ulmZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pv
# vinLbtg/SHUB2RjebYIM9W0jVOR4U3UkV7ndn/OOPcbzaN9l9qRWqveVtihVJ9Ak
# vUCgvxm2EhIRXT0n4ECWOKz3+SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWK
# NsIdw2FzLixre24/LAl4FOmRsqlb30mjdAy87JGA0j3mSj5mO0+7hvoyGtmW9I/2
# kQH2zsZ0/fZMcm8Qq3UwxTSwethQ/gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+
# c23Kjgm9swFXSVRk2XPXfx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFUa2pFEUep
# 8beuyOiJXk+d0tBMdrVXVAmxaQFEfnyhYWxz/gq77EFmPWn9y8FBSX5+k77L+Dvk
# txW/tM4+pTFRhLy/AsGConsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1Zyvg
# DbjmjJnW4SLq8CdCPSWU5nR0W2rRnj7tfqAxM328y+l7vzhwRNGQ8cirOoo6CGJ/
# 2XBjU02N7oJtpQUQwXEGahC0HVUzWLOhcGbyoYIDWTCCAkECAQEwggEBoYHZpIHW
# MIHTMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQL
# EyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJzAlBgNVBAsT
# Hm5TaGllbGQgVFNTIEVTTjozMjFBLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAtkQt/ebWSQ5D
# nG+aKRzPELCFE9GggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MDANBgkqhkiG9w0BAQsFAAIFAOrc1mwwIhgPMjAyNDExMTExOTE1NTZaGA8yMDI0
# MTExMjE5MTU1NlowdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA6tzWbAIBADAKAgEA
# AgIDGQIB/zAHAgEAAgISKzAKAgUA6t4n7AIBADA2BgorBgEEAYRZCgQCMSgwJjAM
# BgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEB
# CwUAA4IBAQBfbl6L1UQn6EuyMZab9mP6hBNAs7VuFK+lU2agiqrs4YLazayD2Thi
# Usf/cicRicxeCewTnZr5dQ04zQbephQD7Zqnv7OpZz0uxVahMfvCLtVPaKfI/DRL
# Qil/6Zux5mtslBGEZ4o9pkeWPb7Vgn+fWnV10SyWEzOxd5Wd8arRliPiWRRFYpDo
# Y/V/rGNLvUZu9Qzk+MPjDEDNEyWHK0pRR0FWSdtjOrxcwy4WQw7GMHiuGDMRNgvd
# qcCva3+2JNkyEYIr0tySrhmCWi8zG3Jaj3IwwoPXz5DqR9VzjPu9JWKJK1omzZm4
# 94wJPK+PINcWGuo/fwiA7Yt1SjLDU7EnMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAH4o6EmDAxASP4AAQAAAfgwDQYJYIZI
# AWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG
# 9w0BCQQxIgQgFWGncMoWPZ+zbZEyAhegVoQNe6Q+vuAtmCiGIxF6xQwwgfoGCyqG
# SIb3DQEJEAIvMYHqMIHnMIHkMIG9BCDvzDPyXw1UkAUFYt8bR4UdjM90Qv5xnVai
# KD3I0Zz3WjCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
# AAAB+KOhJgwMQEj+AAEAAAH4MCIEIMt9A5U3Zk5Fgl7BufM6Jf+OTUwS1xymDtOd
# S52hUsHBMA0GCSqGSIb3DQEBCwUABIICACvBCMw+x4CMzdG+JI8L6b9SJv3p5bSC
# j/b5LIlpT0FmfW48rJanXGmdgcMM8Zb6iArc4Jg3t3UvkUc3MUaB8wM4SUND86cb
# mC7qGYS1fefoaVp36NMsfRB24ut7tKtVzt6NhcGqzjwLtLG/gfK/DCZ3FA0qQ/Sh
# Phm9qK+3HwctDHhMJ+fMfJPJJydyYLzRIx1cxNMO6a5qxxS3gnl+QIIOX2R7lB+A
# tMIrKRJQNavL0FDMcfgVl0c6lNViTVanZNbiHWfLGiewYfTKXIdlIxDCNSpYW8EM
# OkHbmY1DfjyHgjDqnm9ISJFjEB39beQOS058gptn5a05fhV8K4F5lwJl/Lp83isj
# ddQSpbDsyXbSjov8M+L3P704m129zQfPjWtBgdUVvP6vQ2xCa14M4Jpit/xgvygQ
# RALu1lmtdNwtMclgBrEeW60zA34Qbum+Q08WdXjsrlJrHLM5MMxtA14cWCG2PinO
# +BM+0QYTIwkzm5N6rtnVzwHmCuT6+kNNm0ak+dsXcvokNYEk0857S45wIR9Z0Ig6
# hz4nv0EiQuYhLCbPmdVPETULPeWHGDvwdCoFk8Fui1WV5VnQo4Lr9V6L8i/+Edte
# l5D2uwtdFOsD3/Tz6aV8gjTVm+f85O/Z9bAVRqXNK03QGIRJy/zMuhMq5nywqeeD
# R7rDq4nYY0la
# SIG # End signature block


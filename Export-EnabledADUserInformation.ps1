# Configurable variables
$exportCSVFile = "C:\Source\Scripts\Export-EnabledADUserInformation\ADUsers-Basic-$(get-date -f yyyy-MM-dd_HHmmss).csv"
$ADexportCSVFile = "C:\Source\Scripts\Export-EnabledADUserInformation\ADUsers-Extended-$(get-date -f yyyy-MM-dd_HHmmss).csv"

# Set up the script
#  Get a collection of all domain controllers
$DCs = Get-ADDomainController -Filter {Name -like "*"}
$Today = Get-Date
$ADUsers = @()

#  Get a collection of all user accounts
Write-Host "Starting a basic export of enabled AD user records to `n    - $exportCSVFile" -ForegroundColor White
$Users = Get-ADUser -searchbase "DC=OLOS,DC=internal" -Filter * -Properties * | where {$_.enabled -eq $true} | select sAMAccountName, UserPrincipalName, DisplayName, givenname, surname, mail, title, department, streetaddress, state, country, office, city, postalcode, officephone, mobilephone, company, whencreated, whenchanged, lastlogondate,HomeDrive,HomeDirectory,ProfilePath,ScriptPath,msTSHomeDrive,msTSHomeDirectory,msTSProfilePath, DistinguishedName
$Users | Export-Csv -NoTypeInformation  -path $exportCSVFile 
$Count = $Users.Count
Write-Host "`nWrote $Count enabled user records to $exportCSVFile" -ForegroundColor Yellow
Write-Host "`nStarting an ADVANCED export of enabled user records to `n    - $ADexportCSVFile `n" -ForegroundColor White

ForEach ($User in $users) {
    # Reset for loop
    $lastlogintimeraw = $null
    
    # Pull the user object detail
    $samAccount = $User.sAMAccountName
    $HomeDirectory = $User.HomeDirectory
    $ProfilePath = $User.ProfilePath

    # Create and populate the ADUser member
    $ADUser = New-Object System.Object
    $ADUser | Add-Member -MemberType Noteproperty -Name "samAccountName" -Value $samAccount
    $ADUser | Add-Member -MemberType Noteproperty -Name "UserPrincipalName" -Value $User.UserPrincipalname
    $ADUser | Add-Member -MemberType Noteproperty -Name "Displayname" -Value $User.Displayname
    $ADUser | Add-Member -MemberType Noteproperty -Name "department" -Value $User.Department
    $ADUser | Add-Member -MemberType Noteproperty -Name "streetaddress" -Value $User.StreetAddress
    $ADUser | Add-Member -MemberType Noteproperty -Name "state" -Value $User.State
    $ADUser | Add-Member -MemberType Noteproperty -Name "country" -Value $User.Country
    $ADUser | Add-Member -MemberType Noteproperty -Name "office" -Value $User.Office
    $ADUser | Add-Member -MemberType Noteproperty -Name "city" -Value $User.Office
    $ADUser | Add-Member -MemberType Noteproperty -Name "postalcode" -Value $User.Postalcode
    $ADUser | Add-Member -MemberType Noteproperty -Name "officephone" -Value $User.OfficePhone
    $ADUser | Add-Member -MemberType Noteproperty -Name "mobilephone" -Value $User.MobilePhone
    $ADUser | Add-Member -MemberType Noteproperty -Name "company" -Value $User.Company
    $ADUser | Add-Member -MemberType Noteproperty -Name "whencreated" -Value $User.WhenCreated
    $ADUser | Add-Member -MemberType Noteproperty -Name "whenchanged" -Value $User.WhenChanged
    $ADUser | Add-Member -MemberType Noteproperty -Name "ScriptPath" -Value $User.ScriptPath
    $ADUser | Add-Member -MemberType Noteproperty -Name "HomeDrive" -Value $User.HomeDrive
    $ADUser | Add-Member -MemberType Noteproperty -Name "msTSHomeDrive" -Value $User.msTSHomeDrive
    $ADUser | Add-Member -MemberType Noteproperty -Name "msTSHomeDirectory" -Value $User.msTSHomeDirectory
    $ADUser | Add-Member -MemberType Noteproperty -Name "msTSProfilePath" -Value $User.msTSProfilePath
    $ADUser | Add-Member -MemberType Noteproperty -Name "DistinguishedName" -Value $User.DistinguishedName


    ## HOME DIRECTORY FIRST ##
    # Split out the components for the shared home path
    If ($HomeDirectory) {
        $HostName  = $HomeDirectory -split "\\" | Where-Object {$_ -ne ""} | Select-Object -First 1
        $ShareName = ($HomeDirectory -split "\\" | Where-Object {$_ -ne ""})[1]
    }

    Write-Host " samAccountName: $samAccount" -ForegroundColor White
    
    # Get the details of the share (unless it's a DFS path)
    If ( $hostname -eq 'olos.internal') {
        # It's a DFS path, get the DFS folder target first to identify the host server
        $DFSRoot = ($HomeDirectory -split "\\" | Where-Object {$_ -ne ""})[1]
        $DFSFolder = ($HomeDirectory -split "\\" | Where-Object {$_ -ne ""})[2]
        $DFSFolderTargetPath = (Get-DFSNFolder -Path "\\$Hostname\$DFSRoot\$DFSFolder" -ErrorAction SilentlyContinue | Get-DfsnFolderTarget | Where-Object -Property State -EQ 'Online').TargetPath
        
        # Pull folder hosts share details and split them out
        If ($DFSFolderTargetPath) {
            $HostName = $DFSFolderTargetPath -split "\\" | Where-Object {$_ -ne ""} | Select-Object -First 1
            $ShareName = ($DFSFolderTargetPath -split "\\")[-1]
        } Else {
            $Hostname = "-NO DFS TARGET-"
            $ShareName = ""
        }
    }

    $ADUser | Add-Member -MemberType Noteproperty -Name "HomeDirectory" -Value $HomeDirectory

    If (!($HomeDirectory)) {
        # No home drive for this account
        Write-Host "    Home Directory: -NOT SET-" -ForegroundColor Gray
    
        $ADUser | Add-Member -MemberType NoteProperty -name "HomeShareName" -Value ""
        $ADUser | Add-Member -MemberType NoteProperty -name "HomeHost" -Value ""
        $ADUser | Add-Member -MemberType NoteProperty -name "HomeHostPath" -Value ""     
        $ADUser | Add-Member -MemberType NoteProperty -name "ShareValid" -Value ""     

    } ElseIf ($Hostname -eq "-NO DFS TARGET-") {
        $ADUser | Add-Member -MemberType NoteProperty -name "ProfileShareName" -Value ""
        $ADUser | Add-Member -MemberType NoteProperty -name "ProfileHost" -Value ""
        $ADUser | Add-Member -MemberType NoteProperty -name "ProfileHostPath" -Value ""     
        $ADUser | Add-Member -MemberType NoteProperty -name "ProfileShareValid" -Value "NO DFS TARGET"     

    } Else {
        $FSsession = New-CimSession -ComputerName $Hostname

        $ADUser | Add-Member -MemberType NoteProperty -name "HomeShareName" -Value $ShareName
        $ADUser | Add-Member -MemberType NoteProperty -name "HomeHost" -Value $HostName


        If (Get-SMBShare -CimSession $FSsession -Name $ShareName -ea SilentlyContinue) {
            $SMBShare = Get-SmbShare -CimSession $FSsession -Name $Sharename
            $HostPath = $SMBShare.Path
         
            # Write out the results
            Write-Host "    Home Directory: $HomeDirectory" -ForegroundColor Yellow
            Write-Host "    Share: $Sharename" -ForegroundColor Cyan
            Write-Host "    Host: $Hostname" -ForegroundColor Cyan
            Write-Host "    Host Path: $Hostpath" -ForegroundColor Cyan

            $ADUser | Add-Member -MemberType NoteProperty -name "HomeHostPath" -Value $HostPath
            $ADUser | Add-Member -MemberType NoteProperty -name "HomeShareValid" -Value "TRUE"

        } Else {
            # Write out the results
            Write-Host "    Home Directory: -SHARE MISSING-" -ForegroundColor Red

            $ADUser | Add-Member -MemberType NoteProperty -name "HomeHostPath" -Value ""
            $ADUser | Add-Member -MemberType NoteProperty -name "HomeShareValid" -Value "MISSING"

        }
        Remove-CimSession -CimSession $FSsession

    }

    ## PROFILE DIRECTORY NEXT ##

    $ADUser | Add-Member -MemberType Noteproperty -Name "ProfilePath" -Value $ProfilePath       

    # Split out the components for the shared home path
    If ($ProfilePath) {
        $HostName  = $ProfilePath -split "\\" | Where-Object {$_ -ne ""} | Select-Object -First 1
        $ShareName = ($ProfilePath -split "\\" | Where-Object {$_ -ne ""})[1]
    }

    # Get the details of the share (unless it's a DFS path)
    If ( $hostname -eq 'olos.internal') {
        # It's a DFS path, get the DFS folder target first to identify the host server
        $DFSRoot = ($ProfilePath -split "\\" | Where-Object {$_ -ne ""})[1]
        $DFSFolder = ($ProfilePath -split "\\" | Where-Object {$_ -ne ""})[2]
        $DFSFolderTargetPath = (Get-DFSNFolder -Path "\\$Hostname\$DFSRoot\$DFSFolder" -ErrorAction SilentlyContinue| Get-DfsnFolderTarget | Where-Object -Property State -EQ 'Online').TargetPath
        
        # Pull folder hosts share details and split them out
        If ($DFSFolderTargetPath) {
            $HostName = $DFSFolderTargetPath -split "\\" | Where-Object {$_ -ne ""} | Select-Object -First 1
            $ShareName = ($DFSFolderTargetPath -split "\\")[-1]
        } Else {
            $Hostname = "-NO DFS TARGET-"
            $ShareName = ""
        }
    }

    If (!($ProfilePath)) {
        # No home drive for this account
        Write-Host "    Profile Directory: -NOT SET-" -ForegroundColor Gray

        $ADUser | Add-Member -MemberType NoteProperty -name "ProfileShareName" -Value ""
        $ADUser | Add-Member -MemberType NoteProperty -name "ProfileHost" -Value ""
        $ADUser | Add-Member -MemberType NoteProperty -name "ProfileHostPath" -Value ""     
        $ADUser | Add-Member -MemberType NoteProperty -name "ProfileShareValid" -Value ""     

    } ElseIf ($Hostname -eq "-NO DFS TARGET-") {
        $ADUser | Add-Member -MemberType NoteProperty -name "ProfileShareName" -Value ""
        $ADUser | Add-Member -MemberType NoteProperty -name "ProfileHost" -Value ""
        $ADUser | Add-Member -MemberType NoteProperty -name "ProfileHostPath" -Value ""     
        $ADUser | Add-Member -MemberType NoteProperty -name "ProfileShareValid" -Value "NO DFS TARGET"     

    } Else {
        $FSsession = New-CimSession -ComputerName $Hostname

        $ADUser | Add-Member -MemberType NoteProperty -name "ProfileShareName" -Value $ShareName
        $ADUser | Add-Member -MemberType NoteProperty -name "ProfileHost" -Value $HostName

        If (Get-SMBShare -CimSession $FSsession -Name $ShareName -ea SilentlyContinue) {
            $SMBShare = Get-SmbShare -CimSession $FSsession -Name $Sharename
            $HostPath = $SMBShare.Path
         
            # Write out the results
            Write-Host "    Profile Directory: $ProfilePath" -ForegroundColor Yellow
            Write-Host "    Share: $Sharename" -ForegroundColor Green
            Write-Host "    Host: $Hostname" -ForegroundColor Green
            Write-Host "    Host Path: $Hostpath" -ForegroundColor Green

            $ADUser | Add-Member -MemberType NoteProperty -name "ProfileHostPath" -Value $HostPath     
            $ADUser | Add-Member -MemberType NoteProperty -name "ProfileShareValid" -Value "TRUE"  
        } Else {
            # Write out the results
            Write-Host "    Profile Directory: -SHARE MISSING-" -ForegroundColor Red

            $ADUser | Add-Member -MemberType NoteProperty -name "ProfileHostPath" -Value ""
            $ADUser | Add-Member -MemberType NoteProperty -name "ProfileShareValid" -Value "MISSING"  
        }
        Remove-CimSession -CimSession $FSsession

    }

    # Get last login across all DCs
    ForEach ($DC in $DCs)
    { 
      $DChostname = $DC.HostName
      # Write-Host "Checking $DC.Hostname for account $SamAccount"
      $currentUser = Get-ADUser $SamAccount | Get-ADObject -Server $DChostname -Properties lastLogon

      if($currentUser.LastLogon -gt $lastlogintimeraw) 
      {
        $lastlogintimeraw = $currentUser.LastLogon
      }
    }
    $LastLoginTime = [DateTime]::FromFileTime($lastlogintimeraw)
    $LastLoginDays = (New-TimeSpan -Start $lastLoginTime -End $Today).Days
    Write-Host "    Last login: $(Get-Date $LastLoginTime -Format `"dd/MM/yyyy hh:mm`")"
    If ($LastLoginDays -gt 365) {
        Write-Host "    Last login (days): $LastLoginDays " -ForegroundColor Red
    } Else {
        Write-Host "    Last login (days): $LastLoginDays " -ForegroundColor Yellow
    }
 
    Write-Host ""

    $ADUser | Add-Member -MemberType Noteproperty -Name "lastlogondate" -Value $LastLoginTime
    $ADUser | Add-Member -MemberType Noteproperty -Name "lastlogondays" -Value $LastLoginDays

    # Add the user to the ADUsers collection
    $ADUsers += $ADUser
}

$ADUsers | Export-Csv -NoTypeInformation  -path $ADexportCSVFile 
$ADCount = $ADUsers.Count
Write-Host "Wrote $ADCount enabled user records to $ADexportCSVFile" -ForegroundColor Yellow

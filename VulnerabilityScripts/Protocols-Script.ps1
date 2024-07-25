# A SCRIPT TO CONTROL WHICH PROTOCOLS ARE ENABLED IN SECURITYPROVIDERS REGISTRY #

function DisableSSL30 {
    Clear-Host

    $Protocol = "SSL 3.0"
    $ClientRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol\Client"
    $ServerRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol\Server"
    $TestServerPath = Test-Path -Path $ServerRegPath -PathType Container
    $TestClientPath = Test-Path -Path $ClientRegPath -Pathtype Container


    $CheckClientEnabled = Get-ItemPropertyValue -Path $ClientRegPath -Name "Enabled" -ErrorAction SilentlyContinue
    $CheckClientDefaultDisable = Get-ItemPropertyValue -Path $ClientRegPath -Name "DisabledByDefault" -ErrorAction SilentlyContinue
    $CheckServerEnabled = Get-ItemPropertyValue -Path $ServerRegPath -Name "Enabled" -ErrorAction SilentlyContinue
    $CheckServerDefaultDisable = Get-ItemPropertyValue -Path $ServerRegPath -Name "DisabledByDefault" -ErrorAction SilentlyContinue

    #Checking the reg keys are now set to the expected value, spitting out the values if they're wrong
    if (($CheckClientEnabled -eq 0) -and ($CheckClientDefaultDisable -eq 1) -and ($CheckServerEnabled -eq 0) -and ($CheckServerDefaultDisable -eq 1)) {
        return "$Protocol is already disabled!"
    }

    if (!$TestServerPath) {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\" -Name $Protocol -ErrorAction SilentlyContinue
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol" -Name "Server"
    }

    if (!$TestClientPath) {
         New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\" -Name $protocol -ErrorAction SilentlyContinue
         New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol" -Name "Client"
    }
    Clear-Host
    #Setting reg keys to disable the protocol
    Set-ItemProperty -Path $ClientRegPath -Name "Enabled" -Value 0 -Type DWord -Force 
    Set-ItemProperty -Path $ClientRegPath -Name "DisabledByDefault" -Value 1 -Type DWord -Force 
    Set-ItemProperty -Path $ServerRegPath -Name "Enabled" -Value 0 -Type DWord -Force 
    Set-ItemProperty -Path $ServerRegPath -Name "DisabledByDefault" -Value 1 -Type DWord -Force


    $CheckClientEnabled = Get-ItemPropertyValue -Path $ClientRegPath -Name "Enabled"
    $CheckClientDefaultDisable = Get-ItemPropertyValue -Path $ClientRegPath -Name "DisabledByDefault"
    $CheckServerEnabled = Get-ItemPropertyValue -Path $ServerRegPath -Name "Enabled"
    $CheckServerDefaultDisable = Get-ItemPropertyValue -Path $ServerRegPath -Name "DisabledByDefault"

    #Checking the reg keys are now set to the expected value, spitting out the values if they're wrong
    if (($CheckClientEnabled -eq 0) -and ($CheckClientDefaultDisable -eq 1) -and ($CheckServerEnabled -eq 0) -and ($CheckServerDefaultDisable -eq 1)) {
        return "All reg keys changed successfully. Restart the system for the changes to take effect."
    } ELSE {
        return "Reg changes failed!`nthe values for $ClientRegPath :`nEnabled Dword: $CheckClientEnabled`nDisableByDefault Dword: $CheckClientDefaultDisable`nThe values for $ServerRegPath :`nEnabled Dword: $CheckServerEnabled`nDisabledByDefault Dword: $CheckServerDefaultDisable"
    }
}


function DisableTLS10 {
    Clear-Host

    $Protocol = "TLS 1.0"
    $ClientRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol\Client"
    $ServerRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol\Server"
    $TestServerPath = Test-Path -Path $ServerRegPath -PathType Container
    $TestClientPath = Test-Path -Path $ClientRegPath -Pathtype Container


    $CheckClientEnabled = Get-ItemPropertyValue -Path $ClientRegPath -Name "Enabled" -ErrorAction SilentlyContinue
    $CheckClientDefaultDisable = Get-ItemPropertyValue -Path $ClientRegPath -Name "DisabledByDefault" -ErrorAction SilentlyContinue
    $CheckServerEnabled = Get-ItemPropertyValue -Path $ServerRegPath -Name "Enabled" -ErrorAction SilentlyContinue
    $CheckServerDefaultDisable = Get-ItemPropertyValue -Path $ServerRegPath -Name "DisabledByDefault" -ErrorAction SilentlyContinue

    #Checking the reg keys are now set to the expected value, spitting out the values if they're wrong
    if (($CheckClientEnabled -eq 0) -and ($CheckClientDefaultDisable -eq 1) -and ($CheckServerEnabled -eq 0) -and ($CheckServerDefaultDisable -eq 1)) {
        return "$Protocol is already disabled!"
    }

    if (!$TestServerPath) {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\" -Name $Protocol -ErrorAction SilentlyContinue
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol" -Name "Server"
    }

    if (!$TestClientPath) {
         New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\" -Name $protocol -ErrorAction SilentlyContinue
         New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol" -Name "Client"
    }
    Clear-Host
    #Setting reg keys to disable the protocol
    Set-ItemProperty -Path $ClientRegPath -Name "Enabled" -Value 0 -Type DWord -Force 
    Set-ItemProperty -Path $ClientRegPath -Name "DisabledByDefault" -Value 1 -Type DWord -Force 
    Set-ItemProperty -Path $ServerRegPath -Name "Enabled" -Value 0 -Type DWord -Force 
    Set-ItemProperty -Path $ServerRegPath -Name "DisabledByDefault" -Value 1 -Type DWord -Force

    
    $CheckClientEnabled = Get-ItemPropertyValue -Path $ClientRegPath -Name "Enabled"
    $CheckClientDefaultDisable = Get-ItemPropertyValue -Path $ClientRegPath -Name "DisabledByDefault"
    $CheckServerEnabled = Get-ItemPropertyValue -Path $ServerRegPath -Name "Enabled"
    $CheckServerDefaultDisable = Get-ItemPropertyValue -Path $ServerRegPath -Name "DisabledByDefault"

    #Checking the reg keys are now set to the expected value, spitting out the values if they're wrong
    if (($CheckClientEnabled -eq 0) -and ($CheckClientDefaultDisable -eq 1) -and ($CheckServerEnabled -eq 0) -and ($CheckServerDefaultDisable -eq 1)) {
        return "All reg keys changed successfully. Restart the system for the changes to take effect."
    } ELSE {
        return "Reg changes failed!`nthe values for $ClientRegPath :`nEnabled Dword: $CheckClientEnabled`nDisableByDefault Dword: $CheckClientDefaultDisable`nThe values for $ServerRegPath :`nEnabled Dword: $CheckServerEnabled`nDisabledByDefault Dword: $CheckServerDefaultDisable"
    }
}

function DisableTLS11 {
    Clear-Host

    $Protocol = "TLS 1.1"
    $ClientRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol\Client"
    $ServerRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol\Server"
    $TestServerPath = Test-Path -Path $ServerRegPath -PathType Container
    $TestClientPath = Test-Path -Path $ClientRegPath -Pathtype Container


    $CheckClientEnabled = Get-ItemPropertyValue -Path $ClientRegPath -Name "Enabled" -ErrorAction SilentlyContinue
    $CheckClientDefaultDisable = Get-ItemPropertyValue -Path $ClientRegPath -Name "DisabledByDefault" -ErrorAction SilentlyContinue
    $CheckServerEnabled = Get-ItemPropertyValue -Path $ServerRegPath -Name "Enabled" -ErrorAction SilentlyContinue
    $CheckServerDefaultDisable = Get-ItemPropertyValue -Path $ServerRegPath -Name "DisabledByDefault" -ErrorAction SilentlyContinue

    #Checking the reg keys are now set to the expected value, spitting out the values if they're wrong
    if (($CheckClientEnabled -eq 0) -and ($CheckClientDefaultDisable -eq 1) -and ($CheckServerEnabled -eq 0) -and ($CheckServerDefaultDisable -eq 1)) {
        return "$Protocol is already disabled!"
    }

    if (!$TestServerPath) {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\" -Name $Protocol -ErrorAction SilentlyContinue
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol" -Name "Server"
    }

    if (!$TestClientPath) {
         New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\" -Name $protocol -ErrorAction SilentlyContinue
         New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol" -Name "Client"
    }
    Clear-Host
    #Setting reg keys to disable the protocol
    Set-ItemProperty -Path $ClientRegPath -Name "Enabled" -Value 0 -Type DWord -Force 
    Set-ItemProperty -Path $ClientRegPath -Name "DisabledByDefault" -Value 1 -Type DWord -Force 
    Set-ItemProperty -Path $ServerRegPath -Name "Enabled" -Value 0 -Type DWord -Force 
    Set-ItemProperty -Path $ServerRegPath -Name "DisabledByDefault" -Value 1 -Type DWord -Force

    
    $CheckClientEnabled = Get-ItemPropertyValue -Path $ClientRegPath -Name "Enabled"
    $CheckClientDefaultDisable = Get-ItemPropertyValue -Path $ClientRegPath -Name "DisabledByDefault"
    $CheckServerEnabled = Get-ItemPropertyValue -Path $ServerRegPath -Name "Enabled"
    $CheckServerDefaultDisable = Get-ItemPropertyValue -Path $ServerRegPath -Name "DisabledByDefault"

    #Checking the reg keys are now set to the expected value, spitting out the values if they're wrong
    if (($CheckClientEnabled -eq 0) -and ($CheckClientDefaultDisable -eq 1) -and ($CheckServerEnabled -eq 0) -and ($CheckServerDefaultDisable -eq 1)) {
        return "All reg keys changed successfully. Restart the system for the changes to take effect."
    } ELSE {
        return "Reg changes failed!`nthe values for $ClientRegPath :`nEnabled Dword: $CheckClientEnabled`nDisableByDefault Dword: $CheckClientDefaultDisable`nThe values for $ServerRegPath :`nEnabled Dword: $CheckServerEnabled`nDisabledByDefault Dword: $CheckServerDefaultDisable"
    }
}
function DisableTLS12 {
    Clear-Host

    $Protocol = "TLS 1.2"
    $ClientRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol\Client"
    $ServerRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol\Server"
    $TestServerPath = Test-Path -Path $ServerRegPath -PathType Container
    $TestClientPath = Test-Path -Path $ClientRegPath -Pathtype Container


    $CheckClientEnabled = Get-ItemPropertyValue -Path $ClientRegPath -Name "Enabled" -ErrorAction SilentlyContinue
    $CheckClientDefaultDisable = Get-ItemPropertyValue -Path $ClientRegPath -Name "DisabledByDefault" -ErrorAction SilentlyContinue
    $CheckServerEnabled = Get-ItemPropertyValue -Path $ServerRegPath -Name "Enabled" -ErrorAction SilentlyContinue
    $CheckServerDefaultDisable = Get-ItemPropertyValue -Path $ServerRegPath -Name "DisabledByDefault" -ErrorAction SilentlyContinue

    #Checking the reg keys are now set to the expected value, spitting out the values if they're wrong
    if (($CheckClientEnabled -eq 0) -and ($CheckClientDefaultDisable -eq 1) -and ($CheckServerEnabled -eq 0) -and ($CheckServerDefaultDisable -eq 1)) {
        return "$Protocol is already disabled!"
    }

    if (!$TestServerPath) {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\" -Name $Protocol -ErrorAction SilentlyContinue
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol" -Name "Server"
    }

    if (!$TestClientPath) {
         New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\" -Name $protocol -ErrorAction SilentlyContinue
         New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol" -Name "Client"
    }
    Clear-Host
    #Setting reg keys to disable the protocol
    Set-ItemProperty -Path $ClientRegPath -Name "Enabled" -Value 0 -Type DWord -Force 
    Set-ItemProperty -Path $ClientRegPath -Name "DisabledByDefault" -Value 1 -Type DWord -Force 
    Set-ItemProperty -Path $ServerRegPath -Name "Enabled" -Value 0 -Type DWord -Force 
    Set-ItemProperty -Path $ServerRegPath -Name "DisabledByDefault" -Value 1 -Type DWord -Force

    
    $CheckClientEnabled = Get-ItemPropertyValue -Path $ClientRegPath -Name "Enabled"
    $CheckClientDefaultDisable = Get-ItemPropertyValue -Path $ClientRegPath -Name "DisabledByDefault"
    $CheckServerEnabled = Get-ItemPropertyValue -Path $ServerRegPath -Name "Enabled"
    $CheckServerDefaultDisable = Get-ItemPropertyValue -Path $ServerRegPath -Name "DisabledByDefault"

    #Checking the reg keys are now set to the expected value, spitting out the values if they're wrong
    if (($CheckClientEnabled -eq 0) -and ($CheckClientDefaultDisable -eq 1) -and ($CheckServerEnabled -eq 0) -and ($CheckServerDefaultDisable -eq 1)) {
        return "All reg keys changed successfully. Restart the system for the changes to take effect."
    } ELSE {
        return "Reg changes failed!`nthe values for $ClientRegPath :`nEnabled Dword: $CheckClientEnabled`nDisableByDefault Dword: $CheckClientDefaultDisable`nThe values for $ServerRegPath :`nEnabled Dword: $CheckServerEnabled`nDisabledByDefault Dword: $CheckServerDefaultDisable"
    }
}

function EnableSSL30 {
    $Protocol = "SSL 3.0"

    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol"
    $TestRegPath = Test-Path -Path $RegPath

    if ($TestRegPath) {
        Remove-Item -Path $RegPath -Force
        $TestRegPath = Test-Path -Path $RegPath
        if (!$TestRegPath) { return "$Protocol Enabled. Please restart the machine for this change to take effect." }
    }
    ELSE {
        return "$Protocol is already enabled!"
    }
}

function EnableTLS10 {
    $Protocol = "TLS 1.0"

    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol"
    $TestRegPath = Test-Path -Path $RegPath

    if ($TestRegPath) {
        Remove-Item -Path $RegPath -Force
        $TestRegPath = Test-Path -Path $RegPath
        if (!$TestRegPath) { return "$Protocol Enabled. Please restart the machine for this change to take effect." }
    } ELSE {
        return "$Protocol is already enabled!"
    }
}

function EnableTLS11 {
    $Protocol = "TLS 1.1"

    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol"
    $TestRegPath = Test-Path -Path $RegPath

    if ($TestRegPath) {
        Remove-Item -Path $RegPath -Force
        $TestRegPath = Test-Path -Path $RegPath
        if (!$TestRegPath) { return "$Protocol Enabled. Please restart the machine for this change to take effect." }
    }
    ELSE {
        return "$Protocol is already enabled!"
    }
}

function EnableTLS12 {
    $Protocol = "TLS 1.2"

    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$Protocol"
    $TestRegPath = Test-Path -Path $RegPath

    if ($TestRegPath) {
        Remove-Item -Path $RegPath -Force
        $TestRegPath = Test-Path -Path $RegPath
        if (!$TestRegPath) { return "$Protocol Enabled. Please restart the machine for this change to take effect." }
    }
    ELSE {
        return "$Protocol is already enabled!"
    }
}

Write-Host "*******************************"
Write-Host "****** Commands Available: *****"
Write-Host "********* EnableTLS10 *********"
Write-Host "********* EnableTLS11 *********"
Write-Host "********* EnableTLS12 *********"
Write-Host "********* EnableSSL30 *********"
Write-Host "*******************************"
Write-Host "********* DisableSSL30 ********"
Write-Host "********* DisableTLS10 ********"
Write-Host "********* DisableTLS11 ********"
Write-Host "********* DisableTLS12 ********"
Write-Host "*******************************"

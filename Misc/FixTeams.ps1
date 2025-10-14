Get-AppxProvisionedPackage -Online | where {$_.Displayname -like "*teams*"} | Remove-AppxProvisionedPackage -Online

Get-AppxPackage *teams* -AllUsers | Remove-AppxPackage -AllUsers

try {
    Get-ChildItem "C:\Windows\Temp\" -Recurse -ErrorAction Continue | Remove-Item -Recurse -Force -ErrorAction Continue
    Get-ChildItem "C:\ProgramData\Temp\" -Recurse -ErrorAction Continue | Remove-Item -Recurse -Force -ErrorAction Continue
}
catch {
    Write-Host "Removing items failed."
    exit
}

(gwmi win32_product | where {$_.name -match "Teams"}).Uninstall

Remove-Item "C:\Program Files\Microsoft\Teams" -Recurse -Force -ErrorAction SilentlyContinue

Remove-Item "HKLM:\SOFTWARE\Microsoft\Teams" -Recurse -Force -ErrorAction SilentlyContinue

iwr "https://raw.githubusercontent.com/eitgrp/PowerShell/refs/heads/master/Update%20Scripts/Install-TeamsNewonServer2019-x64.ps1" | iex

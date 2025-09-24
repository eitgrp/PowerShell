Get-AppxProvisionedPackage -Online `
	| where {$_.Displayname -like "*teams*"} `
		| Remove-AppxProvisionedPackage -Online

Get-AppxPackage *teams* -AllUsers `
	| Remove-AppxPackage -AllUsers

Get-ChildItem "C:\Windows\Temp\" -Recurse `
    | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Get-ChildItem "C:\ProgramData\Temp\" -Recurse `
    | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

(gwmi win32_product `
    | where {$_.name -match "Teams"}).Uninstall

Remove-Item "C:\Program Files (x86)\Microsoft\Teams" -Recurse -Force -ErrorAction SilentlyContinue

Remove-Item "HKLM:\SOFTWARE\Microsoft\Teams" -Recurse -Force -ErrorAction SilentlyContinue

iwr "https://raw.githubusercontent.com/eitgrp/PowerShell/refs/heads/master/Update%20Scripts/Install-TeamsNewonServer2019-x86.ps1" | iex

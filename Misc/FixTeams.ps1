Get-AppxProvisionedPackage -Online `
	| where {$_.Displayname -like "*teams*"} `
		| Remove-AppxProvisionedPackage -Online

Get-AppxPackage *teams* -AllUsers `
	| Remove-AppxPackage -AllUsers

Get-ChildItem "C:\Windows\Temp\" -Recurse `
    | Remove-Item -Recurse -Force

Get-ChildItem "C:\ProgramData\Temp\" -Recurse `
    | Remove-Item -Recurse -Force

(gwmi win32_product `
    | where {$_.name -match "Teams"}).Uninstall

Remove-Item "C:\Program Files\Microsoft\Teams" -Recurse -Force

Remove-Item "HKLM:\SOFTWARE\Microsoft\Teams" -Recurse -Force

Start-Process Powershell -args "C:\source\software\Install-TeamsNewonServer2019-x64.ps1"

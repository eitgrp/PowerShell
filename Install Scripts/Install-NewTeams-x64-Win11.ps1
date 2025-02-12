[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://statics.teams.cdn.office.net/production-windows-x64/enterprise/webview2/lkg/MSTeams-x64.msix" -OutFile "$ENV:Temp\MSTeams-x64.msix"
Add-AppxProvisionedPackage -Online -PackagePath "$ENV:Temp\MSTeams-x64.msix" -SkipLicense
Remove-Item "$ENV:Temp\MSTeams-x64.msi" -Force

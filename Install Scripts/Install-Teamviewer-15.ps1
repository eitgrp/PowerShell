New-Item "C:\source\Software\Teamviewer" -ItemType Directory
Invoke-WebRequest -Uri "https://dl.teamviewer.com/download/version_15x/TeamViewer_Setup_x64.exe" -OutFile "C:\Source\Software\Teamviewer\Teamviewer.exe"
Start-Process "C:\source\Software\Teamviewer\Teamviewer.exe" -args "/S" -Wait

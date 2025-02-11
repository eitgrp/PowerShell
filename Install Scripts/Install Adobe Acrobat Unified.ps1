New-Item C:\Source -ItemType Directory -ErrorAction SilentlyContinue
New-Item C:\Source\Software -ItemType Directory -ErrorAction SilentlyContinue
New-Item C:\Source\Software\Acrobat -ItemType Directory -ErrorAction SilentlyContinue
Invoke-WebRequest "https://static.desktopservice.eu/downloads/Source/Software/Acrobat/Acrobat.zip" -OutFile "C:\Source\Software\Acrobat\Acrobat.zip"
Expand-Archive -Path "C:\Source\Software\Acrobat\Acrobat.zip" -DestinationPath "C:\Source\Software\Acrobat\"
Start-Process msiexec -args '/I "C:\source\Software\Acrobat\Adobe Acrobat\AcroPro.msi" transforms="C:\source\Software\Acrobat\Adobe Acrobat\AcroPro.mst" /qn' -Wait

$LatestVersion = [system.version]::Parse((Get-EvergreenApp SoberLemurPDFSamBasic | where {($_.Architecture -eq "x64") -and ($_.Type -eq "msi")}).Version)
$DownloadURL = (Get-EvergreenApp SoberLemurPDFSamBasic | where {($_.Architecture -eq "x64") -and ($_.Type -eq "msi")}).uri
try {
    $InstalledVersion = [system.version]::Parse((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | where {$_.DisplayName -like "PDFSam*"}).DisplayVersion)
} Catch {
    $InstalledVersion = [system.version]::Parse((Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | where {$_.DisplayName -like "PDFSam*"}).DisplayVersion)
}
if ($InstalledVersion -lt $LatestVersion) {
    $Test = Test-Path -path "C:\source\Software\PDFSam\"
    if (!$Test) {
        mkdir C:\source\Software\PDFSam
    }
    iwr $DownloadURL -OutFile "C:\source\Software\PDFSam\PDFSam-$LatestVersion.msi"
    Start-Process msiexec -args "/i `"C:\source\Software\PDFSam\PDFSam-$LatestVersion.msi`" /qn" -Wait
}

$targetrootfolder = "C:\Source\DNS\"
$datestamp = Get-Date -Format "yyyyMMddhhmmss"
$targetfolder = $TargetRootFolder+$DateStamp

if (-not (Test-Path $targetfolder)) {
    $output = New-Item -ItemType Directory -Path $targetFolder
}

$zones = Get-DnsServerZone
Write-Host "Found $(($zones).count) zones to export..."
foreach ($zone in $zones) {
    $Report = [System.Collections.Generic.List[Object]]::new()
    $ZoneName = $zone.ZoneName
    $zoneInfo = Get-DnsServerResourceRecord -ZoneName $ZoneName
    foreach ($info in $zoneInfo) {
        $timestamp = if ($info.Timestamp) { $info.Timestamp } else { "static" }
        $timetolive = $info.TimeToLive.TotalSeconds
        $recordData = switch ($info.RecordType) {
            'A' { $info.RecordData.IPv4Address }
            'CNAME' { $info.RecordData.HostnameAlias }
            'NS' { $info.RecordData.NameServer }
            'SOA' { "[$($info.RecordData.SerialNumber)] $($info.RecordData.PrimaryServer), $($info.RecordData.ResponsiblePerson)" }
            'SRV' { $info.RecordData.DomainName }
            'PTR' { $info.RecordData.PtrDomainName }
            'MX' { $info.RecordData.MailExchange }
            'AAAA' { $info.RecordData.IPv6Address }
            'TXT' { $info.RecordData.DescriptiveText }
            default { $null }
        }
        $ReportLine = [PSCustomObject]@{
            Name       = $zone.ZoneName
            Hostname   = $info.Hostname
            Type       = $info.RecordType
            Data       = $recordData
            Timestamp  = $timestamp
            TimeToLive = $timetolive
        }
        $Report.Add($ReportLine)
    }
    $Report | Export-Csv "$targetFolder\$ZoneName.csv" -NoTypeInformation -Encoding utf8
    Write-Host "  Exported $zonename"
    $Report = $null
}

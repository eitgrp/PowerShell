$ProvisonedPackages = @(
    'Microsoft.OutlookForWindows',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.ZuneMusic',
    'Microsoft.ZuneVideo',
    'MicrosoftCorporationII.QuickAssist',
    'Microsoft.BingNews',
    'Microsoft.BingWeather',
    'Microsoft.GamingApp',
    'Microsoft.PowerAutomateDesktop',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.MicrosoftOfficeHub',
    'Microsoft.Getstarted',
    'Clipchamp.Clipchamp',
    'Microsoft.Windows.DevHome',
    'MicrosoftTeams' # This is Teams (Personal)
)

$AppxPackages = @(
    'Microsoft.ZuneMusic',
    'Microsoft.ZuneVideo',
    'Microsoft.OutlookForWindows',
    'Microsoft.BingNews',
    'Microsoft.BingWeather',
    'Microsoft.GamingApp',
    'Microsoft.PowerAutomateDesktop',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.MicrosoftOfficeHub',
    'Microsoft.Getstarted',
    'Clipchamp.Clipchamp',
    'Microsoft.Windows.DevHome',
    'MicrosoftTeams' # This is Teams (Personal)
)

FOREACH ($app in $ProvisionedPackages) {
    get-appxprovisionedpackage -online `
        | Where-Object {$_.Displayname -match $app} `
            | remove-appxprovisionedpackage -Online -ErrorAction SilentlyContinue
}

FOREACH ($package in $AppxPackages) {
    Get-AppxPackage -AllUsers $package `
        | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
}


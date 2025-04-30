<#
This script will take a list of UPNs from a CSV file and find the associated mailbox sizes for those UPNs.

Before using this script you will need to install the Exchange Online module (Install-Module ExchangeOnlineManagement)

You will also need to create a CSV with a singular column with a header of "UPN" with the UPNs listed underneath it

After doing so Update the "$SourceCSV" and "$OutputCSV" variables to the relavent paths, then you're good to go
#>

$SourceCSV = "PATH_TO_CSV"

$OutputCSV = "PATH_TO_CSV"

Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue

Connect-ExchangeOnline

$users = Import-Csv $SourceCSV

$Allresults = @()
foreach ($user in $users.UPN) {
    
    $Mailbox = (Get-EXOMailboxStatistics $user).TotalItemSize.Value
    $Size = (select-string -inputobject $Mailbox -pattern '.+ GB').Matches.Value
    $results = New-Object -TypeName pscustomobject
    $results | Add-Member -Name "UPN" -value $user -MemberType NoteProperty
    $results | Add-Member -Name "Size" -value $Size -MemberType NoteProperty

    $Allresults += $results 
}
Write-host $allresults
$allresults | Export-Csv -Path $OutputCSV

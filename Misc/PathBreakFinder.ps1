#############################################################################################################################################################################
# A script that can be used to find where a path breaks, which can be pasted as a function to either output more info on errors or rebuild the path you are trying to reach #
#############################################################################################################################################################################


$path = "HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters\asda\wefegfeg\asfsdf"

$test = Test-Path -Path $path -PathType Container

if (!$test) {
    [array]$SplitPath = $path.split("\")
    $SectionCount = ($SplitPath | Measure-Object).Count
    $x = 0
    DO {
        $x++
        $y = $SectionCount - $x
        [string]$z = ($SplitPath[0..$y] -join '\')
        $FindFault = Test-Path -Path $z -PathType Container
    } Until($FindFault)
    Write-Host "The last working path is $z"
}

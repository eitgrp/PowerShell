###############################################################################################################################################################################
# A script that can be used to find where a path breaks, which can be pasted as a function to either output detailed errors, or ran as a user to find where permissions break #
#                                     ! This script does not support rebuilding of the desired path, however I may add it in the future !                                     #
###############################################################################################################################################################################

$path = "HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters\asda\wefegfeg\asfsdf"


# Figuring out what kind of path we're looking for
If ($path -like "*.???") {
    $PathType = "leaf"
} elseif ($Path.StartsWith("HKLM:")) {
    $PathType = "Any"
} else {
    $PathType = "Container"
}

# Seeing if it's a network path or not
if ($Path.StartsWith("\\")) {
    $Path = "filesystem::" + $Path
    if (!Test-Path -Path $Path -PathType $PathType) {
        $Path = $Path.TrimStart("filesystem::\\")
        # Splitting the path into sections that we can subtract as we test
        [array]$SplitPath = $path.split("\")
        # Measuring how many sections there are in the original path so we can work backwards, removing each part at a time until we have a working path
        $SectionCount = ($SplitPath | Measure-Object).Count
        #X is a counter for how many parts of the path to take away
        $x = 0
        # This DO loop will take 1 section away and retest the path until it finds a working path, or its the root of the path
        DO {
            # We are no longer looking for anything other than a container in this loop, so we set PathType to container
            $PathType = "Container"
            $x++
            $y = $SectionCount - $x
            # Joining the parts of the path back together to make a cohesive path to test
            [string]$z = "filesystem::\\" + ($SplitPath[0..$y] -join '\')
            $FindFault = Test-Path -Path $z -PathType $PathType
            # If Y is equal to one, that means the problem is between the first character of the path and the first "\", meaning we've hit the root of the path, and need to escape the DO loop.
            if ($y -eq 1) { Return "The root of this path cannot be found! Check the starting hostname/IP Address" }
        } Until( $FindFault )
        Return "The last working path is $($z.TrimStart("Filesystem::"))"
    } ELSE { Return "This path already works!" }
} ELSE {
    # Refer to the comments above as this logic is basically the same, minus the messing around needed for network paths
    if (!Test-Path -Path $path -PathType $PathType) {
        [array]$SplitPath = $path.split("\")
        $SectionCount = ($SplitPath | Measure-Object).Count
        $x = 0
        DO {
            $PathType = "Container"
            $x++
            $y = $SectionCount - $x
            [string]$z = ($SplitPath[0..$y] -join '\')
            $FindFault = Test-Path -Path $z -PathType $PathType
            if ($y -eq 1) { Return "This path is broken at the root! Does this path start with the correct drive letter?" }
        } Until($FindFault)
        Return "The last working path is $z"
    } ELSE { Return "This path already works!" }
}

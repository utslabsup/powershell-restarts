######
#
#  Labs (Maximum Efficiency) Restart Script
#
#  author: Ben Carroll, adapted from
#  author: Daniel Angeloni
#
#  support: ben.carroll@uts.edu.au
#
######

# Preface with: Set-ExecutionPolicy RemoteSigned -Scope Process

# Basic Notes; Only labs, not pods or lecs, for safety.
# Pretty flexible with input, accepts space-separated for multiple labs
# But, must fall on a boundary, e.g. building, floor, or room, not in between

while (1) {
    $input = Read-Host -Prompt "Input lab locations (e.g. CB04 CB0806 CB11.01.000)"

    $locations = $input.trim().Split(" ")

    # Define variables for filtering and grouping
    $includeFilters = @()
    $excludeFilters = @()

    foreach ($location in $locations) {
        if ($location.StartsWith("-")) {
            # Negative entry, add to exclude filters
            $excludeFilters += $location.Substring(1)
        } else {
            # Positive entry, add to include filters
            $includeFilters += $location
        }
    }

    # Manually define certain collections to bypass AD search. This is implemented to allow for aliases such as CB0206POD, which will return no AD objects.
    $overrideFile = ".\_overrides\CB"
    $computers = @()

    $validRegex = "(?'type'lab|lec|pod)?(?'building'05[abcd]|m1|ym|\d{2})(?:(?'floor'(?<=05[abcd])\d|b[1-4]|\d{2})(?:(?'room'\d{3}|\dv\d|[A-z]\d{2}|)(?:(?'computer'(?:[A-z]\d{2}|\d{3})(?:LL|))|)|)|)"

    foreach ($includeFilter in $includeFilters) {
        $lab = $includeFilter.ToUpper().TrimStart("CB")
        $lab = $lab.TrimStart("B")
        $lab = $lab.TrimStart("LAB")
        $lab = $lab.Replace(".", "")
        Write-Host " > Include lab interpreted as: '$lab'"
        if ($lab -match $validRegex) {
            if (Test-Path -LiteralPath "$overrideFile$lab.txt" -PathType Leaf) {
                # Use the override file
                $computers += Get-Content -Path "$overrideFile$lab.txt"
            } else {
                # Pull computers from AD
                $computers += (Get-ADComputer -Filter "Name -like 'LAB$($lab.ToString())*'" | Select-Object -ExpandProperty Name)
            }
        } else {
            Write-Host "Invalid format for include: $includeFilter" -ForegroundColor red
        }
    }

    $included_computers_count = $computers.length
    Write-Host "   > Retrieved $included_computers_count computers from includes."

    # Exclude computers based on negative filters
    foreach ($excludeFilter in $excludeFilters) {
        $lab = $excludeFilter.ToUpper().TrimStart("CB")
        $lab = $lab.TrimStart("B")
        $lab = $lab.TrimStart("LAB")
        Write-Host " > Exclude lab interpreted as: '$lab'"
        if ($lab -match $validRegex) {
            $computers = $computers | Where-Object { $_ -notlike "LAB$lab*" }
        } else {
            Write-Host "Invalid format for exclude: $excludeFilter" -ForegroundColor red
            return 
        }
    }

    $final_computers_count = $computers.length
    $removed_computers = $included_computers_count - $final_computers_count
    Write-Host "   > Removed $removed_computers computers via excludes."

    $counter = 0
    $successful = 0

    foreach ($computer in $computers) {
        # Test connection to each computer
        if (Test-NetConnection -ComputerName $computer -InformationLevel Quiet) {
            # Attempt restart
            Restart-Computer -ComputerName $computer -ErrorVariable errmsg -ErrorAction SilentlyContinue
            if ($errmsg -ne $null) {
                # Error log: Restart failed
                Write-Host "$errmsg" -ForegroundColor red
            } else {
                # Success
                Write-Host "$computer restarted." -ForegroundColor green
                $successful++
            }
        } else {
            # Error log: Connection failed
            Write-Host "$computer is offline." -ForegroundColor red
        }
        $counter++
    }

    if ($counter -ne 0) {
        Write-Host "Finished for $($locations -join ', '), success rate of $('{0:P2}' -f ($successful / $counter))"
    } else {
        Write-Host "No computers found for the specified locations." -ForegroundColor Yellow
    }
}

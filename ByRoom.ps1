######
#
#  Lab Restart Script
#
#  author: Daniel Angeloni
#
#  support: daniel.angeloni@uts.edu.au
#
###### Set-ExecutionPolicy RemoteSigned -Scope Process


while (1) {
    $lab = Read-Host -Prompt "Input lab location (e.g. 'CB0105000' or 'B0105000')"

    # Handle the different potential inputs
    if ($lab.SubString(0,2) -match "CB") {
        $lab = $lab.SubString(2)
    } elseif ($lab[0] -match "B") {
        $lab = $lab.SubString(1)
    } else {
        Write-Host "Invalid format." 
        continue
    }

    # Pull computers from AD (note to self: add in OU for better search functionality and/or searching by room OU)
    $computers = Get-ADComputer -Filter "Name -like 'LAB$($lab.ToString())*'" | select Name
    $counter = 0
    $successful = 0

    foreach ($computer in $computers.Name) {
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

    if ($count -ne 0) {
        Write-Host "Finished for CB$lab, success rate of $('{0:P2}' -f ($successful / $counter))"
    } else {
        Write-Host "Lab does not exist." 
    }
}

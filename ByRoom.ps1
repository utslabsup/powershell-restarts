######
#
#  Lab Restart Script
#
#  author: Andrew Gou
#
#  support: sophie.ryan@uts.edu.au & daniel.angeloni@uts.edu.au
#
###### Set-ExecutionPolicy RemoteSigned -Scope Process

# Machine name text file directory and error log directory, change as needed.
$fileDir = "Labs\"
$errorDir = "Errors\"
$date = Get-Date -Format "dd.MM.yy"

# Create error log file
If (!(Test-Path -Path "$errorDir$date.txt"))
{
    New-Item -ItemType "file" -Path "$errorDir$date.txt" | Out-Null
}

Do 
{
    # Input lab name
    while(1) {
        $lab = Read-Host -Prompt "Input lab location (e.g. 'CB0105000')"

        if (Test-Path -LiteralPath "$fileDir$lab.txt" -PathType Leaf)
        {
	    $counter = 0
	    $successful = 0
            foreach ($computer in Get-Content -path $fileDir$lab.txt)
            {
                # Test connection to each computer
                if (Test-NetConnection -ComputerName $computer -InformationLevel Quiet)
                {
                    # Attempt restart
                    Restart-Computer -ComputerName $computer -ErrorVariable errmsg -ErrorAction SilentlyContinue
                        if ($errmsg -ne $null)
                        {
                            # Error log: Restart failed
                            Write-Host "$errmsg" -ForegroundColor red
                            Add-Content -Path "$errorDir$date.txt" -Value "$errmsg"
                        }
                        else
                        {
                            # Success
                            Write-Host "$computer restarted." -ForegroundColor green
			    $successful++
                        }
                }
                else 
                {
                    # Error log: Connection failed
                    Write-Host "$computer is offline." -ForegroundColor red
                    Add-Content -Path "$errorDir$date.txt" -Value "$computer is offline."
                }
	        $counter++
            }
        }
        else
        {
            # Lab name entered incorrectly
            Write-Host "Lab does not exist."
        }
        Write-Host "Finished for $lab, success rate of $('{0:P2}' -f ($successful / $counter))" 
    }
}
Until (Test-Path -LiteralPath "$fileDir$lab.txt" -PathType Leaf)


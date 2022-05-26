# Written by daniel angeloni

while(1) {
    $ComputerName = Read-Host -Prompt 'Computer Name or IP Address'
    # Attempt restart
    Restart-Computer -ComputerName $ComputerName -ErrorVariable errmsg -ErrorAction SilentlyContinue
    if ($errmsg -ne $null) {
        # Error log: Restart failed
        Write-Host "$errmsg" -ForegroundColor red
    }
    else {
        # Success
        Write-Host "$ComputerName restarted." -ForegroundColor green
    }
}
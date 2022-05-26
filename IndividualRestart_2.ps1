# Written by daniel angeloni

# This is a simple shutdown script to restart individual computers from a powershell terminal. This is used when the other script returns "Access is denied." as it often works when the other doesn't.
 
while(1) {
    $ComputerName = Read-Host -Prompt 'Computer Name'
    # Attempt restart
    $s = New-PSSession -ComputerName $ComputerName
    Invoke-Command -Session $s -Scriptblock {shutdown -r} -ErrorVariable errmsg -ErrorAction SilentlyContinue
    if ($errmsg -ne $null) {
        # Error log: Restart failed
        Write-Host "$errmsg" -ForegroundColor red
    }
    else {
        # Success
        Write-Host "$ComputerName restarted." -ForegroundColor green
    }
    Remove-PSSession $s
}
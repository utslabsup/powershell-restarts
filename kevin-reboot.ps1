#TODO: Add option for Manual PCs
Param(
<#
    NB: All params must be whitelisted for at least one parameterset
    [Parameter(Mandatory = $false,
    Position = 0,
    ParameterSetName = 'Prefix',
    HelpMessage = 'Room Prefix Given')]
    [string]$Prefix = $(throw)
<#
    [Parameter(Mandatory = $true,
        ParameterSetName = 'Size',
        HelpMessage = 'Size of room.',
        Position = 0)]
        #>
        [int]$Size = $(throw "-size of room is required"),

[switch]$IncludeLectern = $false, #Exclude lecterns by default
[switch]$IncludeCurrent = $false #Exclude current PC by default
)

#Check hostname
$Current = $env:COMPUTERNAME
$Prefix = $Current -replace ".{3}$"
#Filter out prefix/suffix

#TODO: Check if user is logged on
#TODO: Confirm restarts
$started = @()
$waiting = @()
$results = @()
#start from 0 if the lectern is to be restarted. If IncludeCurrent is $false, then this $true condition will be ignored if this script is run from the lectern.
$begin = If ($IncludeLectern) {0} Else {1};

#No force.
#Change to PSShutdown at some point
# Also check user login before initiating shutdown
function Restart-NamedPC {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
#TODO test output to parent job
    Write-Host "Attempting to Restart"$Name
    $started += Start-Job -ScriptBlock {
        Param($Name)
        try {
            #write-host $Name
            Restart-Computer -ComputerName $Name -ErrorAction Stop
            Write-Host "Successfully Restarted"$Name #-Verbose 4>&1
        } catch {
            Write-Host "Error restarting PC"$Name":"$_  #-Verbose 4>&1
        }
        #Catch user logged on, skip
        
    } -Name 'reboot-job' -ArgumentList $Name
}

#Attempt to restart each computer.
#TODO : Async detail
$begin..$Size |
    % { $Prefix +'{0:d3}' -f $_ } | 
        % {
            if ($_ -ne $env:COMPUTERNAME -and -not $IncludeCurrent) {
                Restart-NamedPC -Name $_
            } else {
                Write-Host "Skipping Current PC:"$_
            }
        }

Wait-Job * | Out-Null

foreach($job in Get-Job)
{
    $result = Receive-Job $job
    Write-Host $result
}

Remove-Job -state Completed, Failed
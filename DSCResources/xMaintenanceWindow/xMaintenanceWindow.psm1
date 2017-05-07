<#
.SYNOPSIS
    Gets the current resource status
.PARAMETER ScheduleStart
    The start of the schedule. The property TimeOfDay is used for setting the schedule
.PARAMETER ScheduleEnd
    The end of the schedule. The property TimeOfDay is used for setting the schedule
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.DateTime]
        $ScheduleStart,

        [parameter(Mandatory = $true)]
        [System.DateTime]
        $ScheduleEnd
    )

    $returnValue = @{
    ScheduleStart = $ScheduleStart
    ScheduleEnd = $ScheduleEnd
    CurrentTime = Get-Date
    }

    return $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.DateTime]
        $ScheduleStart,

        [parameter(Mandatory = $true)]
        [System.DateTime]
        $ScheduleEnd
    )

    # Set should throw when in window to cancel processing
    $currentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message ('Nothing to set. Maintenance window start: {0}, maintenance window end: {1}. Current time {2}' -f
        $ScheduleStart, $ScheduleEnd, $currentValues.CurrentTime)

        throw 'Hit maintenance schedule. Aborting Set-TargetResource to trigger dependecies'
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.DateTime]
        $ScheduleStart,

        [parameter(Mandatory = $true)]
        [System.DateTime]
        $ScheduleEnd
    )

    $currentValues = Get-TargetResource @PSBoundParameters
    return ($currentValues.CurrentTime.TimeOfDay -ge $ScheduleStart.TimeOfDay -and $currentValues.CurrentTime.TimeOfDay -le $ScheduleEnd.TimeOfDay)
}


Export-ModuleMember -Function *-TargetResource


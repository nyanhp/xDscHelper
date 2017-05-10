<#
.SYNOPSIS
    Returns the nth day of the month
.PARAMETER Year
    The year in which we check
.PARAMETER Month
    The number of the month in which we check
.PARAMETER Day
    The DayOfWeek object which occurrence we want
.PARAMETER Occurrence
    The n in nth day of the month
#>
function Get-DayOfMonth
{
    [CmdletBinding()]
    param
    (
        [System.Int16]
        $Year,

        [System.int16]
        $Month,

        [System.DayOfWeek]
        $Day,

        [System.int16]
        $Occurrence
    )

    $firstDayOfMonth = New-Object -TypeName System.DateTime($Year, $Month, 1)
    $firstOccurrence = $firstDayOfMonth.AddDays((7 - ([int]$firstDayOfMonth.DayOfWeek - [int]$Day)) % 7)

    return $firstOccurrence.AddDays(7 * ($Occurrence - 1))
}

<#
.SYNOPSIS
    Gets the current resource status
.PARAMETER ScheduleStart
    The start of the schedule. The property TimeOfDay is used for setting the schedule
.PARAMETER ScheduleEnd
    The end of the schedule. The property TimeOfDay is used for setting the schedule
.PARAMETER ScheduleType
    The desired schedule. If Daily is specified, DayOfWeek, DayOfMonth and DayNameOfMonth are ignored.
    If Weekly is specified, DayOfMonth is ignored. If Monthly is specified, DayOfWeek can be used to express nth Monday of the month
.PARAMETER DayOfWeek
    The day the maintenance window is defined for. ScheduleEnd can exceed the DayOfWeek
.PARAMETER DayOfMonth
    The nth day of a month. In conjunction with DayOfWeek uses e.g. the nth Monday of the month
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
        $ScheduleEnd,

        [ValidateSet('Once', 'Daily', 'Weekly', 'Monthly')]
        [System.String[]]
        $ScheduleType,

        [ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]
        [System.String]
        $DayOfWeek,

        [System.Int16]
        $DayOfMonth
    )

    $returnValue = @{
        ScheduleStart = $ScheduleStart
        ScheduleEnd = $ScheduleEnd
        CurrentTime = Get-Date
    }

    return $returnValue
}

<#
.SYNOPSIS
    Sets the current resource status
.PARAMETER ScheduleStart
    The start of the schedule. The property TimeOfDay is used for setting the schedule
.PARAMETER ScheduleEnd
    The end of the schedule. The property TimeOfDay is used for setting the schedule
.PARAMETER ScheduleType
    The desired schedule. If Daily is specified, DayOfWeek, DayOfMonth and DayNameOfMonth are ignored.
    If Weekly is specified, DayOfMonth is ignored. If Monthly is specified, DayOfWeek can be used to express nth Monday of the month
.PARAMETER DayOfWeek
    The day the maintenance window is defined for. ScheduleEnd can exceed the DayOfWeek
.PARAMETER DayOfMonth
    The nth day of a month. In conjunction with DayOfWeek uses e.g. the nth Monday of the month
#>
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
        $ScheduleEnd,

        [ValidateSet('Once', 'Daily', 'Weekly', 'Monthly')]
        [System.String[]]
        $ScheduleType,

        [ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]
        [System.String]
        $DayOfWeek,

        [System.Int16]
        $DayOfMonth
    )

    # Set should throw when in window to cancel processing
    $currentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message ('Nothing to set. Maintenance window start: {0}, maintenance window end: {1}. Current time {2}' -f 
        $ScheduleStart.TimeOfDay, $ScheduleEnd.TimeOfDay, $currentValues.CurrentTime)

    throw 'Outside of maintenance schedule. Aborting Set-TargetResource to trigger dependecies'
}

<#
.SYNOPSIS
    Tests the current resource status
.PARAMETER ScheduleStart
    The start of the schedule. The property TimeOfDay is used for setting the schedule
.PARAMETER ScheduleEnd
    The end of the schedule. The property TimeOfDay is used for setting the schedule
.PARAMETER ScheduleType
    The desired schedule. If Daily is specified, DayOfWeek, DayOfMonth and DayNameOfMonth are ignored.
    If Weekly is specified, DayOfMonth is ignored. If Monthly is specified, DayOfWeek can be used to express nth Monday of the month
.PARAMETER DayOfWeek
    The day the maintenance window is defined for. ScheduleEnd can exceed the DayOfWeek
.PARAMETER DayOfMonth
    The nth day of a month. In conjunction with DayOfWeek uses e.g. the nth Monday of the month
#>
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
        $ScheduleEnd,

        [ValidateSet('Once', 'Daily', 'Weekly', 'Monthly')]
        [System.String[]]
        $ScheduleType,

        [ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]
        [System.String]
        $DayOfWeek,

        [System.Int16]
        $DayOfMonth
    )

    $currentValues = Get-TargetResource @PSBoundParameters

    $now = $currentValues.CurrentTime.TimeOfDay
    $shouldSkipSet = $true

    Write-Verbose -Message ('Start: {0}, End {1}, Current: {2}' -f $ScheduleStart.TimeOfDay, $ScheduleEnd.TimeOfDay, $now)

    if ($ScheduleStart.TimeOfDay -le $ScheduleEnd.TimeOfDay)
    {
        Write-Verbose -Message 'Timespans for start and end appear to be on the same day.'
        $shouldSkipSet = $now -ge $ScheduleStart.TimeOfDay -and $now -le $ScheduleEnd.TimeOfDay
    }
    else
    {
        Write-Verbose -Message 'Timespans for start and end appear to be on different days.'
        $shouldSkipSet = $now -ge $ScheduleStart.TimeOfDay -or $now -le $ScheduleEnd.TimeOfDay
    }

    if ($ScheduleType -eq 'Once')
    {
        Write-Verbose -Message ('Schedule is Once, testing if {0} is in maintenance window' -f $currentValues.CurrentTime)
        $shouldSkipSet = $currentValues.CurrentTime -ge $ScheduleStart -and $currentValues.CurrentTime -le $ScheduleEnd
    }

    if ($ScheduleType -eq 'Once' -or $ScheduleType -eq 'Daily')
    {
        return $shouldSkipSet
    }

    $addDays = 0

    # If we had rollover, compare current date -1 days with reference dates. Otherwise 0 is added.
    if ($now -le $ScheduleEnd.TimeOfDay -and -not ($ScheduleStart.TimeOfDay -le $ScheduleEnd.TimeOfDay) )
    {
        Write-Verbose -Message 'We had rollover. Substracting one day from all current values'
        $addDays = -1
    }

    # Logic OR: Never enter set method (i.e return $false) when either argument is $true
    if ($ScheduleType -eq 'Weekly')
    {
        Write-Verbose -Message ('Weekly schedule. Comparing {0} for equality with {1}' -f 
            $currentValues.CurrentTime.AddDays($addDays).DayOfWeek.ToString(), $DayOfWeek
        )

        $shouldSkipSet = $shouldSkipSet -and ($currentValues.CurrentTime.AddDays($addDays).DayOfWeek.ToString() -eq $DayOfWeek)
    }

    if ($ScheduleType -eq 'Monthly')
    {
        Write-Debug -Message 'Monthly schedule.'

        if ($PSBoundParameters.ContainsKey('DayOfMonth') -and $PSBoundParameters.ContainsKey('DayOfWeek'))
        {
            $dom = Get-DayOfMonth -Year $currentValues.CurrentTime.AddDays($addDays).Year -Month $currentValues.CurrentTime.AddDays($addDays).Month -Day $DayOfWeek -Occurrence $DayOfMonth

            Write-Verbose -Message ('Comparing {0} for equality with {1}' -f 
                $currentValues.CurrentTime.AddDays($addDays).Date,
                $dom.Date
            )
            $shouldSkipSet = $shouldSkipSet -and ($currentValues.CurrentTime.AddDays($addDays).Date -eq $dom.Date)
        }
        else
        {
            Write-Verbose -Message ('Comparing {0} for equality with {1}' -f 
                $currentValues.CurrentTime.AddDays($addDays).Day,
                $DayOfMonth
            )
            $shouldSkipSet = $shouldSkipSet -and ($currentValues.CurrentTime.AddDays($addDays).Day -eq $DayOfMonth)
        }
    }    

    return $shouldSkipSet
}


Export-ModuleMember -Function *-TargetResource


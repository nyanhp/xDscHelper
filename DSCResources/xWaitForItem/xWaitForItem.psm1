function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [ValidateSet("Directory", "File")]
        [System.String]
        $Type,

        [System.UInt64]
        $Length,

        [System.UInt64]
        $MinimumLength,

        [System.UInt64]
        $ChildItemCount,

        [System.UInt64]
        $MinimumChildItemCount,

        [System.UInt32]
        $RetryInterval = 10,

        [System.UInt32]
        $RetryCount = 10,

        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure
    )

    $returnValue = @{
        Path = [System.String]::Empty
        Type = [System.String]::Empty
        Length = 0
        ChildItemCount = 0
        Ensure = [System.String]::Empty
    }

    Write-Verbose "Finding $path"
    $item = Get-Item $Path -ErrorAction SilentlyContinue
    
    if (-not $item)
    {
        $returnValue.Ensure = 'Absent'
        return $returnValue
    }

    $returnValue.Ensure = 'Present'
    $returnValue.Path = $Path

    if ($item.GetType().Name -eq 'DirectoryInfo')
    {
        $returnValue.Type = 'Directory'
        $returnValue.ChildItemCount = (Get-ChildItem $Path -Force -Recurse).Count
    }
    else
    {
        $returnValue.Type = 'File'
        $returnValue.Length = $item.Length
    }

    Write-Verbose $returnValue.Ensure
    Write-Verbose $returnValue.Path
    Write-Verbose $returnValue.ChildItemCount
    Write-Verbose $returnValue.Length
    Write-Verbose $returnValue.Type
    $returnValue    
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [ValidateSet("Directory", "File")]
        [System.String]
        $Type,

        [System.UInt64]
        $Length,

        [System.UInt64]
        $MinimumLength,

        [System.UInt64]
        $ChildItemCount,

        [System.UInt64]
        $MinimumChildItemCount,

        [System.UInt32]
        $RetryInterval = 10,

        [System.UInt32]
        $RetryCount = 10,

        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure
    )

    Write-Verbose "Looking for $Path"
        
    while (-not (Test-TargetResource @PSBoundParameters) -and $RetryCount -gt 0)
    {
        Write-Verbose "Looking for item '$Path' at '$(Get-Date)' ($RetryCount retries left)"
        
        Start-Sleep -Seconds $RetryInterval

        Write-Verbose "Stopped sleeping"
            
        $RetryCount--
    }
        
    if ($RetryCount)
    {
        Write-Verbose "Item '$Path' present ($RetryCount retries left)"
    }
    else
    {
        Write-Verbose "Item '$Path' was not present after $($RetryCount) retries and an interval of $($RetryInterval) seconds"
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [ValidateSet("Directory", "File")]
        [System.String]
        $Type,

        [System.UInt64]
        $Length,

        [System.UInt64]
        $MinimumLength,

        [System.UInt64]
        $ChildItemCount,

        [System.UInt64]
        $MinimumChildItemCount,

        [System.UInt32]
        $RetryInterval = 10,

        [System.UInt32]
        $RetryCount = 10,

        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure
    )

    Write-Verbose "Testing $path"
    $currentValues = Get-TargetResource @PSBoundParameters

    if ($currentValues.Ensure -eq 'Absent' -and $Ensure -eq 'Absent')
    {
        return $true
    }
    
    if ($Type -eq 'Directory' -and $PSBoundParameters.ContainsKey('MinimumChildItemCount'))
    {
        Write-Verbose -Message "Testing for at least $MinimumChildItemCount child items"
        return ($currentValues.ChildItemCount -ge $MinimumChildItemCount)
    }

    if ($Type -eq 'Directory' -and $PSBoundParameters.ContainsKey('ChildItemCount'))
    {
        Write-Verbose "Testing against $ChildItemCount child items"
        return ($ChildItemCount -eq $currentValues.ChildItemCount)
    }    
    
    if ($Type -eq 'File' -and $PSBoundParameters.ContainsKey('MinimumLength'))
    {
        Write-Verbose "Testing against minimum file length $MinimumLength"
        return ($currentValues.Length -ge $MinimumLength)
    }

    if ($Type -eq 'File' -and -$PSBoundParameters.ContainsKey('Length'))
    {
        Write-Verbose "Testing against file length $Length"
        return ($Length -eq $currentValues.Length)
    }

    if($CurrentValues.Ensure -eq 'Present' -and $Ensure -eq 'Present' -and ('MinimumChildItemCount','MinimumChildItemCount','MinimumLength','Length' -notin $PSBoundParameters.Keys))
    {
        Write-Verbose -Message "Item is present and no childitemcounts/lengths are being tested."
        return $true
    }

    return $false
}

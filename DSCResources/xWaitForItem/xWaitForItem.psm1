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
        [ValidateSet("Directory","File")]
        [System.String]
        $Type
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
        [ValidateSet("Directory","File")]
        [System.String]
        $Type,

        [System.UInt64]
        $Length,

        [System.UInt64]
        $ChildItemCount,

        [System.UInt32]
        $RetryInterval = 10,

        [System.UInt32]
        $RetryCount = 10,

        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure
    )

    Write-Verbose "Looking for $Path"
        
    while (-not (Test-TargetResource -Path $Path -Type $Type -ChildItemCount $ChildItemCount -Length $Length) -and $RetryCount -gt 0)
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
        Write-Error "Item '$Path' was not present after $($RetryCount) retries and an interval of $($RetryInterval) seconds"
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
        [ValidateSet("Directory","File")]
        [System.String]
        $Type,

        [System.UInt64]
        $Length,

        [System.UInt64]
        $ChildItemCount,

        [System.UInt32]
        $RetryInterval = 10,

        [System.UInt32]
        $RetryCount = 10,

        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure
    )
    Write-Verbose "Testing $path"
    $item = Get-Item $Path -ErrorAction SilentlyContinue
    if ((-not $item -and $Ensure -eq 'Present') -or ($item -and $Ensure -eq 'Absent'))
    {
        Write-Verbose "(-not $item -and $Ensure -eq 'Present') $(-not $item -and $Ensure -eq 'Present')"
        Write-Verbose "($item -and $Ensure -eq 'Absent') $($item -and $Ensure -eq 'Absent')"
        return $false
    }

    if ($Type -eq 'Directory')
    {
        Write-Verbose "Testing against $ChildItemCount child items"
        return ($ChildItemCount -eq (Get-ChildItem -Path $Path -Force -Recurse).Count)
    }
    else
    {
        Write-Verbose "Testing agains file length $Length"
        return ($Length -eq $item.Length)
    }
}

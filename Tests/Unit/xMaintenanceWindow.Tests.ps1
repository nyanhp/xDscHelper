#region HEADER
$script:DSCModuleName = 'xDscHelper' 
$script:DSCResourceName = 'xMaintenanceWindow' 

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
 
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName  `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope "$($script:DSCResourceName)" {

        Describe "$($script:DSCResourceName) - Test" {

            $testParameters = @{
                ScheduleStart = [datetime]::Today.AddHours(22)
                ScheduleEnd = [datetime]::Today.AddHours(6)
            }

            Context 'The current time does not fall within the maintenance window' {
                Mock -CommandName Get-Date -MockWith { [System.DateTime] '0001-01-01 07:00:00'  }
                It "Should test true" {
                    Test-TargetResource @testParameters | Should Be $true
                }
            }

            Context 'The current time falls within the maintenance window' {
                Mock -CommandName Get-Date -MockWith { [System.DateTime] '0001-01-01 05:00:00'  }

                It "Should return false in Test-TargetResource" {
                    Test-TargetResource @testParameters | Should Be $false
                }

                It "Should throw in Set-TargetResource" {
                    {Set-TargetResource @testParameters} | Should Throw
                }
            }

            Assert-VerifiableMocks
        }
    }
}
finally
{
    Invoke-TestCleanup
}


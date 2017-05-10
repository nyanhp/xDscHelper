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

        Describe "$($script:DSCResourceName) - Daily" {

            $testParameters = @{
                ScheduleStart = [datetime]::Today.AddHours(22)
                ScheduleEnd = [datetime]::Today.AddHours(6)
                ScheduleType = 'Daily'
            }

            Context 'The current time does not fall within the maintenance window' {
                Mock -CommandName Get-Date -MockWith { [System.DateTime] '0001-01-01 07:00:00'  }
                It "Should test false" {
                    Test-TargetResource @testParameters | Should Be $false
                }
            }

            Context 'The current time falls within the maintenance window' {
                Mock -CommandName Get-Date -MockWith { [System.DateTime] '0001-01-01 05:00:00'  }

                It "Should return true in Test-TargetResource" {
                    Test-TargetResource @testParameters | Should Be $true
                }

                It "Should throw in Set-TargetResource" {
                    {Set-TargetResource @testParameters} | Should Throw
                }
            }

            Assert-VerifiableMocks
        }

        Describe "$($script:DSCResourceName) - Weekly" {

            $testParameters = @{
                ScheduleStart = [datetime]::Today.AddHours(22)
                ScheduleEnd = [datetime]::Today.AddHours(6)
                ScheduleType = 'Weekly'
                DayOfWeek = 'Monday'
            }

            Context 'The current time does not fall within the maintenance window time' {
                Mock -CommandName Get-Date -MockWith { [System.DateTime] '0002-01-08 07:00:00'  }
                It "Should test false" {
                    Test-TargetResource @testParameters | Should Be $false
                }
            }

            Context 'The current time falls within the maintenance window time' {
                # This returns a Tuesday since our schedule is Monday 22:00 - Tuesday 6:00
                Mock -CommandName Get-Date -MockWith { [System.DateTime] '0002-01-08 05:00:00' }

                It "Should return true in Test-TargetResource" {
                    Test-TargetResource @testParameters | Should Be $true
                }

                It "Should throw in Set-TargetResource" {
                    {Set-TargetResource @testParameters} | Should Throw
                }
            }

            Context 'The current time does not fall within the maintenance window day' {
                Mock -CommandName Get-Date -MockWith { [System.DateTime] '0002-01-09 05:00:00'  }
                It "Should test false" {
                    Test-TargetResource @testParameters | Should Be $false
                }
            }

            Assert-VerifiableMocks
        }

        Describe "$($script:DSCResourceName) - Monthly" {

            $testParameters = @{
                ScheduleStart = [datetime]::Today.AddHours(22)
                ScheduleEnd = [datetime]::Today.AddHours(6)
                ScheduleType = 'Monthly'
                DayOfMonth = 3
            }

            $testParameters2 = $testParameters.Clone()
            $testParameters2.Add('DayOfWeek', 'Wednesday')

            Context 'The current time does not fall within the maintenance window' {
                Mock -CommandName Get-Date -MockWith { [System.DateTime] '0002-01-04 07:00:00'  }
                It "Should test false" {
                    Test-TargetResource @testParameters | Should Be $false
                }
            }

            Context 'The current time falls within the maintenance window' {
                Mock -CommandName Get-Date -MockWith { [System.DateTime] '0002-01-03 23:00:00'  }

                It "Should return true in Test-TargetResource" {
                    Test-TargetResource @testParameters | Should Be $true
                }

                It "Should throw in Set-TargetResource" {
                    {Set-TargetResource @testParameters} | Should Throw
                }
            }

            Context 'The current time does not fall within the maintenance window day of month' {
                Mock -CommandName Get-Date -MockWith { [System.DateTime] '0002-01-04 05:00:00'  }
                It "Should test false" {
                    Test-TargetResource @testParameters2 | Should Be $false
                }
            }

            Context 'The current time falls within the maintenance window day of month' {
                Mock -CommandName Get-Date -MockWith { [System.DateTime] '0002-01-17 05:00:00'  }

                It "Should return true in Test-TargetResource" {
                    Test-TargetResource @testParameters2 | Should Be $true
                }

                It "Should throw in Set-TargetResource" {
                    {Set-TargetResource @testParameters2} | Should Throw
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


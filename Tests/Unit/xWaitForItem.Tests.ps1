#region HEADER
$script:DSCModuleName      = 'xDscHelper' 
$script:DSCResourceName    = 'xWaitForItem' 

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) ) {
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
 
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName  `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try {
    Invoke-TestSetup

    InModuleScope 'xWaitForItem' {
        $null = Add-Type -TypeDefinition '
                namespace Testing
                {
                    public class GetItem
                    {
                        public long Length = 123;

                        public GetItem ()
                        { }

                        public string GetType()
                        {
                            return "DirectoryInfo";
                        }
                    }
                }
                ' -IgnoreWarnings

        Describe "$($script:DSCResourceName) - Directory items" {

                $testParameters = @{
                    Path = 'D:\TestFolder'
                    Type = 'Directory'
                    ChildItemCount = 25
                    RetryCount = 3
                    RetryInterval = 2
                }
            
            Mock -CommandName Get-Item -MockWith {                
                return (New-Object Testing.GetItem)
            }
            Mock -CommandName Get-ChildItem -MockWith {               
                [psobject]@{
                Count = 10
            }
        }

            Context 'The directory does not contain enough child elements but it should' {
                It "Should take at least $($testParameters.RetryCount * $testParameters.RetryInterval)s" {
                    (Measure-Command { Set-TargetResource @testParameters -ErrorAction SilentlyContinue}).Seconds | Should BeGreaterThan ($testParameters.RetryCount * $testParameters.RetryInterval -1)
                }

                It 'Should return false in Test-TargetResource' {
                    Test-TargetResource @testParameters | Should Be $false
                }
            }

            Context 'The directory contains the correct amount of child elements and it should' {
                It "Should return true in Test-TargetResource" {
                    Test-TargetResource @testParameters | Should Be $true
                }
            }
            
            Context 'The directory contains more than the minimum amount of child elements and it should' {
                It "Should return true in Test-TargetResource" {
                    Test-TargetResource @testParameters | Should Be $true
                }
            }

            Context 'The directory does not exist but it should' {
                It "Should return false in Test-TargetResource" {
                    Test-TargetResource @testParameters | Should Be $false
                }

                It "Should take at least $($testParameters.RetryCount * $testParameters.RetryInterval)s" {
                    (Measure-Command { Set-TargetResource @testParameters -ErrorAction SilentlyContinue }).Seconds | Should BeGreaterThan ($testParameters.RetryCount * $testParameters.RetryInterval -1)
                }
            }

            Context 'The directory exists but it should not' {
                It "Should return false in Test-TargetResource" {
                    Test-TargetResource @testParameters | Should Be $false
                }

                It "Should take at least $($testParameters.RetryCount * $testParameters.RetryInterval)s" {
                    (Measure-Command { Set-TargetResource @testParameters -ErrorAction SilentlyContinue}).Seconds | Should BeGreaterThan ($testParameters.RetryCount * $testParameters.RetryInterval -1)
                }
            }

            Assert-VerifiableMocks
        }

        <#Describe "$($script:DSCResourceName) - File items" {

            BeforeEach {
                $testParameters = @{
                    Path = 'D:\Test.file'
                    Type = 'File'
                    ChildItemCount = 25
                }
            }
            
            Mock -CommandName Get-Item -MockWith {}
            Mock -CommandName Get-ChildItem -MockWith {}
            
            Context 'The file length does not match but it should' {

            }

            Context 'The file length matches and it should' {

            }
            
            Context 'The file length exceeds the minimum length and it should' {

            }

            Context 'The file does not exist but it should' {

            }

            Context 'The file exists but it should not' {
                
            }

            Assert-VerifiableMocks
        }#>
    }
}
finally {
    Invoke-TestCleanup
}


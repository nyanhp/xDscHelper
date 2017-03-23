#region HEADER
$script:DSCModuleName = 'xDscHelper' 
$script:DSCResourceName = 'xWaitForItem' 

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
    $null = Add-Type -TypeDefinition '
                namespace Testing
                {
                    public class GetItem
                    {
                        public long Length = 123;
                        public string Type = "DirectoryInfo";

                        public GetItem (string type, long len)
                        { 
                            Length = len;
                            Type = type;
                        }

                        public GetItemName GetType()
                        {
                            return new GetItemName(Type);
                        }
                    }

                    public class GetItemName
                    {
                        public string Name { get; set;}
                        public GetItemName(string name)
                        {
                            Name = name;
                        }
                    }
                }
                ' -IgnoreWarnings

    InModuleScope 'xWaitForItem' {

        Describe "$($script:DSCResourceName) - Directory items" {

            $testParameters = @{
                Path = 'D:\TestFolder'
                Type = 'Directory'
                ChildItemCount = 25
                RetryCount = 3
                RetryInterval = 2
            }

            $testParametersMinCount = @{
                Path = 'D:\TestFolder'
                Type = 'Directory'
                MinimumChildItemCount = 25
                RetryCount = 3
                RetryInterval = 2
            }
            
            Mock -CommandName Get-Item -MockWith {                
                return (New-Object Testing.GetItem('DirectoryInfo', 123))
            }            

            Context 'The directory does not contain enough child elements but it should' {
                Mock -CommandName Get-ChildItem -MockWith {               
                    [psobject]@{
                        Count = 10
                    }
                }
                It "Should take at least $($testParameters.RetryCount * $testParameters.RetryInterval)s" {
                    (Measure-Command { Set-TargetResource @testParameters -ErrorAction SilentlyContinue}).Seconds | Should BeGreaterThan ($testParameters.RetryCount * $testParameters.RetryInterval - 1)
                }

                It 'Should return false in Test-TargetResource' {
                    Test-TargetResource @testParameters | Should Be $false
                }
            }

            Context 'The directory contains the correct amount of child elements and it should' {
                Mock -CommandName Get-ChildItem -MockWith {               
                    [psobject]@{
                        Count = 25
                    }
                }
                It "Should return true in Test-TargetResource" {
                    Test-TargetResource @testParameters | Should Be $true
                }

                It "Should be the same as the input parameters" {
                    (Get-TargetResource @testParameters).ChildItemCount | Should Be $testParameters.ChildItemCount
                }
            }
            
            Context 'The directory contains more than the minimum amount of child elements and it should' {
                Mock -CommandName Get-ChildItem -MockWith {               
                    [psobject]@{
                        Count = 30
                    }
                }
                It "Should return true in Test-TargetResource" {
                    Test-TargetResource @testParametersMinCount | Should Be $true
                }

                It "Should have a Count greater than the input parameters" {
                    (Get-TargetResource @testParametersMinCount).ChildItemCount | Should BeGreaterThan $testParametersMinCount.MinimumChildItemCount
                }
            }

            Context 'The directory does not exist but it should' {
                Mock -CommandName Get-ChildItem -MockWith {               
                    [psobject]@{
                        Count = 10
                    }
                }
                It "Should return false in Test-TargetResource" {
                    Test-TargetResource @testParameters | Should Be $false
                }

                It "Should take at least $($testParameters.RetryCount * $testParameters.RetryInterval)s" {
                    (Measure-Command { Set-TargetResource @testParameters -ErrorAction SilentlyContinue }).Seconds | Should BeGreaterThan ($testParameters.RetryCount * $testParameters.RetryInterval - 1)
                }
            }

            Context 'The directory exists but it should not' {
                Mock -CommandName Get-ChildItem -MockWith {               
                    [psobject]@{
                        Count = 10
                    }
                }
                It "Should return false in Test-TargetResource" {
                    Test-TargetResource @testParameters | Should Be $false
                }

                It "Should take at least $($testParameters.RetryCount * $testParameters.RetryInterval)s" {
                    (Measure-Command { Set-TargetResource @testParameters -ErrorAction SilentlyContinue}).Seconds | Should BeGreaterThan ($testParameters.RetryCount * $testParameters.RetryInterval - 1)
                }
            }

            Assert-VerifiableMocks
        }

        Describe "$($script:DSCResourceName) - File items" {

            
            $testParameters = @{
                Path = 'D:\Test.file'
                Type = 'File'
                Length = 123
                RetryCount = 3
                RetryInterval = 2
            }

            $testParametersMin = @{
                Path = 'D:\Test.file'
                Type = 'File'
                MinimumLength = 123
                RetryCount = 3
                RetryInterval = 2
            }
            
            Mock -CommandName Get-ChildItem -MockWith {               
                [psobject]@{
                    Count = 10
                }
            }
            
            Context 'The file length does not match but it should' {
                Mock -CommandName Get-Item -MockWith {
                
                    return (New-Object Testing.GetItem('File', ($testParameters.Length - 1)))
                }
                It "Should return false in Test-TargetResource" {
                    Test-TargetResource @testParameters | Should Be $false
                }

                It "Should take at least $($testParameters.RetryCount * $testParameters.RetryInterval)s" {
                    (Measure-Command { Set-TargetResource @testParameters -ErrorAction SilentlyContinue}).Seconds | Should BeGreaterThan ($testParameters.RetryCount * $testParameters.RetryInterval - 1)
                }
            }

            Context 'The file length matches and it should' {
                Mock -CommandName Get-Item -MockWith {
                
                    return (New-Object Testing.GetItem('File', $testParameters.Length))
                }
                It "Should return true in Test-TargetResource" {
                    Test-TargetResource @testParameters | Should Be $true
                }

                It "Should be the same as the input parameter" {
                    (Get-TargetResource @testParameters).Length | Should Be $testParameters.Length
                }
            }
            
            Context 'The file length exceeds the minimum length and it should' {
                Mock -CommandName Get-Item -MockWith {
                
                    return (New-Object Testing.GetItem('File', ($testParameters.Length + 1)))
                }
                It "Should return true in Test-TargetResource" {
                    Test-TargetResource @testParametersMin | Should Be $true
                }

                It "Should be greater than the input parameter" {
                    (Get-TargetResource @testParametersMin).Length | Should BeGreaterThan $testParametersMin.MinimumLength
                }
            }

            Context 'The file does not exist but it should' {
                It "Should return false in Test-TargetResource" {
                    Test-TargetResource @testParameters | Should Be $false
                }

                It "Should take at least $($testParameters.RetryCount * $testParameters.RetryInterval)s" {
                    (Measure-Command { Set-TargetResource @testParameters -ErrorAction SilentlyContinue}).Seconds | Should BeGreaterThan ($testParameters.RetryCount * $testParameters.RetryInterval - 1)
                }
            }

            Context 'The file exists but it should not' {
                It "Should return false in Test-TargetResource" {
                    Test-TargetResource @testParameters | Should Be $false
                }

                It "Should take at least $($testParameters.RetryCount * $testParameters.RetryInterval)s" {
                    (Measure-Command { Set-TargetResource @testParameters -ErrorAction SilentlyContinue}).Seconds | Should BeGreaterThan ($testParameters.RetryCount * $testParameters.RetryInterval - 1)
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


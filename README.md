[![Build status](https://ci.appveyor.com/api/projects/status/9dr2dqkats65yb8u/branch/master?svg=true)](https://ci.appveyor.com/project/nyanhp/xdschelper/branch/master)

# xDscHelper
A DSC resource module that contains helper resources not fitting elsewhere. All of the resources in this repository are provided AS IS.

## Installation
To install xDscHelper module either

* Unzip the content under $env:ProgramFiles\WindowsPowerShell\Modules folder
* Or `Install-Module xDscHelper` in an elevated PowerShell session

Run `Get-DSCResource` to see that xDscHelper is among the DSC Resources listed

Requirements
This module requires at least PowerShell v4.0, which ships in Windows 8.1 or Windows Server 2012R2.

## Description
The module xDscHelper contains the following resources:

* xWaitForItem - Allows you to wait for files to reach a specific length or content or for folders reach a specified amount of child items
* xMaintenanceWindow - Allows you to specify a maintenance window as a dependency for your resources

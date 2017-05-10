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

## Examples
This example for xWaitForItem waits for a hypothetic configuration file created by another system, process or product which a local service depends on:  

```powershell
configuration conf
{
    Import-DscResource -ModuleName xDscHelper

    node localhost
    {
        # Wait for a third party product or another system to create a file you need
        xWaitForItem configFile
        {
            Path = 'C:\ConfigFileFromOtherSystem.ini'
            Type = 'File'
            MinimumLength = 1
        }

        # Use it as a dependency
        Service myService
        {
           Name = 'IniNeedingService'
           Path = 'C:\Svc\My.exe'
           DependsOn = '[xWaitForItem]configFile'
        }
    }
}
```

This example for xWaitForItem waits for a folder to fully replicate it's contents:  

```powershell
configuration conf
{
    Import-DscResource -ModuleName xDscHelper

    node localhost
    {
        # Wait for e.g folder replication
        xWaitForItem folderContents
        {
            Path = 'C:\SomeReplicatedFolder'
            Type = 'Directory'
            ChildItemCount = 25
        }

        # Use it as a dependency
        Service myService
        {
           Name = 'FileNeedingService'
           Path = 'C:\Svc\My.exe'
           DependsOn = '[xWaitForItem]folderContents'
        }
    }
}
```

This example for xMaintenanceWindow defines a maintenance window for the second tuesday of each month from 10 pm to 6 am and uses it as a dependency for other resources:  

```powershell
configuration conf
{
    Import-DscResource -ModuleName xDscHelper

    node localhost
    {
        xMaintenanceWindow patchday
        {
            ScheduleStart = (Get-Date).Date.AddHours(22)
            ScheduleEnd = (Get-Date).Date.AddHours(6)
            ScheduleType = 'Monthly'
            DayOfWeek = 'Tuesday'
            DayOfMonth = 2
        }

        Package 1
        {
            DependsOn = '[xMaintenanceWindow]patchday'
            ...
        }

        Package 2
        {
            DependsOn = '[xMaintenanceWindow]patchday'
            ...
        }

        Package 3
        {
            DependsOn = '[xMaintenanceWindow]patchday'
            ...
        }
    }
}
```

$machineNames = 'ServerA', 'ServerB'

configuration TestMaintenance
{
param
(
    [string[]]$ComputerName
)
    Import-DscResource -ModuleName xDscHelper
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    node $ComputerName
    {
        # Default type once
        xMaintenanceWindow mw
        {
            ScheduleStart = (Get-Date).AddHours(-1)
            ScheduleEnd = (Get-Date).AddHours(2)
            ScheduleType = 'Once'
        }        

        # Default type once
        xMaintenanceWindow mw1
        {
            ScheduleStart = (Get-Date).AddHours(1).AddMinutes(1)
            ScheduleEnd = (Get-Date).AddHours(2).AddMinutes(1)
            ScheduleType = 'Daily'
        }        

        xMaintenanceWindow mw2
        {
            ScheduleStart = (Get-Date).AddHours(-1).AddMinutes(2)
            ScheduleEnd = (Get-Date).AddHours(2).AddMinutes(2)
            ScheduleType = 'Weekly'
            DayOfWeek = (Get-Date).DayOfWeek
        }        

        xMaintenanceWindow mw3
        {
            ScheduleStart = (Get-Date).AddHours(1).AddMinutes(3)
            ScheduleEnd = (Get-Date).AddHours(2).AddMinutes(3)
            ScheduleType = 'Monthly'
            DayOfWeek = 'Wednesday'
            DayOfMonth = 2
        }

        File test
        {
            DestinationPath = 'C:\IShouldBe.here0'
            Type =  'File'
            DependsOn = '[xMaintenanceWindow]mw'
            Contents = 'mw'
        }

        File test1
        {
            DestinationPath = 'C:\IShouldNotBe.here1'
            Type =  'File'
            DependsOn = '[xMaintenanceWindow]mw1'
            Contents = 'mw1'
        }

        File test2
        {
            DestinationPath = 'C:\IShouldBe.here2'
            Type =  'File'
            DependsOn = '[xMaintenanceWindow]mw2'
            Contents = 'mw2'
        }

        File test3
        {
            DestinationPath = 'C:\IShouldNotBe.here3'
            Type =  'File'
            DependsOn = '[xMaintenanceWindow]mw3'
            Contents = 'mw3'
        }
    }
}

TestMaintenance -ComputerName $machineNames

Start-DscConfiguration -Verbose -Wait -Force -Path .\TestMaintenance

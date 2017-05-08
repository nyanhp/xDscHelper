
configuration TestMaintenance
{
    Import-DscResource -ModuleName xDscHelper
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    node XCASQL1
    {
        xMaintenanceWindow mw
        {
            ScheduleStart = (Get-Date).AddHours(-1)
            ScheduleEnd = (Get-Date).AddHours(2)
        }        

        xMaintenanceWindow mw1
        {
            ScheduleStart = (Get-Date).AddHours(1)
            ScheduleEnd = (Get-Date).AddHours(2)
        }        

        xMaintenanceWindow mw2
        {
            ScheduleStart = (Get-Date).AddHours(-1)
            ScheduleEnd = (Get-Date).AddHours(2)
            ScheduleType = 'Weekly'
            DayOfWeek = (Get-Date).DayOfWeek
        }        

        xMaintenanceWindow mw3
        {
            ScheduleStart = (Get-Date).AddHours(1)
            ScheduleEnd = (Get-Date).AddHours(2)
            ScheduleType = 'Weekly'
            DayOfWeek = (Get-Date).DayOfWeek
        }

        File test
        {
            DestinationPath = 'C:\IShouldNotBe.here0'
            Type =  'File'
            DependsOn = '[xMaintenanceWindow]mw'
            Contents = 'mw'
        }

        File test1
        {
            DestinationPath = 'C:\IShouldBe.here1'
            Type =  'File'
            DependsOn = '[xMaintenanceWindow]mw1'
            Contents = 'mw1'
        }

        File test2
        {
            DestinationPath = 'C:\IShouldNotBe.here2'
            Type =  'File'
            DependsOn = '[xMaintenanceWindow]mw2'
            Contents = 'mw2'
        }

        File test3
        {
            DestinationPath = 'C:\IShouldBe.here3'
            Type =  'File'
            DependsOn = '[xMaintenanceWindow]mw3'
            Contents = 'mw3'
        }
    }
}
#$cred = Get-Credential

TestMaintenance

Start-DscConfiguration -Verbose -Wait -Force -Path .\TestMaintenance -Credential $cred
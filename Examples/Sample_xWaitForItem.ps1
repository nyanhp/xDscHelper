$machineNames = 'ServerA', 'ServerB'

configuration TestWaitForItem
{
param
(
    [string[]]$ComputerName
)
    Import-DscResource -ModuleName xDscHelper
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    node $ComputerName
    {
        <# Wait for a file to reach a specific length. In this case we are waiting for someone to copy 
            the correct version of our sshd config
        #>
        xWaitForItem aFile
        {
            Path = 'C:\openssh\sshd.config'
            Type = 'File'
            Length = 12345
        }

        Service openSsh
        {
            Name = 'sshd'
            State = 'Running'
            StartupType = 'Automatic'
            Path = 'C:\openssh\sshd.exe'
            DependsOn = '[xWaitForItem]aFile'
        }

        # Now we wait for e.g. a DFS replicated folder to fully replicate with a broader retry count/interval
        xWaitForItem aFolder
        {
            Path = 'C:\SomeDfsTarget'
            Type = 'Directory'
            MinimumChildItemCount = 300
            RetryCount = 10
            RetryInterval = 60
        }

        SomeCompositeResource mySuperResource
        {
            SomeParam1 = 'Value1'
            DependsOn = '[xWaitForItem]aFolder'
        }
    }
}

TestWaitForItem -ComputerName $machineNames

Start-DscConfiguration -Verbose -Wait -Force -Path .\TestWaitForItem

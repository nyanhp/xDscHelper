@{

# Version number of this module.
ModuleVersion = '1.0.0.0'

# ID used to uniquely identify this module
GUID = '7b3b0e3f-09c6-4ddf-9b08-1cd2a6e09371'

# Author of this module
Author = 'Jan-Hendrik Peters'

# Company or vendor of this module
CompanyName = 'Jan-Hendrik Peters'

# Copyright statement for this module
Copyright = '(c) 2017 Jan-Hendrik Peters'

# Description of the functionality provided by this module
Description = 'A DSC resource module that contains helper resources not fitting elsewhere. All of the resources in this module are provided AS IS.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
CLRVersion = '4.0'

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = '*'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
DscResourcesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'xDscHelper', 'DSCResource')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/nyanhp/xDscHelper/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/nyanhp/xDscHelper'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}

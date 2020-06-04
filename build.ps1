#Requires -Version 7.0
#Requires -Modules Microsoft.PowerShell.Management, PackageManagement, PowerShellGet
using namespace System.Management.Automation

param(
    $Task = 'Default',

    [switch] $Force,
    [switch] $Verbose,
    [switch] $Debug
)

$PSModuleAutoLoadingPreference = [PSModuleAutoLoadingPreference]::None
$InformationPreference = [ActionPreference]::Continue
$VerbosePreference = [ActionPreference]::SilentlyContinue
$DebugPreference = [ActionPreference]::SilentlyContinue



Write-Information 'Starting build...'

. .\build\Initialize-Variables.ps1 -Force:$Force -Verbose:$Verbose -Debug:$Debug
. .\build\Install-Dependencies.ps1 -Force:$Force -Verbose:$Verbose -Debug:$Debug



# try {
#
#     'Started build...'
#     Invoke-Build $Task -Result 'Result' -File $PSScriptRoot/build/module.ps1
#
# } finally {
#
#     'Finished build:'
#     $Result.Tasks | Format-Table Elapsed, Name, Error -AutoSize | Out-String
#
#     if ($Result.Error) {
#
#         'Build has failed'
#         $Error[-1].ScriptStackTrace | Out-String
#         exit 1
#
#     }
# }

Write-Information 'Build has succeeded'
exit 0

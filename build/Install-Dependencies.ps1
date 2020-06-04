#Requires -Version 7.0
using namespace System
using namespace System.IO

param(
    [switch] $Force,
    [switch] $Verbose,
    [switch] $Debug
)

Write-Information 'Installing dependencies...'

function Install-Dependencies() {

    if (-not (Get-PackageProvider NuGet -ForceBootstrap) -or $Force) {
        Write-InitializePackagingScript

        Invoke-InitializePackagingScript
    }


    try {
        Set-ModulePath -Folder $Int_BuildDeps_Dir

        @('InvokeBuild', 'Pester', 'PSScriptAnalyzer', 'DependsOn', 'Select-Ast') |
            Import-Dependency -Folder $Int_BuildDeps_Dir

    } finally {
        Set-ModulePath -Folder $Int_BuildDeps_Dir -Remove
    }
}

function Write-InitializePackagingScript () {
    Write-Information " - Saving 'Initialize packaging script'..."

    Set-Content -Path $Int_InitializePackagingScript_File -Value @"

    #Requires -RunAsAdministrator

    Write-Information 'Install-PackageProvider' -InformationAction Continue
    Install-PackageProvider Nuget -Force -Verbose:$Verbose

    Write-Information 'Set-PackageSource' -InformationAction Continue
    Set-PackageSource PSGallery -Trusted -Verbose:$Verbose

"@ -Force
}

function Invoke-InitializePackagingScript () {
    Write-Information " - Invoking 'Initialize packaging script'..."

    Start-Process 'pwsh.exe' "-NoProfile -ExecutionPolicy Bypass -File `"$Int_InitializePackagingScript_File`"" -Verb RunAs -Wait
}

function Set-ModulePath {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory, Position = 1)]
        [string] $Folder,

        [Parameter()]
        [switch] $Remove
    )

    $__PathSeparator = [Path]::PathSeparator
    $__Folders = @(
        "$Env:PSModulePath".Split($__PathSeparator, [StringSplitOptions]::RemoveEmptyEntries) |
            Where-Object { $_ -ine $Folder }
    )

    if ($Remove.IsPresent) {
        $__DebugText = "PSModulePath: Removing folder '$Folder'"
    } else {
        $__DebugText = "PSModulePath: Adding folder '$Folder'"
        $__Folders = @($Folder) + @($__Folders)
    }

    if ($PSCmdlet.ShouldProcess("$__DebugText?")) {

        Write-Debug "$__DebugText" -Debug:$Debug

        [Environment]::SetEnvironmentVariable(
            'PSModulePath',
            "$($__Folders -join $__PathSeparator)",
            [EnvironmentVariableTarget]::Process)
    }
}

function Import-Dependency {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1)]
        [string] $Folder,

        [Parameter(ValueFromPipeline)]
        [string] $Name
    )

    process {

        $__Target_Dir = Join-Path $Folder -ChildPath $Name

        if (-not (Test-Path $__Target_Dir) -or $Force) {

            Find-Module $Name | Save-Module -LiteralPath $Folder -Force
            Write-Debug "Import-Dependency: Saved module: $Name @ $Folder" -Debug:$Debug
        }

        $__Target_File = (
            Get-ChildItem -LiteralPath $__Target_Dir -Filter "$Name.psd1" -Recurse -File |
                Select-Object -First 1
        ) ?? (
            Get-ChildItem -LiteralPath $__Target_Dir -Filter "$Name.psm1" -Recurse -File |
                Select-Object -First 1
        )

        if (! $__Target_File) {
            Write-Warning "Import-Dependency: Unable to find module file @ $__Target_Dir"
        }

        if (-not (Get-Module $Name) -or $Force) {
            Write-Verbose "Import-Dependency: Import module: $Name @ $Folder" -Verbose:$Verbose
            Import-Module $Name -Force
        }
    }
}



Install-Dependencies

# if ($__BuildDeps) {
#     Write-Information ' - Installing build dependencies...'
#     foreach ($__Current in $__BuildDeps) {
#         Install-Module -Name $__Current -Scope 'CurrentUser' -Force -SkipPublisher -Verbose:$Verbose
#     }
#
#     $__BuildDeps |
#         Where-Object { Import-Module $_ -PassThru -ea SilentlyContinue } |
#         Format-List | Out-String | Write-Verbose -Verbose:$Verbose
# }

#   if (-not (Test-Path $Int_ModuleDeps_Dir) -or $Force) {
#       Write-Information ' - Installing module dependencies...'
#       Invoke-PSDepend -Path $Settings_Dependencies_File -Target $Int_ModuleDeps_Dir -Install -Import -Force:$Force
#   }

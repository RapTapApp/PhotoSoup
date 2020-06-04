#Requires -Version 7.0
using namespace System.Collections
using namespace System.Collections.Generic

param(
    [switch] $Force,
    [switch] $Verbose,
    [switch] $Debug
)

Write-Information 'Initializing variables...'

function Initialize-Variables() {

    # Repository
    Split-Path $PSScriptRoot | Set-Location

    Update-VariableTable 'Folders' (
        [ordered] @{
            Root_Dir           = { Get-SingleDir '.' }

            Build_Dir          = { Get-SingleDir 'build' }
            Build_Tasks_Dir    = { Get-SingleDir 'tasks' -Folder $Build_Dir }

            Docs_Dir           = { Get-SingleDir 'docs' }

            Module_Dir         = { Get-SingleDir 'src' }
            Module_Classes_Dir = { Get-SingleDir 'classes' -Folder $Module_Dir }
            Module_Private_Dir = { Get-SingleDir 'private' -Folder $Module_Dir }
            Module_Public_Dir  = { Get-SingleDir 'public' -Folder $Module_Dir }

            Tests_Dir          = { Get-SingleDir 'tests' }
        })

    Update-VariableTable 'Repository files' (
        [ordered] @{
            Licence_File                 = Get-SingleFile 'LICENSE.md'

            Settings_Dependencies_File   = Get-SingleFile 'Settings.Dependencies.psd1'
            Settings_Project_File        = Get-SingleFile 'Settings.Project.psd1'
            Settings_ScriptAnalyzer_File = Get-SingleFile 'Settings.ScriptAnalyzer.psd1'
        })



    # Project
    Import-PowerShellDataFile $Settings_Project_File |
        Update-VariableTable 'Project settings'

    ('GUID', 'Name', 'Description', 'Version', 'Uri', 'Author', 'Company', 'Copyright') |
        ForEach-Object { "Project_$_" } |
        Where-Object { -not (Get-Variable $_ -ValueOnly) } |
        Write-Error "Variable '$_' has not been set in settings file: '$Settings_Project_File'"



    # Module
    Update-VariableTable 'Module scripts' (
        [ordered] @{
            Module_Script_Initialize_File = Get-SingleFile 'Script.Initialize.ps1' -Folder $Module_Dir -Optional
            Module_Script_Finalize_File   = Get-SingleFile 'Script.Finalize.ps1' -Folder $Module_Dir -Optional

            Module_Script_Classes_Files   = Select-Files *.ps1 -Folder $Module_Classes_Dir
            Module_Script_Private_Files   = Select-Files *.ps1 -Folder $Module_Private_Dir
            Module_Script_Public_Files    = Select-Files *.ps1 -Folder $Module_Public_Dir

            Module_Script_Files           = {
                @($Module_Script_Initialize_File ?? @()) +
                @($Module_Script_Finalize_File ?? @()) +
                @($Module_Script_Classes_Files) +
                @($Module_Script_Private_Files) +
                @($Module_Script_Public_Files)
            }
        })



    # Int
    Update-VariableTable 'Intermediates' (
        [ordered] @{
            Int_Dir                            = { Get-SingleDir '_int' }
            Int_InitializePackagingScript_File = { Join-Path $Int_Dir -ChildPath 'Init-Deps.ps1' }
            Int_BuildDeps_Dir                  = { Get-SingleDir 'build.deps' -Folder $Int_Dir }
            Int_ModuleDeps_Dir                 = { Get-SingleDir 'module.deps' -Folder $Int_Dir }
        })



    # Out
    Update-VariableTable 'Outputs' (
        [ordered] @{
            Out_Dir                    = { Get-SingleDir '_out' -Folder $Env:Build_ArtifactStagingDirectory }

            Out_Module_Dir             = { Get-SingleDir $Project_Name -Folder $Out_Dir }
            Out_Module_Manifest_File   = { Join-Path $Out_Module_Dir -ChildPath "$Project_Name.psd1" }
            Out_Module_Script_File     = { Join-Path $Out_Module_Dir -ChildPath "$Project_Name.psm1" }

            Out_Tests_Dir              = { Get-SingleDir 'tests' -Folder $Out_Dir }
            Out_Tests_RunResults_File  = { Join-Path $Out_Tests_Dir -ChildPath 'RunResults.xml' }
            Out_Tests_CodeCovered_File = { Join-Path $Out_Tests_Dir -ChildPath 'CodeCovered.xml' }
        })
}



function Get-SingleDir {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RelativePath,

        [Parameter()]
        [string] $Folder
    )

    if (! $Folder) {
        $Folder = Get-Location
    }

    # Determine path
    $__Path = Join-Path $Folder -ChildPath $RelativePath

    # When path doesn't exist then create folder
    if (-not(Test-Path $__Path)) {
        New-Item $__Path -ItemType Directory | Out-Null

        Write-Debug "Get-SingleDir: Created folder: $RelativePath" -Debug:$Debug
    }

    # Return path
    Write-Output $(Resolve-Path $__Path)
}

function Get-SingleFile {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Filter,

        [Parameter()]
        [string] $Folder,

        [Parameter()]
        [switch] $Optional
    )

    if (! $Folder) {
        $Folder = Get-Location
    }

    $__Files = @(Get-ChildItem -LiteralPath $Folder -Filter $Filter -File -Recurse:$Recurse)
    Write-Debug "Get-SingleFile: $Filter @ $Folder => Found $($__Files.Count) file(s)" -Debug:$Debug

    if ($__Files.Count -gt 1) {
        Write-Error "Get-SingleFile: Failed when expecting a single file and found multiple files instead: $__Files"
    }

    if ($__Files.Count -gt 0) {
        Write-Output $__Files[0]
    } elseif (! $Optional) {
        Write-Warning "Get-SingleFile: Expected to find file: $Filter @ $Folder"
    }
}

function Select-Files {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Filter,

        [Parameter()]
        [string] $Folder,

        [Parameter()]
        [switch] $Recurse
    )


    if (! $Folder) {
        $Folder = Get-Location
    }

    $__Files = @(Get-ChildItem -LiteralPath $Folder -Filter $Filter -File -Recurse:$Recurse)
    Write-Debug "Select-Files: $Filter @ $Folder $($Recurse ? '-Recurse' : '') => Found $($__Files.Count) file(s)" -Debug:$Debug

    Write-Output $__Files -NoEnumerate
}



function Update-VariableTable {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory, Position = 1)]
        [string] $Text,

        [Parameter(Mandatory, Position = 2, ValueFromPipeline)]
        [IDictionary] $InputTable
    )

    begin {
        $__WhatIf = $PSBoundParameters.WhatIf ?? $false
        $__Confirm = $PSBoundParameters.Confirm ?? $false

        $__Vars = [List[DictionaryEntry]]::new()
    }

    process {
        foreach ($__Entry in $InputTable.GetEnumerator()) {
            $__Vars.Add($__Entry)
        }
    }

    end {
        $__Vars | Update-Variable -Text $Text -WhatIf:$__WhatIf -Confirm:$__Confirm
    }
}

function Update-Variable {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory, Position = 1)]
        [string] $Text,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        $Value
    )

    begin {
        $__WhatIf = $PSBoundParameters.WhatIf ?? $false
        $__Confirm = $PSBoundParameters.Confirm ?? $false

        $__Vars = [List[DictionaryEntry]]::new()
    }

    process {

        # Get value
        $__DebugText = "Update-Variable: $Name = "

        if ($Value -is [scriptblock]) {
            $__DebugText += "& {$Value} => "
            $Value = & $Value
        }

        $__DebugText += "$Value"
        Write-Debug $__DebugText -Debug:$Debug

        # Set variable
        $__VarArgs = @{
            Name    = $Name
            Value   = $Value
            Scope   = 'Script'
            Option  = 'ReadOnly'
            WhatIf  = $__WhatIf
            Confirm = $__Confirm
        }
        Set-Variable @__VarArgs -Force

        # Log
        if ($Verbose) {
            $__Vars.Add($(
                    [DictionaryEntry]::new($Name, $Value)
                ))
        }
    }

    end {
        # Log
        if ($Verbose) {
            $__Table = $__Vars | Format-Table -HideTableHeaders | Out-String -Stream | Where-Object { $_ } | Out-String
            Write-Verbose "Updated variables: $Text`n$__Table" -Verbose:$Verbose
        }
    }
}



Initialize-Variables

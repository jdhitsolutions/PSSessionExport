Function Import-PSWorkingSessionModule {
    #Import-PSWorkingSessionModule -data $in.modules
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [alias("modules")]
        [object]$Data
    )
    begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
    }
    process {
        Write-Verbose "Processing $($data.count) modules"
        $data | ForEach-Object {
            #only import the module if it does already exist
            if (-Not (Get-Module -FullyQualifiedName @{Modulename = $_.Name; ModuleVersion = $_.version })) {
                if ($_.standard) {
                    Write-Verbose "Importing $($_.name) version $($_.version)"
                    if ($pscmdlet.ShouldProcess($_.name, "Import-Module")) {
                        Import-Module -FullyQualifiedName @{ModuleName = $_.Name; ModuleVersion = $_.version }
                    }
                }
                else {
                    #Import the custom manifest if found
                    $manifest = Join-Path -Path $_.moduleBase -ChildPath "$($_.name).psd1"
                    $module = Join-Path -Path $_.moduleBase -ChildPath "$($_.name).psm1"
                    if (Test-Path $manifest) {
                        Write-Verbose "Importing $manifest"
                        if ($pscmdlet.shouldprocess($manifest, "Import-Module")) {
                            Import-Module $manifest
                        }
                    }
                    elseif (Test-Path $module) {
                        Write-Verbose "Importing $module"
                        if ($pscmdlet.shouldprocess($module, "Import-Module")) {
                            Import-Module $module
                        }
                    }
                    else {
                        if ($pscmdlet.shouldProcess($_.path, "Import-Module")) {
                            Import-Module $_.path
                        }
                    }
                }
            }
            else {
                Write-Warning "Module $($_.name) version $($_.version) is already loaded."
            }
        }
    } #process
    end {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    }

} #import modules
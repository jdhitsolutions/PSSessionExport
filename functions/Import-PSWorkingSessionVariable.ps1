Function Import-PSWorkingSessionVariable {
    #some variables will be deserialized versions$
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
        [alias("variables")]
        [ValidateNotNullOrEmpty()]
        [object]$Data
    )
    begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
    }
    Process {
        foreach ($var in $data) {
            Write-Verbose "Adding $($var.name)"
            $vHash = @{
                Name        = $var.name
                Description = $var.Description
                Visibility  = $var.Visibility -as [System.Management.Automation.SessionStateEntryVisibility]
                Option      = $var.options -as [System.Management.Automation.ScopedItemOptions]
                Value       = $var.value
                Force       = $True
                Scope       = "Global"
                ErrorAction = "Stop"
            }

            Try {
                Set-Variable @vHash
            }
            Catch {
                Write-Warning "Skipping variable $($vhash.name). $($_.Exception.message)"
            }

        } #foreach
    } #process
    end {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    }
}

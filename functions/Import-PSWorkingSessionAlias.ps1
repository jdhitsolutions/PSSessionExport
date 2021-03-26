Function Import-PSWorkingSessionAlias {

    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
        [alias("Aliases")]
        [ValidateNotNullOrEmpty()]
        [object]$Data
    )
    begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
    }
    Process {
        Write-Verbose "Processing $($data.count) aliases"
        foreach ($alias in $data) {
            try {
                [void](Get-Alias -Name $alias.name -ErrorAction Stop )
            }
            Catch {
                Write-Verbose "Creating alias $($alias.name)"
                New-Alias -Name $alias.name -Value $alias.definition -Description $alias.description -Option $alias.options
            }
        } #>

    } #process
    end {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    }
}
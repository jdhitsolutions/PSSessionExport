Function Import-PSWorkingSessionFunction {

    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
        [alias("functions")]
        [ValidateNotNullOrEmpty()]
        [object]$Data
    )
    begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
    }
    Process {
        Write-Verbose "Restoring $($data.count) functions"
        foreach ($item in $data) {
            Write-Verbose $item.name
            $f = New-Item -Path function: -Name $item.name -Value $item.scriptblock -Force
            if ($item.Description) {
                $f.description = $item.Description
            }
            if (-Not $WhatIfPreference) {
                $f.Options = $item.options
                $f.Visibility = $item.Visibility
            }
        }
    } #process
    end {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    }
}
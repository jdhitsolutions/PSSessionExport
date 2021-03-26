Function Import-PSWorkingSessionPSDrive {

    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
        [alias("psdrives")]
        [ValidateNotNullOrEmpty()]
        [object]$Data
    )
    begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
    }
    Process {
        Write-Verbose "Restoring $($data.count) PSDrive(s)"
        foreach ($item in $data) {
            Try {
                $drv = Get-PSDrive -Name $item.name -ErrorAction stop
                if ($item.currentlocation) {
                    $drv.currentLocation = $item.CurrentLocation
                }
            } #try
            Catch {
                Write-Verbose "Restoring PSDrive $($item.name)"
                $drv = New-PSDrive -Name $item.name -PSProvider $item.Provider -Root $item.root
                if ($item.currentlocation) {
                    $drv.currentLocation = $item.CurrentLocation
                }
                if ($item.description) {
                    $drv.description = $item.description
                }
            } #catch
        } #foreach

    } #process
    end {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    }
}
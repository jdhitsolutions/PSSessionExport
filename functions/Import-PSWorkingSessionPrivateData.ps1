Function Import-PSWorkingSessionPrivateData {
    #Import-PSWorkingSessionPrivateData -data $in.privatedata
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
        [alias("privatedata")]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Data
    )
    begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
    }
    Process {
        $data.GetEnumerator() | ForEach-Object {
            Write-Verbose "Setting private data value for $($_.name)"
            if ($pscmdlet.ShouldProcess($_.Name, "Set value to $($_.value.value)")) {
                $host.privatedata.$($_.name) = $_.value
            }
        } #process
    } #foreach
    end {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    }
}
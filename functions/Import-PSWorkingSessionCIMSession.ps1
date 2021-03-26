Function Import-PSWorkingSessionCIMSession {

    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
        [alias("cimsessions")]
        [ValidateNotNullOrEmpty()]
        [object]$Data
    )
    begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
    }
    Process {
        $data | ForEach-Object {
            $params = @{Computername = $_.computername }
            if ($_.protocol -eq "DCOM") {
                $params.add("SessionOption", (New-CimSessionOption -Protocol DCOM))
            }
            if ($_.credential.username) {
                $params.add("Credential", $_.credential)
            }
            [void](New-CimSession @params)
        } #foreach
    } #process
    end {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    }
}
Function Import-PSWorkingSessionPSSession {

    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
        [alias("PSSessions")]
        [ValidateNotNullOrEmpty()]
        [object]$Data
    )
    begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
    }
    Process {
        Write-Verbose "Found $($data.computername.count) PSSession(s)"
        Foreach ($session in $data) {
            $params = @{ErrorAction = "Stop" }
            Write-Verbose "Processing session for $($session.computername)"
            if ($session.CertificateThumbprint) {
                $params.Add("CertificateThumbprint".$session.CertificateThumbprint)
            }
            if ($session.configurationName -AND ($session.transport -ne 'SSH')) {
                $params.Add("ConfigurationName", $session.ConfigurationName)
            }
            if ($session.credential) {
                $params.add("Credential", $session.credential)
            }
            if ($session.port -AND ($session.port -notmatch "5985|80")) {
                Write-Verbose "Using custom port $($session.port)"
                $params.Add("Port", $session.port)
            }
            if ($session.transport -eq 'SSH') {
                $params.Add("Hostname", $session.computername)
                $params.Add("SSHTransport", $True)
                if ($session.Username) {
                    $params.Add("UserName", $session.userName)
                }
            }
            elseif ($session.Computertype.value -eq 'VirtualMachine') {
                Write-Verbose "Connecting to virtual machine $($session.ComputerName)"
                $params.Add("VMName", $session.computername)
            }
            elseif ($session.computertype.value -eq "RemoteMachine") {
                Write-Verbose "Connecting to remote computer $($session.ComputerName)"
                $params.Add("Computername", $session.computername)
                $ci = $session.ConnectionInfo
                $opt = New-PSSessionOption @ci
                $params.Add("SessionOption", $opt)
            }
            else {
                Write-Warning "Computertype $($session.Computertype.value) not handled at this time."
                $skip = $True
            }
            if (-Not $skip) {

                Try {
                    [void](New-PSSession @params)
                }
                Catch {
                    Write-Warning "Failed to recreate PSSession for $($session.Computername). $($_.Exception.Message)"
                    $params | Out-String | Write-Verbose
                }
            }
        }

    } #process
    end {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    }
}
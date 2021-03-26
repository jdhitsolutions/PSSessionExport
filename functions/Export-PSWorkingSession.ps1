Function Export-PSWorkingSession {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType("none", "System.Io.FileInfo")]
    Param(
        [Parameter(Position = 0, HelpMessage = "Specify the filename and path for the export XML file.")]
        [ValidateNotNullorEmpty()]
        [string]$Path = "ExportedWorkingSession.xml",
        [Parameter(HelpMessage = "How many levels deep do you want to export? The default is 3.")]
        [ValidateRange(2, 10)]
        [int]$Depth = 3,
        [Parameter(HelpMessage = "Export existing and open PSSessions.")]
        [switch]$ExportPSSession,
        [Parameter(HelpMessage = "Export existing CIMSessions. You will be prompted for credentials.")]
        [switch]$ExportCimSession,
        [switch]$Passthru
    )

    Write-Verbose "Starting $($myinvocation.mycommand)"
    $master = [ordered]@{
        Computername = [System.Environment]::MachineName
        Username     = [System.Environment]::UserName
        Date         = Get-Date
        PSVersion    = "{0}.{1}" -f $PSVersionTable.PSVersion.Major, $PSVersionTable.PSVersion.Minor
        Host         = $host.Name
        Version      = $host.version
    }

    Write-Verbose "Exporting host private data"
    $pdHash = @{}
    $host.PrivateData.psobject.properties | ForEach-Object -Process { $pdhash.Add($_.name, $_.value) }
    $master.Add("PrivateData", $pdHash)

    Write-Verbose "Exporting loaded modules"

    $modules = Get-Module | Select-Object Name, Version, Path, ModuleBase,
    @{Name = "Standard"; Expression = { Test-ModuleLocation $_.moduleBase } }

    $master.Add("Modules", $modules)

    Write-Verbose "Exporting variables"
    $exclude = "PWD", "PSCulture", "Profile", "`$", "?", "^", "false", "true", "host",
    "nestedpromptlevel", "home", "MyInvocation", "Pid", "PSEdition", "PSHome", "PSVersionTable", "pwd",
    "ShellID", "StackTrace", "NestedpromptLevel", "PSUiCulture", "ConsoleFileName", "Error", "ExecutionContext",
    "OutputEncoding", "PSBoundParameters", "PSCmdlet", "Passthru", "PSScriptRoot"

    $myVariables = Get-Variable -Scope global | Where-Object { $exclude -notcontains $_.name }

    $master.Add("Variables", $myVariables)

    Write-Verbose "Exporting Aliases"
    $master.Add("Aliases", (Get-Alias | Select-Object -Property Name, Definition, Options, Description))

    Write-Verbose "Exporting command history"
    $master.Add("History", (Get-History))

    Write-Verbose "Exporting PSDrives"
    #if using credentials the file can only be re-imported on the same computer by the same
    $master.Add("PSDrives", (Get-PSDrive | Select-Object -Property Name, Provider, Description, Root, CurrentLocation, Credential))

    if ($ExportPSSession) {
        Write-Verbose "Exporting PSSessions"

        $ciProperties = @("MaximumReceivedDataSizePerCommand", "MaximumReceivedObjectSize", "NoMachineProfile", "ProxyAccessType", "ProxyAuthentication", "ProxyCredential", "SkipCACheck", "SkipCNCheck", "SkipRevocationCheck", "NoEncryption", "UseUTF16", "OutputBufferingMode", "IncludePortInSPN", "MaxConnectionRetryCount", "Culture", "UICulture", "OpenTimeout", "CancelTimeout", "OperationTimeout", "IdleTimeout")
        $sessions = Get-PSSession | Where-Object { $_.state -eq "Opened" }
        $all = foreach ($session in $sessions) {
            $ci = $session.runspace.connectioninfo
            $obj = [ordered]@{
                PSTypeName            = "ExportedPSSession"
                Computername          = $session.Computername
                ComputerType          = $session.Computertype
                ConfigurationName     = $session.ConfigurationName
                Credential            = $ci.credential
                Username              = $ci.Username
                CertificateThumbprint = $ci.CertificateThumbprint
                Port                  = $ci.Port
                Transport             = $session.transport
            }

            #add connection info
            $ciHash = @{}
            foreach ($property in $ciProperties) {
                #" $property = $($ci.$property)"
                if ($null -ne $ci.$property) {
                    $ciHash.Add($property, $ci.$property)
                }
                else {
                    Write-Host "Skipping $property"
                }
            }
            $obj.Add("ConnectionInfo", $ciHash)

            New-Object -TypeName PSObject -Property $obj
        }

        $master.Add("PSSessions", $all)
    }

    If ($ExportCimSession) {
        Write-Verbose "Exporting CIM Sessions"
        #no way to determine credentials or session options so I'll prompt

        $cim = Get-CimSession | Where-Object { $_.TestConnection() } |
        Select-Object Computername, Protocol,
        @{Name = "Credential"; Expression = { Get-Credential -Message "Enter a credential for the $($_.computername.toUpper()) CIMSession if needed or click cancel" ; } }

        $master.Add("CimSessions", $cim)
    }

    Write-Verbose "Exporting functions"
    $fun = Get-ChildItem function: |
    Where-Object { -not $_.source -AND $_.name -notmatch "^([A-Z]:|(cd[\.\\])|Clear-Host|help|mkdir)" } |
    Select-Object -Property Name, Options, Description, Visibility, ScriptBlock
    $master.Add("Functions", $fun)

    Write-Verbose "Exporting all session information to $path"
    $master | Export-Clixml -Path $path -Depth $Depth

    if ($Passthru) {
        Get-Item -Path $Path
    }
    Write-Verbose "Ending $($myinvocation.MyCommand)"

} #Export-PSWorkingSession
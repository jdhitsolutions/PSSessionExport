
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

Function Test-ModuleLocation {
    [cmdletbinding()]
    Param([string]$ModuleBase)

    $moduleLocations = $env:PSModulePath -split ([system.io.path]::PathSeparator)
    $Paths = $env:Path -split ([system.io.path]::PathSeparator) | Where-Object { $_ }

    foreach ($item in $moduleLocations) {
        $rx = [System.Text.RegularExpressions.Regex]::new("^$($item.replace('\','\\'))", "IgnoreCase")
        if ($rx.Ismatch($ModuleBase)) {
            Return $True
        }
    } #foreach module location

    #test if module base is in %PATH%
    foreach ($location in $paths) {
        $rx = [System.Text.RegularExpressions.Regex]::new("^$($location.replace('\','\\'))", "IgnoreCase")
        if ($rx.Ismatch($ModuleBase)) {
            Return $True
        }
    } #foreach path

    #otherwise the answer is false
    Return $false
}

#region import functions

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
                Write-Warning "$($_.name) version $($_.version) is already loaded."
            }
        }
    } #process
    end {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    }

} #import modules

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
            }

            Set-Variable @vHash

        } #foreach
    } #process
    end {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    }
}

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

Function Import-PSWorkingSession {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType("none", "System.Io.FileInfo")]
    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = "Specify the filename and path of exported XML file.")]
        [ValidateNotNullorEmpty()]
        [ValidateScript( { Test-Path $_ })]
        [string]$Path
    )

    Write-Verbose "Starting $($myinvocation.mycommand)"
    Write-Verbose "Importing PS Console session data from $Path"

    $in = New-Object PSObject -Property (Import-Clixml $Path)

    if (($in.psversion -as [version]).major -eq $PSVersionTable.PSVersion.Major) {
        Import-PSWorkingSessionPrivateData -data $in.PrivateData
        Import-PSWorkingSessionModule -data $in.modules
        Import-PSWorkingSessionFunction -data $in.functions
        Import-PSWorkingSessionVariable -data $in.variables
        Import-PSWorkingSessionPSDrive -data $in.psdrives
        Import-PSWorkingSessionAlias -data $in.aliases

        if ($in.PSSessions.computername.count -gt 0) {
            Import-PSWorkingSessionPSSession -data $in.pssessions
        }
        if ($in.CimSessions.computername.count -gt 0) {
            Import-PSWorkingSessionCIMSession -data $in.cimsessions
        }
    }
    else {
        Write-Warning "The export was created from a PowerShell $($in.psversion) session which is incompatible with $($PSVersiontable.PSVersion)."
    }

    Write-Verbose "Ending $($myinvocation.mycommand)"
}

Function Get-PSWorkingSession {
    [CmdletBinding()]
    [OutputType("none", "System.Io.FileInfo")]
    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = "Specify the filename and path of exported XML file.")]
        [ValidateNotNullorEmpty()]
        [ValidateScript( { Test-Path $_ })]
        [string]$Path
    )

    Write-Verbose "Starting $($myinvocation.mycommand)"
    Write-Verbose "Importing PS Console session data from $Path"

    $in = New-Object PSObject -Property (Import-Clixml $Path)

    $in | Select-Object -Property Date, Host, PSVersion, Username, Computername,
    @{Name = "PSSessions"; Expression = { if ($_.Pssessions.computername.count -gt 0) { $true } else { $false } } },
    @{Name = "CimSessions"; Expression = { if ($_.Cimsessions.computername.count -gt 0) { $true } else { $false } } }

    Write-Verbose "Ending $($myinvocation.mycommand)"

}

#endregion

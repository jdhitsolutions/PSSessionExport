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
        #import data in a specific order
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
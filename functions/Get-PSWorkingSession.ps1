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

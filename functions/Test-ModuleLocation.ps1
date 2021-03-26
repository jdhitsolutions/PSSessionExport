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

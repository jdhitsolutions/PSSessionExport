Get-Childitem -Path $PSScriptRoot\functions\*.ps1 |
Foreach-Object {
    . $_.FullName
}
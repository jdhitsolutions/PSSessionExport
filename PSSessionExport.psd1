#
# Module manifest for module 'PSSessionExport'

@{
    RootModule           = 'PSSessionExport'

    ModuleVersion        = '0.10.0'
    CompatiblePSEditions = @("Desktop", "Core")
    GUID                 = 'ddfa66f0-666e-4359-885d-199ae8db27e9'
    Author               = 'Jeff Hicks'
    CompanyName          = 'JDH Information Technology Solutions, Inc.'
    Copyright            = '(c) 2021-2022 JDH Information Technology Solutions, Inc.'
    Description          = 'A demonstration module that allows you to export and import a PowerShell working session.'
    PowerShellVersion    = '5.1'

    # ScriptsToProcess = @()
    # TypesToProcess = @()
    # FormatsToProcess = @()

    FunctionsToExport    = 'Export-PSWorkingSession',
    'Import-PSWorkingSessionAlias',
    'Import-PSWorkingSessionCIMSession',
    'Import-PSWorkingSessionFunction',
    'Import-PSWorkingSessionModule',
    'Import-PSWorkingSessionPrivateData',
    'Import-PSWorkingSessionPSDrive',
    'Import-PSWorkingSessionPSSession',
    'Import-PSWorkingSessionVariable',
    'Test-ModuleLocation',
    'Import-PSWorkingSession',
    'Get-PSWorkingSession'

    CmdletsToExport      = ''
    VariablesToExport    = ''
    AliasesToExport      = ''
    PrivateData          = @{

        PSData = @{

            # Tags = @()
            # LicenseUri = ''
            # ProjectUri = ''
            # IconUri = ''
            # ReleaseNotes = ''
            # Prerelease = ''
            # RequireLicenseAcceptance = $false
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfoURI = ''
    # DefaultCommandPrefix = ''

}


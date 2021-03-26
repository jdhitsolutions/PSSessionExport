# PSSessionExport

This is a demonstration module created in response to an Iron Scripter PowerShell [Challenge](https://ironscripter.us/a-powershell-session-challenge-2/). The goal was to export as much of a PowerShell working console session to a file and then import the file in a new PowerShell console session. It is unlikely to reach 100% compatibility, but this module tries to get as close as possible.

It is assumed you will be exporting and importing into the same PowerShell major version, i.e 5 or 7. If you attempt to import across versions, you will get an error.

## Export

You can export the current session to an XML file. You will have to specify if you want to include exporting existing PSSessions and/or CimSessions.

![Export session](images/export.png)

In a new PowerShell session, you can get information about the export.

![Get export information](images/get.png)

The module includes functions to import individual items such as Aliases or PSDrives, but it is expected you will import the entire session.

![Import a session](images/import.png)

## To Do

The project isn't 100% complete. These items still need to be addressed.

- Export PSReadline Options
- Export custom format data. This should be added from module imports. But there may be stand-alone formats.
- Export custom type. Maybe use the [PSTypeExtensionTools](https://github.com/jdhitsolutions/PSTypeExtensionTools) module and let the user specify what type extensions to export. Anything that was extended by a module should be already be taken care of.
- help documentation

Last updated *2021-03-26 14:19:39Z*

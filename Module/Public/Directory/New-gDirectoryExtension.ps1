function New-gDirectoryExtension {
    <#
    .SYNOPSIS
        This function creates a new application extension with the specified properties.

    .DESCRIPTION
        The New-gDirectoryExtension function is used to create an application extension with a given name, application ID, data type, and target object. 
        It uses Microsoft Graph API to create the application extension.

    .PARAMETER Name
        This is the name of the application extension. This is a mandatory parameter.

    .PARAMETER ApplicationID
        This is the application ID for which the extension is to be created. This is a mandatory parameter.

    .PARAMETER dataType
        This is the type of data that the extension will store. 
        This can be one of the following: 'String', 'Binary', 'Boolean', 'DateTime', 'Integer', 'LargeInteger'. This is a mandatory parameter.

    .PARAMETER TargetObjects
        This is the target object to which the extension applies. 
        It can be one of the following: 'User', 'Group', 'Organization', 'Device', 'Application'. This is a mandatory parameter.

    .EXAMPLE
        New-gDirectoryExtension -Name extension_edc06b6cff794fb28be5bf7b17cf9ab1_Region -ApplicationID edc06b6c-ff79-4fb2-8be5-bf7b17cf9ab1 -dataType String -TargetObjects User
        This example creates an application extension with the name 'extension_edc06b6cff794fb28be5bf7b17cf9ab1_Region'. Here, 'edc06b6cff794fb28be5bf7b17cf9ab1' is the application ID 'edc06b6c-ff79-4fb2-8be5-bf7b17cf9ab1', but with the hyphens removed. The data type for this extension is 'String' and the target object is 'User'.

    .NOTES
        The function uses the Microsoft Graph API, so it requires the application to have the appropriate permissions to create an extension property in the application identified by the ApplicationID parameter.

    #>
    [CmdletBinding()]
    param (

        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string]
        $ApplicationID,

        [Parameter(Mandatory)]
        [ValidateSet('String', 'Binary', 'Boolean', 'DateTime', 'Integer', 'LargeInteger')]
        $dataType,

        [Parameter(Mandatory)]
        [ValidateSet('User', 'Group', 'Organization', 'Device', 'Application')]
        $TargetObjects
    )

    if (-not ($ApplicationID -as [guid])) {
        return
    }

    $Body = @{
        name          = $Name
        dataType      = $dataType
        targetObjects = @(
            $TargetObjects
        )
    }

    $RestSplat = @{
        Uri    = "https://graph.microsoft.com/v1.0/applications/{0}/extensionProperties" -f $ApplicationID
        Body   = $Body | ConvertTo-Json
        Method = 'POST'
    }

    Invoke-gRestMethod @RestSplat

}

function Get-gDirectoryExtension {
    <#
    .SYNOPSIS
    List extensions registered to an app

    .DESCRIPTION
    This function retrieves the list of extensions that are registered to a specific app.
    It uses the Microsoft Graph API and the provided app ID (or object) to get this information.

    .PARAMETER App
    Object representing the app. This can be an app object from the pipeline or an application ID.

    .EXAMPLE
    Get-gDirectoryExtension -App 13c18f60-226c-457c-ac82-c0da4550d524

    .NOTES
    This function requires an existing connection to the Microsoft Graph API.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Placeholder')]
    param (

        [Parameter( Mandatory, ValueFromPipeline, ParameterSetName = 'pipeline' )]
        [ArgumentCompleter([completer_gApp_DisplayName])]
        [object]
        $App

    )
    process {
        $AppList = foreach ($Item in $App) {
            try {
                Get-gApp -App $Item
            }
            catch {
                $PSCmdlet.WriteError($_)
            
            }
        }
        foreach ($thisApp in $AppList) {

            $Uri = "https://graph.microsoft.com/beta/applications/{0}/extensionProperties" -f $thisApp.Id
            $RestSplat = @{
                Uri    = $Uri
                Method = 'GET'
            }
            $ExtensionList = (Invoke-gRestMethod @RestSplat).value

            foreach ($Extension in $ExtensionList) {
                [PSCustomObject]@{
                    App                    = $thisApp.DisplayName
                    AppId                  = $thisApp.Id
                    Name                   = $Extension.name
                    DataType               = $Extension.dataType
                    Id                     = $Extension.Id
                    DeletedDateTime        = $Extension.deletedDateTime
                    AppDisplayName         = $Extension.appDisplayName
                    isMultiValued          = $Extension.isMultiValued
                    isSyncedFromOnPremises = $Extension.isSyncedFromOnPremises
                    TargetObjects          = @($Extension.targetObjects) -ne '' -join ', '
                }
            }
        }
    }
}

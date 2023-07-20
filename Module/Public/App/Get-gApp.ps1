function Get-gApp {
    <#
        .SYNOPSIS
        Retrieves the list of applications within the organization.
    
        .DESCRIPTION
        The Get-gApp function retrieves the list of applications within the organization.
    
        .PARAMETER App
        Specifies the name or the ID of the application to retrieve. This parameter can be autocompleted.
    
        .PARAMETER AppId
        Specifies the ID of the application to retrieve. This parameter takes precedence over the App parameter if both are supplied.
    
        .PARAMETER All
        Specifies to list all applications within the organization.
    
        .EXAMPLE
        Get-gApp -App 'MyApp'
    
        This command retrieves the application named 'MyApp'.
    
        .EXAMPLE
        Get-gApp -AppId 'a5cd84d8-85a9-47cb-a1af-b2577a61063d'
    
        This command retrieves the application with the ID 'a5cd84d8-85a9-47cb-a1af-b2577a61063d'.
    
        .EXAMPLE
        Get-gApp -All
    
        This command retrieves all applications within the organization.
 
        .EXAMPLE
        Import-Csv .\apps.csv | Get-gApp | Export-Excel .\applist.xlsx

        This command imports a list of application names or IDs from a CSV file, uses the Get-gApp function to retrieve details for the corresponding applications, and exports the resulting list to an Excel file named 'applist.xlsx'. To use this example, ensure the ImportExcel module is installed by running `Install-Module ImportExcel -Force`.

        .NOTES
        Even though the displayName is used in some of the examples, displayNames are not unique, so it's best to use IDs. 
    
        To get optional claims, one per worksheet, use the following example:
    
        $all = Get-gApp -All
    
        foreach ($item in $all) {
            $hash = [ordered]@{}
            $hash['DisplayName'] = $item.displayName
            foreach ($claim in ($item.OptionalClaims | Format-Flat -depth 99)) {
                foreach ($thisDef in $claim.PSObject.Properties) {
                    $Hash[$thisDef.name] = $thisDef.value
                }
    
                [pscustomobject]$Hash | Format-Vertical | Export-Excel .\optionalclaims.xlsx -WorksheetName $item.displayName
            }
        }
    
        #>
    [CmdletBinding(DefaultParameterSetName = 'Placeholder')]
    param (

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'pipeline' )]
        [ArgumentCompleter([completer_iApp_DisplayName])]
        [object]
        $App,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'AppID', Position = 0)]
        $AppId,

        [Parameter(ParameterSetName = 'All')]
        [switch]
        $All
    )
    begin {
        if ($All) {
            try {
                $RestSplat = @{
                    Uri         = 'https://graph.microsoft.com/beta/applications/{0}' -f $value
                    Method      = 'GET'
                    ErrorAction = 'Stop'
                }
                $AppList = (Invoke-gRestMethod @RestSplat).value
            }
            catch {
                $PSCmdlet.WriteError($_)
            }

            foreach ($thisApp in $AppList) {
                if ($thisApp.AppRoles) {
                    $RoleList = [System.Collections.Generic.List[string]]::New()

                    foreach ($Role in $thisApp.AppRoles) {
                        if ($Role.Value) {
                            $RoleList.Add('{0}' -f $Role.DisplayName)
                        }
                    }
                }
                [PSCustomObject]@{
                    DisplayName           = $thisApp.DisplayName
                    AppRoles              = @($RoleList) -ne '' -join "`r`n"
                    PublisherDomain       = $thisApp.PublisherDomain
                    SignInAudience        = $thisApp.SignInAudience
                    GroupMembershipClaims = $thisApp.GroupMembershipClaims
                    CreatedDateTime       = $thisApp.CreatedDateTime
                    IdentifierUris        = @($thisApp.IdentifierUris) -ne '' -join "`r`n"
                    AppID                 = $thisApp.AppID
                    ID                    = $thisApp.ID
                    AppRoleObject         = $thisApp.AppRoles
                    Tags                  = @($thisApp.Tags) -ne '' -join ","
                    OptionalClaims        = $thisApp.OptionalClaims
                }
            }
            return
        }
    }
    process {
        if ($AppID) {
            $App = $AppId
        }
        $AppList = foreach ($Item in $App) {
            if (-not $Script:AppHash -or -not $Script:AppHash.ContainsKey($Item)) {
                hash_gApp_Role
            }
            $value = if ($AppId) {
                $Item
            }
            elseif ($Item -is [string] -and $Item -as [Guid]) {
                $Item
            }
            elseif ($Item.Id -and $Item.Id -as [guid]) {
                $Item.Id
            }
            elseif ($Script:AppHash.ContainsKey($Item)) {
                $Script:AppHash[$Item]['id']
            }
            else {
                Write-Error "Application not found"
                continue
            }
            try {
                if ($AppId) {
                    $UriFilter = "?`$filter={0}" -f ('AppId eq ''{0}''' -f $AppId)
                    $RestSplat = @{
                        Uri         = "https://graph.microsoft.com/beta/applications{0}" -f $UriFilter
                        Method      = 'GET'
                        ErrorAction = 'Stop'
                    }
                    (Invoke-gRestMethod @RestSplat).value
                }
                else {
                    $RestSplat = @{
                        Uri         = 'https://graph.microsoft.com/beta/applications/{0}' -f $Value
                        Method      = 'GET'
                        ErrorAction = 'Stop'
                    }
                    Invoke-gRestMethod @RestSplat
                }
            }
            catch {
                $PSCmdlet.WriteError($_)
            }
        }
        foreach ($thisApp in $AppList) {

            if ($thisApp.AppRoles) {
                $RoleList = [System.Collections.Generic.List[string]]::New()

                foreach ($Role in $thisApp.AppRoles) {
                    if ($Role.Value) {
                        $RoleList.Add('{0}' -f $Role.DisplayName)
                    }
                }
            }
            [PSCustomObject]@{
                DisplayName           = $thisApp.DisplayName
                AppRoles              = @($RoleList) -ne '' -join "`r`n"
                PublisherDomain       = $thisApp.PublisherDomain
                SignInAudience        = $thisApp.SignInAudience
                GroupMembershipClaims = $thisApp.GroupMembershipClaims
                CreatedDateTime       = $thisApp.CreatedDateTime
                IdentifierUris        = @($thisApp.IdentifierUris) -ne '' -join "`r`n"
                AppID                 = $thisApp.AppID
                ID                    = $thisApp.ID
                AppRoleObject         = $thisApp.AppRoles
                Tags                  = @($thisApp.Tags) -ne '' -join ","
                OptionalClaims        = $thisApp.OptionalClaims
            }
        }
    }
}

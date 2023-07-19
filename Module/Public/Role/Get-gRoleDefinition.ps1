function Get-gRoleDefinition {

    <#
    .SYNOPSIS
    Returns one or more Azure AD Role Definitions.
    
    .DESCRIPTION
    Retrieves role definitions and role assignments from the RBAC provider called 'directory' (Azure Active Directory).
    
    .PARAMETER Role
    Specifies the Role ID or DisplayName as a string or object.
    If using the DisplayName of the Role Definition, note that it is not unique in Azure AD and may result in multiple matches.
    
    .PARAMETER All
    Retrieves all Azure AD Role Definitions.

    .EXAMPLE
    Import-Csv .\rolelist.csv | Get-gRoleDefinition
    Retrieves role definitions for each role listed in a CSV file.
     
    .EXAMPLE
    Get-gRoleDefinition -Role 'Knowledge Administrator'
    Retrieves the role definition with the specified DisplayName.
    
    .EXAMPLE
    Get-gRoleDefinition -Role '62e90394-69f5-4237-9190-012177145e10'
    Retrieves the role definition with the specified Role ID.
    
    .EXAMPLE
    Get-gRoleDefinition -All
    Retrieves all Azure AD Role Definitions.
    
    .EXAMPLE
    Get-gRoleDefinition -All | Export-Csv .\RoleDefinitions.csv -NoTypeInformation
    Retrieves all Azure AD Role Definitions and exports them to a CSV file.
    #>


    [CmdletBinding()]
    param(
        
        [Parameter( Mandatory, ValueFromPipeline, ParameterSetName = 'pipeline' )]
        [object]
        $Role,

        [Parameter(ParameterSetName = 'All')]
        [switch]
        $All
    )
    begin {

        if ($All) {

            $RestSplat = @{
                Uri    = "https://graph.microsoft.com/beta/roleManagement/directory/roleDefinitions"
                Method = 'GET'
            }

            (Invoke-gRestMethod @RestSplat).value
            return
        }
    }
    process {
        foreach ($Item in $Role) {
            if ($Item.Id -is [string] -and $Item.Id -as [Guid]) {
                $filterstring = '{0}?' -f $Item.Id
            }
            elseif ($Item -is [string] -and $Item -as [Guid]) {
                $filterstring = '{0}?' -f $Item
            }
            elseif ($Item.DisplayName -is [string]) {
                $filterstring = "?`$filter=DisplayName eq '{0}'" -f $Item.DisplayName
            }
            elseif ($Item -is [string]) {
                $filterstring = "?`$filter=DisplayName eq '{0}'" -f $Item
            }
        }
        if ($filterstring) {
            $RestSplat = @{
                Uri    = "https://graph.microsoft.com/beta/roleManagement/directory/roleDefinitions/{0}" -f $filterstring
                Method = 'GET'
            }
            $Result = Invoke-gRestMethod @RestSplat
            if ($filterstring -like '*filter=*') {
                return $Result.value
            }
            $Result
        }
    }
}

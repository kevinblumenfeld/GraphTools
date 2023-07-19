function Get-gRoleAssignment {
    <#
    .SYNOPSIS
    Retrieves role assignments from the Microsoft Graph API.

    .DESCRIPTION
    The Get-gRoleAssignment function retrieves role assignments from the Microsoft Graph API. 
    Role assignments tie together a role definition with members and scopes.
    This applies to custom and built-in roles. You can retrieve role assignments by RoleDefinitionId, PrincipalId, or Id. 

    .PARAMETER RoleDefinitionId
    Specifies the RoleDefinitionId for which to retrieve role assignments.
    May be combined with PrincipalId and/or DirectoryScopeId.

    .PARAMETER PrincipalId
    Specifies the PrincipalId for which to retrieve role assignments.
    May be combined with RoleDefinitionId and/or DirectoryScopeId.

    .PARAMETER DirectoryScopeId
    Specifies the DirectoryScopeId for which to retrieve role assignments.
    May be combined with RoleDefinitionId and/or PrincipalId.

    .PARAMETER Id
    Specifies the Id of the role assignment to retrieve.

    .EXAMPLE
    Get-gRoleAssignment
    Retrieves all role assignment

    .EXAMPLE
    Get-gRoleAssignment -Id 'lonqqS8SdEyVII7c0ZKCbOElzZegQW9Nuu3_bEgnD_0-1'
    Retrieves a specific role assignment by the assignments Id

    .EXAMPLE
    Get-gRoleAssignment -RoleDefinitionId 'b5a8dcf3-09d5-43a9-a639-8e29ef291470'
    Retrieves role assignments associated with the specified RoleDefinitionId

    .EXAMPLE
    Get-gRoleAssignment -RoleDefinitionId 'b5a8dcf3-09d5-43a9-a639-8e29ef291470' -PrincipalId '725d17ec-cc33-432c-9eb0-83187b9cbee7'
    Retrieves role assignments associated with the specified RoleDefinitionId and PrincipalId

    .EXAMPLE
    Get-gRoleAssignment -RoleDefinitionId 'b5a8dcf3-09d5-43a9-a639-8e29ef291470' -PrincipalId '725d17ec-cc33-432c-9eb0-83187b9cbee7' -DirectoryScopeId '/'
    Retrieves role assignments associated with the specified RoleDefinitionId, PrincipalId, and DirectoryScopeId

    .EXAMPLE
    Get-gRoleAssignment -DirectoryScopeId '/'
    Retrieves role assignments associated with the specified DirectoryScopeId.

    .NOTES
    The Microsoft Graph API for Intune requires an active Intune license for the tenant.
    #>
    [CmdletBinding(DefaultParameterSetName = 'placeholder')]
    param(
               
        [Parameter()]
        $RoleDefinitionId,

        [Parameter()]
        $PrincipalId,
        
        [Parameter()]
        $DirectoryScopeId,
        
        [Parameter( Mandatory, ParameterSetName = 'Id' )]
        $Id
    )
   
    if ($Id) {
        $filterstring = '/{0}' -f $Id
    }
    elseif ($PSBoundParameters.Keys.Count -ge 1) {
        $filterstring = @()
    }

    if ($PrincipalId) {
        $filterstring += ("PrincipalId eq '{0}'" -f $PrincipalId)
    }

    if ($RoleDefinitionId) {
        $filterstring += ("RoleDefinitionId eq '{0}'" -f $RoleDefinitionId)
    }

    if ($DirectoryScopeId) {
        $filterstring += ("DirectoryScopeId eq '{0}'" -f $DirectoryScopeId)
    }

    if ($filterstring.count -ge 1 -and (-not $Id)) {
        $filterstring = '?$filter={0}' -f (@($filterstring) -join ' and ')
    }

    $RestSplat = @{
        Uri    = 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments{0}' -f $filterstring
        Method = 'GET'
    }

    $Response = Invoke-gRestMethod @RestSplat
    if (-not $Id) {
        return $Response.value
    }

    $Response
}

function New-gRoleAssignment {
    <#
    .SYNOPSIS
    Creates a new role assignment using the Microsoft Graph API.

    .DESCRIPTION
    This function creates a new role assignment object using the Microsoft Graph API.
    The role assignment is created with the specified role definition, principal (user or group), and directory scope.

    .PARAMETER RoleDefinitionId
    The ID of the role definition for the role assignment.

    .PARAMETER PrincipalId
    The ID of the principal (user or group) for the role assignment.

    .PARAMETER DirectoryScopeId
    The identifier of the directory object representing the scope of the assignment.
    The scope of an assignment determines the set of resources for which the principal has been granted access.
    Directory scopes are shared scopes stored in the directory that are understood by multiple applications.
    Use '/' for tenant-wide scope.

    .EXAMPLE
    Assigns the User Administrator role to a principal with the tenant scope.
    
    New-gRoleAssignment -RoleDefinitionId 'e8cef6f1-e4bd-4ea8-bc07-4b8d950f4477' -PrincipalId '72ae3f1a-c8f1-4aad-af82-51473013fa74' -DirectoryScopeId '/'
    
    .EXAMPLE
    Assigns the User Administrator role to a principal with administrative unit scope.

    $splat = @{
        RoleDefinitionId = '9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3'
        PrincipalId      = '72ae3f1a-c8f1-4aad-af82-51473013fa74'
        DirectoryScopeId = '/administrativeUnits/5d107bba-d8e2-4e13-b6ae-884be90e5d1a'
    }
    New-gRoleAssignment @splat
    
    .EXAMPLE
    Assigns a principal the Application Administrator role at the application scope.
    The object ID of the application registration is 661e1310-bd76-4795-89a7-8f3c8f855bfc.

    $splat = @{
        RoleDefinitionId = '9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3'
        PrincipalId      = '72ae3f1a-c8f1-4aad-af82-51473013fa74'
        DirectoryScopeId = '/661e1310-bd76-4795-89a7-8f3c8f855bfc'
    }
    New-gRoleAssignment @splat
    
    #>
    [CmdletBinding()]
    param(
        
        [Parameter( Mandatory )]
        $RoleDefinitionId,

        [Parameter( Mandatory )]
        $PrincipalId,

        [Parameter( Mandatory )]
        $DirectoryScopeId
    )

    $Body = @{
        '@odata.type'    = '#microsoft.graph.unifiedRoleAssignment'
        roleDefinitionId = $RoleDefinitionId
        principalId      = $PrincipalId
        directoryScopeId = $DirectoryScopeId
    }

    $RestSplat = @{
        Uri    = 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments'
        Method = 'POST'
        Body   = $Body | ConvertTo-Json
    }

    Invoke-gRestMethod @RestSplat
}

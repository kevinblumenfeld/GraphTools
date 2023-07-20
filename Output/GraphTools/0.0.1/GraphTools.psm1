using namespace System.Management.Automation
#Region '.\Classes\completer_iUser_Deleted_DisplayName.ps1' 0
#using namespace System.Management.Automation

class completer_iUser_Deleted_DisplayName                : IArgumentCompleter {
    [System.Collections.Generic.IEnumerable[CompletionResult]] CompleteArgument(
        [string]$CommandName, [string]$ParameterName, [string]$WordToComplete,
        [Language.CommandAst]$CommandAst, [System.Collections.IDictionary] $FakeBoundParameters
    ) {
        $result = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
        if ($wordToComplete) {
            $wordToComplete = $wordToComplete -replace '"|''', ''
            arg_gUser_Deleted_DisplayName -WordToComplete $WordToComplete |
            ForEach-Object DisplayName | Sort-Object | ForEach-Object { $result.Add([System.Management.Automation.CompletionResult]::new("'$_'", $_, ([CompletionResultType]::ParameterValue) , $_) ) }
        }
        return $result
    }
}
#EndRegion '.\Classes\completer_iUser_Deleted_DisplayName.ps1' 17
#Region '.\Classes\completer_iUser_DisplayName.ps1' 0
#using namespace System.Management.Automation

class completer_iUser_DisplayName                : IArgumentCompleter {
    [System.Collections.Generic.IEnumerable[CompletionResult]] CompleteArgument(
        [string]$CommandName, [string]$ParameterName, [string]$WordToComplete,
        [Language.CommandAst]$CommandAst, [System.Collections.IDictionary] $FakeBoundParameters
    ) {
        $result = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
        if ($wordToComplete) {
            $wordToComplete = $wordToComplete -replace '"|''', ''
            arg_gUser_DisplayName -WordToComplete $WordToComplete |
            ForEach-Object DisplayName | Sort-Object | ForEach-Object { $result.Add([System.Management.Automation.CompletionResult]::new("'$_'", $_, ([CompletionResultType]::ParameterValue) , $_) ) }
        }
        return $result
    }
}
#EndRegion '.\Classes\completer_iUser_DisplayName.ps1' 17
#Region '.\Private\ArgumentsForCompleters\arg_gUser_Deleted_DisplayName.ps1' 0
function arg_gUser_Deleted_DisplayName {
    <#
    .SYNOPSIS
    Interactive use only. Used for autocompletion of user arguments.
    
    .PARAMETER WordToComplete
    Specifies the user you want to autocomplete at the command line.
    
    .NOTES
    This function only works with the Beta endpoint.
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        $WordToComplete
    )

    $RestSplat = @{
        Uri     = "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.user?`$filter={0}&top=50&select=DisplayName" -f (
            [System.Web.HttpUtility]::UrlEncode(('startswith({0}, ''{1}'')' -f 'DisplayName', $WordToComplete ))
        )
        Headers = @{
            ConsistencyLevel = 'Eventual'
            Authorization    = "Bearer $Script:Token"
        }
        Method  = 'Get'
    }
    (Invoke-RestMethod @RestSplat).value
}
#EndRegion '.\Private\ArgumentsForCompleters\arg_gUser_Deleted_DisplayName.ps1' 30
#Region '.\Private\ArgumentsForCompleters\arg_gUser_DisplayName.ps1' 0
function arg_gUser_DisplayName {
    <#
    .SYNOPSIS
    Interactive use only. Used for autocompletion of user arguments.
    
    .PARAMETER WordToComplete
    Specifies the user you want to autocomplete at the command line.
    
    .NOTES
    This function only works with the Beta endpoint.
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        $WordToComplete
    )

    $RestSplat = @{
        Uri     = "https://graph.microsoft.com/beta/users?`$filter={0}&top=50&select=DisplayName" -f (
            [System.Web.HttpUtility]::UrlEncode(('startswith({0}, ''{1}'')' -f 'DisplayName', $WordToComplete ))
        )
        Headers = @{
            ConsistencyLevel = 'Eventual'
            Authorization    = "Bearer $Script:Token"
        }
        Method  = 'Get'
    }
    (Invoke-RestMethod @RestSplat).value
}
#EndRegion '.\Private\ArgumentsForCompleters\arg_gUser_DisplayName.ps1' 30
#Region '.\Private\Connect\Connect-iGraphMI.ps1' 0
function Connect-gGraphMI {
    <#
    .DESCRIPTION
    Connect with Managed Identity to Graph API

    #>
    [CmdletBinding()]
    param ()

    $resourceURI = 'https://graph.microsoft.com/'
    $tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=$resourceURI&api-version=2019-08-01"
    $tokenResponse = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER" = "$env:IDENTITY_HEADER" } -Uri $tokenAuthURI
    $Script:Token = $tokenResponse.access_token

}
#EndRegion '.\Private\Connect\Connect-iGraphMI.ps1' 16
#Region '.\Private\Rest\Invoke-gRestMethod.ps1' 0
function Invoke-gRestMethod {
    <#
    .SYNOPSIS
    Invokes a REST method with various options.  This is a private function, only used interally by other functions.

    .DESCRIPTION
    This function allows invoking a REST method with customizable parameters such as URI, HTTP method, request body, and eventual consistency.

    .PARAMETER Uri
    The URI of the REST API endpoint to invoke.

    .PARAMETER Method
    The HTTP method to use for the request. Valid values are GET, POST, DELETE, and PATCH. (Default: GET)

    .PARAMETER Body
    The request body to include in the REST request.

    .PARAMETER Eventual
    Specifies whether to use eventual consistency for the request. If specified, the 'ConsistencyLevel' header will be set to 'Eventual'.

    .EXAMPLE
    Invoke-gRestMethod -Uri 'https://api.example.com/resource' -Method GET
    Invokes a GET request to the specified URI.

    .NOTES
    This is a private function that requires a script-scoped token variable and is meant to be executed only by other functions within the module.

    #>
    param (

        [Parameter()]
        $Uri,

        [Parameter()]
        [validateset('GET', 'POST', 'DELETE', 'PATCH')]
        $Method = 'GET',

        [Parameter()]
        $Body,

        [Parameter()]
        [switch]
        $Eventual
    )

    $RestSplat = @{
        Uri     = $Uri
        Method  = $Method
        Headers = @{
            'Content-Type' = 'application/json'
        }
        Verbose = $false
    }

    if ($Eventual) {
        $RestSplat['Headers']['ConsistencyLevel'] = 'Eventual'
    }
    if ($Body) {
        $RestSplat['Body'] = $Body
    }

    do {
        try {
            $i = 0
            while ((-not $script:Token -or ([datetime]::UtcNow -ge $script:TokenExpirationTime)) -and ($i -le 30)) { 
                Connect-gGraph -ClientID $Script:ClientID -TenantID $Script:TenantID -Secret $Script:Secret
                $i++
            }

            $RestSplat['Headers']['Authorization'] = "Bearer $Script:Token"

            # Send the response
            $Response = Invoke-RestMethod @RestSplat
            $Response

            # If page, and didn't catch, update Next
            $RestSplat['Uri'] = $Response.'@odata.nextLink'
        }

        catch {
            if ($_.Exception.Response.StatusCode -eq 429) {
                Write-Verbose ('IWR ERROR [ 429 ] SLEEPING FOR [ {0} ] SECONDS' -f $_.Exception.Response.Headers.GetValues('Retry-After')[0])
                Start-Sleep -Seconds $_.Exception.Response.Headers.GetValues('Retry-After')[0]
            }

            elseif ($_.Exception.Response.StatusCode -eq 401) {
                Write-Verbose ('IWR ERROR [ {0} ] CONNECT THEN SLEEP FOR [  5  ] SECONDS' -f $_.Exception.Response.StatusCode)
                Connect-gGraph
                Start-Sleep -Seconds 5
            }

            else {
                $PSCmdlet.WriteError($PSItem)
                Write-Verbose ('STOPPING! IWR ERROR [ {0} ]  URI [ {1} ]  EXCEPTION [  {2}  ]' -f $_.Exception.Response.StatusCode, $RestSplat['Uri'], $_)
                Return
            }
        }
    } while ($RestSplat['Uri'])
}
#EndRegion '.\Private\Rest\Invoke-gRestMethod.ps1' 100
#Region '.\Private\Rest\Set-gToken.ps1' 0
function Set-gToken {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Token,

        [Parameter(Mandatory)]
        $TokenExpirationTime,
        
        [Parameter(Mandatory)]
        $ClientID,

        [Parameter(Mandatory)]
        $TenantID,
        
        [Parameter(Mandatory)]
        $Secret
    )

    $Script:Token = $Token
    $Script:TokenExpirationTime = $TokenExpirationTime
    $Script:ClientID = $ClientID
    $Script:TenantID = $TenantID
    $Script:Secret = $Secret
}
#EndRegion '.\Private\Rest\Set-gToken.ps1' 27
#Region '.\Private\User\Get-gUserAll.ps1' 0
function Get-gUserAll {
    [CmdletBinding()]
    param (

        [Parameter()]
        $ThrottleLimit = 8,
        
        [Parameter()]
        [string]
        $Select,
        
        [Parameter()]
        [switch]
        $Beta
    )

    $UserCount = Invoke-gRestMethod -Uri "https://graph.microsoft.com/v1.0/users/`$count" -Method 'GET' -Eventual
    Write-Verbose "Getting $($UserCount) users. . .  "

    $ModuleBase = $MyInvocation.MyCommand.Module.Path

    '!#$%&*+-/0123456789=?ABCDEFGHIJKLMNOPQRSTUVWXYZ^_`{|}~'.toCharArray() | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {

        $Character = "$_"
        Import-Module $using:ModuleBase -Force
                
        $TokenSplat = @{
            Token               = $using:Token
            TokenExpirationTime = $using:TokenExpirationTime
            ClientID            = $using:ClientID
            TenantId            = $using:TenantID
            Secret              = $using:Secret
        }

        Set-gToken @TokenSplat

        if (-not $using:Beta) {

            Write-Host "NOT BETA"
            $Uri = "https://graph.microsoft.com/v1.0/users?`$filter={0}" -f (
                [System.Web.HttpUtility]::UrlEncode(('startswith({0}, ''{1}'')' -f 'mailnickname', "$Character" ))
            )
        }
        else {
            $Uri = "https://graph.microsoft.com/beta/users?`$filter={0}" -f (
                [System.Web.HttpUtility]::UrlEncode(('startswith({0}, ''{1}'')' -f 'mailnickname', "$Character" ))
            )
        }
        
        if ($using:Select) {
            $Uri = '{0}&$Select={1}' -f $Uri, $using:Select
        }
        $splat = @{
            Uri         = $Uri
            Method      = 'GET'
            ErrorAction = 'Stop'
        }
        try {
            (Invoke-gRestMethod @splat).value
        
        }
        catch {
            Write-Error -ErrorRecord $_
        }
    }
}
#EndRegion '.\Private\User\Get-gUserAll.ps1' 67
#Region '.\Private\User\Get-gUserDeletedAll.ps1' 0
function Get-gUserDeletedAll {
    [CmdletBinding()]
    param (

        [Parameter()]
        $ThrottleLimit = 8,
        
        [Parameter()]
        [string]
        $Select,
        
        [Parameter()]
        [switch]
        $Beta
    )

    $ModuleBase = $MyInvocation.MyCommand.Module.Path

    '!#$%&*+-/0123456789=?ABCDEFGHIJKLMNOPQRSTUVWXYZ^_`{|}~'.toCharArray() | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {

        $Character = "$_"
        Import-Module $using:ModuleBase -Force
                
        $TokenSplat = @{
            Token               = $using:Token
            TokenExpirationTime = $using:TokenExpirationTime
            ClientID            = $using:ClientID
            TenantId            = $using:TenantID
            Secret              = $using:Secret
        }

        Set-gToken @TokenSplat

        if (-not $using:Beta) {
            $Uri = "https://graph.microsoft.com/v1.0/directory/deletedItems/microsoft.graph.user?`$filter={0}" -f (
                [System.Web.HttpUtility]::UrlEncode(('startswith({0}, ''{1}'')' -f 'mailnickname', "$Character" ))
            )
        }
        else {
            $Uri = "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.user?`$filter={0}" -f (
                [System.Web.HttpUtility]::UrlEncode(('startswith({0}, ''{1}'')' -f 'mailnickname', "$Character" ))
            )
        }
        
        if ($using:Select) {
            $Uri = '{0}&$Select={1}' -f $Uri, $using:Select
        }
        $splat = @{
            Uri         = $Uri
            Method      = 'GET'
            ErrorAction = 'Stop'
            # Eventual    = $true
        }
        try {
            (Invoke-gRestMethod @splat).value
        
        }
        catch {
            Write-Error -ErrorRecord $_
        }
    }
}
#EndRegion '.\Private\User\Get-gUserDeletedAll.ps1' 63
#Region '.\Public\Connect\Connect-gGraph.ps1' 0
function Connect-gGraph {
    <#
    .DESCRIPTION
    Connect with Client Credential Flow to Graph API
    
    .PARAMETER ClientID
    Client ID of the Azure AD App Registration
    
    .PARAMETER TenantID
    Tenant ID of the Azure AD App Registration
    
    .PARAMETER Secret
    The Secret from the Azure AD App Registration

    .PARAMETER ManagedIdentity
    If set, connects to the Graph API using Managed Identity
    
    .EXAMPLE
    Connect-gGraph -ClientID "yourClientID" -TenantID "yourTenantID" -Secret "yourSecret"
    Connects to the Graph API using the specified client credentials.
    
    .EXAMPLE
    Connect-gGraph -ClientID "yourClientID" -TenantID "yourTenantID" -Secret "yourSecret" -Verbose
    Connects to the Graph API using the specified client credentials with verbose output for interactive execution.

    .EXAMPLE
    Connect-gGraph -ManagedIdentity
    Connects to the Graph API using Managed Identity.
    
    #>
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'AppReg')]
        $ClientID,

        [Parameter(ParameterSetName = 'AppReg')]
        $TenantID,

        [Parameter(ParameterSetName = 'AppReg')]
        $Secret,

        [Parameter(ParameterSetName = 'ManagedIdentity')]
        [switch]
        $ManagedIdentity
    )

    if ($ManagedIdentity) {
        Connect-gGraphMI
    }
    do {
        try {
            $Request = @{
                Method      = 'POST'
                ErrorAction = 'Stop'
                Body        = @{
                    Grant_Type    = 'client_credentials'
                    Client_Id     = $ClientID
                    Client_Secret = $Secret
                    Scope         = 'https://graph.microsoft.com/.default'

                }
                Uri         = 'https://login.microsoftonline.com/{0}/oauth2/v2.0/token' -f $TenantID
            }
            $Response = Invoke-RestMethod @Request
            
            $Script:ClientID = $ClientID
            $Script:TenantId = $TenantID
            $Script:Secret = $Secret
        }

        catch {
            if ($_.Exception -like '*transport*' -or $_.Exception -like '*invalid pointer*' ) {
                # Transport Error
                $TransportError++
                $PSCmdlet.WriteError($_)
                Write-Verbose ('Retrying Transport Error. Retried {0} times.' -f $TransportError)
                if ($TransportError -ge 200) {
                    Write-Verbose ('STOPPING! Retried {0} times. Halting this call!' -f $TransportError)
                    break
                }
            }

            else {
                # Something unexpected went wrong
                Write-Verbose ('Continuing ! Something other than Transport Error occurred {0}' -f $_)
                continue
            }
        }
    } until ($Response.access_token)

    $Script:TokenExpirationTime = ([datetime]::UtcNow).AddSeconds($Response.expires_in - 10)
    $Script:Token = $Response.access_token
}

#EndRegion '.\Public\Connect\Connect-gGraph.ps1' 95
#Region '.\Public\Role\Get-gRoleAssignment.ps1' 0
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
#EndRegion '.\Public\Role\Get-gRoleAssignment.ps1' 104
#Region '.\Public\Role\Get-gRoleDefinition.ps1' 0
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
#EndRegion '.\Public\Role\Get-gRoleDefinition.ps1' 91
#Region '.\Public\Role\New-gRoleAssignment.ps1' 0
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
#EndRegion '.\Public\Role\New-gRoleAssignment.ps1' 77
#Region '.\Public\User\Get-gUser.ps1' 0
function Get-gUser {
    <#
    .SYNOPSIS
    Retrieve the properties and relationships of user objects in Azure Active Directory (AAD).

    .DESCRIPTION
    This cmdlet retrieves user objects from AAD and provides various options for filtering and selecting specific properties.
    Users can be identified by their ID, UserPrincipalName, or DisplayName. Additionally, a list of users can be provided in a CSV file.
    The cmdlet also supports parallel processing of user objects, with a default throttle limit of 8 threads.

    .PARAMETER User
    Specifies the ID, UserPrincipalName, or DisplayName of the user to retrieve.
    A list of users can also be provided in a CSV file.
    If the CSV file has headers, they must contain one of the following columns: Id, UserPrincipalName, or DisplayName.
    DisplayName is not unique in AAD and may result in multiple matches.

    Note that tab completion is supported for the DisplayName parameter.
    You can type a few letters and use tab multiple times to cycle through and find matching DisplayNames of users you want more details on.
    For example, typing 'fr' and pressing tab multiple times may show both 'Frank' and 'Fred' as options.

    .PARAMETER Select
    Specifies a comma-separated list of properties to be returned by Microsoft Graph.
    For example: Get-gUser -Select 'DisplayName,UserPrincipalName,Mail'
    
    .PARAMETER IncludeManager
    If the user has a manager listed in Azure AD, this switch includes the user's manager in the output

    .PARAMETER All
    Switch to retrieve all users in the Azure AD Tenant.

    .PARAMETER Beta
    Switch to use the beta version of Microsoft Graph API.

    .PARAMETER ThrottleLimit
    Only used with the -All switch. Specifies the maximum number of parallel threads or concurrent operations allowed during parallel processing. Default value is 8.

    .EXAMPLE
    Import-Csv .\userlist.csv | Get-gUser

    .EXAMPLE
    Import-Csv .\userlist.csv | Get-gUser -Select 'DisplayName,UserPrincipalName,Mail'

    .EXAMPLE
    Import-Csv .\userlist.csv | Get-gUser -IncludeManager -Select 'DisplayName,UserPrincipalName'
    
    .EXAMPLE
    Get-gUser -User '72ae3f1a-c8f1-4aad-af82-51473013fa74'

    .EXAMPLE
    Get-gUser -User 'Kevin Blumenfeld'
    
    .EXAMPLE
    Get-gUser -User 'Kevin Blumenfeld' -Beta
    Retrieves user information for 'Kevin Blumenfeld' using the beta version of Microsoft Graph API.

    .EXAMPLE
    Get-gUser -User 'Kevin Blumenfeld' -Select 'DisplayName,UserPrincipalName'

    .EXAMPLE
    Get-gUser -User 'Kevin Blumenfeld' -Select 'DisplayName,UserPrincipalName'

    .EXAMPLE
    Get-gUser -User 'Kevin Blumenfeld' -IncludeManager -Select 'DisplayName,UserPrincipalName'

    .EXAMPLE
    Get-gUser -All
    Retrieves all users in the Azure AD Tenant.

    .EXAMPLE
    Get-gUser -All -Beta
    Retrieves all users in the Azure AD Tenant using the beta version of Microsoft Graph API.
    
    .EXAMPLE
    Get-gUser -All -Select 'DisplayName,UserPrincipalName'
    Retrieves all users in the Azure AD Tenant.

    .EXAMPLE
    Get-gUser -All -Beta -Select 'DisplayName,UserPrincipalName'
    Retrieves all users in the Azure AD Tenant using the beta version of Microsoft Graph API.

    #>
    [CmdletBinding()]
    param (
        [Parameter( Mandatory, ValueFromPipeline, ParameterSetName = 'pipeline' )]
        [ArgumentCompleter([completer_iUser_DisplayName])]
        [object]
        $User,

        [Parameter(ParameterSetName = 'pipeline' )]
        [string]
        $Select,

        [Parameter(ParameterSetName = 'pipeline' )]
        [switch]
        $IncludeManager,

        [Parameter(ParameterSetName = 'pipeline')]
        [Parameter(ParameterSetName = 'All')]
        [switch]
        $Beta,

        [Parameter(ParameterSetName = 'All')]
        [switch]
        $All,

        [Parameter(ParameterSetName = 'All')]
        [int]
        $ThrottleLimit = 8
    )

    begin {
        if ($All) {
            $splat = @{
                ThrottleLimit = $ThrottleLimit
            }
            if ($Select) {
                $splat['Select'] = $Select
            }
            Get-gUserAll @splat
            return
        }
    }
    process {
        foreach ($Item in $User) {
            if ($Item -is [string] -and $Item -as [Guid]) {
                $filterstring = '{0}?' -f $Item
            }
            elseif ($Item -as [mailaddress]) {
                $filterstring = "?`$filter=userprincipalname eq '{0}'" -f [System.Web.HttpUtility]::UrlEncode($Item)
                
            }
            elseif ($Item -is [string]) {
                $filterstring = "?`$filter=DisplayName eq '{0}'" -f $Item
            }
            else {
                if ($Item.Id) {
                    $filterstring = '{0}?' -f $Item.Id
                }
                elseif ($Item.UserPrincipalName -as [mailaddress]) {
                    $filterstring = '{0}?' -f $Item.UserPrincipalName
                }
                elseif ($Item.DisplayName) {
                    $filterstring = "?`$filter=DisplayName eq '{0}'" -f $Item.DisplayName
                }
            }
            if ($filterstring) {
                if ($Select) {
                    $filterstring = '{0}&$Select={1}' -f $filterstring, $Select
                }
                if ($IncludeManager) {
                    $filterstring = '{0}&$expand=manager' -f $filterstring
                }

                if (-not $Beta) {
                    $Uri = 'https://graph.microsoft.com/v1.0/users/{0}' -f $filterstring
                }
                else {
                    $Uri = 'https://graph.microsoft.com/beta/users/{0}' -f $filterstring
                }
                
                if ($filterstring -like '*filter=*') {
                    (Invoke-gRestMethod -Method 'GET' -Uri $Uri).value
                    continue
                }
                Invoke-gRestMethod -Method 'GET' -Uri $Uri
            }
        }
    }
}
#EndRegion '.\Public\User\Get-gUser.ps1' 170
#Region '.\Public\User\Get-gUserDeleted.ps1' 0
function Get-gUserDeleted {
    <#
    .SYNOPSIS
    Retrieve the properties and relationships of user objects in Azure Active Directory (AAD).

    .DESCRIPTION
    This cmdlet retrieves user objects from AAD and provides various options for filtering and selecting specific properties.
    Users can be identified by their ID, UserPrincipalName, or DisplayName. Additionally, a list of users can be provided in a CSV file.
    The cmdlet also supports parallel processing of user objects, with a default throttle limit of 8 threads.

    .PARAMETER User
    Specifies the ID, UserPrincipalName, or DisplayName of the user to retrieve.
    A list of users can also be provided in a CSV file.
    If the CSV file has headers, they must contain one of the following columns: Id, UserPrincipalName, or DisplayName.
    DisplayName is not unique in AAD and may result in multiple matches.

    Note that tab completion is supported for the DisplayName parameter.
    You can type a few letters and use tab multiple times to cycle through and find matching DisplayNames of users you want more details on.
    For example, typing 'fr' and pressing tab multiple times may show both 'Frank' and 'Fred' as options.

    .PARAMETER Select
    Specifies a comma-separated list of properties to be returned by Microsoft Graph.
    For example: Get-gUser -Select 'DisplayName,UserPrincipalName,Mail'
    
    .PARAMETER IncludeManager
    If the user has a manager listed in Azure AD, this switch includes the user's manager in the output

    .PARAMETER All
    Switch to retrieve all users in the Azure AD Tenant.

    .PARAMETER Beta
    Switch to use the beta version of Microsoft Graph API.

    .PARAMETER ThrottleLimit
    Only used with the -All switch. Specifies the maximum number of parallel threads or concurrent operations allowed during parallel processing. Default value is 8.

    .EXAMPLE
    Import-Csv .\userlist.csv | Get-gUser

    .EXAMPLE
    Import-Csv .\userlist.csv | Get-gUser -Select 'DisplayName,UserPrincipalName,Mail'

    .EXAMPLE
    Import-Csv .\userlist.csv | Get-gUser -IncludeManager -Select 'DisplayName,UserPrincipalName'
    
    .EXAMPLE
    Get-gUser -User '72ae3f1a-c8f1-4aad-af82-51473013fa74'

    .EXAMPLE
    Get-gUser -User 'Kevin Blumenfeld'
    
    .EXAMPLE
    Get-gUser -User 'Kevin Blumenfeld' -Beta
    Retrieves user information for 'Kevin Blumenfeld' using the beta version of Microsoft Graph API.

    .EXAMPLE
    Get-gUser -User 'Kevin Blumenfeld' -Select 'DisplayName,UserPrincipalName'

    .EXAMPLE
    Get-gUser -User 'Kevin Blumenfeld' -Select 'DisplayName,UserPrincipalName'

    .EXAMPLE
    Get-gUser -User 'Kevin Blumenfeld' -IncludeManager -Select 'DisplayName,UserPrincipalName'

    .EXAMPLE
    Get-gUser -All
    Retrieves all users in the Azure AD Tenant.

    .EXAMPLE
    Get-gUser -All -Beta
    Retrieves all users in the Azure AD Tenant using the beta version of Microsoft Graph API.
    
    .EXAMPLE
    Get-gUser -All -Select 'DisplayName,UserPrincipalName'
    Retrieves all users in the Azure AD Tenant.

    .EXAMPLE
    Get-gUser -All -Beta -Select 'DisplayName,UserPrincipalName'
    Retrieves all users in the Azure AD Tenant using the beta version of Microsoft Graph API.

    #>
    [CmdletBinding()]
    param (
        [Parameter( Mandatory, ValueFromPipeline, ParameterSetName = 'pipeline' )]
        [ArgumentCompleter([completer_iUser_Deleted_DisplayName])]
        [object]
        $User,

        [Parameter(ParameterSetName = 'pipeline' )]
        [string]
        $Select,

        [Parameter(ParameterSetName = 'pipeline' )]
        [switch]
        $IncludeManager,

        [Parameter(ParameterSetName = 'pipeline')]
        [Parameter(ParameterSetName = 'All')]
        [switch]
        $Beta,

        [Parameter(ParameterSetName = 'All')]
        [switch]
        $All,

        [Parameter(ParameterSetName = 'All')]
        [int]
        $ThrottleLimit = 8
    )

    begin {
        if ($All) {
            $splat = @{
                ThrottleLimit = $ThrottleLimit
            }
            if ($Select) {
                $splat['Select'] = $Select
            }
            Get-gUserDeletedAll @splat
            return
        }
    }
    process {
        foreach ($Item in $User) {
            if ($Item -is [string] -and $Item -as [Guid]) {
                $filterstring = '{0}?' -f $Item
            }
            elseif ($Item -as [mailaddress]) {
                $filterstring = "?`$filter=userprincipalname eq '{0}'" -f [System.Web.HttpUtility]::UrlEncode($Item)
                
            }
            elseif ($Item -is [string]) {
                $filterstring = "?`$filter=DisplayName eq '{0}'" -f $Item
            }
            else {
                if ($Item.Id) {
                    $filterstring = '{0}?' -f $Item.Id
                }
                elseif ($Item.UserPrincipalName -as [mailaddress]) {
                    $filterstring = '{0}?' -f $Item.UserPrincipalName
                }
                elseif ($Item.DisplayName) {
                    $filterstring = "?`$filter=DisplayName eq '{0}'" -f $Item.DisplayName
                }
            }
            if ($filterstring) {
                if ($Select) {
                    $filterstring = '{0}&$Select={1}' -f $filterstring, $Select
                }
                if ($IncludeManager) {
                    $filterstring = '{0}&$expand=manager' -f $filterstring
                }

                if (-not $Beta) {
                    $Uri = 'https://graph.microsoft.com/v1.0/directory/deletedItems/microsoft.graph.user/{0}' -f $filterstring
                }
                else {
                    $Uri = 'https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.user/{0}' -f $filterstring
                }
                if ($filterstring -like '*filter=*') {
                    (Invoke-gRestMethod -Method 'GET' -Uri $Uri).value
                    continue
                }
                Invoke-gRestMethod -Method 'GET' -Uri $Uri
            }
        }
    }
}
#EndRegion '.\Public\User\Get-gUserDeleted.ps1' 169


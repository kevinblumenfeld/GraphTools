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
        [ArgumentCompleter([completer_gUser_DisplayName])]
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

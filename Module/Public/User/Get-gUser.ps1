function Get-gUser {

    <#
    .SYNOPSIS
    Retrieve the properties and relationships of user objects in Azure Active Directory (AAD).

    .DESCRIPTION
    This cmdlet retrieves user objects from AAD, providing options for filtering and selecting specific properties.
    Users can be identified by their ID, UserPrincipalName, or DisplayName. The cmdlet supports wildcard characters in the UserPrincipalName and DisplayName, and the objects piped into the function are processed individually.

    .PARAMETER User
    Specifies the ID, UserPrincipalName, or DisplayName of the user to retrieve. This parameter supports wildcards (*) for UserPrincipalName and DisplayName. If this parameter is not provided, the cmdlet retrieves all users in the Azure AD Tenant.

    .PARAMETER Select
    Specifies a comma-separated list of properties to be returned by Microsoft Graph.

    .PARAMETER IncludeManager
    If the user has a manager listed in Azure AD, this switch includes the user's manager in the output.

    .PARAMETER Beta
    Specifies to use the beta version of the Microsoft Graph API.

    .PARAMETER ThrottleLimit
    Specifies the maximum number of parallel threads or concurrent operations allowed during parallel processing. Default value is 8. This parameter is only used when the User parameter is not provided.
    
    .EXAMPLE
    Import-Csv .\userlist.csv | Get-gUser -Select 'DisplayName,UserPrincipalName,Mail'

    .EXAMPLE
    Import-Csv .\userlist.csv | Get-gUser -IncludeManager -Select 'DisplayName,UserPrincipalName'
    
    .EXAMPLE
    Get-gUser -User '72ae3f1a-c8f1-4aad-af82-51443013fa74'

    .EXAMPLE
    Get-gUser -User 'Kevin Blumenfeld'
    
    .EXAMPLE
    Get-gUser -User 'Kevin*'
    Retrieves user information for users whose name begins with 'Kevin'.

    .EXAMPLE
    Get-gUser -User '*Blumenfeld'
    Retrieves user information for users whose name ends with 'Blumenfeld'.

    .EXAMPLE
    Get-gUser -User '*@company.com'
    Retrieves user information for users whose UserPrincipalName ends with '@company.com'.

    .EXAMPLE
    Get-gUser -User 'Kevin*' -Select 'DisplayName,UserPrincipalName'
    Retrieves the DisplayName and UserPrincipalName for users whose name begins with 'Kevin'.

    .EXAMPLE
    Get-gUser -User '*@company.com' -Select 'DisplayName,UserPrincipalName'
    Retrieves the DisplayName and UserPrincipalName for users whose UserPrincipalName ends with '@company.com'.

    .EXAMPLE
    Get-gUser -User 'Kevin*' -IncludeManager -Select 'DisplayName,UserPrincipalName'
    Retrieves the DisplayName, UserPrincipalName, and manager for users whose name begins with 'Kevin'.

    .EXAMPLE
    Get-gUser -User '*@company.com' -IncludeManager -Select 'DisplayName,UserPrincipalName'
    Retrieves the DisplayName, UserPrincipalName, and manager for users whose UserPrincipalName ends with '@company.com'.

    .EXAMPLE
    Get-gUser
    Retrieves all users in the Azure AD Tenant.

    .EXAMPLE
    Get-gUser -Beta
    Retrieves all users in the Azure AD Tenant using the beta version of Microsoft Graph API.

    .EXAMPLE
    Get-gUser -Select 'DisplayName,UserPrincipalName'
    Retrieves all users in the Azure AD Tenant with only the specified properties.

    .EXAMPLE
    Get-gUser -Beta -Select 'DisplayName,UserPrincipalName'
    Retrieves all users in the Azure AD Tenant using the beta version of Microsoft Graph API with only the specified properties.

    .NOTES
    When the -IncludeManager switch is used, a full user object is output for Manager field

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

        [Parameter(ParameterSetName = 'pipeline' )]
        [Parameter(ParameterSetName = 'All' )]
        [switch]
        $Beta,

        [Parameter(ParameterSetName = 'All' )]
        [int]
        $ThrottleLimit = 8
    )

    begin {
        if ($PSCmdlet.ParameterSetName -eq 'All') {
            $splat = @{ThrottleLimit = $ThrottleLimit }
            if ($Select) { $splat['Select'] = $Select }
            if ($Beta) { $splat['Beta'] = $true }
            Get-gUserAll @splat
            return
        }
    }
    process {
        
        if ($PSCmdlet.ParameterSetName -eq 'All') { return }

        foreach ($Item in $User) {
            $filterstring = if ($Item -match "\*+" -and $Item -as [mailaddress]) { "?`$filter={0}" -f [System.Web.HttpUtility]::UrlEncode((New-gFilterString $Item -SearchField 'userPrincipalName')) }
            elseif ($Item -match "\*+") { "?`$filter={0}" -f [System.Web.HttpUtility]::UrlEncode((New-gFilterString $Item -SearchField 'displayName')) }
            elseif ($Item -is [string] -and $Item -as [Guid]) { $Item }
            elseif ($Item -as [mailaddress]) { "?`$filter=userPrincipalName eq '{0}'" -f [System.Web.HttpUtility]::UrlEncode($Item) }
            elseif ($Item -is [string]) { "?`$filter=DisplayName eq '{0}'" -f [System.Web.HttpUtility]::UrlEncode($Item) }
            elseif ($Item.Id) { $Item.Id }
            elseif ($Item.UserPrincipalName -as [mailaddress]) { $Item.UserPrincipalName }
            elseif ($Item.DisplayName) { "?`$filter=DisplayName eq '{0}'" -f $Item.DisplayName }

            if (-not $filterstring) { continue }

            if ($Select) { $filterstring = '{0}&$Select={1}' -f $filterstring, $Select }
            if ($IncludeManager) { $filterstring = '{0}&$expand=manager' -f $filterstring }

            $Uri = 'https://graph.microsoft.com/{0}/users/{1}' -f @(
                if ($Beta) { 'beta' } else { 'v1.0' }
                $filterString
            )
            $splat = @{ 'Uri' = $Uri }

            if ($filterstring -like '*filter=*') {
                if ($filterstring -like '*endswith*') {
                    $splat['Eventual'] = $true
                    $splat['Uri'] = '{0}&$count=true' -f $Uri
                }
                (Invoke-gRestMethod @splat).value
                continue
            }
            Invoke-gRestMethod -Method 'GET' -Uri $Uri
        }
    }
}

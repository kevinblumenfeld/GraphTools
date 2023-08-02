function Search-gUser {
    <#
    .SYNOPSIS
    A function to search a user in the Microsoft Graph API.

    .DESCRIPTION
    This function allows you to search for a specific user in the Microsoft Graph API.
    The function accepts several parameters to refine your search, such as the user's name, the search field, 
    and optional parameters to further specify your request.

    .PARAMETER User
    Specifies the user to search for. This parameter is mandatory and accepts a string or object that
    defines the user.

    .PARAMETER SearchField
    Specifies the field to search. This parameter is mandatory.

    .PARAMETER Select
    Specifies which fields to return in the response. This is an optional parameter.

    .PARAMETER IncludeManager
    Includes the manager of the user in the search. This is an optional parameter.

    .PARAMETER Beta
    Specifies whether to use the beta version of the Microsoft Graph API. If not specified, the v1.0 version will be used. 
    This is an optional parameter.

    .EXAMPLE
    Search-gUser -User 'johndoe' -SearchField 'displayName' -IncludeManager
    This example shows how to search for a user based on their display name and include their manager in the search.

    .EXAMPLE
    Search-gUser -User 'john*' -SearchField 'displayName' -Select 'displayName,mail' -Beta
    This example shows how to search for a user with wildcard based on their display name in the beta version of the Microsoft Graph API 
    and select only their displayName and mail in the returned data.

    .EXAMPLE
    Search-gUser -User '*@domain.com' -SearchField 'userPrincipalName' -Select 'userPrincipalName,displayName,mail' -Beta
    This example shows how to search for a user with wildcard based on their display name in the beta version of the Microsoft Graph API 
    and select only their displayName and mail in the returned data.
    #>

    [CmdletBinding()]
    param (
        [Parameter( Mandatory )]
        [ArgumentCompleter([completer_gUser_DisplayName])]
        [object]
        $User,

        [Parameter( Mandatory )]
        [string]
        $SearchField,

        [Parameter()]
        [string]
        $Select,

        [Parameter()]
        [switch]
        $IncludeManager,

        [Parameter()]
        [switch]
        $Beta
    )


    process {
        
        if ($PSCmdlet.ParameterSetName -eq 'All') { return }

        foreach ($Item in $User) {
            $filterstring = if ($Item -match "\*+") { "?`$filter={0}" -f (New-gFilterString $Item -SearchField $SearchField) }
            else { "?`$filter={0} eq '{1}'" -f $SearchField, $Item }
            if (-not $filterstring) { continue }

            if ($Select) { $filterstring = '{0}&$Select={1}' -f $filterstring, $Select }
            if ($IncludeManager) { $filterstring = '{0}&$expand=manager' -f $filterstring }

            $Uri = 'https://graph.microsoft.com/{0}/users/{1}' -f @(
                if ($Beta) { 'beta' } else { 'v1.0' }
                $filterstring
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

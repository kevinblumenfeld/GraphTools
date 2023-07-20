function hash_gApp_Role {
    [CmdletBinding()]
    param (

    )

    $Script:RoleHash = @{}
    $Script:AppHash = @{}
    $Script:AppHashById = @{}

    $RestSplat = @{
        Uri     = 'https://graph.microsoft.com/beta/applications'
        Headers = @{ 'Authorization' = "Bearer $Script:Token" }
        Method  = 'GET'
        verbose = $false
    }

    do {

        $Response = Invoke-RestMethod @RestSplat

        if ($Response.'@odata.nextLink') {
            $Next = $Response.'@odata.nextLink'
        }
        else {
            $Next = $null
        }

        foreach ($App in $Response.value) {

            if ($App.AppRoles) {
                $RoleList = [System.Collections.Generic.List[string]]::New()

                foreach ($Role in $App.AppRoles) {

                    $RoleList.Add('{0}' -f $Role.DisplayName)
                    $Script:RoleHash[$Role.Id] = '{0}' -f $Role.DisplayName

                }
            }
            $AppHash[$App.DisplayName] = @{
                Id                    = $App.Id
                AppRole               = @($RoleList) -ne '' -join "`r`n"
                PublisherDomain       = $App.PublisherDomain
                SignInAudience        = $App.SignInAudiences
                GroupMembershipClaims = $App.GroupMembershipClaims
                CreatedDateTime       = $App.CreatedDateTime
                IdentifierUris        = @($App.IdentifierUris) -ne '' -join "`r`n"
                AppID                 = $App.AppID
            }
            $AppHashById[$App.Id] = @{
                DisplayName           = $App.DisplayName
                AppRole               = @($RoleList) -ne '' -join "`r`n"
                PublisherDomain       = $App.PublisherDomain
                SignInAudience        = $App.SignInAudiences
                GroupMembershipClaims = $App.GroupMembershipClaims
                CreatedDateTime       = $App.CreatedDateTime
                IdentifierUris        = @($App.IdentifierUris) -ne '' -join "`r`n"
                AppID                 = $App.AppID
            }

        }

        $RestSplat = @{
            Uri     = $Next
            Headers = @{ Authorization = "Bearer $Script:Token" }
            Method  = 'Get'
            Verbose = $false
        }
    } until (-not $next)
}

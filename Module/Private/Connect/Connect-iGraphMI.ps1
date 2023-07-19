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

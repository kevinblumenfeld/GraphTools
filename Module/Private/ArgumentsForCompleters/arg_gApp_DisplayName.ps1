function arg_gApp_DisplayName {
    [CmdletBinding()]
    param (
        [Parameter()]
        $WordToComplete
    )

    

    $RestSplat = @{
        Uri     = "https://graph.microsoft.com/beta/applications?`$filter={0}&top=20&select=DisplayName" -f (
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

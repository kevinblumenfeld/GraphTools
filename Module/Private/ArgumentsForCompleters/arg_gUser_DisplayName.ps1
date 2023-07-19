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

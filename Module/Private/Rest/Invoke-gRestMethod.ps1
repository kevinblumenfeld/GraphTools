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
            while ((-not $script:Token) -or ([DateTime]::UtcNow -ge $script:TokenExpirationTime )) { 
                Connect-gGraph -ClientID $Script:ClientID -TenantID $Script:TenantID -Secret $Script:Secret
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
                Connect-gGraph -ClientID $Script:ClientID -TenantID $Script:TenantID -Secret $Script:Secret
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

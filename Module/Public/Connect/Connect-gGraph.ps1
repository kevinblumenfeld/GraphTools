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

    $Script:TokenExpirationTime = ([datetime]::UtcNow).AddSeconds($Response.'expires_in' - 120)
    $Script:Token = $Response.access_token
}


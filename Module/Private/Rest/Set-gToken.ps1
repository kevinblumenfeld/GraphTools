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

function Set-gToken {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Token,

        [Parameter()]
        $ClientID,

        [Parameter()]
        $TenantID,

        [Parameter()]
        $Secret,

        [Parameter()]
        $TokenExpirationTime
    )

    $Script:Token = $Token
    $Script:ClientID = $ClientID
    $Script:Secret = $Secret
    $Script:TenantID = $TenantID
    $Script:TokenExpirationTime = $TokenExpirationTime

}

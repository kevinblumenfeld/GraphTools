function Get-gUserMemberOf {

    [CmdletBinding()]
    param (

        [Parameter(Mandatory)]
        $UserID,
    
        [Parameter()]
        $Select = 'DisplayName,ID'
    )

    $RestSplat = @{
        Uri = "https://graph.microsoft.com/v1.0/users/{0}/memberOf/microsoft.graph.group/?`$select={1}" -f $UserID, $Select
    }
    
    (Invoke-RestMethod @RestSplat).value
}
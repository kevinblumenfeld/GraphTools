function Get-gUserApp {
    param (
        [Parameter(Mandatory)]
        $UserID,
    
        [Parameter()]
        $Select = 'resourceDisplayName,principalDisplayName,appRoleId'
    )

    $GroupList = Get-gUserMemberOf -UserID $UserID

    foreach ($Group in $GroupList) {
        
        $RestSplat = @{
            Uri = "https://graph.microsoft.com/v1.0/groups/{0}/appRoleAssignments/?`$select={1}" -f $Group.ID, $Select
        }
        (Invoke-RestMethod @RestSplat).value
    }
}
function Format-gObject {
    
    [CmdletBinding()]
    param (
        [Parameter( Mandatory, ValueFromPipeline, ParameterSetName = 'pipeline' )]
        [object]
        $Object
    )

    process {
        $Hash = [ordered]@{}

        foreach ($row in $Object.PSObject.Properties) {
            if ($row.value -is [System.Management.Automation.PSCustomObject]) {
                foreach ($item in $row.value.PSObject.Properties) {
                    $Hash[$item.name] = $item.value
                }
                continue
            }
            if ($row.name -match 'proxyaddresses|othermails|mobilephone|businessPhones|imAddresses') {
                $Hash[$row.name] = @($row.value) -ne '' -join ','
                continue
            }
            if ($row.name -eq 'appRoles') {
                $AppRoleList = foreach ($role in $row.value) {
                    '{0} [ Value {1} ] [ Enabled {2} ] {3}' -f $role.displayName, $role.value, $role.isEnabled, $role.id   
                }
                $Hash[$row.name] = @($AppRoleList) -ne '' -join "`r`n"
                continue
            }
            if ($row.name -eq 'passwordCredentials') {
                $CredList = foreach ($cred in $row.value) {
                    '{0} [ End {1} ] [ Hint {2} ] {3}' -f $cred.displayName, $cred.endDateTime, $cred.Hint, $cred.keyId
                }
                $Hash[$row.name] = @($CredList) -ne '' -join "`r`n"
                continue
            }
            $Hash[$row.name] = $row.value
        }
        [pscustomobject]$Hash
    }
}
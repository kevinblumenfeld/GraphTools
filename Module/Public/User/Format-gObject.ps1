function Format-gObject {
    
    [CmdletBinding()]
    param (
        [Parameter( Mandatory, ValueFromPipeline, ParameterSetName = 'pipeline' )]
        [object[]]
        $InputObject
    )
    begin {
        $list = [System.Collections.Generic.List[object]]::new()
        $props = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::InvariantCultureIgnoreCase)
    }
    process {
        # $Hash = [ordered]@{}
        foreach ($object in $InputObject) {
            
            foreach ($property in $object.PSObject.Properties) {
                
                if ($property.value -is [System.Management.Automation.PSCustomObject]) {
                    foreach ($item in $property.value.PSObject.Properties) {
                        $Hash[$item.name] = $item.value
                        $null = $props.Add($property.Name)
                    }
                    continue
                }
                if ($property.name -match 'proxyaddresses|othermails|mobilephone|businessPhones|imAddresses') {
                    $Hash[$property.name] = @($property.value) -ne '' -join ','
                    $null = $props.Add($property.Name)
                    continue
                }
                if ($property.name -eq 'appRoles') {
                    $AppRoleList = foreach ($role in $property.value) {
                        '{0} [ Value {1} ] [ Enabled {2} ] {3}' -f $role.displayName, $role.value, $role.isEnabled, $role.id   
                    }
                    $Hash[$property.name] = @($AppRoleList) -ne '' -join "`r`n"
                    $null = $props.Add($property.Name)
                    continue
                }
                if ($property.name -eq 'passwordCredentials') {
                    $CredList = foreach ($cred in $property.value) {
                        '{0} [ End {1} ] [ Hint {2} ] {3}' -f $cred.displayName, $cred.endDateTime, $cred.Hint, $cred.keyId
                    }
                    $Hash[$property.name] = @($CredList) -ne '' -join "`r`n"
                    $null = $props.Add($property.Name)
                    continue
                }
                $Hash[$property.name] = $property.value
                $null = $props.Add($property.Name)
            }
            $list.Add([pscustomobject]$Hash)
        }
    }
    end {
        $list | Select-Object @($props.psbase.Keys)
    }
}
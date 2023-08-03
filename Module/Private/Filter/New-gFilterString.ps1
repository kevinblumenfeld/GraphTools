
function New-gFilterString {
    param (
        [validatescript({
                if ($_ -is [string] -and $_ -match '\*.*\*|^\*$') { throw [ParameterBindingException]::new("Wildcard cannot be '*something*' or just '*'") } else { $true }
            })]
        [parameter(position = 0, mandatory = $true)]
        [string]
        $SearchTerm,
            
        [parameter(position = 1)]
        [string]
        $SearchField,

        [parameter()]
        $ExtraFields = @(),
        
        [switch]
        $ToLower
    )
    
    # Adapted from James O'Neil https://youtu.be/hXFbfwmdNsU: https://github.com/jhoneill/MsftGraph
    
    if ($toLower) { $SearchTerm = $SearchTerm.ToLower() }
    if ($Searchterm -as [mailaddress] -and (-not $SearchField)) { $SearchField = 'userPrincipalName' }
    
    #Replace '  with '' - ensure we don't turn '' into '''' !
    $SearchTerm = $SearchTerm -replace "(?<!')'(?!')" , "''"
    #validation blocked "* and *something*" so we have no *, * at the start, in the middle, or at the end
    # if ($SearchField -eq 'proxyAddresses') { $filterStrings = , "{0}/any(p:endsWith(p, '{1}'))" -f $SearchField, $SearchTerm }
    if ($SearchTerm -notmatch '\*') { $filterStrings = , "$SearchField eq '$SearchTerm'" }
    elseif ($SearchTerm -match '^\*(.+)') { $filterStrings = , "endswith($SearchField,'$($Matches[1])')" }
    elseif ($SearchTerm -match '(.+)\*$') { $filterStrings = , "startswith($SearchField,'$($Matches[1])')" }
    elseif ($SearchTerm -match '^(.+)\*(.+)$') {
        $filterStrings = , ("(startswith($SearchField,'$($Matches[1])')" +
            " and endswith($SearchField,'$($Matches[2])'))"  )
    }
    if ($ToLower) { $filterStrings[0] = $filterStrings[0] -replace "$SearchField" , "toLower($SearchField)" }

    foreach ($f in $ExtraFields) { $filterStrings += $filterStrings[0] -replace "$SearchField", $f }
    $filterStrings -join ' or '
}

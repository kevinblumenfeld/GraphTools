function Get-gUserAll {
    [CmdletBinding()]
    param (

        [Parameter()]
        $ThrottleLimit = 8,
        
        [Parameter()]
        [string]
        $Select,
        
        [Parameter()]
        [switch]
        $Beta
    )

    $UserCount = Invoke-gRestMethod -Uri "https://graph.microsoft.com/v1.0/users/`$count" -Method 'GET' -Eventual
    Write-Verbose "Getting $($UserCount) users. . .  "

    $ModuleBase = $MyInvocation.MyCommand.Module.Path

    '!#$%&*+-/0123456789=?ABCDEFGHIJKLMNOPQRSTUVWXYZ^_`{|}~'.toCharArray() | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {

        $Character = "$_"
        Import-Module $using:ModuleBase -Force
                
        $TokenSplat = @{
            Token               = $using:Token
            TokenExpirationTime = $using:TokenExpirationTime
            ClientID            = $using:ClientID
            TenantId            = $using:TenantID
            Secret              = $using:Secret
        }

        Set-gToken @TokenSplat

        $Uri = 'https://graph.microsoft.com/{0}/users?$filter={1}' -f @(
            if ($using:Beta) { 'beta' } else { 'v1.0' }
            [System.Web.HttpUtility]::UrlEncode(('startswith({0}, ''{1}'')' -f 'mailnickname', "$Character" ))
        )
        if ($using:Select) { $Uri = '{0}&$Select={1}' -f $Uri, $using:Select }
        $splat = @{
            Uri         = $Uri
            ErrorAction = 'Stop'
        }
        try {
            (Invoke-gRestMethod @splat).value
        
        }
        catch {
            Write-Error -ErrorRecord $_
        }
    }
}

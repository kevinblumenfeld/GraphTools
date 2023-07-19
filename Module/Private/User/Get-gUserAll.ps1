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

        if (-not $using:Beta) {

            Write-Host "NOT BETA"
            $Uri = "https://graph.microsoft.com/v1.0/users?`$filter={0}" -f (
                [System.Web.HttpUtility]::UrlEncode(('startswith({0}, ''{1}'')' -f 'mailnickname', "$Character" ))
            )
        }
        else {
            $Uri = "https://graph.microsoft.com/beta/users?`$filter={0}" -f (
                [System.Web.HttpUtility]::UrlEncode(('startswith({0}, ''{1}'')' -f 'mailnickname', "$Character" ))
            )
        }
        
        if ($using:Select) {
            $Uri = '{0}&$Select={1}' -f $Uri, $using:Select
        }
        $splat = @{
            Uri         = $Uri
            Method      = 'GET'
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

function Get-gUserDeletedAll {
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
            $Uri = "https://graph.microsoft.com/v1.0/directory/deletedItems/microsoft.graph.user?`$filter={0}" -f (
                [System.Web.HttpUtility]::UrlEncode(('startswith({0}, ''{1}'')' -f 'mailnickname', "$Character" ))
            )
        }
        else {
            $Uri = "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.user?`$filter={0}" -f (
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
            # Eventual    = $true
        }
        try {
            (Invoke-gRestMethod @splat).value
        
        }
        catch {
            Write-Error -ErrorRecord $_
        }
    }
}

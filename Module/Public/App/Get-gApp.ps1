function Get-gApp {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param (

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ByApp')]
        [ArgumentCompleter([completer_gApp_DisplayName])]
        [object]
        $App,

        [Parameter(Mandatory, ParameterSetName = 'ByAppID')]
        [guid]
        $AppId,

        [Parameter()]
        [string]
        $Select,

        [Parameter()]
        [string]
        $Filter
    )

    begin {
        if ($PSCmdlet.ParameterSetName -eq 'All') {
            $splat = @{ Uri = 'https://graph.microsoft.com/v1.0/applications/' }
            (Invoke-gRestMethod @splat).value
            return
        }
    }
    process {
        if ($PSCmdlet.ParameterSetName -eq 'All') { return }

        foreach ($Item in $App) {

            $filterstring = if ($Item -match "\*+") { "?`$filter={0}" -f (New-gFilterString $Item -SearchField 'DisplayName') }
            elseif (-not $AppID -and ($Item -is [string] -and $Item -as [Guid])) { $Item }
            elseif ($PSCmdlet.ParameterSetName -eq 'ByAppId') { "?`$filter=AppId eq '{0}'" -f $Item }
            elseif ($Item -is [string]) { "?`$filter=DisplayName eq '{0}'" -f $Item }
            elseif ($Item.Id -and $Item.Id -as [guid]) { $Item.Id }
            elseif ($Item.DisplayName) { "?`$filter=DisplayName eq '{0}'" -f $Item.DisplayName }
            if ($Select) { $filterstring = '{0}&$Select={1}' -f $filterstring, $Select }
            if ($Filter) { $filterstring = '{0}&$filter={1}' -f $filterstring, $Filter }

            
            $splat = @{ Uri = 'https://graph.microsoft.com/v1.0/applications/{0}' -f $filterstring }
            Write-Host ("URI {0}" -f $splat['Uri'])
            if ($filterstring -like '*filter=*') {
                if ($filterstring -like '*endswith*') {
                    $splat['Eventual'] = $true
                    $splat['Uri'] = '{0}&$count=true' -f $Uri
                }
                (Invoke-gRestMethod @splat).value
                continue
            }
            Invoke-gRestMethod @splat
        }
    }
}

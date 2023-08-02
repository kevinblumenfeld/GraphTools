function Get-gApp {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param (

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ByApp')]
        [ArgumentCompleter([completer_gApp_DisplayName])]
        [object]
        $App,

        [Parameter(Mandatory, ParameterSetName = 'ByAppID')]
        [guid]
        $AppId
    )

    begin {
        if ($PSCmdlet.ParameterSetName -eq 'All') {
            $RestSplat = @{ Uri = 'https://graph.microsoft.com/v1.0/applications/' }
            (Invoke-gRestMethod @RestSplat).value
            return
        }
    }
    process {
        if ($PSCmdlet.ParameterSetName -eq 'All') { return }

        foreach ($Item in $App) {

            $UriFilter = if ($Item -match "\*+") { "?`$filter={0}" -f (New-gFilterString $Item ) }
            elseif (-not $AppID -and ($Item -is [string] -and $Item -as [Guid])) { $Item }
            elseif ($PSCmdlet.ParameterSetName -eq 'ByAppId') { "?`$filter=AppId eq '{0}'" -f $Item }
            elseif ($Item -is [string]) { "?`$filter=DisplayName eq '{0}'" -f $Item }
            elseif ($Item.Id -and $Item.Id -as [guid]) { $Item.Id }
            elseif ($Item.DisplayName) { "?`$filter=DisplayName eq '{0}'" -f $Item.DisplayName }
            
            else {
                Write-Error "Application not found"
                continue
            } 
            
            $RestSplat = @{ Uri = 'https://graph.microsoft.com/v1.0/applications/{0}' -f $UriFilter }

            if ($UriFilter -like '*filter=*') {
                (Invoke-gRestMethod @RestSplat).value
                continue
            }
            Invoke-gRestMethod @RestSplat
        }
    }
}

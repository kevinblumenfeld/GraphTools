function Invoke-gParallel {
    [CmdletBinding(DefaultParameterSetName = 'FromPipeline')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FromPipeline')]
        [object[]]
        $Object,

        [Parameter(Mandatory, ParameterSetName = 'FromFile')]
        [ValidateScript( { Test-Path $_ } )]
        [string]
        $SourceFilePath,

        [Parameter(Mandatory)]
        [string]
        $Endpoint,

        [Parameter(Mandatory)]
        [string]
        $Field,

        [Parameter()]
        [int]
        $ThrottleLimit = 8
    )

    begin {
        $objects = [System.Collections.Generic.List[object]]::new()
    }
    process {
        if ($PSCmdlet.ParameterSetName -eq 'FromPipeline') {
            $objects.AddRange($Object)
        }
    }
    end {
        if ($PSCmdlet.ParameterSetName -eq 'FromFile') {
            $objects = Import-Csv -Path $SourceFilePath
        }

        [ref]$Reference = 0
        $groupSize = [math]::Ceiling($objects.Count / $ThrottleLimit)
        $Chunk = $objects | Group-Object -Property {
            [math]::Floor($Reference.Value++ / $groupSize)
        }
        $ModuleBase = $MyInvocation.MyCommand.Module.Path

        
        $Token = $Script:Token
        $ClientID = $Script:ClientID
        $Secret = $Script:Secret
        $TenantID = $Script:TenantID
        $TokenExpirationTime = $Script:TokenExpirationTime
    
        $Chunk | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
    
            Import-Module $using:ModuleBase -Force
    
            $toksplat = @{
                Token               = $using:Token
                ClientID            = $using:ClientID
                Secret              = $using:Secret
                TenantID            = $using:TenantID
                TokenExpirationTime = $using:TokenExpirationTime
            }
            Set-gToken @toksplat
    
            foreach ($row in $_.Group) {
                $splat = @{
                    Uri = "https://graph.microsoft.com{0}" -f ($Using:Endpoint -f $row.$using:field)
                }

                if ($Using:Endpoint -like '*filter=*') {
                    if ($Using:Endpoint -like '*endswith*') {
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
}
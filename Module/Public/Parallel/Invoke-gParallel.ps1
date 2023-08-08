function Invoke-gParallel {
    <#
    .SYNOPSIS
    Executes parallel processing for given objects or file, and invokes a REST method against a specified endpoint.

    .DESCRIPTION
    The Invoke-gParallel function takes input from a pipeline or a file and processes it in parallel. It can be used to send REST requests to a specific endpoint with a given throttle limit.

    .PARAMETER Object
    An array of objects to be processed in parallel. Used when input is provided from the pipeline.

    .PARAMETER SourceFilePath
    The path to the CSV file containing the objects to be processed. Used when input is provided from a file.

    .PARAMETER Endpoint
    The endpoint against which the REST method will be invoked.

    .PARAMETER Field
    The field name to be used within the endpoint URL.

    .PARAMETER ThrottleLimit
    The maximum number of parallel tasks to run at once. Defaults to 8 if not specified.

    .EXAMPLE
    $Result = Invoke-gParallel -SourceFilePath list.csv -Endpoint "/v1.0/users/?`$filter=mail eq '{0}'" -Field email
    Invokes the function using a CSV file containing a list of email addresses, and sends a REST request to the specified endpoint for each email.

    .EXAMPLE
    $Data | Invoke-gParallel -Endpoint "/v1.0/users/?`$filter=mail eq '{0}'" -Field email
    Invokes the function using pipeline input, and sends a REST request to the specified endpoint for each provided item.

    .NOTES
    Ensure that the necessary authentication details like Token, ClientID, Secret, TenantID, and TokenExpirationTime are provided in the script scope. This function is designed to work with Microsoft Graph but can be adapted to other RESTful services.
    #>
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
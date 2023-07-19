[CmdletBinding()]
Param(
    [Parameter()]
    [switch]
    $Build,

    [Parameter()]
    [switch]
    $Publish,

    [Parameter()]
    [string]
    $GalleryToken
)
Install-Module -Name ModuleBuilder -Force
$modulePath = [IO.Path]::Combine($PSScriptRoot, 'Module')
Build-Module -Path $modulePath -Verbose

Publish-Module -Path $modulePath -NuGetApiKey $env:PSGALLERY_TOKEN

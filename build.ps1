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
Install-Module -Name ModuleBuilder -Force -Repository PSGallery
$modulePath = [IO.Path]::Combine($PSScriptRoot, 'Module')
$outputPath = [IO.Path]::Combine($PSScriptRoot, 'Output')
Build-Module -Path $modulePath -Verbose

Publish-Module -Path $outputPath -NuGetApiKey $env:PSGALLERY_TOKEN

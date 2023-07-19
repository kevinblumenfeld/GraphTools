[CmdletBinding()]
Param(
    [Parameter()]
    [switch]
    $InstallDependencies,
    
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

$modulePath = [IO.Path]::Combine($PSScriptRoot, 'Module')
$outputPath = [IO.Path]::Combine($PSScriptRoot, 'Output')

if ($InstallDependencies) {
    Install-Module -Name ModuleBuilder -Force -Repository PSGallery
}
if ($Build) {
    Build-Module -Path $modulePath -Verbose
}
if ($Publish) {
    Publish-Module -Path $outputPath -NuGetApiKey $env:PSGALLERY_TOKEN
}


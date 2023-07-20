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
$outputPath = [IO.Path]::Combine($PSScriptRoot, 'Output', 'GraphTools')

if ($InstallDependencies) {
    Write-Host "Installing Dependencies"
    Install-Module -Name ModuleBuilder -Force -Repository PSGallery
}
if ($Build) {
    Write-Host "Building Module"
    Build-Module -Path $modulePath -Verbose
}
if ($Publish) {
    Write-Host "Publishing Module"
    Publish-Module -Path $outputPath -NuGetApiKey $env:PSGALLERY_TOKEN
}

[CmdletBinding()]
Param(
    [Parameter()]
    [switch]
    $InstallDependencies,
    
    [Parameter()]
    [switch]
    $RemoveBuildFiles,

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
$outputFolder = [IO.Path]::Combine($PSScriptRoot, 'Output')
$outputPath = [IO.Path]::Combine($PSScriptRoot, 'Output', 'GraphTools')

if ($InstallDependencies) {
    Write-Host "Installing Dependencies"
    Install-Module -Name ModuleBuilder -Force -Repository PSGallery
}
if ($RemoveBuildFiles) {
    Write-Host "Removing Build Files"
    Remove-Item $outputFolder -Recurse -Force
}
if ($Build) {
    Write-Host "Building Module"
    Build-Module -Path $modulePath -Verbose
}
if ($Publish) {
    Write-Host "Publishing Module"
    Publish-Module -Path $outputPath -NuGetApiKey $env:PSGALLERY_TOKEN
}

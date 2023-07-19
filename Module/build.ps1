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
$TempPath = (Get-gtem TEMP:\).fullname
Build-Module -Path $TempPath -Verbose

Publish-Module GraphTools -NuGetApiKey $env:PSGALLERY_TOKEN

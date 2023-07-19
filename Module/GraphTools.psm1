Get-ChildItem -File -Recurse *.ps1 -Path @(
    "$PSScriptRoot/Enum"
    "$PSScriptRoot/Classes"
    "$PSScriptRoot/Public"
    "$PSScriptRoot/Private")  | ForEach-Object {
    . $_.FullName
}

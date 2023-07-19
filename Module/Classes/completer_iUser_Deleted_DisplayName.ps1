using namespace System.Management.Automation

class completer_iUser_Deleted_DisplayName                : IArgumentCompleter {
    [System.Collections.Generic.IEnumerable[CompletionResult]] CompleteArgument(
        [string]$CommandName, [string]$ParameterName, [string]$WordToComplete,
        [Language.CommandAst]$CommandAst, [System.Collections.IDictionary] $FakeBoundParameters
    ) {
        $result = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
        if ($wordToComplete) {
            $wordToComplete = $wordToComplete -replace '"|''', ''
            arg_gUser_Deleted_DisplayName -WordToComplete $WordToComplete |
            ForEach-Object DisplayName | Sort-Object | ForEach-Object { $result.Add([System.Management.Automation.CompletionResult]::new("'$_'", $_, ([CompletionResultType]::ParameterValue) , $_) ) }
        }
        return $result
    }
}

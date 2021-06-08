$PesterTests = Get-ChildItem -Path:($PSScriptRoot + '/*.Tests.ps1') -Recurse

$PesterResultsFileXmldir = "$PSScriptRoot/test_results/"
# $PesterResultsFileXml = $PesterResultsFileXmldir + "results.xml"
if (-not (Test-Path $PesterResultsFileXmldir))
{
    new-item -path $PesterResultsFileXmldir -ItemType Directory
}

$configuration = [PesterConfiguration]::Default
$configuration.Run.Path = "$PSScriptRoot"
$configuration.Should.ErrorAction = 'Continue'
$configuration.CodeCoverage.Enabled = $true
$configuration.testresult.Enabled = $true
$configuration.testresult.OutputFormat = 'JUnitXml'
$configuration.CodeCoverage.OutputPath = ($PesterResultsFileXmldir + 'coverage.xml')
$configuration.testresult.OutputPath = ($PesterResultsFileXmldir + 'results.xml')

Write-Host ("[RUN COMMAND] Invoke-Pester -Path:('$PSScriptRoot')"
Invoke-Pester -configuration $configuration

$PesterTestResultPath = (Get-ChildItem -Path:("$($PesterResultsFileXmldir)")).FullName | Where-Object { $_ -match "results.xml" }
If (Test-Path -Path:($PesterTestResultPath))
{
    [xml]$PesterResults = Get-Content -Path:($PesterTestResultPath)
    If ($PesterResults.ChildNodes.failures -gt 0)
    {
        Write-Error ("Test Failures: $($PesterResults.ChildNodes.failures)")
    }
    If ($PesterResults.ChildNodes.errors -gt 0)
    {
        Write-Error ("Test Errors: $($PesterResults.ChildNodes.errors)")
    }
}
Else
{
    Write-Error ("Unable to find file path: $PesterTestResultPath")
}
Write-Host -ForegroundColor Green '-------------Done-------------'
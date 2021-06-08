Describe 'Build Tests'{
    It 'Branch Version should be greater than Master' -skip {
        $templatePath = "$PSScriptRoot\..\..\AWS\template.yaml"
        $VersionRegex = [regex]'(SemanticVersion: )(.*)'
        $templateVersion = Select-String -Path:($templatePath) -Pattern:($VersionRegex)
        $templateVersion = $templateVersion.Matches.Groups[2].value
        $branchTemplateVersion = [version]$templateVersion
        $masterTemplate = (Invoke-WebRequest https://raw.githubusercontent.com/TheJumpCloud/jumpcloud-slack-app/master/AWS/template.yaml -useBasicParsing).tostring()
        $masterVersion = Select-String -inputobject:($masterTemplate) -Pattern:($VersionRegex)
        $masterVersion = $masterVersion.Matches.Groups[2].value
        $masterTemplateVersion = [version]$masterversion
        $branchTemplateVersion | Should -BeGreaterThan $masterTemplateVersion
    }
}
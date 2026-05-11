Import-Module "$PSScriptRoot\..\scripts\modules\Ingestra.Common.psm1" -Force

Describe "Get-IngestraRequiredSecretNames" {
    It "returns provision secrets for the provision profile" {
        $names = Get-IngestraRequiredSecretNames -Profile provision

        ($names -contains "AZURE_TENANT_ID") | Should -Be $true
        ($names -contains "AZURE_CLIENT_ID") | Should -Be $true
        ($names -contains "AZURE_CLIENT_SECRET") | Should -Be $true
        ($names -contains "PINECONE_API_KEY") | Should -Be $true
        ($names -contains "SUPABASE_ACCESS_TOKEN") | Should -Be $true
        ($names -contains "VERCEL_TOKEN") | Should -Be $true
    }

    It "returns smoke endpoints for the smoke profile" {
        $names = Get-IngestraRequiredSecretNames -Profile smoke

        ($names -contains "INGESTRA_UPLOAD_URL") | Should -Be $true
        ($names -contains "INGESTRA_SEARCH_URL") | Should -Be $true
        ($names -contains "INGESTRA_CHAT_URL") | Should -Be $true
    }
}

Describe "Test-IngestraSecretsPresent" {
    It "reports missing secret names" {
        [Environment]::SetEnvironmentVariable("INGESTRA_TEST_PRESENT", "ok")
        [Environment]::SetEnvironmentVariable("INGESTRA_TEST_MISSING", $null)

        $result = Test-IngestraSecretsPresent -Names @(
            "INGESTRA_TEST_PRESENT",
            "INGESTRA_TEST_MISSING"
        )

        $result.Success | Should -Be $false
        ($result.Missing -contains "INGESTRA_TEST_MISSING") | Should -Be $true
        ($result.Present -contains "INGESTRA_TEST_PRESENT") | Should -Be $true
    }
}

Describe "Get-IngestraAutomationConfigSection" {
    It "loads the supabase config section from the default automation config" {
        $section = Get-IngestraAutomationConfigSection -SectionName supabase

        $section.projectName | Should -Be "ingestra-ci"
        $section.region | Should -Be "eu-west-1"
    }
}

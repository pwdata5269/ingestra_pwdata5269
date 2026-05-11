Describe "Supabase provider script" {
    It "exists" {
        Test-Path "$PSScriptRoot\..\scripts\providers\Supabase.ps1" | Should -Be $true
    }

    It "accepts ListProjects as a supported action" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Supabase.ps1" -Raw

        $scriptContent | Should -Match '"ListProjects"'
    }

    It "accepts EnsureProject as a supported action" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Supabase.ps1" -Raw

        $scriptContent | Should -Match '"EnsureProject"'
    }

    It "accepts EnsureAzureAuthConfig as a supported action" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Supabase.ps1" -Raw

        $scriptContent | Should -Match '"EnsureAzureAuthConfig"'
    }

    It "returns null safely when no existing project matches" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Supabase.ps1" -Raw

        $scriptContent | Should -Match '\$match.Count -eq 0'
        $scriptContent | Should -Match 'return \$null'
    }

    It "patches the project auth config endpoint for Azure auth" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Supabase.ps1" -Raw

        $scriptContent | Should -Match '/config/auth'
        $scriptContent | Should -Match 'external_azure_enabled'
        $scriptContent | Should -Match 'external_azure_client_id'
        $scriptContent | Should -Match 'external_azure_secret'
        $scriptContent | Should -Match 'external_azure_url'
    }
}

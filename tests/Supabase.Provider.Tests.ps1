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

    It "accepts EnsureSchema as a supported action" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Supabase.ps1" -Raw

        $scriptContent | Should -Match '"EnsureSchema"'
    }

    It "accepts EnsureAzureAuthConfig as a supported action" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Supabase.ps1" -Raw

        $scriptContent | Should -Match '"EnsureAzureAuthConfig"'
    }

    It "accepts EnsureBrowserAuthConfig as a supported action" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Supabase.ps1" -Raw

        $scriptContent | Should -Match '"EnsureBrowserAuthConfig"'
    }

    It "accepts GetPublicClientConfig as a supported action" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Supabase.ps1" -Raw

        $scriptContent | Should -Match '"GetPublicClientConfig"'
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

    It "patches browser auth config with site url and redirect allow list" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Supabase.ps1" -Raw

        $scriptContent | Should -Match 'site_url'
        $scriptContent | Should -Match 'uri_allow_list'
        $scriptContent | Should -Match 'EnsureBrowserAuthConfig'
    }

    It "resolves a public client key from the project API keys endpoint" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Supabase.ps1" -Raw

        $scriptContent | Should -Match '/api-keys\?reveal=true'
        $scriptContent | Should -Match 'supabase_public_key'
    }

    It "applies checked-in Supabase migrations through the Supabase CLI" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Supabase.ps1" -Raw

        $scriptContent | Should -Match 'supabase\\migrations'
        $scriptContent | Should -Match 'function Get-PsqlCommand'
        $scriptContent | Should -Match 'psql is required for EnsureSchema'
        $scriptContent | Should -Match 'function Invoke-PostgresSqlFile'
        $scriptContent | Should -Match '"--dbname=\$DbUrl"'
        $scriptContent | Should -Match '"-v" "ON_ERROR_STOP=1"'
        $scriptContent | Should -Match 'foreach \(\$migrationFile in \$migrationFiles\)'
        $scriptContent | Should -Match 'SUPABASE_DB_URL is required for EnsureSchema'
        $scriptContent | Should -Match 'RLS: enabled in checked-in migrations'
    }
}

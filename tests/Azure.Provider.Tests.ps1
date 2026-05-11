Describe "Azure provider script" {
    It "exists" {
        Test-Path "$PSScriptRoot\..\scripts\providers\Azure.ps1" | Should -Be $true
    }

    It "accepts EnsureSupabaseLoginApp as a supported action" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Azure.ps1" -Raw

        $scriptContent | Should -Match '"EnsureSupabaseLoginApp"'
    }

    It "builds the Supabase redirect URI from project ref" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Azure.ps1" -Raw

        $scriptContent | Should -Match 'https://\$projectRef\.supabase\.co/auth/v1/callback'
    }

    It "creates a fresh client secret for both created and existing app paths" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Azure.ps1" -Raw

        $scriptContent | Should -Match 'New-AzureApplicationPassword -ApplicationObjectId \(\[string\]\$existing.id\)'
        $scriptContent | Should -Match 'New-AzureApplicationPassword -ApplicationObjectId \(\[string\]\$created.id\)'
        $scriptContent | Should -Match 'Set-IngestraOutput -Name "supabase_login_client_secret" -Value \$secretText'
    }
}

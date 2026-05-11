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
}

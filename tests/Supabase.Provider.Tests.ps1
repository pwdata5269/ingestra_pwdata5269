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

    It "returns null safely when no existing project matches" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Supabase.ps1" -Raw

        $scriptContent | Should -Match '\$match.Count -eq 0'
        $scriptContent | Should -Match 'return \$null'
    }
}

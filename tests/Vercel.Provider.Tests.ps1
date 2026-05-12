Describe "Vercel provider script" {
    It "exists" {
        Test-Path "$PSScriptRoot\..\scripts\providers\Vercel.ps1" | Should -Be $true
    }

    It "accepts EnsureProject as a supported action" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Vercel.ps1" -Raw

        $scriptContent | Should -Match '"EnsureProject"'
    }

    It "accepts UpsertEnvironmentVariables as a supported action" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Vercel.ps1" -Raw

        $scriptContent | Should -Match '"UpsertEnvironmentVariables"'
    }

    It "creates projects through the Vercel projects API" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Vercel.ps1" -Raw

        $scriptContent | Should -Match '/v11/projects'
    }

    It "upserts environment variables through the Vercel env API" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Vercel.ps1" -Raw

        $scriptContent | Should -Match '/v10/projects/\$resolvedProjectName/env'
        $scriptContent | Should -Match 'upsert = "true"'
    }
}

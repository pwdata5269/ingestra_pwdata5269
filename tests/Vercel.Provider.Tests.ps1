Describe "Vercel provider script" {
    It "exists" {
        Test-Path "$PSScriptRoot\..\scripts\providers\Vercel.ps1" | Should -Be $true
    }

    It "accepts EnsureProject as a supported action" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Vercel.ps1" -Raw

        $scriptContent | Should -Match '"EnsureProject"'
    }

    It "accepts EnsureProjectLink as a supported action" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Vercel.ps1" -Raw

        $scriptContent | Should -Match '"EnsureProjectLink"'
    }

    It "accepts UpsertEnvironmentVariables as a supported action" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Vercel.ps1" -Raw

        $scriptContent | Should -Match '"UpsertEnvironmentVariables"'
    }

    It "creates projects through the Vercel projects API" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Vercel.ps1" -Raw

        $scriptContent | Should -Match '/v11/projects'
    }

    It "updates project link and production branch through the Vercel project API" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Vercel.ps1" -Raw

        $scriptContent | Should -Match '/v9/projects/\$resolvedProjectName'
        $scriptContent | Should -Match 'gitRepository'
        $scriptContent | Should -Match 'productionBranch'
        $scriptContent | Should -Match 'repo'
        $scriptContent | Should -Match 'type'
    }

    It "handles projects that do not yet expose a link property" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Vercel.ps1" -Raw

        $scriptContent | Should -Match 'function Get-VercelProjectLink'
        $scriptContent | Should -Match '\$Project\.PSObject\.Properties\["link"\]'
    }

    It "upserts environment variables through the Vercel env API" {
        $scriptContent = Get-Content "$PSScriptRoot\..\scripts\providers\Vercel.ps1" -Raw

        $scriptContent | Should -Match '/v10/projects/\$resolvedProjectName/env'
        $scriptContent | Should -Match 'upsert = "true"'
    }
}

Describe "Frontend auth harness" {
    It "loads a generated runtime config before the app module" {
        $indexContent = Get-Content "$PSScriptRoot\..\index.html" -Raw

        $indexContent | Should -Match '<script src="/runtime-config\.js"></script>'
        $indexContent | Should -Match '<script type="module" src="/app\.js"></script>'
    }

    It "reads Supabase values from the generated runtime config" {
        $appContent = Get-Content "$PSScriptRoot\..\app.js" -Raw

        $appContent | Should -Match 'window\.INGESTRA_RUNTIME_CONFIG'
        $appContent | Should -Match 'SUPABASE_URL and SUPABASE_PUBLIC_KEY must be present in runtime-config\.js'
    }
}

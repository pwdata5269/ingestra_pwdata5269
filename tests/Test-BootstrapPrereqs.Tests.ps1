Describe "Test-BootstrapPrereqs script" {
    It "exists" {
        Test-Path "$PSScriptRoot\..\scripts\Test-BootstrapPrereqs.ps1" | Should Be $true
    }

    It "can validate the minimal profile with no required secrets" {
        { & "$PSScriptRoot\..\scripts\Test-BootstrapPrereqs.ps1" -Profile minimal } | Should Not Throw
    }
}

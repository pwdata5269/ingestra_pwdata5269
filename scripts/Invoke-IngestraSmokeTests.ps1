[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\modules\Ingestra.Common.psm1" -Force

$requiredNames = Get-IngestraRequiredSecretNames -Profile smoke
$result = Test-IngestraSecretsPresent -Names $requiredNames
if (-not $result.Success) {
    throw "Missing smoke-test endpoints: $($result.Missing -join ', ')"
}

$checks = @(
    @{ Name = "Upload"; Url = [Environment]::GetEnvironmentVariable("INGESTRA_UPLOAD_URL") }
    @{ Name = "Search"; Url = [Environment]::GetEnvironmentVariable("INGESTRA_SEARCH_URL") }
    @{ Name = "Chat"; Url = [Environment]::GetEnvironmentVariable("INGESTRA_CHAT_URL") }
)

$summaryLines = @(
    "## Smoke Tests"
)

foreach ($check in $checks) {
    try {
        Invoke-WebRequest -Uri $check.Url -Method Options -ErrorAction Stop | Out-Null
        Write-Host "$($check.Name) endpoint reachable: $($check.Url)"
        $summaryLines += "- $($check.Name): pass"
    }
    catch {
        Write-Error "$($check.Name) endpoint failed: $($check.Url)"
        $summaryLines += "- $($check.Name): fail"
        Write-IngestraSummary -Lines $summaryLines
        throw
    }
}

Write-IngestraSummary -Lines $summaryLines

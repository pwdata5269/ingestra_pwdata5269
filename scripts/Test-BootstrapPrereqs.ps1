[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("minimal", "provision", "supabase-schema", "smoke")]
    [string]$Profile = "minimal"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\modules\Ingestra.Common.psm1" -Force

$requiredNames = @(Get-IngestraRequiredSecretNames -Profile $Profile)
$result = if ($requiredNames.Count -eq 0) {
    [pscustomobject]@{
        Missing = @()
        Present = @()
        Success = $true
    }
}
else {
    Test-IngestraSecretsPresent -Names $requiredNames
}

Write-Host "Bootstrap profile: $Profile"
Write-Host "Required secret count: $($requiredNames.Count)"

if ($result.Success) {
    Write-Host "All required secrets are present."
    Write-IngestraSummary -Lines @(
        "## Bootstrap Validation",
        ("- Profile: {0}" -f $Profile),
        "- Result: pass",
        ("- Required secrets: {0}" -f $requiredNames.Count)
    )
    return
}

$missingList = $result.Missing | ForEach-Object { "- {0}" -f $_ }
Write-Error ("Missing required secrets for profile '{0}': {1}" -f $Profile, ($result.Missing -join ", "))
Write-IngestraSummary -Lines @(
    "## Bootstrap Validation",
    ("- Profile: {0}" -f $Profile),
    "- Result: fail",
    "- Missing secrets:"
) + $missingList

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("ListOrganizations", "CreateProject")]
    [string]$Action,

    [Parameter()]
    [string]$ProjectName,

    [Parameter()]
    [string]$Region = "eu-west-1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\..\modules\Ingestra.Common.psm1" -Force

$token = [Environment]::GetEnvironmentVariable("SUPABASE_ACCESS_TOKEN")
if ([string]::IsNullOrWhiteSpace($token)) {
    throw "SUPABASE_ACCESS_TOKEN is required."
}

$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/json"
    "User-Agent"  = "ingestra-cicd/1.0"
}

$baseUri = "https://api.supabase.com/v1"

switch ($Action) {
    "ListOrganizations" {
        Invoke-IngestraApiRequest -Method GET -Uri "$baseUri/organizations" -Headers $headers | ConvertTo-Json -Depth 10
        break
    }

    "CreateProject" {
        if ([string]::IsNullOrWhiteSpace($ProjectName)) {
            throw "ProjectName is required for CreateProject."
        }

        $orgSlug = [Environment]::GetEnvironmentVariable("SUPABASE_ORG_SLUG")
        $dbPassword = [Environment]::GetEnvironmentVariable("SUPABASE_DB_PASSWORD")

        if ([string]::IsNullOrWhiteSpace($orgSlug)) {
            throw "SUPABASE_ORG_SLUG is required."
        }

        if ([string]::IsNullOrWhiteSpace($dbPassword)) {
            throw "SUPABASE_DB_PASSWORD is required."
        }

        $body = @{
            name              = $ProjectName
            organization_slug = $orgSlug
            db_pass           = $dbPassword
            region            = $Region
        }

        Invoke-IngestraApiRequest -Method POST -Uri "$baseUri/projects" -Headers $headers -Body $body | ConvertTo-Json -Depth 10
        break
    }
}

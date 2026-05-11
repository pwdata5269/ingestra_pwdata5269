[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("ListOrganizations", "ListProjects", "CreateProject", "EnsureProject")]
    [string]$Action,

    [Parameter()]
    [string]$ProjectName,

    [Parameter()]
    [string]$Region,

    [Parameter()]
    [string]$ConfigPath
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

function Get-SupabaseConfigValue {
    param(
        [Parameter(Mandatory)]
        [string]$PropertyName
    )

    if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
        return $null
    }

    $section = Get-IngestraAutomationConfigSection -SectionName "supabase" -Path $ConfigPath
    $property = $section.PSObject.Properties[$PropertyName]
    if ($null -eq $property) {
        return $null
    }

    return [string]$property.Value
}

function Resolve-SupabaseProjectInputs {
    $resolvedProjectName = $ProjectName
    $resolvedRegion = $Region

    if ([string]::IsNullOrWhiteSpace($resolvedProjectName)) {
        $resolvedProjectName = Get-SupabaseConfigValue -PropertyName "projectName"
    }

    if ([string]::IsNullOrWhiteSpace($resolvedRegion)) {
        $resolvedRegion = Get-SupabaseConfigValue -PropertyName "region"
    }

    if ([string]::IsNullOrWhiteSpace($resolvedProjectName)) {
        throw "ProjectName is required for $Action."
    }

    if ([string]::IsNullOrWhiteSpace($resolvedRegion)) {
        throw "Region is required for $Action."
    }

    [pscustomobject]@{
        ProjectName = $resolvedProjectName
        Region      = $resolvedRegion
    }
}

function Get-SupabaseProjectByName {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $projects = Invoke-IngestraApiRequest -Method GET -Uri "$baseUri/projects" -Headers $headers
    return @($projects | Where-Object { $_.name -eq $Name } | Select-Object -First 1)[0]
}

switch ($Action) {
    "ListOrganizations" {
        $organizations = Invoke-IngestraApiRequest -Method GET -Uri "$baseUri/organizations" -Headers $headers
        Write-IngestraSummary -Lines @(
            "## Supabase",
            "- Action: list organizations",
            ("- Organization count: {0}" -f @($organizations).Count)
        )
        $organizations | ConvertTo-Json -Depth 10
        break
    }

    "ListProjects" {
        $projects = Invoke-IngestraApiRequest -Method GET -Uri "$baseUri/projects" -Headers $headers
        Write-IngestraSummary -Lines @(
            "## Supabase",
            "- Action: list projects",
            ("- Project count: {0}" -f @($projects).Count)
        )
        $projects | ConvertTo-Json -Depth 10
        break
    }

    "CreateProject" {
        $resolved = Resolve-SupabaseProjectInputs

        $orgSlug = [Environment]::GetEnvironmentVariable("SUPABASE_ORG_SLUG")
        $dbPassword = [Environment]::GetEnvironmentVariable("SUPABASE_DB_PASSWORD")

        if ([string]::IsNullOrWhiteSpace($orgSlug)) {
            throw "SUPABASE_ORG_SLUG is required."
        }

        if ([string]::IsNullOrWhiteSpace($dbPassword)) {
            throw "SUPABASE_DB_PASSWORD is required."
        }

        $body = @{
            name              = $resolved.ProjectName
            organization_slug = $orgSlug
            db_pass           = $dbPassword
            region            = $resolved.Region
        }

        $createdProject = Invoke-IngestraApiRequest -Method POST -Uri "$baseUri/projects" -Headers $headers -Body $body
        Write-IngestraSummary -Lines @(
            "## Supabase",
            "- Action: create project",
            ("- Result: created"),
            ("- Project name: {0}" -f $resolved.ProjectName),
            ("- Region: {0}" -f $resolved.Region),
            ("- Project ref: {0}" -f $createdProject.ref)
        )
        $createdProject | ConvertTo-Json -Depth 10
        break
    }

    "EnsureProject" {
        $resolved = Resolve-SupabaseProjectInputs
        $existing = Get-SupabaseProjectByName -Name $resolved.ProjectName

        if ($null -ne $existing) {
            Write-Host "Supabase project '$($resolved.ProjectName)' already exists."
            Write-IngestraSummary -Lines @(
                "## Supabase",
                "- Action: ensure project",
                "- Result: already exists",
                ("- Project name: {0}" -f $resolved.ProjectName),
                ("- Region: {0}" -f $existing.region),
                ("- Project ref: {0}" -f $existing.ref)
            )
            $existing | ConvertTo-Json -Depth 10
            break
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
            name              = $resolved.ProjectName
            organization_slug = $orgSlug
            db_pass           = $dbPassword
            region            = $resolved.Region
        }

        $createdProject = Invoke-IngestraApiRequest -Method POST -Uri "$baseUri/projects" -Headers $headers -Body $body
        Write-IngestraSummary -Lines @(
            "## Supabase",
            "- Action: ensure project",
            "- Result: created",
            ("- Project name: {0}" -f $resolved.ProjectName),
            ("- Region: {0}" -f $resolved.Region),
            ("- Project ref: {0}" -f $createdProject.ref)
        )
        $createdProject | ConvertTo-Json -Depth 10
        break
    }
}

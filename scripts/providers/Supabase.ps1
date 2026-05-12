[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("ListOrganizations", "ListProjects", "CreateProject", "EnsureProject", "EnsureSchema", "EnsureAzureAuthConfig", "EnsureBrowserAuthConfig", "GetPublicClientConfig")]
    [string]$Action,

    [Parameter()]
    [string]$ProjectName,

    [Parameter()]
    [string]$Region,

    [Parameter()]
    [string]$ProjectRef,

    [Parameter()]
    [string]$AzureClientId,

    [Parameter()]
    [string]$AzureClientSecret,

    [Parameter()]
    [string]$SiteUrl,

    [Parameter()]
    [string]$RedirectUrlAllowList,

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
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))

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

function Get-FrontendConfigValue {
    param(
        [Parameter(Mandatory)]
        [string]$PropertyName
    )

    if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
        return $null
    }

    $section = Get-IngestraAutomationConfigSection -SectionName "frontend" -Path $ConfigPath
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
    $match = @($projects | Where-Object { $_.name -eq $Name } | Select-Object -First 1)
    if ($match.Count -eq 0) {
        return $null
    }

    return $match[0]
}

function Resolve-SupabaseProjectRef {
    if (-not [string]::IsNullOrWhiteSpace($ProjectRef)) {
        return $ProjectRef
    }

    $resolved = Resolve-SupabaseProjectInputs
    $project = Get-SupabaseProjectByName -Name $resolved.ProjectName
    if ($null -eq $project) {
        throw "Supabase project '$($resolved.ProjectName)' was not found."
    }

    return [string]$project.ref
}

function Get-SupabaseProjectUrl {
    param(
        [Parameter(Mandatory)]
        [string]$Ref
    )

    return "https://$Ref.supabase.co"
}

function Get-SupabaseProjectDetails {
    param(
        [Parameter(Mandatory)]
        [string]$Ref
    )

    return (Invoke-IngestraApiRequest -Method GET -Uri "$baseUri/projects/$Ref" -Headers $headers)
}

function Get-SupabasePublicClientKey {
    param(
        [Parameter(Mandatory)]
        [string]$Ref
    )

    $keys = Invoke-IngestraApiRequest -Method GET -Uri "$baseUri/projects/$Ref/api-keys?reveal=true" -Headers $headers
    $preferred = @(
        $keys | Where-Object { $_.name -match 'publishable' } | Select-Object -First 1
        $keys | Where-Object { $_.name -match 'anon' } | Select-Object -First 1
    ) | Where-Object { $null -ne $_ } | Select-Object -First 1

    if ($null -eq $preferred) {
        throw "No publishable or anon key was returned for Supabase project '$Ref'."
    }

    return [string]$preferred.api_key
}

function Resolve-BrowserAuthConfig {
    $resolvedSiteUrl = $SiteUrl
    $resolvedRedirectUrlAllowList = $RedirectUrlAllowList

    if ([string]::IsNullOrWhiteSpace($resolvedSiteUrl)) {
        throw "SiteUrl is required for EnsureBrowserAuthConfig."
    }

    if ([string]::IsNullOrWhiteSpace($resolvedRedirectUrlAllowList)) {
        $localDevelopmentUrl = Get-FrontendConfigValue -PropertyName "localDevelopmentUrl"
        if ([string]::IsNullOrWhiteSpace($localDevelopmentUrl)) {
            $localDevelopmentUrl = "http://localhost:3000"
        }

        $resolvedRedirectUrlAllowList = ($localDevelopmentUrl.TrimEnd("/") + "/**")
    }

    [pscustomobject]@{
        SiteUrl              = $resolvedSiteUrl
        RedirectUrlAllowList = $resolvedRedirectUrlAllowList
    }
}

function Get-SupabaseMigrationFilePaths {
    $migrationsPath = Join-Path $repoRoot "supabase\migrations"
    if (-not (Test-Path -LiteralPath $migrationsPath)) {
        throw "Supabase migrations directory not found: $migrationsPath"
    }

    $files = Get-ChildItem -LiteralPath $migrationsPath -Filter *.sql | Sort-Object Name
    if (@($files).Count -eq 0) {
        throw "No Supabase migration files were found in $migrationsPath"
    }

    return @($files)
}

function Get-SupabaseDbUrl {
    param(
        [Parameter(Mandatory)]
        [string]$Ref
    )

    $dbPassword = [Environment]::GetEnvironmentVariable("SUPABASE_DB_PASSWORD")
    if ([string]::IsNullOrWhiteSpace($dbPassword)) {
        throw "SUPABASE_DB_PASSWORD is required."
    }

    $project = Get-SupabaseProjectDetails -Ref $Ref
    $host = [string]$project.database.host
    if ([string]::IsNullOrWhiteSpace($host)) {
        throw "Supabase database host was not returned for project '$Ref'."
    }

    $encodedPassword = [System.Uri]::EscapeDataString($dbPassword)
    return "postgresql://postgres:$encodedPassword@$host:5432/postgres"
}

function Invoke-SupabaseCliCommand {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $output = & npx "supabase@latest" @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    if ($output) {
        $output | ForEach-Object { Write-Host $_ }
    }

    if ($exitCode -ne 0) {
        throw "Supabase CLI command failed with exit code $exitCode."
    }

    return ($output | Out-String)
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
        Set-IngestraOutput -Name "supabase_project_ref" -Value ([string]$createdProject.ref)
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
            Set-IngestraOutput -Name "supabase_project_ref" -Value ([string]$existing.ref)
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
        Set-IngestraOutput -Name "supabase_project_ref" -Value ([string]$createdProject.ref)
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

    "EnsureSchema" {
        $resolvedProjectRef = Resolve-SupabaseProjectRef
        $dbUrl = Get-SupabaseDbUrl -Ref $resolvedProjectRef
        $migrationFiles = @(Get-SupabaseMigrationFilePaths)

        Invoke-SupabaseCliCommand -Arguments @("db", "push", "--db-url", $dbUrl, "--include-all")

        Write-IngestraSummary -Lines @(
            "## Supabase Schema",
            "- Action: ensure schema",
            "- Result: applied",
            ("- Project ref: {0}" -f $resolvedProjectRef),
            ("- Migration count: {0}" -f $migrationFiles.Count),
            ("- Schema: public"),
            "- RLS: enabled in checked-in migrations"
        )
        Set-IngestraOutput -Name "supabase_project_ref" -Value $resolvedProjectRef
        [pscustomobject]@{
            project_ref     = $resolvedProjectRef
            migration_count = $migrationFiles.Count
            schema          = "public"
        } | ConvertTo-Json -Depth 10
        break
    }

    "EnsureAzureAuthConfig" {
        $resolvedProjectRef = Resolve-SupabaseProjectRef

        if ([string]::IsNullOrWhiteSpace($AzureClientId)) {
            throw "AzureClientId is required for EnsureAzureAuthConfig."
        }

        if ([string]::IsNullOrWhiteSpace($AzureClientSecret)) {
            throw "AzureClientSecret is required for EnsureAzureAuthConfig."
        }

        $tenantId = [Environment]::GetEnvironmentVariable("AZURE_TENANT_ID")
        if ([string]::IsNullOrWhiteSpace($tenantId)) {
            throw "AZURE_TENANT_ID is required."
        }

        $azureUrl = "https://login.microsoftonline.com/$tenantId"
        $body = @{
            external_azure_enabled   = $true
            external_azure_client_id = $AzureClientId
            external_azure_secret    = $AzureClientSecret
            external_azure_url       = $azureUrl
        }

        $configured = Invoke-IngestraApiRequest -Method PATCH -Uri "$baseUri/projects/$resolvedProjectRef/config/auth" -Headers $headers -Body $body
        Write-IngestraSummary -Lines @(
            "## Supabase Auth",
            "- Action: ensure Azure auth config",
            "- Result: configured",
            ("- Project ref: {0}" -f $resolvedProjectRef),
            ("- Azure client ID: {0}" -f $AzureClientId),
            ("- Azure URL: {0}" -f $azureUrl)
        )
        Set-IngestraOutput -Name "supabase_project_ref" -Value $resolvedProjectRef
        $configured | ConvertTo-Json -Depth 10
        break
    }

    "EnsureBrowserAuthConfig" {
        $resolvedProjectRef = Resolve-SupabaseProjectRef
        $resolvedBrowserAuthConfig = Resolve-BrowserAuthConfig

        $body = @{
            site_url       = $resolvedBrowserAuthConfig.SiteUrl
            uri_allow_list = $resolvedBrowserAuthConfig.RedirectUrlAllowList
        }

        $configured = Invoke-IngestraApiRequest -Method PATCH -Uri "$baseUri/projects/$resolvedProjectRef/config/auth" -Headers $headers -Body $body
        Write-IngestraSummary -Lines @(
            "## Supabase Auth",
            "- Action: ensure browser auth config",
            "- Result: configured",
            ("- Project ref: {0}" -f $resolvedProjectRef),
            ("- Site URL: {0}" -f $resolvedBrowserAuthConfig.SiteUrl),
            ("- Redirect allow list: {0}" -f $resolvedBrowserAuthConfig.RedirectUrlAllowList)
        )
        Set-IngestraOutput -Name "supabase_project_ref" -Value $resolvedProjectRef
        Set-IngestraOutput -Name "supabase_site_url" -Value $resolvedBrowserAuthConfig.SiteUrl
        Set-IngestraOutput -Name "supabase_redirect_url_allow_list" -Value $resolvedBrowserAuthConfig.RedirectUrlAllowList
        $configured | ConvertTo-Json -Depth 10
        break
    }

    "GetPublicClientConfig" {
        $resolvedProjectRef = Resolve-SupabaseProjectRef
        $supabaseUrl = Get-SupabaseProjectUrl -Ref $resolvedProjectRef
        $supabasePublicKey = Get-SupabasePublicClientKey -Ref $resolvedProjectRef

        Add-IngestraMask -Value $supabasePublicKey
        Set-IngestraOutput -Name "supabase_project_ref" -Value $resolvedProjectRef
        Set-IngestraOutput -Name "supabase_url" -Value $supabaseUrl
        Set-IngestraOutput -Name "supabase_public_key" -Value $supabasePublicKey
        Write-IngestraSummary -Lines @(
            "## Supabase Frontend Config",
            "- Action: get public client config",
            "- Result: resolved",
            ("- Project ref: {0}" -f $resolvedProjectRef),
            ("- Supabase URL: {0}" -f $supabaseUrl)
        )

        [pscustomobject]@{
            project_ref         = $resolvedProjectRef
            supabase_url        = $supabaseUrl
            supabase_public_key = $supabasePublicKey
        } | ConvertTo-Json -Depth 10
        break
    }
}

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("ListProjects", "EnsureProject", "EnsureProjectLink", "UpsertEnvironmentVariables")]
    [string]$Action,

    [Parameter()]
    [string]$ProjectName,

    [Parameter()]
    [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\..\modules\Ingestra.Common.psm1" -Force

$token = [Environment]::GetEnvironmentVariable("VERCEL_TOKEN")
if ([string]::IsNullOrWhiteSpace($token)) {
    throw "VERCEL_TOKEN is required."
}

$baseUri = "https://api.vercel.com"
$teamId = [Environment]::GetEnvironmentVariable("VERCEL_TEAM_ID")

function Get-VercelConfigValue {
    param(
        [Parameter(Mandatory)]
        [string]$PropertyName
    )

    if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
        return $null
    }

    $section = Get-IngestraAutomationConfigSection -SectionName "vercel" -Path $ConfigPath
    $property = $section.PSObject.Properties[$PropertyName]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Get-VercelApiUri {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [hashtable]$Query
    )

    $builder = [System.UriBuilder]::new("$baseUri$Path")
    $parts = [System.Collections.Generic.List[string]]::new()

    if (-not [string]::IsNullOrWhiteSpace($teamId)) {
        $parts.Add(("teamId={0}" -f [System.Uri]::EscapeDataString($teamId)))
    }

    if ($Query) {
        foreach ($entry in $Query.GetEnumerator()) {
            if (-not [string]::IsNullOrWhiteSpace([string]$entry.Value)) {
                $parts.Add(("{0}={1}" -f [System.Uri]::EscapeDataString([string]$entry.Key), [System.Uri]::EscapeDataString([string]$entry.Value)))
            }
        }
    }

    if ($parts.Count -gt 0) {
        $builder.Query = ($parts -join "&")
    }

    return $builder.Uri.AbsoluteUri
}

function Invoke-VercelApiRequest {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("GET", "POST", "PATCH")]
        [string]$Method,

        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter()]
        $Body
    )

    $headers = @{
        Authorization = "Bearer $token"
        Accept        = "application/json"
    }

    $params = @{
        Method      = $Method
        Uri         = $Uri
        Headers     = $headers
        ErrorAction = "Stop"
    }

    if ($null -ne $Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 20)
        $params.ContentType = "application/json"
    }

    Invoke-RestMethod @params
}

function Invoke-VercelCliCommand {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [Parameter()]
        [hashtable]$EnvironmentVariables
    )

    $savedValues = @{}

    if ($EnvironmentVariables) {
        foreach ($entry in $EnvironmentVariables.GetEnumerator()) {
            $savedValues[$entry.Key] = [Environment]::GetEnvironmentVariable($entry.Key)
            [Environment]::SetEnvironmentVariable($entry.Key, [string]$entry.Value)
        }
    }

    try {
        $output = & npx "vercel@latest" @Arguments 2>&1
        $exitCode = $LASTEXITCODE
        $outputText = ($output | Out-String)
        if ($output) {
            $output | ForEach-Object { Write-Host $_ }
        }

        if ($exitCode -ne 0 -and $outputText -notmatch 'already connected to your project') {
            throw "Vercel CLI command failed with exit code $exitCode."
        }

        return $outputText
    }
    finally {
        if ($EnvironmentVariables) {
            foreach ($entry in $EnvironmentVariables.GetEnumerator()) {
                [Environment]::SetEnvironmentVariable($entry.Key, $savedValues[$entry.Key])
            }
        }
    }
}

function Resolve-VercelProjectName {
    $resolvedProjectName = $ProjectName

    if ([string]::IsNullOrWhiteSpace($resolvedProjectName)) {
        $resolvedProjectName = [string](Get-VercelConfigValue -PropertyName "projectName")
    }

    if ([string]::IsNullOrWhiteSpace($resolvedProjectName)) {
        throw "ProjectName is required for $Action."
    }

    return $resolvedProjectName
}

function Get-GitHubRepositoryFromOrigin {
    $remote = git remote get-url origin 2>$null
    if ([string]::IsNullOrWhiteSpace($remote)) {
        return $null
    }

    if ($remote -match 'github\.com[:/](?<owner>[^/]+)/(?<repo>[^/.]+)(?:\.git)?$') {
        return "{0}/{1}" -f $Matches.owner, $Matches.repo
    }

    return $null
}

function Resolve-VercelRepositoryLinkInputs {
    $gitProvider = [string](Get-VercelConfigValue -PropertyName "gitProvider")
    $repo = [string](Get-VercelConfigValue -PropertyName "repo")
    $productionBranch = [string](Get-VercelConfigValue -PropertyName "productionBranch")

    if ([string]::IsNullOrWhiteSpace($gitProvider)) {
        $gitProvider = "github"
    }

    if ([string]::IsNullOrWhiteSpace($repo)) {
        $repo = Get-GitHubRepositoryFromOrigin
    }

    if ([string]::IsNullOrWhiteSpace($productionBranch)) {
        $productionBranch = "main"
    }

    if ([string]::IsNullOrWhiteSpace($repo)) {
        throw "vercel.repo is required in config or must be derivable from the origin remote."
    }

    [pscustomobject]@{
        GitProvider      = $gitProvider
        Repo             = $repo
        ProductionBranch = $productionBranch
    }
}

function Get-VercelProjects {
    $uri = Get-VercelApiUri -Path "/v10/projects"
    $response = Invoke-VercelApiRequest -Method GET -Uri $uri

    if ($response -is [System.Array]) {
        return @($response)
    }

    if ($null -ne $response.projects) {
        return @($response.projects)
    }

    return @($response)
}

function Get-VercelProjectByName {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $projects = Get-VercelProjects
    $match = @($projects | Where-Object { $_.name -eq $Name } | Select-Object -First 1)
    if ($match.Count -eq 0) {
        return $null
    }

    return $match[0]
}

function Get-VercelProjectLink {
    param(
        [Parameter(Mandatory)]
        $Project
    )

    $property = $Project.PSObject.Properties["link"]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

switch ($Action) {
    "ListProjects" {
        $projects = Get-VercelProjects
        Write-IngestraSummary -Lines @(
            "## Vercel",
            "- Action: list projects",
            ("- Project count: {0}" -f @($projects).Count)
        )
        $projects | ConvertTo-Json -Depth 10
        break
    }

    "EnsureProject" {
        $resolvedProjectName = Resolve-VercelProjectName
        $existing = Get-VercelProjectByName -Name $resolvedProjectName

        if ($null -ne $existing) {
            Write-Host "Vercel project '$resolvedProjectName' already exists."
            Write-IngestraSummary -Lines @(
                "## Vercel",
                "- Action: ensure project",
                "- Result: already exists",
                ("- Project name: {0}" -f $resolvedProjectName),
                ("- Project ID: {0}" -f $existing.id)
            )
            Set-IngestraOutput -Name "vercel_project_id" -Value ([string]$existing.id)
            Set-IngestraOutput -Name "vercel_project_name" -Value ([string]$existing.name)
            $existing | ConvertTo-Json -Depth 10
            break
        }

        $body = @{
            name = $resolvedProjectName
        }

        $uri = Get-VercelApiUri -Path "/v11/projects"
        $created = Invoke-VercelApiRequest -Method POST -Uri $uri -Body $body
        Write-IngestraSummary -Lines @(
            "## Vercel",
            "- Action: ensure project",
            "- Result: created",
            ("- Project name: {0}" -f $resolvedProjectName),
            ("- Project ID: {0}" -f $created.id)
        )
        Set-IngestraOutput -Name "vercel_project_id" -Value ([string]$created.id)
        Set-IngestraOutput -Name "vercel_project_name" -Value ([string]$created.name)
        $created | ConvertTo-Json -Depth 10
        break
    }

    "EnsureProjectLink" {
        $resolvedProjectName = Resolve-VercelProjectName
        $linkInputs = Resolve-VercelRepositoryLinkInputs
        $project = Get-VercelProjectByName -Name $resolvedProjectName

        if ($null -eq $project) {
            throw "Vercel project '$resolvedProjectName' was not found."
        }

        $currentLink = Get-VercelProjectLink -Project $project
        $isLinked = (
            $null -ne $currentLink -and
            [string]$currentLink.type -eq $linkInputs.GitProvider -and
            [string]$currentLink.repo -eq $linkInputs.Repo -and
            [string]$currentLink.productionBranch -eq $linkInputs.ProductionBranch
        )

        if ($isLinked) {
            Write-Host "Vercel project '$resolvedProjectName' is already linked to '$($linkInputs.Repo)'."
            Write-IngestraSummary -Lines @(
                "## Vercel",
                "- Action: ensure project link",
                "- Result: already linked",
                ("- Project name: {0}" -f $resolvedProjectName),
                ("- Repo: {0}" -f $linkInputs.Repo),
                ("- Production branch: {0}" -f $linkInputs.ProductionBranch)
            )
            $project | ConvertTo-Json -Depth 10
            break
        }

        $cliEnvironment = @{
            VERCEL_PROJECT_ID = [string]$project.id
            VERCEL_ORG_ID     = if (-not [string]::IsNullOrWhiteSpace($teamId)) { $teamId } else { [string]$project.accountId }
        }

        $cliOutput = Invoke-VercelCliCommand -Arguments @("git", "connect", "--yes", "--token", $token) -EnvironmentVariables $cliEnvironment

        $updated = Get-VercelProjectByName -Name $resolvedProjectName
        $result = if ($cliOutput -match 'already connected to your project') { 'already linked' } else { 'linked' }
        Write-IngestraSummary -Lines @(
            "## Vercel",
            "- Action: ensure project link",
            ("- Result: {0}" -f $result),
            ("- Project name: {0}" -f $resolvedProjectName),
            ("- Repo: {0}" -f $linkInputs.Repo),
            ("- Production branch: {0}" -f $linkInputs.ProductionBranch)
        )
        $updated | ConvertTo-Json -Depth 10
        break
    }

    "UpsertEnvironmentVariables" {
        $resolvedProjectName = Resolve-VercelProjectName
        $vars = @()

        $supabaseUrl = [Environment]::GetEnvironmentVariable("SUPABASE_URL")
        $supabaseAnonKey = [Environment]::GetEnvironmentVariable("SUPABASE_ANON_KEY")

        if (-not [string]::IsNullOrWhiteSpace($supabaseUrl)) {
            $vars += @{
                key = "SUPABASE_URL"
                value = $supabaseUrl
                target = @("production", "preview", "development")
                type = "plain"
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($supabaseAnonKey)) {
            $vars += @{
                key = "SUPABASE_ANON_KEY"
                value = $supabaseAnonKey
                target = @("production", "preview", "development")
                type = "encrypted"
            }
        }

        if ($vars.Count -eq 0) {
            throw "No Vercel environment variables were available to upsert."
        }

        $uri = Get-VercelApiUri -Path "/v10/projects/$resolvedProjectName/env" -Query @{ upsert = "true" }
        $result = Invoke-VercelApiRequest -Method POST -Uri $uri -Body $vars
        Write-IngestraSummary -Lines @(
            "## Vercel",
            "- Action: upsert environment variables",
            ("- Project name: {0}" -f $resolvedProjectName),
            ("- Variable count: {0}" -f $vars.Count)
        )
        $result | ConvertTo-Json -Depth 10
        break
    }
}

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("EnsureSupabaseLoginApp")]
    [string]$Action,

    [Parameter()]
    [string]$SupabaseProjectRef,

    [Parameter()]
    [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\..\modules\Ingestra.Common.psm1" -Force

$tenantId = [Environment]::GetEnvironmentVariable("AZURE_TENANT_ID")
$clientId = [Environment]::GetEnvironmentVariable("AZURE_CLIENT_ID")
$clientSecret = [Environment]::GetEnvironmentVariable("AZURE_CLIENT_SECRET")
$supabaseToken = [Environment]::GetEnvironmentVariable("SUPABASE_ACCESS_TOKEN")

if ([string]::IsNullOrWhiteSpace($tenantId)) { throw "AZURE_TENANT_ID is required." }
if ([string]::IsNullOrWhiteSpace($clientId)) { throw "AZURE_CLIENT_ID is required." }
if ([string]::IsNullOrWhiteSpace($clientSecret)) { throw "AZURE_CLIENT_SECRET is required." }
if ([string]::IsNullOrWhiteSpace($supabaseToken)) { throw "SUPABASE_ACCESS_TOKEN is required." }

$graphBaseUri = "https://graph.microsoft.com/v1.0"
$supabaseBaseUri = "https://api.supabase.com/v1"

function Get-AzureConfigValue {
    param(
        [Parameter(Mandatory)]
        [string]$PropertyName
    )

    if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
        return $null
    }

    $section = Get-IngestraAutomationConfigSection -SectionName "azure" -Path $ConfigPath
    $property = $section.PSObject.Properties[$PropertyName]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

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

    return $property.Value
}

function Get-GraphAccessToken {
    $tokenUri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    $body = @{
        client_id     = $clientId
        client_secret = $clientSecret
        scope         = "https://graph.microsoft.com/.default"
        grant_type    = "client_credentials"
    }

    $response = Invoke-RestMethod -Method POST -Uri $tokenUri -Body $body -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
    return [string]$response.access_token
}

function Invoke-GraphApiRequest {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("GET", "POST", "PATCH")]
        [string]$Method,

        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter()]
        $Body
    )

    $accessToken = Get-GraphAccessToken
    $headers = @{
        Authorization = "Bearer $accessToken"
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

function Get-SupabaseProjectByName {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $projects = Invoke-IngestraApiRequest -Method GET -Uri "$supabaseBaseUri/projects" -Headers @{
        Authorization = "Bearer $supabaseToken"
        Accept        = "application/json"
        "User-Agent"  = "ingestra-cicd/1.0"
    }

    $match = @($projects | Where-Object { $_.name -eq $Name } | Select-Object -First 1)
    if ($match.Count -eq 0) {
        return $null
    }

    return $match[0]
}

function Resolve-SupabaseProjectRef {
    if (-not [string]::IsNullOrWhiteSpace($SupabaseProjectRef)) {
        return $SupabaseProjectRef
    }

    $projectName = [string](Get-SupabaseConfigValue -PropertyName "projectName")
    if ([string]::IsNullOrWhiteSpace($projectName)) {
        throw "Supabase project name is required in config to resolve the project ref."
    }

    $project = Get-SupabaseProjectByName -Name $projectName
    if ($null -eq $project) {
        throw "Supabase project '$projectName' was not found."
    }

    return [string]$project.ref
}

function Get-AzureApplicationByDisplayName {
    param(
        [Parameter(Mandatory)]
        [string]$DisplayName
    )

    $encodedFilter = [System.Uri]::EscapeDataString("displayName eq '$DisplayName'")
    $response = Invoke-GraphApiRequest -Method GET -Uri "$graphBaseUri/applications?`$filter=$encodedFilter"
    $value = @($response.value)
    if ($value.Count -eq 0) {
        return $null
    }

    return $value[0]
}

function New-OptionalClaimObject {
    param(
        [Parameter(Mandatory)]
        [string[]]$ClaimNames
    )

    return @{
        idToken = @(
            $ClaimNames | ForEach-Object {
                @{
                    name = $_
                    essential = $false
                    additionalProperties = @()
                }
            }
        )
    }
}

switch ($Action) {
    "EnsureSupabaseLoginApp" {
        $createEnabled = [bool](Get-AzureConfigValue -PropertyName "createSupabaseLoginApp")
        if (-not $createEnabled) {
            throw "Azure Supabase login app automation is disabled in config."
        }

        $displayName = [string](Get-AzureConfigValue -PropertyName "supabaseLoginAppName")
        $signInAudience = [string](Get-AzureConfigValue -PropertyName "signInAudience")
        $optionalClaims = @((Get-AzureConfigValue -PropertyName "optionalClaims"))

        if ([string]::IsNullOrWhiteSpace($displayName)) {
            throw "azure.supabaseLoginAppName is required in config."
        }

        if ([string]::IsNullOrWhiteSpace($signInAudience)) {
            throw "azure.signInAudience is required in config."
        }

        $projectRef = Resolve-SupabaseProjectRef
        $redirectUri = "https://$projectRef.supabase.co/auth/v1/callback"
        $existing = Get-AzureApplicationByDisplayName -DisplayName $displayName

        if ($null -ne $existing) {
            $patchBody = @{
                signInAudience = $signInAudience
                web = @{
                    redirectUris = @($redirectUri)
                    implicitGrantSettings = @{
                        enableAccessTokenIssuance = $false
                        enableIdTokenIssuance = $false
                    }
                }
                optionalClaims = (New-OptionalClaimObject -ClaimNames $optionalClaims)
            }

            Invoke-GraphApiRequest -Method PATCH -Uri "$graphBaseUri/applications/$($existing.id)" -Body $patchBody | Out-Null
            Write-IngestraSummary -Lines @(
                "## Azure",
                "- Action: ensure Supabase login app",
                "- Result: already exists",
                ("- Display name: {0}" -f $displayName),
                ("- Application ID: {0}" -f $existing.appId),
                ("- Redirect URI: {0}" -f $redirectUri)
            )
            Set-IngestraOutput -Name "supabase_login_app_id" -Value ([string]$existing.appId)
            Set-IngestraOutput -Name "supabase_login_redirect_uri" -Value $redirectUri
            [pscustomobject]@{
                Result = "already_exists"
                DisplayName = $displayName
                AppId = [string]$existing.appId
                RedirectUri = $redirectUri
                SupabaseProjectRef = $projectRef
            } | ConvertTo-Json -Depth 10
            break
        }

        $createBody = @{
            displayName = $displayName
            signInAudience = $signInAudience
            web = @{
                redirectUris = @($redirectUri)
                implicitGrantSettings = @{
                    enableAccessTokenIssuance = $false
                    enableIdTokenIssuance = $false
                }
            }
            optionalClaims = (New-OptionalClaimObject -ClaimNames $optionalClaims)
        }

        $created = Invoke-GraphApiRequest -Method POST -Uri "$graphBaseUri/applications" -Body $createBody
        $passwordResult = Invoke-GraphApiRequest -Method POST -Uri "$graphBaseUri/applications/$($created.id)/addPassword" -Body @{
            passwordCredential = @{
                displayName = "$displayName bootstrap secret"
            }
        }

        $secretText = [string]$passwordResult.secretText
        Add-IngestraMask -Value $secretText
        Set-IngestraOutput -Name "supabase_login_app_id" -Value ([string]$created.appId)
        Set-IngestraOutput -Name "supabase_login_client_secret" -Value $secretText
        Set-IngestraOutput -Name "supabase_login_redirect_uri" -Value $redirectUri
        Write-IngestraSummary -Lines @(
            "## Azure",
            "- Action: ensure Supabase login app",
            "- Result: created",
            ("- Display name: {0}" -f $displayName),
            ("- Application ID: {0}" -f $created.appId),
            ("- Redirect URI: {0}" -f $redirectUri)
        )
        [pscustomobject]@{
            Result = "created"
            DisplayName = $displayName
            AppId = [string]$created.appId
            RedirectUri = $redirectUri
            SupabaseProjectRef = $projectRef
        } | ConvertTo-Json -Depth 10
        break
    }
}

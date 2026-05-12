Set-StrictMode -Version Latest

$script:IngestraRepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$script:DefaultAutomationConfigPath = Join-Path $script:IngestraRepoRoot "config\automation-config.json"

function Get-IngestraRequiredSecretNames {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("minimal", "provision", "supabase-project", "supabase-schema", "smoke")]
        [string]$Profile = "minimal"
    )

    switch ($Profile) {
        "minimal" {
            return @()
        }
        "provision" {
            return @(
                "AZURE_TENANT_ID",
                "AZURE_CLIENT_ID",
                "AZURE_CLIENT_SECRET",
                "PINECONE_API_KEY",
                "SUPABASE_ACCESS_TOKEN",
                "SUPABASE_ORG_SLUG",
                "SUPABASE_DB_PASSWORD",
                "VERCEL_TOKEN"
            )
        }
        "supabase-schema" {
            return @(
                "SUPABASE_ACCESS_TOKEN",
                "SUPABASE_ORG_SLUG",
                "SUPABASE_DB_PASSWORD",
                "SUPABASE_DB_URL"
            )
        }
        "supabase-project" {
            return @(
                "SUPABASE_ACCESS_TOKEN",
                "SUPABASE_ORG_SLUG",
                "SUPABASE_DB_PASSWORD"
            )
        }
        "smoke" {
            return @(
                "INGESTRA_UPLOAD_URL",
                "INGESTRA_SEARCH_URL",
                "INGESTRA_CHAT_URL"
            )
        }
    }
}

function Test-IngestraSecretsPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Names
    )

    $missing = [System.Collections.Generic.List[string]]::new()

    foreach ($name in $Names) {
        $value = [Environment]::GetEnvironmentVariable($name)
        if ([string]::IsNullOrWhiteSpace($value)) {
            $missing.Add($name)
        }
    }

    [pscustomobject]@{
        Missing = @($missing)
        Present = @($Names | Where-Object { $_ -notin $missing })
        Success = ($missing.Count -eq 0)
    }
}

function Invoke-IngestraApiRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("GET", "POST", "PUT", "PATCH", "DELETE")]
        [string]$Method,

        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter()]
        [hashtable]$Headers,

        [Parameter()]
        $Body
    )

    $params = @{
        Method      = $Method
        Uri         = $Uri
        ErrorAction = "Stop"
    }

    if ($Headers) {
        $params.Headers = $Headers
    }

    if ($null -ne $Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 10)
        $params.ContentType = "application/json"
    }

    Invoke-RestMethod @params
}

function Get-IngestraAutomationConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = $script:DefaultAutomationConfigPath
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Automation config file not found: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "Automation config file is empty: $Path"
    }

    return ($raw | ConvertFrom-Json -Depth 20)
}

function Get-IngestraAutomationConfigSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SectionName,

        [Parameter()]
        [string]$Path = $script:DefaultAutomationConfigPath
    )

    $config = Get-IngestraAutomationConfig -Path $Path
    $section = $config.PSObject.Properties[$SectionName]
    if ($null -eq $section) {
        throw "Automation config section '$SectionName' was not found in $Path"
    }

    return $section.Value
}

function Write-IngestraSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Lines
    )

    $summaryPath = [Environment]::GetEnvironmentVariable("GITHUB_STEP_SUMMARY")
    if ([string]::IsNullOrWhiteSpace($summaryPath)) {
        return
    }

    Add-Content -LiteralPath $summaryPath -Value ($Lines -join [Environment]::NewLine)
}

function Set-IngestraOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value
    )

    $outputPath = [Environment]::GetEnvironmentVariable("GITHUB_OUTPUT")
    if ([string]::IsNullOrWhiteSpace($outputPath)) {
        return
    }

    Add-Content -LiteralPath $outputPath -Value ("{0}={1}" -f $Name, $Value)
}

function Add-IngestraMask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    Write-Host ("::add-mask::{0}" -f $Value)
}

Export-ModuleMember -Function Get-IngestraRequiredSecretNames
Export-ModuleMember -Function Test-IngestraSecretsPresent
Export-ModuleMember -Function Invoke-IngestraApiRequest
Export-ModuleMember -Function Get-IngestraAutomationConfig
Export-ModuleMember -Function Get-IngestraAutomationConfigSection
Export-ModuleMember -Function Write-IngestraSummary
Export-ModuleMember -Function Set-IngestraOutput
Export-ModuleMember -Function Add-IngestraMask

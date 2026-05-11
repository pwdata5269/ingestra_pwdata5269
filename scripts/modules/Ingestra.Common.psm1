Set-StrictMode -Version Latest

function Get-IngestraRequiredSecretNames {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("minimal", "provision", "smoke")]
        [string]$Profile = "minimal"
    )

    switch ($Profile) {
        "minimal" {
            return @()
        }
        "provision" {
            return @(
                "PINECONE_API_KEY",
                "SUPABASE_ACCESS_TOKEN",
                "SUPABASE_ORG_SLUG",
                "SUPABASE_DB_PASSWORD",
                "VERCEL_TOKEN"
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

Export-ModuleMember -Function Get-IngestraRequiredSecretNames
Export-ModuleMember -Function Test-IngestraSecretsPresent
Export-ModuleMember -Function Invoke-IngestraApiRequest
Export-ModuleMember -Function Write-IngestraSummary

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("EnsureIndex", "DeleteIndex", "DescribeIndex")]
    [string]$Action,

    [Parameter(Mandatory)]
    [string]$IndexName,

    [Parameter()]
    [int]$Dimension = 384,

    [Parameter()]
    [ValidateSet("cosine", "dotproduct", "euclidean")]
    [string]$Metric = "cosine",

    [Parameter()]
    [ValidateSet("aws", "gcp", "azure")]
    [string]$Cloud = "aws",

    [Parameter()]
    [string]$Region = "us-east-1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\..\modules\Ingestra.Common.psm1" -Force

$apiKey = [Environment]::GetEnvironmentVariable("PINECONE_API_KEY")
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    throw "PINECONE_API_KEY is required."
}

$headers = @{
    "Api-Key"                = $apiKey
    "Accept"                 = "application/json"
    "X-Pinecone-Api-Version" = "2026-04"
}

$baseUri = "https://api.pinecone.io"

function Get-PineconeIndex {
    param([string]$Name)

    try {
        return Invoke-IngestraApiRequest -Method GET -Uri "$baseUri/indexes/$Name" -Headers $headers
    }
    catch {
        if ($_.Exception.Message -match "404") {
            return $null
        }

        throw
    }
}

switch ($Action) {
    "DescribeIndex" {
        $index = Get-PineconeIndex -Name $IndexName
        if ($null -eq $index) {
            throw "Index '$IndexName' does not exist."
        }

        $index | ConvertTo-Json -Depth 10
        break
    }

    "DeleteIndex" {
        Invoke-IngestraApiRequest -Method DELETE -Uri "$baseUri/indexes/$IndexName" -Headers $headers | Out-Null
        Write-Host "Deleted Pinecone index '$IndexName'."
        break
    }

    "EnsureIndex" {
        $existing = Get-PineconeIndex -Name $IndexName
        if ($null -ne $existing) {
            Write-Host "Pinecone index '$IndexName' already exists."
            return
        }

        $body = @{
            name                  = $IndexName
            vector_type           = "dense"
            dimension             = $Dimension
            metric                = $Metric
            spec                  = @{
                serverless = @{
                    cloud  = $Cloud
                    region = $Region
                }
            }
            deletion_protection   = "disabled"
        }

        Invoke-IngestraApiRequest -Method POST -Uri "$baseUri/indexes" -Headers $headers -Body $body | Out-Null
        Write-Host "Created Pinecone index '$IndexName' in $Cloud/$Region."
        break
    }
}

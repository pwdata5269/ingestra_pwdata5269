[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$InputXmlPath,

    [Parameter(Mandatory)]
    [string]$OutputHtmlPath,

    [Parameter()]
    [string]$ReportTitle = "Pester Test Report",

    [Parameter()]
    [string]$GeneratedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss 'UTC'")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $InputXmlPath)) {
    throw "Input XML report not found: $InputXmlPath"
}

[xml]$report = Get-Content -LiteralPath $InputXmlPath -Raw

if ($null -eq $report.testsuites) {
    throw "Unsupported JUnit XML format in $InputXmlPath"
}

$testCases = foreach ($suite in $report.testsuites.testsuite) {
    foreach ($case in $suite.testcase) {
        $failureNode = $case.SelectSingleNode("failure")
        $errorNode = $case.SelectSingleNode("error")
        $skippedNode = $case.SelectSingleNode("skipped")
        $statusAttribute = [string]$case.status

        $status = if ($null -ne $failureNode -or $null -ne $errorNode) {
            "failed"
        }
        elseif ($null -ne $skippedNode) {
            "skipped"
        }
        elseif ($statusAttribute -eq "Skipped") {
            "skipped"
        }
        elseif ($statusAttribute -eq "Failed") {
            "failed"
        }
        else {
            "passed"
        }

        $detail = if ($null -ne $failureNode) {
            [string]$failureNode.InnerText
        }
        elseif ($null -ne $errorNode) {
            [string]$errorNode.InnerText
        }
        elseif ($null -ne $skippedNode) {
            [string]$skippedNode.InnerText
        }
        else {
            ""
        }

        [pscustomobject]@{
            Suite    = [string]$suite.name
            Name     = [string]$case.name
            Status   = $status
            Duration = [double]$case.time
            Detail   = $detail.Trim()
        }
    }
}

$passedCount = @($testCases | Where-Object Status -eq "passed").Count
$failedCount = @($testCases | Where-Object Status -eq "failed").Count
$skippedCount = @($testCases | Where-Object Status -eq "skipped").Count
$totalCount = @($testCases).Count

$rows = foreach ($testCase in $testCases) {
    $encodedSuite = [System.Net.WebUtility]::HtmlEncode($testCase.Suite)
    $encodedName = [System.Net.WebUtility]::HtmlEncode($testCase.Name)
    $encodedStatus = [System.Net.WebUtility]::HtmlEncode($testCase.Status.ToUpperInvariant())
    $encodedDetail = [System.Net.WebUtility]::HtmlEncode($testCase.Detail)
    $durationText = "{0:N3}s" -f $testCase.Duration
    $detailMarkup = if ([string]::IsNullOrWhiteSpace($encodedDetail)) {
        ""
    }
    else {
        "<details><summary>Details</summary><pre>$encodedDetail</pre></details>"
    }

    @"
<tr class="status-$($testCase.Status)">
  <td>$encodedSuite</td>
  <td>$encodedName</td>
  <td><span class="badge badge-$($testCase.Status)">$encodedStatus</span></td>
  <td>$durationText</td>
  <td>$detailMarkup</td>
</tr>
"@
}

$titleEncoded = [System.Net.WebUtility]::HtmlEncode($ReportTitle)
$generatedEncoded = [System.Net.WebUtility]::HtmlEncode($GeneratedAt)

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$titleEncoded</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f3f6fb;
      --panel: #ffffff;
      --ink: #162032;
      --muted: #5d6b82;
      --border: #d7dfeb;
      --pass: #0f8a5f;
      --pass-bg: #dff7ed;
      --fail: #b42318;
      --fail-bg: #fee4e2;
      --skip: #8a5b0f;
      --skip-bg: #fff1d6;
      --accent: #1d4ed8;
    }

    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: linear-gradient(180deg, #eef4ff 0%, var(--bg) 100%);
      color: var(--ink);
      font: 15px/1.5 "Segoe UI", Arial, sans-serif;
    }

    .wrap {
      max-width: 1120px;
      margin: 0 auto;
      padding: 32px 20px 48px;
    }

    .hero, .panel {
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 18px;
      box-shadow: 0 18px 50px rgba(15, 23, 42, 0.08);
    }

    .hero {
      padding: 28px;
      margin-bottom: 24px;
    }

    h1 {
      margin: 0 0 8px;
      font-size: 30px;
      line-height: 1.15;
    }

    .meta {
      color: var(--muted);
      margin: 0;
    }

    .summary {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
      gap: 14px;
      margin-top: 22px;
    }

    .card {
      padding: 16px;
      border-radius: 14px;
      border: 1px solid var(--border);
      background: #fbfdff;
    }

    .card h2 {
      margin: 0 0 6px;
      color: var(--muted);
      font-size: 13px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }

    .card p {
      margin: 0;
      font-size: 28px;
      font-weight: 700;
    }

    .panel {
      padding: 20px;
    }

    table {
      width: 100%;
      border-collapse: collapse;
    }

    th, td {
      padding: 14px 12px;
      border-bottom: 1px solid var(--border);
      text-align: left;
      vertical-align: top;
    }

    th {
      color: var(--muted);
      font-size: 13px;
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }

    tr:last-child td {
      border-bottom: 0;
    }

    .badge {
      display: inline-block;
      border-radius: 999px;
      padding: 4px 10px;
      font-size: 12px;
      font-weight: 700;
      letter-spacing: 0.03em;
    }

    .badge-passed {
      color: var(--pass);
      background: var(--pass-bg);
    }

    .badge-failed {
      color: var(--fail);
      background: var(--fail-bg);
    }

    .badge-skipped {
      color: var(--skip);
      background: var(--skip-bg);
    }

    details summary {
      cursor: pointer;
      color: var(--accent);
      font-weight: 600;
    }

    pre {
      margin: 10px 0 0;
      padding: 12px;
      overflow-x: auto;
      white-space: pre-wrap;
      border-radius: 12px;
      background: #0f172a;
      color: #e2e8f0;
      font: 12px/1.45 Consolas, "Courier New", monospace;
    }
  </style>
</head>
<body>
  <div class="wrap">
    <section class="hero">
      <h1>$titleEncoded</h1>
      <p class="meta">Generated: $generatedEncoded</p>
      <div class="summary">
        <div class="card">
          <h2>Total Tests</h2>
          <p>$totalCount</p>
        </div>
        <div class="card">
          <h2>Passed</h2>
          <p>$passedCount</p>
        </div>
        <div class="card">
          <h2>Failed</h2>
          <p>$failedCount</p>
        </div>
        <div class="card">
          <h2>Skipped</h2>
          <p>$skippedCount</p>
        </div>
      </div>
    </section>

    <section class="panel">
      <table>
        <thead>
          <tr>
            <th>Suite</th>
            <th>Test</th>
            <th>Status</th>
            <th>Duration</th>
            <th>Detail</th>
          </tr>
        </thead>
        <tbody>
$($rows -join [Environment]::NewLine)
        </tbody>
      </table>
    </section>
  </div>
</body>
</html>
"@

$outputDirectory = Split-Path -Parent $OutputHtmlPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

Set-Content -LiteralPath $OutputHtmlPath -Value $html -Encoding UTF8
Write-Host "Created HTML report: $OutputHtmlPath"

param(
    [string]$ProjectPath = ".",
    [Parameter(Mandatory = $true)]
    [string]$FeedbackPath,
    [string]$OutputPath = "",
    [ValidateSet("General", "Code", "Research", "Manuscript", "Audit")]
    [string]$Mode = "General"
)

$ErrorActionPreference = "Stop"

function Invoke-Git {
    param([string]$RepoPath, [string[]]$Arguments)
    try {
        $output = & git -C $RepoPath @Arguments 2>$null
        if ($LASTEXITCODE -ne 0) { return "" }
        return ($output -join [Environment]::NewLine)
    } catch {
        return ""
    }
}

$resolvedProject = (Resolve-Path -LiteralPath $ProjectPath).Path
$resolvedFeedback = (Resolve-Path -LiteralPath $FeedbackPath).Path
$feedback = Get-Content -LiteralPath $resolvedFeedback -Raw -Encoding UTF8

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $outDir = Join-Path $resolvedProject ".codex-external-feedback"
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutputPath = Join-Path $outDir "feedback-classification-$stamp.md"
} else {
    $parent = Split-Path -Parent $OutputPath
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

$candidateLines = $feedback -split "`r?`n" |
    Where-Object { $_ -match '^\s*(-|\*|\d+\.|\|)' -or $_ -match '(?i)(risk|issue|bug|fix|test|evidence|unsupported|uncertain|overclaim|recommend|should|must|문제|위험|수정|테스트|근거|권장|해야)' } |
    Select-Object -First 80

if ($candidateLines.Count -eq 0) {
    $candidateLines = @($feedback.Substring(0, [Math]::Min($feedback.Length, 1200)))
}

$items = New-Object System.Collections.Generic.List[string]
$index = 1
foreach ($line in $candidateLines) {
    $clean = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($clean)) { continue }
    $escaped = $clean -replace "\|", "\|"
    $items.Add("| $index | $escaped | pending |  |  |")
    $index++
}

$status = Invoke-Git -RepoPath $resolvedProject -Arguments @("status", "--short")
$diffStat = Invoke-Git -RepoPath $resolvedProject -Arguments @("diff", "--stat")

$table = ($items -join [Environment]::NewLine)
Set-Content -LiteralPath $OutputPath -Encoding UTF8 -Value @"
# External Feedback Classification

- Mode: $Mode
- Project: $resolvedProject
- Feedback source: $resolvedFeedback
- Generated: $(Get-Date -Format o)

## Local Context

### Git Status

``````text
$status
``````

### Diff Stat

``````text
$diffStat
``````

## Classification Table

Use one of: `apply`, `consider`, `reject`, `needs user decision`.

| # | Feedback item | Classification | Local evidence | Planned action |
| ---: | --- | --- | --- | --- |
$table

## Raw Feedback

``````text
$feedback
``````
"@

Write-Host "Created feedback classification worksheet: $OutputPath"

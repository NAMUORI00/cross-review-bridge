param(
    [string]$ProjectPath = ".",
    [ValidateSet("Review", "Analysis", "Debug", "Research")]
    [string]$Mode = "Review",
    [string[]]$IncludeFiles = @(),
    [string]$Goal = "",
    [string]$OutputPath = "",
    [int]$MaxDiffChars = 40000,
    [switch]$CopyToClipboard
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

function Read-SafeFile {
    param([string]$Root, [string]$RelativePath)
    $fullPath = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        return "### $RelativePath`n`n_File not found._"
    }
    $content = Redact-Text (Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8)
    if ($content.Length -gt 12000) {
        $content = $content.Substring(0, 12000) + "`n`n[Truncated.]"
    }
    return "### $RelativePath`n`n``````text`n$content`n``````"
}

function Redact-Text {
    param([AllowNull()][string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return "" }

    $redacted = $Text
    $redacted = $redacted -replace '(?i)(api[_-]?key|access[_-]?token|refresh[_-]?token|secret|password|authorization)\s*[:=]\s*["'']?[^"''\s,;]+', '$1=[REDACTED]'
    $redacted = $redacted -replace '(?i)bearer\s+[a-z0-9._\-]+', 'Bearer [REDACTED]'
    $redacted = $redacted -replace 'sk-[A-Za-z0-9_\-]{20,}', 'sk-[REDACTED]'
    $redacted = $redacted -replace 'hf_[A-Za-z0-9]{20,}', 'hf_[REDACTED]'
    $redacted = $redacted -replace 'gh[pousr]_[A-Za-z0-9_]{20,}', 'gh_[REDACTED]'
    return $redacted
}

function Get-FileSnapshot {
    param([string]$Root)
    $ignored = @(".git", ".agents", "gpt-feedback-loop", "review-brief.md", "node_modules", ".next", "dist", "build", "coverage", ".venv", "venv", "__pycache__", ".codex-cross-review")
    $rootPath = (Resolve-Path -LiteralPath $Root).Path.TrimEnd([char[]]"\/")
    $files = Get-ChildItem -LiteralPath $Root -Recurse -Force -File |
        Where-Object {
            $path = $_.FullName.Substring($rootPath.Length).TrimStart([char[]]"\/")
            foreach ($part in $ignored) {
                if ($path -match "(^|[\\/])$([regex]::Escape($part))([\\/]|$)") { return $false }
            }
            return $true
        } |
        Select-Object -First 200 |
        ForEach-Object { ".\" + $_.FullName.Substring($rootPath.Length).TrimStart([char[]]"\/") }
    return ($files -join [Environment]::NewLine)
}

$resolvedProject = (Resolve-Path -LiteralPath $ProjectPath).Path
$outDir = Join-Path $resolvedProject ".codex-cross-review"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutputPath = Join-Path $outDir "brief-$($Mode.ToLower())-$stamp.md"
}

$status = Invoke-Git -RepoPath $resolvedProject -Arguments @("status", "--short")
$diffStat = Invoke-Git -RepoPath $resolvedProject -Arguments @("diff", "--stat")
$diff = Redact-Text (Invoke-Git -RepoPath $resolvedProject -Arguments @("diff", "--", "."))
if ($diff.Length -gt $MaxDiffChars) {
    $diff = $diff.Substring(0, $MaxDiffChars) + "`n`n[Diff truncated. Increase -MaxDiffChars or include focused files.]"
}
$branch = Invoke-Git -RepoPath $resolvedProject -Arguments @("branch", "--show-current")
$snapshot = Get-FileSnapshot -Root $resolvedProject

$modeInstruction = switch ($Mode) {
    "Review" { "Review for correctness, regressions, maintainability, security/privacy risk, and missing tests." }
    "Analysis" { "Analyze architecture, maintainability, product/UX risks, and high-leverage improvements." }
    "Debug" { "Analyze likely root causes, evidence, diagnostics, and smallest safe fixes." }
    "Research" { "Research implementation alternatives and recommend a practical path. Prefer primary sources." }
}

$included = ""
if ($IncludeFiles.Count -gt 0) {
    $included = ($IncludeFiles | ForEach-Object { Read-SafeFile -Root $resolvedProject -RelativePath $_ }) -join "`n`n"
}

$brief = @"
# Cross Review Brief

You are the external reviewer in a human-approved cross-review loop.
Codex Desktop has local code access and will implement only validated recommendations.

## Mode

$Mode

## Goal

$Goal

## Review Instructions

$modeInstruction

Return:
- Critical issues first
- Concrete fix suggestions
- File/area references when possible
- Assumptions and uncertainty
- Advice you would not apply without more context

## Project

$resolvedProject

## Git Branch

$branch

## Git Status

``````text
$status
``````

## File Snapshot

``````text
$snapshot
``````

## Diff Stat

``````text
$diffStat
``````

## Git Diff

``````diff
$diff
``````

## Included Files

$included
"@

Set-Content -LiteralPath $OutputPath -Value $brief -Encoding UTF8

if ($CopyToClipboard) {
    Set-Clipboard -Value $brief
}

Write-Host "Created cross-review brief: $OutputPath"
if ($CopyToClipboard) {
    Write-Host "Copied cross-review brief to clipboard."
}

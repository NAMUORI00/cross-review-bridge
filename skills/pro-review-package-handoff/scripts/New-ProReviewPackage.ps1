param(
    [string]$ProjectPath = ".",
    [ValidateSet("General", "CodeReview", "Research", "Manuscript", "DecisionResponse", "Audit")]
    [string]$Mode = "General",
    [string]$Goal = "",
    [string[]]$IncludeFiles = @(),
    [switch]$IncludeDiscoveredArtifacts,
    [string]$OutputPath = "",
    [string]$PackageName = "",
    [int]$MaxDiffChars = 80000,
    [int]$MaxFileBytes = 5242880,
    [switch]$IncludeAbsoluteProjectPath,
    [switch]$DryRun,
    [switch]$CopyPromptToClipboard
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

function Normalize-RelativePath {
    param([string]$Path)
    return ($Path -replace "\\", "/").TrimStart("/")
}

function Test-UnsafeRelativePath {
    param([string]$RelativePath)
    if ([string]::IsNullOrWhiteSpace($RelativePath)) { return $true }
    if ([IO.Path]::IsPathRooted($RelativePath)) { return $true }
    $normalized = Normalize-RelativePath $RelativePath
    $parts = $normalized -split "/"
    return ($parts -contains "..")
}

function Test-ExcludedPath {
    param([string]$RelativePath)
    if (Test-UnsafeRelativePath $RelativePath) { return $true }
    $path = Normalize-RelativePath $RelativePath
    $parts = $path -split "/"
    $blockedParts = @(".git", ".svn", ".hg", "node_modules", ".venv", "venv", "__pycache__", ".next", "dist", "build", "coverage", ".cache", ".codex-pro-review-packages", ".codex-external-feedback", ".codex-cross-review")
    foreach ($part in $parts) {
        if ($blockedParts -contains $part) { return $true }
    }
    $leaf = [IO.Path]::GetFileName($path)
    if ($leaf -match '^(?i)\.env(\..*)?$') { return $true }
    if ($path -match '(?i)(^|/)(id_rsa|id_dsa|id_ecdsa|id_ed25519|.*\.pem|.*\.pfx|.*\.key)$') { return $true }
    if ($path -match '(?i)(secret|credential|password|token|apikey|api_key)') { return $true }
    return $false
}

function Redact-Text {
    param([AllowNull()][string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    $redacted = $Text
    $redacted = $redacted -replace '(?i)authorization\s*[:=]\s*bearer\s+[^"''\s,;]+', 'Authorization: Bearer [REDACTED]'
    $redacted = $redacted -replace '(?i)authorization\s*[:=]\s*(?!bearer\s+\[redacted\])["'']?[^"''\s,;]+', 'Authorization=[REDACTED]'
    $redacted = $redacted -replace '(?i)bearer\s+[a-z0-9._\-]{8,}', 'Bearer [REDACTED]'
    $redacted = $redacted -replace '(?i)(api[_-]?key|access[_-]?token|refresh[_-]?token|secret|password)\s*[:=]\s*["'']?[^"''\s,;]+', '$1=[REDACTED]'
    $redacted = $redacted -replace 'sk-[A-Za-z0-9_\-]{20,}', 'sk-[REDACTED]'
    $redacted = $redacted -replace 'hf_[A-Za-z0-9]{20,}', 'hf_[REDACTED]'
    $redacted = $redacted -replace 'gh[pousr]_[A-Za-z0-9_]{20,}', 'gh_[REDACTED]'
    return $redacted
}

function Test-SecretLikeText {
    param([string]$FullPath)
    try {
        $bytes = [IO.File]::ReadAllBytes($FullPath)
        if ($bytes -contains 0) { return $false }
        $text = [Text.Encoding]::UTF8.GetString($bytes)
        return ($text -match '(?i)(api[_-]?key|access[_-]?token|refresh[_-]?token|secret|password|authorization)\s*[:=]' -or
                $text -match '(?i)bearer\s+[a-z0-9._\-]{12,}' -or
                $text -match 'sk-[A-Za-z0-9_\-]{20,}' -or
                $text -match 'gh[pousr]_[A-Za-z0-9_]{20,}')
    } catch {
        return $false
    }
}

function Read-TextFile {
    param([string]$FullPath)
    try {
        $bytes = [IO.File]::ReadAllBytes($FullPath)
        if ($bytes -contains 0) { return $null }
        return [Text.Encoding]::UTF8.GetString($bytes)
    } catch {
        return $null
    }
}

function Get-ChangedFiles {
    param([string]$Root)
    $files = @()
    $files += (Invoke-Git -RepoPath $Root -Arguments @("diff", "--name-only")) -split "`r?`n"
    $files += (Invoke-Git -RepoPath $Root -Arguments @("diff", "--cached", "--name-only")) -split "`r?`n"
    $files += (Invoke-Git -RepoPath $Root -Arguments @("ls-files", "--others", "--exclude-standard")) -split "`r?`n"
    return $files | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
}

function Get-DiscoveredArtifacts {
    param([string]$Root)
    $allowed = @(".pdf", ".html", ".htm", ".md", ".txt", ".png", ".jpg", ".jpeg", ".svg", ".tex", ".csv", ".tsv", ".xlsx", ".docx", ".pptx", ".log", ".patch", ".diff")
    $rootPath = (Resolve-Path -LiteralPath $Root).Path.TrimEnd([char[]]"\/")
    $items = Get-ChildItem -LiteralPath $Root -Recurse -Force -File |
        Where-Object {
            $rel = Normalize-RelativePath ($_.FullName.Substring($rootPath.Length).TrimStart([char[]]"\/"))
            if (Test-ExcludedPath $rel) { return $false }
            if ($_.Length -gt $MaxFileBytes) { return $false }
            $ext = $_.Extension.ToLowerInvariant()
            if ($allowed -notcontains $ext) { return $false }
            if ($rel -match '(?i)(review|decision|response|evidence|claim|support|matrix|audit|figure|fig|screenshot|result|test|log|paper|manuscript|draft|html|pdf)') { return $true }
            return $false
        } |
        Select-Object -First 200
    return $items | ForEach-Object { Normalize-RelativePath ($_.FullName.Substring($rootPath.Length).TrimStart([char[]]"\/")) }
}

function Get-CategoryPath {
    param([string]$RelativePath)
    $path = Normalize-RelativePath $RelativePath
    $leaf = [IO.Path]::GetFileName($path)
    $ext = [IO.Path]::GetExtension($path).ToLowerInvariant()
    if ($ext -in @(".ps1", ".py", ".js", ".ts", ".tsx", ".jsx", ".mjs", ".cjs", ".java", ".go", ".rs", ".cs", ".cpp", ".c", ".h", ".hpp", ".rb", ".php", ".sh", ".psm1", ".yaml", ".yml", ".json")) { return "source/$path" }
    if ($leaf -match '(?i)(review|decision|response|evidence|claim|support|matrix|audit)') { return "evidence/$path" }
    if ($ext -eq ".pdf") { return "artifacts/pdf/$path" }
    if ($ext -in @(".html", ".htm")) { return "artifacts/html/$path" }
    if ($ext -in @(".png", ".jpg", ".jpeg", ".svg")) { return "artifacts/figures/$path" }
    if ($ext -in @(".log", ".txt")) { return "artifacts/logs/$path" }
    if ($ext -in @(".patch", ".diff")) { return "context/$path" }
    return "source/$path"
}

function Resolve-InProjectFile {
    param([string]$Root, [string]$RelativePath)
    if (Test-UnsafeRelativePath $RelativePath) { return $null }
    $full = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { return $null }
    $resolvedRoot = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Root).Path).TrimEnd([char[]]"\/")
    $resolvedFile = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $full).Path)
    $rootPrefix = $resolvedRoot + [IO.Path]::DirectorySeparatorChar
    if (-not $resolvedFile.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) { return $null }
    return $resolvedFile
}

function New-ReviewPrompt {
    param([string]$Mode, [string]$Goal)
    $common = @"
You are the external reviewer in a Codex Desktop cross-review loop.
Read 000_READ_ME_FIRST.txt first, then inspect 000_MANIFEST.md and the included context.

Review goal:
$Goal

Return Korean output with:
- final recommendation: ready / minor revision / major revision / not ready
- critical risks
- correctness or regression issues
- security/privacy risks
- unsupported or uncertain claims
- small edits to apply now
- evidence or tests to regenerate/audit
- artifact QA: tables/figures/equations/captions/references/UI/screenshots/logs
- next action order

Do not invent missing files, APIs, experiments, or claims. Mark unsupported or uncertain items clearly.
"@
    if ($Mode -in @("Research", "Manuscript", "DecisionResponse")) {
        $common += @"

For research/manuscript material, also include:
- previous reviewer concern closure table with 0-100 improvement scores, when prior reviews are present
- remaining rejection-grade risks
- overclaim risk phrases
- table/figure/equation/caption/reference QA
"@
    }
    return $common.Trim()
}

$resolvedProject = (Resolve-Path -LiteralPath $ProjectPath).Path
$projectLabel = if ($IncludeAbsoluteProjectPath) { $resolvedProject } else { Split-Path -Leaf $resolvedProject }
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
if ([string]::IsNullOrWhiteSpace($PackageName)) {
    $safeMode = $Mode.ToLowerInvariant()
    $PackageName = "pro-review-package-$safeMode-$stamp"
}
$outRoot = Join-Path $resolvedProject ".codex-pro-review-packages"
New-Item -ItemType Directory -Path $outRoot -Force | Out-Null
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $outRoot "$PackageName.zip"
}
$outputParent = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputParent)) {
    New-Item -ItemType Directory -Path $outputParent -Force | Out-Null
}

$changedFiles = @(Get-ChangedFiles -Root $resolvedProject)
$artifactFiles = @()
if ($IncludeDiscoveredArtifacts) {
    $artifactFiles = @(Get-DiscoveredArtifacts -Root $resolvedProject)
}
$requestedFiles = @($IncludeFiles | ForEach-Object { Normalize-RelativePath $_ })
$candidateFiles = @($changedFiles + $artifactFiles + $requestedFiles) |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Select-Object -Unique

$included = New-Object System.Collections.Generic.List[object]
$skipped = New-Object System.Collections.Generic.List[object]
foreach ($rel in $candidateFiles) {
    $norm = Normalize-RelativePath $rel
    if (Test-ExcludedPath $norm) {
        $skipped.Add([pscustomobject]@{ Path = $norm; Reason = "excluded path or sensitive name" })
        continue
    }
    $full = Resolve-InProjectFile -Root $resolvedProject -RelativePath $norm
    if (-not $full) {
        $skipped.Add([pscustomobject]@{ Path = $norm; Reason = "missing or outside project" })
        continue
    }
    $item = Get-Item -LiteralPath $full
    if ($item.Length -gt $MaxFileBytes) {
        $skipped.Add([pscustomobject]@{ Path = $norm; Reason = "larger than MaxFileBytes" })
        continue
    }
    $redactContent = Test-SecretLikeText -FullPath $full
    $packagePath = Get-CategoryPath -RelativePath $norm
    $included.Add([pscustomobject]@{ Source = $norm; PackagePath = $packagePath; Size = $item.Length; Redacted = $redactContent })
}

if ($DryRun) {
    Write-Host "Pro review package dry run"
    Write-Host "Project: $projectLabel"
    Write-Host "Mode: $Mode"
    Write-Host "Goal: $Goal"
    Write-Host ""
    Write-Host "Included candidates:"
    foreach ($file in $included) { Write-Host "  + $($file.Source) -> $($file.PackagePath)" }
    Write-Host ""
    Write-Host "Skipped candidates:"
    foreach ($file in $skipped) { Write-Host "  - $($file.Path): $($file.Reason)" }
    Write-Host ""
    Write-Host "Approve this list before creating or uploading the ZIP."
    exit 0
}

$workRoot = Join-Path $outRoot "work-$stamp"
if (Test-Path -LiteralPath $workRoot) { Remove-Item -LiteralPath $workRoot -Recurse -Force }
New-Item -ItemType Directory -Path $workRoot -Force | Out-Null

$status = Invoke-Git -RepoPath $resolvedProject -Arguments @("status", "--short")
$diffStat = Invoke-Git -RepoPath $resolvedProject -Arguments @("diff", "--stat")
$stagedDiffStat = Invoke-Git -RepoPath $resolvedProject -Arguments @("diff", "--cached", "--stat")
$diff = Redact-Text (Invoke-Git -RepoPath $resolvedProject -Arguments @("diff", "--", "."))
$stagedDiff = Redact-Text (Invoke-Git -RepoPath $resolvedProject -Arguments @("diff", "--cached", "--", "."))
if ($diff.Length -gt $MaxDiffChars) {
    $diff = $diff.Substring(0, $MaxDiffChars) + "`n`n[Diff truncated. Increase -MaxDiffChars or include focused files.]"
}
if ($stagedDiff.Length -gt $MaxDiffChars) {
    $stagedDiff = $stagedDiff.Substring(0, $MaxDiffChars) + "`n`n[Staged diff truncated. Increase -MaxDiffChars or include focused files.]"
}
$commits = Invoke-Git -RepoPath $resolvedProject -Arguments @("log", "--oneline", "-n", "12")
$branch = Invoke-Git -RepoPath $resolvedProject -Arguments @("branch", "--show-current")

New-Item -ItemType Directory -Path (Join-Path $workRoot "context") -Force | Out-Null
Set-Content -LiteralPath (Join-Path $workRoot "context/task.md") -Encoding UTF8 -Value @"
# Task

Mode: $Mode
Goal: $Goal
Project: $projectLabel
Branch: $branch
Generated: $(Get-Date -Format o)
"@
Set-Content -LiteralPath (Join-Path $workRoot "context/git-status.txt") -Encoding UTF8 -Value $status
Set-Content -LiteralPath (Join-Path $workRoot "context/git-diff-stat.txt") -Encoding UTF8 -Value $diffStat
Set-Content -LiteralPath (Join-Path $workRoot "context/git-diff.patch") -Encoding UTF8 -Value $diff
Set-Content -LiteralPath (Join-Path $workRoot "context/git-staged-diff-stat.txt") -Encoding UTF8 -Value $stagedDiffStat
Set-Content -LiteralPath (Join-Path $workRoot "context/git-staged-diff.patch") -Encoding UTF8 -Value $stagedDiff
Set-Content -LiteralPath (Join-Path $workRoot "context/recent-commits.txt") -Encoding UTF8 -Value $commits

foreach ($file in $included) {
    $source = Resolve-InProjectFile -Root $resolvedProject -RelativePath $file.Source
    $dest = Join-Path $workRoot ($file.PackagePath -replace "/", [IO.Path]::DirectorySeparatorChar)
    New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
    if ($file.Redacted) {
        $text = Read-TextFile -FullPath $source
        if ($null -eq $text) {
            Set-Content -LiteralPath $dest -Encoding UTF8 -Value "[Skipped binary-like content that matched secret scan.]"
        } else {
            Set-Content -LiteralPath $dest -Encoding UTF8 -Value (Redact-Text $text)
        }
    } else {
        Copy-Item -LiteralPath $source -Destination $dest -Force
    }
}

$reviewPrompt = New-ReviewPrompt -Mode $Mode -Goal $Goal
$manifestIncluded = ($included | ForEach-Object {
    $category = ($_.PackagePath -split "/")[0]
    $safety = if ($_.Redacted) { "content redacted" } else { "original" }
    "| $($_.PackagePath) | $category | $($_.Source) | $($_.Size) | $safety |"
}) -join [Environment]::NewLine
if ([string]::IsNullOrWhiteSpace($manifestIncluded)) { $manifestIncluded = "| _none_ | _none_ | _none_ | 0 | _none_ |" }
$manifestSkipped = ($skipped | ForEach-Object { "| $($_.Path) | $($_.Reason) |" }) -join [Environment]::NewLine
if ([string]::IsNullOrWhiteSpace($manifestSkipped)) { $manifestSkipped = "| _none_ | _none_ |" }

Set-Content -LiteralPath (Join-Path $workRoot "000_REVIEW_PROMPT.md") -Encoding UTF8 -Value $reviewPrompt
Set-Content -LiteralPath (Join-Path $workRoot "000_CODEX_WORK_SUMMARY.md") -Encoding UTF8 -Value @"
# Codex Work Summary

Codex Desktop prepared this package for external review.

- Mode: $Mode
- Goal: $Goal
- Project branch: $branch
- Changed files detected: $($changedFiles.Count)
- Included files: $($included.Count)
- Skipped files: $($skipped.Count)
- Verification included: git status, unstaged diff/stat, staged diff/stat, recent commits
- Known gaps: this package does not prove CI passed unless CI logs are included as artifacts

The external review is advisory. Codex Desktop should verify recommendations locally before applying them.
"@
Set-Content -LiteralPath (Join-Path $workRoot "000_READ_ME_FIRST.txt") -Encoding UTF8 -Value @"
Read this file first.

Goal:
$Goal

Recommended read order:
1. 000_READ_ME_FIRST.txt
2. 000_MANIFEST.md
3. 000_CODEX_WORK_SUMMARY.md
4. context/task.md
5. context/git-status.txt and context/git-diff-stat.txt
6. context/git-diff.patch and context/git-staged-diff.patch
7. source/, artifacts/, and evidence/ as needed when those folders are present

Return Korean output using this format:
- final recommendation: ready / minor revision / major revision / not ready
- critical risks
- correctness or regression issues
- security/privacy risks
- unsupported or uncertain claims
- small edits to apply now
- evidence or tests to regenerate/audit
- artifact QA: tables/figures/equations/captions/references/UI/screenshots/logs
- next action order

If prior reviews or decision letters are present, score improvement for each reviewer concern from 0 to 100.
If evidence is missing, say unsupported or uncertain. Do not overclaim. Do not invent missing files, APIs, tests, or results.
"@
Set-Content -LiteralPath (Join-Path $workRoot "000_MANIFEST.md") -Encoding UTF8 -Value @"
# Pro Review Package Manifest

- Package: $PackageName
- Generated: $(Get-Date -Format o)
- Mode: $Mode
- Goal: $Goal
- Project: $projectLabel
- Branch: $branch

## Read Order

1. 000_READ_ME_FIRST.txt
2. 000_MANIFEST.md
3. 000_CODEX_WORK_SUMMARY.md
4. context/task.md
5. context/git-status.txt
6. context/git-diff-stat.txt and context/git-staged-diff-stat.txt
7. context/git-diff.patch and context/git-staged-diff.patch
8. source/, artifacts/, and evidence/ as needed

## Included Files

| Package path | Category | Source path | Bytes | Safety |
| --- | --- | --- | ---: | --- |
$manifestIncluded

## Skipped Files

| Source path | Reason |
| --- | --- |
$manifestSkipped

## Git Context

- context/git-status.txt
- context/git-diff-stat.txt
- context/git-diff.patch
- context/git-staged-diff-stat.txt
- context/git-staged-diff.patch
- context/recent-commits.txt

## Safety Notes

Secret-like paths were skipped by default. Secret-like text content in included files was redacted before packaging. The package should still be reviewed before external upload.

## Reviewer Next Step

Use 000_REVIEW_PROMPT.md as the response contract. Mark missing evidence as unsupported or uncertain.
"@

if (Test-Path -LiteralPath $OutputPath) { Remove-Item -LiteralPath $OutputPath -Force }
Compress-Archive -Path (Join-Path $workRoot "*") -DestinationPath $OutputPath -Force

if ($CopyPromptToClipboard) {
    Set-Clipboard -Value $reviewPrompt
}

Write-Host "Created pro review package: $OutputPath"
Write-Host "Included files: $($included.Count)"
Write-Host "Skipped files: $($skipped.Count)"
Write-Host "Upload manually if browser upload is blocked, then ask the reviewer to read 000_READ_ME_FIRST.txt first."

# Claude Statusline Installer for Windows
# Run: irm https://raw.githubusercontent.com/bartleby/claude-statusline/main/windows/install.ps1 | iex

$ErrorActionPreference = "Stop"

$RepoUrl = "https://raw.githubusercontent.com/bartleby/claude-statusline/main/windows"
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$ScriptsDir = Join-Path $ClaudeDir "scripts"
$HooksDir = Join-Path $ClaudeDir "hooks"
$SkillsDir = Join-Path $ClaudeDir "skills" "skin"

Write-Host ""
Write-Host "Installing Claude Statusline for Windows..." -ForegroundColor Cyan
Write-Host ""

# Create directories
New-Item -ItemType Directory -Force -Path $ScriptsDir | Out-Null
New-Item -ItemType Directory -Force -Path $HooksDir | Out-Null
New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null

# Download scripts
$scripts = @(
    "context-bar.py",
    "themes.py",
    "claude-skin.py",
    "update-usage-cache.py",
    "skin-hook.py"
)

foreach ($script in $scripts) {
    $url = "$RepoUrl/$script"
    $dest = Join-Path $ScriptsDir $script
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        Write-Host "  Downloaded: $script" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed to download: $script" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Scripts installed to $ScriptsDir" -ForegroundColor Green

# Create batch wrapper scripts (Windows doesn't expand ~ in commands)
$contextBarBat = Join-Path $ScriptsDir "context-bar.bat"
$skinHookBat = Join-Path $ScriptsDir "skin-hook.bat"
$claudeSkinBat = Join-Path $ScriptsDir "claude-skin.bat"

Set-Content -Path $contextBarBat -Value "@echo off`nchcp 65001 >nul 2>&1`nset PYTHONIOENCODING=utf-8`npython `"%USERPROFILE%\.claude\scripts\context-bar.py`" %*" -Encoding ASCII
Set-Content -Path $skinHookBat -Value "@echo off`nchcp 65001 >nul 2>&1`nset PYTHONIOENCODING=utf-8`npython `"%USERPROFILE%\.claude\scripts\skin-hook.py`" %*" -Encoding ASCII
Set-Content -Path $claudeSkinBat -Value "@echo off`nchcp 65001 >nul 2>&1`nset PYTHONIOENCODING=utf-8`npython `"%USERPROFILE%\.claude\scripts\claude-skin.py`" %*" -Encoding ASCII

Write-Host "Batch wrappers created" -ForegroundColor Green

# Create skill definition for /skin command visibility in menu
$skillLines = @(
    "---",
    "name: skin",
    "description: Apply a skin/theme to Claude Code statusline",
    "command: %USERPROFILE%\.claude\scripts\claude-skin.bat",
    "user-invocable: true",
    "---",
    "",
    "Apply a skin theme. Run without arguments to see gallery, or with skin name to apply."
)
$skillContent = $skillLines -join "`n"

$skillFile = Join-Path $SkillsDir "SKILL.md"
Set-Content -Path $skillFile -Value $skillContent -Encoding UTF8
Write-Host "Skill installed to $SkillsDir" -ForegroundColor Green

# Update settings.json
$settingsFile = Join-Path $ClaudeDir "settings.json"

$newSettings = @{
    statusLine = @{
        type = "command"
        command = "%USERPROFILE%\.claude\scripts\context-bar.bat"
    }
    hooks = @{
        UserPromptSubmit = @(
            @{
                matcher = ""
                hooks = @(
                    @{
                        type = "command"
                        command = "%USERPROFILE%\.claude\scripts\skin-hook.bat"
                    }
                )
            }
        )
    }
}

if (Test-Path $settingsFile) {
    try {
        $existingSettings = Get-Content $settingsFile -Raw | ConvertFrom-Json -AsHashtable

        # Check if already configured
        $alreadyConfigured = $false
        if ($existingSettings.statusLine -and $existingSettings.statusLine.command) {
            if ($existingSettings.statusLine.command -like "*context-bar*") {
                $alreadyConfigured = $true
            }
        }

        if ($alreadyConfigured) {
            Write-Host "Settings already configured" -ForegroundColor Green
        }
        else {
            # Merge settings
            $existingSettings.statusLine = $newSettings.statusLine

            # Merge hooks
            if (-not $existingSettings.hooks) {
                $existingSettings.hooks = @{}
            }
            if (-not $existingSettings.hooks.UserPromptSubmit) {
                $existingSettings.hooks.UserPromptSubmit = @()
            }

            # Check if hook already exists
            $hookExists = $false
            foreach ($hookGroup in $existingSettings.hooks.UserPromptSubmit) {
                if ($hookGroup.hooks) {
                    foreach ($hook in $hookGroup.hooks) {
                        if ($hook.command -like "*skin-hook*") {
                            $hookExists = $true
                            break
                        }
                    }
                }
                if ($hookExists) { break }
            }

            if (-not $hookExists) {
                $existingSettings.hooks.UserPromptSubmit += $newSettings.hooks.UserPromptSubmit[0]
            }

            $existingSettings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
            Write-Host "Settings updated at $settingsFile" -ForegroundColor Green
        }
    }
    catch {
        Write-Host ""
        Write-Host "NOTE: Could not automatically update settings.json" -ForegroundColor Yellow
        Write-Host "Please add this to your $settingsFile manually:" -ForegroundColor Yellow
        Write-Host ""
        $newSettings | ConvertTo-Json -Depth 10
        Write-Host ""
    }
}
else {
    # Create new settings file
    $newSettings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
    Write-Host "Settings created at $settingsFile" -ForegroundColor Green
}

# Set default skin
$skinFile = Join-Path $ClaudeDir "current_skin"
if (-not (Test-Path $skinFile)) {
    Set-Content -Path $skinFile -Value "kratos" -NoNewline
    Write-Host "Default skin set to 'kratos'" -ForegroundColor Green
}

# Check Python availability
Write-Host ""
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Python found: $pythonVersion" -ForegroundColor Green
}
catch {
    Write-Host "WARNING: Python not found in PATH" -ForegroundColor Yellow
    Write-Host "Please install Python from https://python.org or Microsoft Store" -ForegroundColor Yellow
}

# Check for keyring package (optional, for rate limits)
Write-Host ""
Write-Host "Installing optional dependency for rate limits..." -ForegroundColor Cyan
try {
    python -m pip install --quiet keyring 2>$null
    Write-Host "keyring package installed (for rate limits)" -ForegroundColor Green
}
catch {
    Write-Host "NOTE: 'keyring' package not installed. Rate limits will show '?'" -ForegroundColor Yellow
    Write-Host "To install: pip install keyring" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Usage:" -ForegroundColor White
Write-Host "  /skin          - show available skins" -ForegroundColor Gray
Write-Host "  /skin <name>   - apply a skin" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Shift+Tab to refresh statusline after applying a skin." -ForegroundColor Gray
Write-Host ""
Write-Host "Restart Claude Code to activate the statusline." -ForegroundColor Yellow
Write-Host ""

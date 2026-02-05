# Claude Statusline Uninstaller for Windows
# Run: irm https://raw.githubusercontent.com/bartleby/claude-statusline/main/windows/uninstall.ps1 | iex

$ErrorActionPreference = "SilentlyContinue"

$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$ScriptsDir = Join-Path $ClaudeDir "scripts"
$SkillsDir = Join-Path $ClaudeDir "skills" "skin"

Write-Host ""
Write-Host "Uninstalling Claude Statusline..." -ForegroundColor Cyan
Write-Host ""

# Remove scripts
if (Test-Path $ScriptsDir) {
    $scripts = @("context-bar.py", "themes.py", "claude-skin.py", "update-usage-cache.py", "skin-hook.py")
    foreach ($script in $scripts) {
        $path = Join-Path $ScriptsDir $script
        if (Test-Path $path) {
            Remove-Item -Force $path
            Write-Host "  Removed: $script" -ForegroundColor Green
        }
    }
}

# Remove skill
if (Test-Path $SkillsDir) {
    Remove-Item -Recurse -Force $SkillsDir
    Write-Host "  Removed: skills/skin/" -ForegroundColor Green
}

# Remove config files
$configFiles = @("current_skin", "usage_cache")
foreach ($file in $configFiles) {
    $path = Join-Path $ClaudeDir $file
    if (Test-Path $path) {
        Remove-Item -Force $path
        Write-Host "  Removed: $file" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Uninstallation complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "NOTE: settings.json was not modified." -ForegroundColor Yellow
Write-Host "To complete uninstallation, manually remove:" -ForegroundColor Yellow
Write-Host "  - statusLine section from settings.json" -ForegroundColor Gray
Write-Host "  - skin-hook entry from hooks.UserPromptSubmit" -ForegroundColor Gray
Write-Host ""

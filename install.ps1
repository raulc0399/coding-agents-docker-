#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ScriptDir = Split-Path -Parent (Resolve-Path $PSCommandPath)

# Add ScriptDir to PATH for this session
if ($env:PATH -notlike "*$ScriptDir*") {
  $env:PATH = "$ScriptDir;$env:PATH"
}

# Persist to user PATH in registry
$userPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
if ($userPath -notlike "*$ScriptDir*") {
  [System.Environment]::SetEnvironmentVariable('PATH', "$ScriptDir;$userPath", 'User')
  Write-Host "Added $ScriptDir to user PATH."
} else {
  Write-Host "$ScriptDir is already in user PATH."
}

Write-Host ""
Write-Host "Done. You can now run d_claude.ps1, d_codex.ps1, d_copilot.ps1, rebuild_containers.ps1 from any directory."
Write-Host "Note: open a new terminal for the PATH change to take effect in other sessions."

param(
  [switch]$SkipInstall
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$lab = Join-Path $root 'emulator_rules_lab'
$tmp = Join-Path $root '.codex_tmp'

New-Item -ItemType Directory -Force `
  (Join-Path $tmp 'firebase-config'), `
  (Join-Path $tmp 'firebase-home'), `
  (Join-Path $tmp 'npm-cache') | Out-Null

$env:XDG_CONFIG_HOME = Join-Path $tmp 'firebase-config'
$env:HOME = Join-Path $tmp 'firebase-home'
$env:USERPROFILE = Join-Path $tmp 'firebase-home'
$env:npm_config_cache = Join-Path $tmp 'npm-cache'

function Invoke-CheckedCommand {
  param(
    [Parameter(Mandatory = $true)][string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
  )

  & $Command @Arguments
  $exitCode = $LASTEXITCODE
  if ($exitCode -ne 0) {
    throw "Command failed with exit code ${exitCode}: $Command $($Arguments -join ' ')"
  }
}

Push-Location $lab
try {
  if (-not $SkipInstall) {
    if (Test-Path package-lock.json) {
      Invoke-CheckedCommand npm ci
    } else {
      Invoke-CheckedCommand npm install
    }
  }

  Invoke-CheckedCommand npm run test:rules
} finally {
  Pop-Location
}

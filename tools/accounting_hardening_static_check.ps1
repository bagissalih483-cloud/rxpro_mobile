param(
  [string]$Root = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"

function Assert-Contains {
  param(
    [string]$Path,
    [string]$Pattern,
    [string]$Message
  )

  $fullPath = Join-Path $Root $Path
  if (-not (Test-Path $fullPath)) {
    throw "Missing file: $Path"
  }

  $content = Get-Content -LiteralPath $fullPath -Raw
  if ($content -notmatch $Pattern) {
    throw $Message
  }
}

Assert-Contains `
  -Path "functions\modules\accounting.js" `
  -Pattern "accountingEnsureAppointmentAdisyon" `
  -Message "Missing appointment -> adisyon callable."

Assert-Contains `
  -Path "functions\modules\accounting.js" `
  -Pattern "accountingProcessSale" `
  -Message "Missing sale processing callable."

Assert-Contains `
  -Path "functions\modules\accounting.js" `
  -Pattern "accountingCollectInstallmentPayment" `
  -Message "Missing installment collection callable."

Assert-Contains `
  -Path "functions\modules\accounting.js" `
  -Pattern "accountingRefundSale" `
  -Message "Missing refund callable."

Assert-Contains `
  -Path "infra\rules\firestore.rules" `
  -Pattern "serverManagedAccountingCollection" `
  -Message "Missing server-managed accounting rules guard."

Assert-Contains `
  -Path "lib\features\accounting\services\appointment_adisyon_service.dart" `
  -Pattern "accountingEnsureAppointmentAdisyon" `
  -Message "Appointment adisyon service is not using callable flow."

$accountingSource = Get-ChildItem -Path (Join-Path $Root "lib\features\accounting") -Recurse -File -Include "*.dart"
$unsafeWrites = $accountingSource |
  Select-String -Pattern "transaction\.set\(|\.set\(|\.add\(" |
  Where-Object {
    $_.Line -match "accountingSales|accountingPayments|accountingReceivables|accountingInstallments|accountingRefunds|AccountingFirestorePaths\.(sale|sales|payment|payments|receivable|receivables|installment|installments)"
  }

if ($unsafeWrites) {
  $unsafeWrites | ForEach-Object {
    Write-Host "$($_.Path):$($_.LineNumber): $($_.Line.Trim())"
  }
  throw "Unsafe client-side accounting write candidate found."
}

Write-Host "Accounting hardening static check passed."

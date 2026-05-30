param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "== RxPro public data matrix check =="

$failures = @()

function Add-Failure($Message) {
  $script:failures += $Message
}

$matrixPath = Join-Path $root 'docs\PUBLIC_DATA_MATRIX.md'
$firestoreRulesPath = Join-Path $root 'infra\rules\firestore.rules'
$storageRulesPath = Join-Path $root 'infra\rules\storage.rules'

foreach ($path in @($matrixPath, $firestoreRulesPath, $storageRulesPath)) {
  if (-not (Test-Path -LiteralPath $path)) {
    Add-Failure "$path is missing."
  }
}

if ($failures.Count -eq 0) {
  $matrix = Get-Content -LiteralPath $matrixPath -Raw
  $firestoreRules = Get-Content -LiteralPath $firestoreRulesPath -Raw
  $storageRules = Get-Content -LiteralPath $storageRulesPath -Raw

  $expectedFirestorePublic = @(
    'publicProfiles',
    'businesses',
    'businessProfiles',
    'registeredBusinesses',
    'businessPlaceIndex',
    'directory_pois_google_cache',
    'placeQueryBuckets',
    'businessServices',
    'businessProfilePosts',
    'businessStories',
    'businessCampaigns',
    'campaigns',
    'businessReviews',
    'businessRatings'
  )

  $expectedStoragePublic = @(
    'business_logos',
    'business_covers',
    'business_intro',
    'user_profiles',
    'business_stories',
    'business_campaigns'
  )

  foreach ($collection in $expectedFirestorePublic) {
    if ($matrix -notmatch [regex]::Escape($collection)) {
      Add-Failure "docs/PUBLIC_DATA_MATRIX.md does not document Firestore collection $collection."
    }
    if ($firestoreRules -notmatch [regex]::Escape("`"$collection`"") -and
        $firestoreRules -notmatch "match\s+/$([regex]::Escape($collection))/") {
      Add-Failure "infra/rules/firestore.rules does not contain expected public collection $collection."
    }
  }

  foreach ($path in $expectedStoragePublic) {
    if ($matrix -notmatch [regex]::Escape($path)) {
      Add-Failure "docs/PUBLIC_DATA_MATRIX.md does not document Storage path $path."
    }
    if ($storageRules -notmatch "match\s+/$([regex]::Escape($path))/") {
      Add-Failure "infra/rules/storage.rules does not contain expected public Storage path $path."
    }
  }

  $explicitPublicFirestore = New-Object System.Collections.Generic.HashSet[string]
  $currentCollection = $null
  foreach ($line in Get-Content -LiteralPath $firestoreRulesPath) {
    if ($line -match '^\s*match\s+/([A-Za-z0-9_]+)/\{') {
      $currentCollection = $Matches[1]
    }
    if ($line -match 'allow\s+read:\s+if\s+true;' -and $currentCollection) {
      [void]$explicitPublicFirestore.Add($currentCollection)
    }
  }

  foreach ($collection in $explicitPublicFirestore) {
    if ($expectedFirestorePublic -notcontains $collection) {
      Add-Failure "Firestore collection $collection has allow read: if true but is not in PUBLIC_DATA_MATRIX.md expected list."
    }
  }

  $explicitPublicStorage = New-Object System.Collections.Generic.HashSet[string]
  $currentStoragePath = $null
  foreach ($line in Get-Content -LiteralPath $storageRulesPath) {
    if ($line -match '^\s*match\s+/([A-Za-z0-9_]+)/') {
      $currentStoragePath = $Matches[1]
    }
    if ($line -match 'allow\s+read:\s+if\s+true;' -and $currentStoragePath) {
      [void]$explicitPublicStorage.Add($currentStoragePath)
    }
  }

  foreach ($path in $explicitPublicStorage) {
    if ($expectedStoragePublic -notcontains $path) {
      Add-Failure "Storage path $path has allow read: if true but is not in PUBLIC_DATA_MATRIX.md expected list."
    }
  }

  $requiredForbiddenTerms = @(
    'ownerEmail',
    'customerEmail',
    'ownerPhone',
    'customerPhone',
    'balance',
    'revenue',
    'iban',
    'taxNumber',
    'internalNotes',
    'privateNotes'
  )

  foreach ($term in $requiredForbiddenTerms) {
    if ($matrix -notmatch [regex]::Escape($term) -and
        $firestoreRules -notmatch [regex]::Escape("`"$term`"")) {
      Add-Failure "Forbidden public-data term $term is not documented or enforced."
    }
  }

  if (Test-Path -LiteralPath (Join-Path $root 'lib\core\businesses\google_places_directory_service.dart')) {
    Add-Failure 'Live Google Places directory service still exists in lib/core/businesses.'
  }

  foreach ($relativePath in @(
    'tools\check_places_function.ps1',
    'tools\set_places_secret_from_file.ps1',
    'functions\scripts\seedGooglePlacesDirectoryIndex.js'
  )) {
    if (Test-Path -LiteralPath (Join-Path $root $relativePath)) {
      Add-Failure "$relativePath still enables live Google Places operations."
    }
  }

  $functionsIndexPath = Join-Path $root 'functions\index.js'
  if (Test-Path -LiteralPath $functionsIndexPath) {
    $functionsIndex = Get-Content -LiteralPath $functionsIndexPath -Raw
    if ($functionsIndex -notmatch 'enablePlacesDirectorySearch\s*:\s*false') {
      Add-Failure 'functions/index.js must keep enablePlacesDirectorySearch: false for the registered-only/imported-directory strategy.'
    }
  }
}

if ($failures.Count -gt 0) {
  Write-Host "Public data matrix blockers:" -ForegroundColor Yellow
  foreach ($failure in $failures) {
    Write-Host " - $failure" -ForegroundColor Yellow
  }
  Write-Error "Public data matrix check failed with $($failures.Count) blocker(s)."
}

Write-Host "Public data matrix check completed."

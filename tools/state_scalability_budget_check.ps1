param(
  [int]$MaxTotalSetState = 0,
  [int]$MaxMainShellSetState = 0,
  [int]$MaxHomeExploreSetState = 0,
  [int]$MaxBusinessProfileEditSetState = 0,
  [int]$MaxStaffInviteSetState = 0,
  [int]$MaxBusinessStaffFormSetState = 0,
  [int]$MaxBusinessFinanceSetState = 0,
  [int]$MaxCampaignAiCreateSetState = 0,
  [int]$MaxBusinessCampaignsSetState = 0,
  [int]$MaxCustomerCampaignsSetState = 0,
  [int]$MaxBulkMessageCreateSetState = 0,
  [int]$MaxBusinessAnalysisSetState = 0,
  [int]$MaxBusinessProductMovementSetState = 0,
  [int]$MaxBusinessProfileBookingSetState = 0,
  [int]$MaxBusinessCustomersSetState = 0,
  [int]$MaxBusinessProductsSetState = 0,
  [int]$MaxBusinessServicesManageSetState = 0,
  [int]$MaxBusinessCategoryRequiredSetState = 0,
  [int]$MaxRegisteredBusinessesSetState = 0,
  [int]$MaxBusinessProfileEditEntrySetState = 0,
  [int]$MaxBusinessAccountingShellSetState = 0,
  [int]$MaxAccountingSalesSetState = 0,
  [int]$MaxAccountingExpensesSetState = 0,
  [int]$MaxAccountEntryLiteSetState = 0,
  [int]$MaxAccountEntrySetState = 0,
  [int]$MaxAccountDeletionRequestSetState = 0,
  [int]$MaxPhonePasswordResetFlowSetState = 0,
  [int]$MaxBusinessStoryCreateSetState = 0,
  [int]$MaxFixLoginGateSetState = 0,
  [int]$MaxBusinessProfileReviewsSetState = 0,
  [int]$MaxBusinessProfilePostInteractionSetState = 0,
  [int]$MaxAppointmentEntrySetState = 0,
  [int]$MaxAppointmentManualSheetSetState = 0,
  [int]$MaxCustomerAppointmentsSetState = 0,
  [int]$MaxBusinessProfilePostCreateSetState = 0,
  [int]$MaxHomeExploreRouteDistanceChipSetState = 0,
  [int]$MaxNotificationPreferencesSetState = 0,
  [int]$MaxFavoriteFeedSetState = 0,
  [int]$MaxMessagesInboxSetState = 0,
  [int]$MaxBusinessCustomerDirectMessageSetState = 0,
  [int]$MaxAdminModerationSetState = 0,
  [int]$MaxAccountingReportsSetState = 0,
  [int]$MaxAccountingReceivablesSetState = 0,
  [int]$MaxAccountingOverviewPanelSetState = 0,
  [int]$MaxBusinessStoryViewerSetState = 0,
  [int]$MaxFixBootstrapSetState = 0,
  [int]$MaxRoleGateShellSetState = 0,
  [int]$MaxStaffWorkspaceSetState = 0,
  [int]$MaxBusinessProfileSetState = 0,
  [int]$MaxHomeExploreAsyncBuilders = 2,
  [int]$MaxStarterDirectoryCap = 300,
  [int]$MaxNearbyCollectionLimit = 120,
  [switch]$WarnOnly
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "== RxPro state and scalability budget check =="

function Get-RepoTextMatches {
  param(
    [Parameter(Mandatory = $true)][string[]]$Paths,
    [Parameter(Mandatory = $true)][string]$Pattern
  )

  $matches = @()
  foreach ($path in $Paths) {
    if (-not (Test-Path $path)) { continue }
    $matches += Get-ChildItem -Path $path -Recurse -Filter *.dart -File |
      Where-Object {
        $_.FullName -notmatch '\\build\\' -and
        $_.FullName -notmatch '\\SourcePackages\\' -and
        $_.FullName -notmatch '\\.dart_tool\\'
      } |
      Select-String -Pattern $Pattern
  }

  return @($matches)
}

function Assert-Budget {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][int]$Actual,
    [Parameter(Mandatory = $true)][int]$Maximum
  )

  Write-Host "${Name}: $Actual / $Maximum"
  if ($Actual -gt $Maximum) {
    if (-not $WarnOnly) {
      throw "$Name exceeded budget: $Actual > $Maximum"
    }
  }
}

$setStateMatches = Get-RepoTextMatches -Paths @('lib') -Pattern 'setState\('
Assert-Budget `
  -Name 'Total setState calls in lib' `
  -Actual $setStateMatches.Count `
  -Maximum $MaxTotalSetState

$mainShellPath = 'lib\app\main_shells.dart'
$mainShellSetState = @(
  Select-String -Path $mainShellPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Main shell setState calls' `
  -Actual $mainShellSetState.Count `
  -Maximum $MaxMainShellSetState

$homeExplorePath = 'lib\features\public_home\home_explore_page.dart'
$homeExploreSetState = @(
  Select-String -Path $homeExplorePath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Home explore page setState calls' `
  -Actual $homeExploreSetState.Count `
  -Maximum $MaxHomeExploreSetState

$businessProfileEditPath = 'lib\features\business\pages\business_profile_edit_page.dart'
$businessProfileEditSetState = @(
  Select-String -Path $businessProfileEditPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business profile edit page setState calls' `
  -Actual $businessProfileEditSetState.Count `
  -Maximum $MaxBusinessProfileEditSetState

$staffInvitePath = 'lib\features\staff_invites\staff_invite_code_page.dart'
$staffInviteSetState = @(
  Select-String -Path $staffInvitePath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Staff invite code page setState calls' `
  -Actual $staffInviteSetState.Count `
  -Maximum $MaxStaffInviteSetState

$businessStaffFormPath = 'lib\features\businesses\presentation\pages\business_staff_form_page.dart'
$businessStaffFormSetState = @(
  Select-String -Path $businessStaffFormPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business staff form page setState calls' `
  -Actual $businessStaffFormSetState.Count `
  -Maximum $MaxBusinessStaffFormSetState

$businessFinancePath = 'lib\features\businesses\presentation\pages\business_finance_page.dart'
$businessFinanceSetState = @(
  Select-String -Path $businessFinancePath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business finance page setState calls' `
  -Actual $businessFinanceSetState.Count `
  -Maximum $MaxBusinessFinanceSetState

$campaignAiCreatePath = 'lib\features\campaigns\campaign_ai_create_safe_page.dart'
$campaignAiCreateSetState = @(
  Select-String -Path $campaignAiCreatePath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Campaign AI create page setState calls' `
  -Actual $campaignAiCreateSetState.Count `
  -Maximum $MaxCampaignAiCreateSetState

$businessCampaignsPath = 'lib\features\campaigns\business_campaigns_page.dart'
$businessCampaignsSetState = @(
  Select-String -Path $businessCampaignsPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business campaigns page setState calls' `
  -Actual $businessCampaignsSetState.Count `
  -Maximum $MaxBusinessCampaignsSetState

$customerCampaignsPath = 'lib\features\campaigns\customer_campaigns_page.dart'
$customerCampaignsSetState = @(
  Select-String -Path $customerCampaignsPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Customer campaigns page setState calls' `
  -Actual $customerCampaignsSetState.Count `
  -Maximum $MaxCustomerCampaignsSetState

$bulkMessageCreatePath = 'lib\features\campaigns\bulk_message_create_page.dart'
$bulkMessageCreateSetState = @(
  Select-String -Path $bulkMessageCreatePath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Bulk message create page setState calls' `
  -Actual $bulkMessageCreateSetState.Count `
  -Maximum $MaxBulkMessageCreateSetState

$businessAnalysisPath = 'lib\features\business_analysis\presentation\pages\business_analysis_page.dart'
$businessAnalysisSetState = @(
  Select-String -Path $businessAnalysisPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business analysis page setState calls' `
  -Actual $businessAnalysisSetState.Count `
  -Maximum $MaxBusinessAnalysisSetState

$businessProductMovementPath = 'lib\features\business_analysis\presentation\pages\business_product_movement_page.dart'
$businessProductMovementSetState = @(
  Select-String -Path $businessProductMovementPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business product movement page setState calls' `
  -Actual $businessProductMovementSetState.Count `
  -Maximum $MaxBusinessProductMovementSetState

$businessProfileBookingPath = 'lib\features\businesses\presentation\widgets\business_profile_booking_part.dart'
$businessProfileBookingSetState = @(
  Select-String -Path $businessProfileBookingPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business profile booking part setState calls' `
  -Actual $businessProfileBookingSetState.Count `
  -Maximum $MaxBusinessProfileBookingSetState

$businessCustomersPath = 'lib\features\businesses\business_customers_page.dart'
$businessCustomersSetState = @(
  Select-String -Path $businessCustomersPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business customers page setState calls' `
  -Actual $businessCustomersSetState.Count `
  -Maximum $MaxBusinessCustomersSetState

$businessProductsPath = 'lib\features\businesses\business_products_page.dart'
$businessProductsSetState = @(
  Select-String -Path $businessProductsPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business products page setState calls' `
  -Actual $businessProductsSetState.Count `
  -Maximum $MaxBusinessProductsSetState

$businessServicesManagePath = 'lib\features\businesses\business_services_manage_page.dart'
$businessServicesManageSetState = @(
  Select-String -Path $businessServicesManagePath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business services manage page setState calls' `
  -Actual $businessServicesManageSetState.Count `
  -Maximum $MaxBusinessServicesManageSetState

$businessCategoryRequiredPath = 'lib\features\businesses\business_category_required_page.dart'
$businessCategoryRequiredSetState = @(
  Select-String -Path $businessCategoryRequiredPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business category required page setState calls' `
  -Actual $businessCategoryRequiredSetState.Count `
  -Maximum $MaxBusinessCategoryRequiredSetState

$registeredBusinessesPath = 'lib\features\businesses\registered_businesses_page.dart'
$registeredBusinessesSetState = @(
  Select-String -Path $registeredBusinessesPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Registered businesses page setState calls' `
  -Actual $registeredBusinessesSetState.Count `
  -Maximum $MaxRegisteredBusinessesSetState

$businessProfileEditEntryPath = 'lib\features\business\pages\business_profile_edit_entry_page.dart'
$businessProfileEditEntrySetState = @(
  Select-String -Path $businessProfileEditEntryPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business profile edit entry page setState calls' `
  -Actual $businessProfileEditEntrySetState.Count `
  -Maximum $MaxBusinessProfileEditEntrySetState

$businessAccountingShellPath = 'lib\features\accounting\business_accounting_shell.dart'
$businessAccountingShellSetState = @(
  Select-String -Path $businessAccountingShellPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business accounting shell setState calls' `
  -Actual $businessAccountingShellSetState.Count `
  -Maximum $MaxBusinessAccountingShellSetState

$accountingSalesPath = 'lib\features\accounting\presentation\pages\accounting_sales_page.dart'
$accountingSalesSetState = @(
  Select-String -Path $accountingSalesPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Accounting sales page setState calls' `
  -Actual $accountingSalesSetState.Count `
  -Maximum $MaxAccountingSalesSetState

$accountingExpensesPath = 'lib\features\accounting\pages\accounting_expenses_page.dart'
$accountingExpensesSetState = @(
  Select-String -Path $accountingExpensesPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Accounting expenses page setState calls' `
  -Actual $accountingExpensesSetState.Count `
  -Maximum $MaxAccountingExpensesSetState

$accountEntryLitePath = 'lib\features\public_home\presentation\pages\account_entry_lite_pages.dart'
$accountEntryLiteSetState = @(
  Select-String -Path $accountEntryLitePath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Account entry lite pages setState calls' `
  -Actual $accountEntryLiteSetState.Count `
  -Maximum $MaxAccountEntryLiteSetState

$accountEntryPath = 'lib\features\public_home\presentation\pages\account_entry_page.dart'
$accountEntrySetState = @(
  Select-String -Path $accountEntryPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Account entry page setState calls' `
  -Actual $accountEntrySetState.Count `
  -Maximum $MaxAccountEntrySetState

$accountDeletionRequestPath = 'lib\features\legal\account_deletion_request_page.dart'
$accountDeletionRequestSetState = @(
  Select-String -Path $accountDeletionRequestPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Account deletion request page setState calls' `
  -Actual $accountDeletionRequestSetState.Count `
  -Maximum $MaxAccountDeletionRequestSetState

$phonePasswordResetFlowPath = 'lib\features\auth\presentation\pages\phone_password_reset_flow_page.dart'
$phonePasswordResetFlowSetState = @(
  Select-String -Path $phonePasswordResetFlowPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Phone password reset flow page setState calls' `
  -Actual $phonePasswordResetFlowSetState.Count `
  -Maximum $MaxPhonePasswordResetFlowSetState

$businessStoryCreatePath = 'lib\features\stories\business_story_create_page.dart'
$businessStoryCreateSetState = @(
  Select-String -Path $businessStoryCreatePath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business story create page setState calls' `
  -Actual $businessStoryCreateSetState.Count `
  -Maximum $MaxBusinessStoryCreateSetState

$fixLoginGatePath = 'lib\features\auth\presentation\pages\fix_login_gate_page.dart'
$fixLoginGateSetState = @(
  Select-String -Path $fixLoginGatePath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Fix login gate page setState calls' `
  -Actual $fixLoginGateSetState.Count `
  -Maximum $MaxFixLoginGateSetState

$businessProfileReviewsPath = 'lib\features\businesses\presentation\widgets\business_profile_reviews_part.dart'
$businessProfileReviewsSetState = @(
  Select-String -Path $businessProfileReviewsPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business profile reviews part setState calls' `
  -Actual $businessProfileReviewsSetState.Count `
  -Maximum $MaxBusinessProfileReviewsSetState

$businessProfilePostInteractionPath = 'lib\features\business\widgets\business_profile_post_interactive_card.dart'
$businessProfilePostInteractionSetState = @(
  Select-String -Path $businessProfilePostInteractionPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business profile post interaction card setState calls' `
  -Actual $businessProfilePostInteractionSetState.Count `
  -Maximum $MaxBusinessProfilePostInteractionSetState

$appointmentEntryPath = 'lib\features\appointments\presentation\pages\appointment_entry_page.dart'
$appointmentEntrySetState = @(
  Select-String -Path $appointmentEntryPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Appointment entry page setState calls' `
  -Actual $appointmentEntrySetState.Count `
  -Maximum $MaxAppointmentEntrySetState

$appointmentManualSheetPath = 'lib\features\appointments\presentation\pages\appointment_entry_manual_sheet.dart'
$appointmentManualSheetSetState = @(
  Select-String -Path $appointmentManualSheetPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Appointment manual sheet setState calls' `
  -Actual $appointmentManualSheetSetState.Count `
  -Maximum $MaxAppointmentManualSheetSetState

$customerAppointmentsPath = 'lib\features\appointments\presentation\pages\customer_appointments_page.dart'
$customerAppointmentsSetState = @(
  Select-String -Path $customerAppointmentsPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Customer appointments page setState calls' `
  -Actual $customerAppointmentsSetState.Count `
  -Maximum $MaxCustomerAppointmentsSetState

$businessProfilePostCreatePath = 'lib\features\business\pages\business_profile_post_create_page.dart'
$businessProfilePostCreateSetState = @(
  Select-String -Path $businessProfilePostCreatePath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business profile post create page setState calls' `
  -Actual $businessProfilePostCreateSetState.Count `
  -Maximum $MaxBusinessProfilePostCreateSetState

$homeExploreRouteDistanceChipPath = 'lib\features\public_home\presentation\widgets\home_explore_route_distance_chip.dart'
$homeExploreRouteDistanceChipSetState = @(
  Select-String -Path $homeExploreRouteDistanceChipPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Home explore route distance chip setState calls' `
  -Actual $homeExploreRouteDistanceChipSetState.Count `
  -Maximum $MaxHomeExploreRouteDistanceChipSetState

$notificationPreferencesPath = 'lib\features\notifications\presentation\notification_preferences_page.dart'
$notificationPreferencesSetState = @(
  Select-String -Path $notificationPreferencesPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Notification preferences page setState calls' `
  -Actual $notificationPreferencesSetState.Count `
  -Maximum $MaxNotificationPreferencesSetState

$favoriteFeedPath = 'lib\features\favorites\favorite_feed_page.dart'
$favoriteFeedSetState = @(
  Select-String -Path $favoriteFeedPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Favorite feed page setState calls' `
  -Actual $favoriteFeedSetState.Count `
  -Maximum $MaxFavoriteFeedSetState

$messagesInboxPath = 'lib\features\messages\messages_inbox_page.dart'
$messagesInboxSetState = @(
  Select-String -Path $messagesInboxPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Messages inbox page setState calls' `
  -Actual $messagesInboxSetState.Count `
  -Maximum $MaxMessagesInboxSetState

$businessCustomerDirectMessagePath = 'lib\features\businesses\presentation\pages\business_customer_direct_message_page.dart'
$businessCustomerDirectMessageSetState = @(
  Select-String -Path $businessCustomerDirectMessagePath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business customer direct message page setState calls' `
  -Actual $businessCustomerDirectMessageSetState.Count `
  -Maximum $MaxBusinessCustomerDirectMessageSetState

$adminModerationPath = 'lib\features\admin\presentation\admin_moderation_page.dart'
$adminModerationSetState = @(
  Select-String -Path $adminModerationPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Admin moderation page setState calls' `
  -Actual $adminModerationSetState.Count `
  -Maximum $MaxAdminModerationSetState

$accountingReportsPath = 'lib\features\accounting\pages\accounting_reports_page.dart'
$accountingReportsSetState = @(
  Select-String -Path $accountingReportsPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Accounting reports page setState calls' `
  -Actual $accountingReportsSetState.Count `
  -Maximum $MaxAccountingReportsSetState

$accountingReceivablesPath = 'lib\features\accounting\pages\accounting_receivables_page.dart'
$accountingReceivablesSetState = @(
  Select-String -Path $accountingReceivablesPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Accounting receivables page setState calls' `
  -Actual $accountingReceivablesSetState.Count `
  -Maximum $MaxAccountingReceivablesSetState

$accountingOverviewPanelPath = 'lib\features\accounting\presentation\widgets\accounting_overview_panel.dart'
$accountingOverviewPanelSetState = @(
  Select-String -Path $accountingOverviewPanelPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Accounting overview panel setState calls' `
  -Actual $accountingOverviewPanelSetState.Count `
  -Maximum $MaxAccountingOverviewPanelSetState

$businessStoryViewerPath = 'lib\features\stories\business_story_viewer_page.dart'
$businessStoryViewerSetState = @(
  Select-String -Path $businessStoryViewerPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business story viewer page setState calls' `
  -Actual $businessStoryViewerSetState.Count `
  -Maximum $MaxBusinessStoryViewerSetState

$fixBootstrapPath = 'lib\app\fix_bootstrap_app.dart'
$fixBootstrapSetState = @(
  Select-String -Path $fixBootstrapPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Fix bootstrap app setState calls' `
  -Actual $fixBootstrapSetState.Count `
  -Maximum $MaxFixBootstrapSetState

$roleGateShellPath = 'lib\app\role_gate_shell.dart'
$roleGateShellSetState = @(
  Select-String -Path $roleGateShellPath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Role gate shell setState calls' `
  -Actual $roleGateShellSetState.Count `
  -Maximum $MaxRoleGateShellSetState

$staffWorkspacePath = 'lib\features\businesses\staff_workspace_page.dart'
$staffWorkspaceSetState = @(
  Select-String -Path $staffWorkspacePath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Staff workspace page setState calls' `
  -Actual $staffWorkspaceSetState.Count `
  -Maximum $MaxStaffWorkspaceSetState

$businessProfilePath = 'lib\features\businesses\business_profile_page.dart'
$businessProfileSetState = @(
  Select-String -Path $businessProfilePath -Pattern 'setState\(' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Business profile page setState calls' `
  -Actual $businessProfileSetState.Count `
  -Maximum $MaxBusinessProfileSetState

$homeExploreAsyncBuilders = @(
  Select-String -Path $homeExplorePath -Pattern 'StreamBuilder|FutureBuilder' -ErrorAction SilentlyContinue
)
Assert-Budget `
  -Name 'Home explore page async builders' `
  -Actual $homeExploreAsyncBuilders.Count `
  -Maximum $MaxHomeExploreAsyncBuilders

$policyPath = 'lib\core\businesses\business_directory_query_budget_policy.dart'
if (-not (Test-Path $policyPath)) {
  if (-not $WarnOnly) {
    throw 'Business directory query budget policy is missing.'
  }
}

$policyText = Get-Content -Raw -Path $policyPath
$starterCapMatch = [regex]::Match($policyText, 'starterPageCap\s*=\s*(\d+)')
$nearbyLimitMatch = [regex]::Match($policyText, 'nearbyCollectionLimit\s*=\s*(\d+)')

if (-not $starterCapMatch.Success -or -not $nearbyLimitMatch.Success) {
  if (-not $WarnOnly) {
    throw 'Business directory query budget constants could not be read.'
  }
} else {
  Assert-Budget `
    -Name 'Starter directory Firestore page cap' `
    -Actual ([int]$starterCapMatch.Groups[1].Value) `
    -Maximum $MaxStarterDirectoryCap
  Assert-Budget `
    -Name 'Nearby directory Firestore per-collection limit' `
    -Actual ([int]$nearbyLimitMatch.Groups[1].Value) `
    -Maximum $MaxNearbyCollectionLimit
}

$cacheText = Get-Content -Raw -Path 'lib\core\businesses\business_directory_cache_service.dart'
if ($cacheText -match 'limit:\s*300' -or $cacheText -match '_businessPageCap\s*=\s*1000') {
  if (-not $WarnOnly) {
    throw 'Explore directory still contains legacy broad Firestore scan limits.'
  }
}

Write-Host "State and scalability budget check completed."

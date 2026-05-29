/// 50B Firestore Collections Foundation.
///
/// Bu dosya Firestore koleksiyon adlarını merkezi ve yazım hatasına kapalı
/// tutmak için oluşturuldu. İlk aşamada davranış değiştirmez; mevcut kodu
/// otomatik olarak bu sabitlere taşımaz.
abstract final class FirestoreCollections {
  FirestoreCollections._();

  static const users = 'users';
  static const usersPrivate = 'users_private';
  static const publicProfiles = 'publicProfiles';
  static const accountDeletionRequests = 'accountDeletionRequests';
  static const functionAbuseLogs = 'functionAbuseLogs';
  static const functionRateLimits = 'functionRateLimits';
  static const adminAuditLogs = 'adminAuditLogs';
  static const moderationBlocks = 'moderationBlocks';
  static const businesses = 'businesses';
  static const businessPlaceIndex = 'businessPlaceIndex';
  static const directoryPoisGoogleCache = 'directory_pois_google_cache';
  static const placeQueryBuckets = 'placeQueryBuckets';
  static const businessClaimRequests = 'businessClaimRequests';
  static const registeredBusinesses = 'registeredBusinesses';
  static const businessProfiles = 'businessProfiles';
  static const businessStaff = 'businessStaff';
  static const businessActivityLogs = 'businessActivityLogs';
  static const businessExpenses = 'businessExpenses';
  static const appointments = 'appointments';
  static const appointmentSlots = 'appointmentSlots';
  static const notifications = 'notifications';
  static const notificationPreferences = 'notificationPreferences';
  static const services = 'services';
  static const businessServices = 'businessServices';
  static const businessReviews = 'businessReviews';
  static const businessReviewReports = 'businessReviewReports';
  static const businessRatings = 'businessRatings';
  static const favorites = 'favorites';
  static const follows = 'follows';
  static const campaigns = 'campaigns';
  static const businessCampaigns = 'businessCampaigns';
  static const campaignReports = 'campaignReports';
  static const messages = 'messages';
  static const messageThreads = 'messageThreads';
  static const chats = 'chats';
  static const businessProfilePosts = 'businessProfilePosts';
  static const businessProducts = 'businessProducts';
  static const businessProductSales = 'businessProductSales';
  static const businessProductPurchases = 'businessProductPurchases';
  static const businessProfilePostReports = 'businessProfilePostReports';
  static const businessProfilePostLikes = 'businessProfilePostLikes';
  static const businessStories = 'businessStories';
  static const businessFollowers = 'businessFollowers';
  static const businessProfilePostSaves = 'businessProfilePostSaves';
  static const followedBusinesses = 'followedBusinesses';
  static const followingBusinesses = 'followingBusinesses';
  static const favoriteBusinesses = 'favoriteBusinesses';
  static const chatThreads = 'chatThreads';
  static const conversations = 'conversations';
  static const businessCustomerMessages = 'businessCustomerMessages';
  static const businessCustomers = 'businessCustomers';
  static const customerMessages = 'customerMessages';
  static const directMessages = 'directMessages';
  static const userMessages = 'userMessages';
  static const customerNotifications = 'customerNotifications';
  static const financeRecords = 'financeRecords';
  static const businessFinanceRecords = 'businessFinanceRecords';
  static const expenses = 'expenses';
  static const payments = 'payments';
  static const transactions = 'transactions';
  static const accountingSales = 'accountingSales';
  static const accountingPayments = 'accountingPayments';
  static const accountingReceivables = 'accountingReceivables';
  static const accountingExpenses = 'accountingExpenses';
  static const accountingRecurringExpenses = 'accountingRecurringExpenses';
  static const accountingReports = 'accountingReports';
}

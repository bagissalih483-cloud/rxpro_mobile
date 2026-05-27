import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:rxpro_mobile/core/firestore/firestore_schema_versions.dart';
import 'package:rxpro_mobile/features/messages/data/chat_repository.dart';

/// Messaging service foundation.
///
/// 51C-E foundation only:
/// - This service is NOT wired into UI yet.
/// - Existing MessagesInboxPage and BusinessAppointmentManagementPage behavior
///   remains unchanged.
/// - Existing mirror collection writes remain unchanged.
/// - Notification/push flow is not touched.
///
/// Future target:
/// UI -> MessagingService -> ChatRepository -> Firestore
class MessagingService {
  MessagingService({ChatRepository? chatRepository, Uuid? uuid})
    : _chatRepository = chatRepository ?? ChatRepository(),
      _uuid = uuid ?? const Uuid();

  final ChatRepository _chatRepository;
  final Uuid _uuid;

  /// Canonical 1:1 business-individual thread id.
  ///
  /// Uses stable, readable ids while avoiding UI-specific naming.
  /// Existing legacy thread ids are not migrated by this foundation patch.
  String buildBusinessIndividualThreadId({
    required String businessId,
    required String individualUid,
  }) {
    final cleanBusinessId = _cleanIdPart(businessId);
    final cleanIndividualUid = _cleanIdPart(individualUid);

    if (cleanBusinessId.isEmpty || cleanIndividualUid.isEmpty) {
      return '';
    }

    return 'business_${cleanBusinessId}_individual_$cleanIndividualUid';
  }

  /// Sends one canonical message into messageThreads/{threadId}/messages.
  ///
  /// Important:
  /// - This does not write to legacy mirror collections.
  /// - Existing UI flows are not calling this method yet.
  /// - When UI migration starts, legacy mirror preservation should be handled
  ///   explicitly and temporarily inside a migration-specific service method.
  Future<String> sendCanonicalBusinessIndividualMessage({
    required String businessId,
    required String individualUid,
    required String senderUid,
    required String senderRole,
    required String text,
    String businessName = '',
    String individualName = '',
    String customerUid = '',
    String customerName = '',
    String senderName = '',
    String receiverUid = '',
    String receiverRole = '',
    String topic = 'general',
    String messageType = 'text',
    String? threadId,
    String? messageId,
    String sourceModule = 'messaging_service_51C_E',
  }) async {
    final cleanBusinessId = businessId.trim();
    final cleanIndividualUid = individualUid.trim();
    final cleanText = text.trim();

    if (cleanBusinessId.isEmpty ||
        cleanIndividualUid.isEmpty ||
        senderUid.trim().isEmpty ||
        cleanText.isEmpty) {
      return '';
    }

    final effectiveThreadId = (threadId ?? '').trim().isNotEmpty
        ? threadId!.trim()
        : buildBusinessIndividualThreadId(
            businessId: cleanBusinessId,
            individualUid: cleanIndividualUid,
          );

    if (effectiveThreadId.isEmpty) {
      return '';
    }

    final effectiveMessageId = (messageId ?? '').trim().isNotEmpty
        ? messageId!.trim()
        : 'msg_${_uuid.v4()}';

    final effectiveCustomerUid = customerUid.trim().isNotEmpty
        ? customerUid.trim()
        : cleanIndividualUid;

    final effectiveCustomerName = customerName.trim().isNotEmpty
        ? customerName.trim()
        : individualName.trim();

    await _chatRepository.upsertThread(
      threadId: effectiveThreadId,
      businessId: cleanBusinessId,
      individualUid: cleanIndividualUid,
      businessName: businessName,
      individualName: individualName,
      customerUid: effectiveCustomerUid,
      customerName: effectiveCustomerName,
      topic: topic,
      status: 'open',
      sourceModule: sourceModule,
      extra: <String, dynamic>{
        'messagingServiceVersion':
            FirestoreSchemaVersions.messagingConstants51cC,
      },
    );

    await _chatRepository.addCanonicalMessage(
      threadId: effectiveThreadId,
      messageId: effectiveMessageId,
      senderUid: senderUid,
      senderRole: senderRole,
      text: cleanText,
      senderName: senderName,
      receiverUid: receiverUid,
      receiverRole: receiverRole,
      messageType: messageType,
      sourceModule: sourceModule,
      extra: <String, dynamic>{
        'messagingServiceVersion':
            FirestoreSchemaVersions.messagingConstants51cC,
      },
    );

    await _chatRepository.updateLastMessage(
      threadId: effectiveThreadId,
      text: cleanText,
      senderUid: senderUid,
      senderRole: senderRole,
      senderName: senderName,
      sourceModule: sourceModule,
      extra: <String, dynamic>{
        'messagingServiceVersion':
            FirestoreSchemaVersions.messagingConstants51cC,
      },
    );

    return effectiveMessageId;
  }

  Future<void> markThreadRead({
    required String threadId,
    required String uid,
    String sourceModule = 'messaging_service_51C_E',
  }) {
    return _chatRepository.markThreadReadForUid(
      threadId: threadId,
      uid: uid,
      sourceModule: sourceModule,
    );
  }

  Future<void> openThread({
    required String threadId,
    required String actorUid,
    String actorRole = '',
    String sourceModule = 'messaging_service_51C_E',
  }) {
    return _chatRepository.setThreadOpen(
      threadId: threadId,
      isOpen: true,
      actorUid: actorUid,
      actorRole: actorRole,
      sourceModule: sourceModule,
    );
  }

  Future<void> closeThread({
    required String threadId,
    required String actorUid,
    String actorRole = '',
    String sourceModule = 'messaging_service_51C_E',
  }) {
    return _chatRepository.setThreadOpen(
      threadId: threadId,
      isOpen: false,
      actorUid: actorUid,
      actorRole: actorRole,
      sourceModule: sourceModule,
    );
  }

  static String _cleanIdPart(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  /// 51C-L foundation for future BusinessAppointmentManagementPage migration.
  ///
  /// This helper is not wired into UI yet.
  ///
  /// It keeps migration options open:
  /// - canonical write through MessagingService/ChatRepository
  /// - optional legacy mirror writes via caller-provided write operations
  ///
  /// Existing UI behavior remains unchanged until a later exact migration patch.
  Future<String> sendBusinessCustomerMessageWithLegacyMirrors({
    required String businessId,
    required String businessName,
    required String customerUid,
    required String customerName,
    required String text,
    required String senderUid,
    required String senderRole,
    String senderName = '',
    String receiverRole = 'customer',
    String topic = 'business_customer',
    String? threadId,
    String? messageId,
    Iterable<Future<void> Function()> legacyMirrorWrites =
        const <Future<void> Function()>[],
    String sourceModule = 'messaging_service_51C_L',
  }) async {
    final resultMessageId = await sendCanonicalBusinessIndividualMessage(
      businessId: businessId,
      businessName: businessName,
      individualUid: customerUid,
      individualName: customerName,
      customerUid: customerUid,
      customerName: customerName,
      senderUid: senderUid,
      senderRole: senderRole,
      senderName: senderName,
      receiverUid: customerUid,
      receiverRole: receiverRole,
      text: text,
      threadId: threadId,
      messageId: messageId,
      topic: topic,
      sourceModule: sourceModule,
    );

    for (final write in legacyMirrorWrites) {
      await write();
    }

    return resultMessageId;
  }

  /// 51C-L safe utility for a future migration patch.
  ///
  /// It lets UI migration code preserve existing "try every mirror path"
  /// behavior without mixing migration decisions into page code.
  Future<int> runLegacyMirrorWritesSafely({
    required Iterable<Future<void> Function()> writes,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    var successCount = 0;

    for (final write in writes) {
      try {
        await write();
        successCount++;
      } catch (error, stackTrace) {
        onError?.call(error, stackTrace);
      }
    }

    return successCount;
  }

  /// 51C-L utility for future deterministic ids when old UI does not provide one.
  String createMessageId() => 'msg_${_uuid.v4()}';

  /// 51C-L utility for future migration payload compatibility.
  Map<String, dynamic> withServerUpdateStamp(Map<String, dynamic> data) {
    return <String, dynamic>{
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

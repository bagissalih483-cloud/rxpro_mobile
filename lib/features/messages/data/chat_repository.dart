import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/core/firestore/firestore_schema_versions.dart';

/// Messaging / chat repository foundation.
///
/// 51C-D foundation only:
/// - This repository is NOT wired into UI yet.
/// - Existing MessagesInboxPage and BusinessAppointmentManagementPage behavior
///   remains unchanged.
/// - Existing mirror collection writes remain unchanged.
/// - Notification/push flow is not touched.
///
/// Future target:
/// UI -> MessagingService -> ChatRepository -> Firestore
class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _threads =>
      _db.collection(FirestoreCollections.messageThreads);

  CollectionReference<Map<String, dynamic>> messagesRef(String threadId) =>
      _threads.doc(threadId).collection(FirestoreCollections.messages);

  DocumentReference<Map<String, dynamic>> threadRef(String threadId) =>
      _threads.doc(threadId);

  DocumentReference<Map<String, dynamic>> messageRef({
    required String threadId,
    required String messageId,
  }) => messagesRef(threadId).doc(messageId);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchThreadsForParticipant({
    required String participantId,
    int limit = 50,
  }) {
    final cleanParticipantId = participantId.trim();
    Query<Map<String, dynamic>> query = _threads;

    if (cleanParticipantId.isNotEmpty) {
      query = query.where(
        FirestoreFields.participantIds,
        arrayContains: cleanParticipantId,
      );
    }

    return query
        .orderBy(FirestoreFields.lastMessageAt, descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getThread(String threadId) {
    return threadRef(threadId.trim()).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchThread(String threadId) {
    return threadRef(threadId.trim()).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages({
    required String threadId,
    int limit = 100,
    bool descending = false,
  }) {
    return messagesRef(threadId.trim())
        .orderBy(FirestoreFields.createdAt, descending: descending)
        .limit(limit)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchMessages({
    required String threadId,
    int limit = 100,
    bool descending = false,
  }) {
    return messagesRef(threadId.trim())
        .orderBy(FirestoreFields.createdAt, descending: descending)
        .limit(limit)
        .get();
  }

  /// Creates/updates canonical thread document.
  ///
  /// Future UI migration should call this through MessagingService, not directly.
  Future<void> upsertThread({
    required String threadId,
    required String businessId,
    required String individualUid,
    String businessName = '',
    String individualName = '',
    String customerUid = '',
    String customerName = '',
    String topic = 'general',
    String status = 'open',
    String sourceModule = 'chat_repository_51C_D',
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    final cleanThreadId = threadId.trim();
    final cleanBusinessId = businessId.trim();
    final cleanIndividualUid = individualUid.trim();
    final cleanCustomerUid = customerUid.trim().isNotEmpty
        ? customerUid.trim()
        : cleanIndividualUid;

    final now = FieldValue.serverTimestamp();

    final data = <String, dynamic>{
      ...extra,
      FirestoreFields.threadId: cleanThreadId,
      FirestoreFields.conversationId: cleanThreadId,
      FirestoreFields.businessId: cleanBusinessId,
      FirestoreFields.businessName: businessName.trim(),
      FirestoreFields.individualUid: cleanIndividualUid,
      FirestoreFields.individualName: individualName.trim(),
      FirestoreFields.customerUid: cleanCustomerUid,
      FirestoreFields.customerName: customerName.trim().isNotEmpty
          ? customerName.trim()
          : individualName.trim(),
      FirestoreFields.participantIds: <String>[
        cleanBusinessId,
        cleanIndividualUid,
      ].where((value) => value.isNotEmpty).toSet().toList(),
      FirestoreFields.participantUids: <String>[
        cleanBusinessId,
        cleanIndividualUid,
      ].where((value) => value.isNotEmpty).toSet().toList(),
      FirestoreFields.userIds: <String>[
        cleanBusinessId,
        cleanIndividualUid,
      ].where((value) => value.isNotEmpty).toSet().toList(),
      FirestoreFields.threadStatus: status,
      FirestoreFields.status: status,
      FirestoreFields.topic: topic,
      FirestoreFields.sourceModule: sourceModule,
      FirestoreFields.schemaVersion: FirestoreSchemaVersions.messageThreadV1,
      FirestoreFields.updatedAt: now,
    };

    return threadRef(cleanThreadId).set(data, SetOptions(merge: true));
  }

  /// Adds a canonical message under messageThreads/{threadId}/messages.
  ///
  /// This method intentionally writes only to the canonical path.
  /// Existing legacy mirror writes must stay in the current UI until the
  /// migration plan explicitly moves them into MessagingService.
  Future<void> addCanonicalMessage({
    required String threadId,
    required String messageId,
    required String senderUid,
    required String senderRole,
    required String text,
    String senderName = '',
    String receiverUid = '',
    String receiverRole = '',
    String messageType = 'text',
    String sourceModule = 'chat_repository_51C_D',
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    final cleanThreadId = threadId.trim();
    final cleanMessageId = messageId.trim();
    final now = FieldValue.serverTimestamp();

    final data = <String, dynamic>{
      ...extra,
      FirestoreFields.messageId: cleanMessageId,
      FirestoreFields.threadId: cleanThreadId,
      FirestoreFields.conversationId: cleanThreadId,
      FirestoreFields.senderUid: senderUid.trim(),
      FirestoreFields.senderId: senderUid.trim(),
      FirestoreFields.fromUid: senderUid.trim(),
      FirestoreFields.senderName: senderName.trim(),
      FirestoreFields.senderRole: senderRole.trim(),
      FirestoreFields.fromRole: senderRole.trim(),
      FirestoreFields.receiverUid: receiverUid.trim(),
      FirestoreFields.receiverId: receiverUid.trim(),
      FirestoreFields.toUid: receiverUid.trim(),
      FirestoreFields.receiverRole: receiverRole.trim(),
      FirestoreFields.toRole: receiverRole.trim(),
      FirestoreFields.text: text,
      FirestoreFields.messageText: text,
      FirestoreFields.body: text,
      FirestoreFields.content: text,
      FirestoreFields.messageType: messageType,
      FirestoreFields.messageStatus: 'sent',
      FirestoreFields.readByUid: <String, dynamic>{senderUid.trim(): true},
      FirestoreFields.createdAt: now,
      FirestoreFields.updatedAt: now,
      FirestoreFields.sourceModule: sourceModule,
      FirestoreFields.schemaVersion: FirestoreSchemaVersions.messagePayloadV1,
      FirestoreFields.isDeleted: false,
    };

    return messageRef(
      threadId: cleanThreadId,
      messageId: cleanMessageId,
    ).set(data, SetOptions(merge: true));
  }

  Future<void> updateLastMessage({
    required String threadId,
    required String text,
    required String senderUid,
    required String senderRole,
    String senderName = '',
    String sourceModule = 'chat_repository_51C_D',
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    final now = FieldValue.serverTimestamp();

    final data = <String, dynamic>{
      ...extra,
      FirestoreFields.lastMessage: text,
      FirestoreFields.lastMessageText: text,
      FirestoreFields.lastSenderUid: senderUid.trim(),
      FirestoreFields.lastSenderName: senderName.trim(),
      FirestoreFields.lastSenderRole: senderRole.trim(),
      FirestoreFields.lastMessageSenderUid: senderUid.trim(),
      FirestoreFields.lastMessageSenderName: senderName.trim(),
      FirestoreFields.lastMessageSenderRole: senderRole.trim(),
      FirestoreFields.lastMessageAt: now,
      FirestoreFields.updatedAt: now,
      FirestoreFields.sourceModule: sourceModule,
      FirestoreFields.schemaVersion: FirestoreSchemaVersions.messageThreadV1,
    };

    return threadRef(threadId.trim()).set(data, SetOptions(merge: true));
  }

  Future<void> markThreadReadForUid({
    required String threadId,
    required String uid,
    String sourceModule = 'chat_repository_51C_D',
  }) {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return Future<void>.value();

    return threadRef(threadId.trim()).set(<String, dynamic>{
      '${FirestoreFields.unreadByUid}.$cleanUid': false,
      '${FirestoreFields.unreadCountsByUid}.$cleanUid': 0,
      '${FirestoreFields.readByUid}.$cleanUid': true,
      '${FirestoreFields.readAt}.$cleanUid': FieldValue.serverTimestamp(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.sourceModule: sourceModule,
    }, SetOptions(merge: true));
  }

  Future<void> setThreadOpen({
    required String threadId,
    required bool isOpen,
    required String actorUid,
    String actorRole = '',
    String sourceModule = 'chat_repository_51C_D',
  }) {
    final status = isOpen ? 'open' : 'closed';

    final data = <String, dynamic>{
      FirestoreFields.threadStatus: status,
      FirestoreFields.status: status,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.sourceModule: sourceModule,
    };

    if (!isOpen) {
      data[FirestoreFields.closedAt] = FieldValue.serverTimestamp();
      data[FirestoreFields.closedByUid] = actorUid.trim();
      data[FirestoreFields.closedByRole] = actorRole.trim();
    }

    return threadRef(threadId.trim()).set(data, SetOptions(merge: true));
  }

  /// 51C-O: legacy-safe read helper for current MessagesInboxPage customer inbox.
  ///
  /// Uses the existing field model:
  /// messageThreads.where(customerUid == currentUid)
  ///
  /// No behavior change; UI still maps snapshots to its private view model.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchThreadsByCustomerUidLegacy(
    String customerUid,
  ) {
    return _threads
        .where(FirestoreFields.customerUid, isEqualTo: customerUid.trim())
        .snapshots();
  }

  /// 51C-O: legacy-safe read helper for current MessagesInboxPage business inbox.
  ///
  /// Uses the existing field model:
  /// messageThreads.where(businessId whereIn businessIds.take(10))
  ///
  /// No behavior change; UI still maps snapshots to its private view model.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchThreadsByBusinessIdsLegacy(
    List<String> businessIds,
  ) {
    final ids = businessIds
        .where((id) => id.trim().isNotEmpty)
        .take(10)
        .toList();

    if (ids.isEmpty) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _threads.where(FirestoreFields.businessId, whereIn: ids).snapshots();
  }

  /// 51C-O: legacy-safe thread document stream for MessagesInboxPage.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchThreadLegacy(
    String threadId,
  ) {
    return threadRef(threadId.trim()).snapshots();
  }

  /// 51C-O: legacy-safe message list stream for MessagesInboxPage.
  ///
  /// Keeps ordering in UI exactly as before; repository only owns Firestore path.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessagesLegacy(
    String threadId,
  ) {
    return messagesRef(threadId.trim()).snapshots();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/core/services/app_observability_service.dart';

class MessagesRepository {
  MessagesRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  static const int _threadMessageWindowLimit = 120;

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  CollectionReference<Map<String, dynamic>> get _businesses =>
      _firestore.collection(FirestoreCollections.businesses);

  CollectionReference<Map<String, dynamic>> get _threads =>
      _firestore.collection(FirestoreCollections.messageThreads);

  Stream<MessageUserContext?> watchCurrentUserContext() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _users.doc(user.uid).snapshots().map((snapshot) {
      final userData = snapshot.data() ?? <String, dynamic>{};
      final currentName =
          userData[FirestoreFields.displayName]?.toString() ??
          user.email ??
          'Kullanıcı';

      return MessageUserContext(
        uid: user.uid,
        email: user.email ?? '',
        name: currentName,
        isBusinessOwner: _isBusinessOwnerUser(userData),
      );
    });
  }

  Stream<List<String>> watchOwnedBusinessIds(String ownerUid) {
    return _businesses
        .where(FirestoreFields.ownerUid, isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => doc.data()[FirestoreFields.id]?.toString() ?? doc.id,
              )
              .where((id) => id.trim().isNotEmpty)
              .toList();
        });
  }

  Stream<List<MessageThreadItem>> watchCustomerThreads(String customerUid) {
    return _threads
        .where(FirestoreFields.customerUid, isEqualTo: customerUid)
        .snapshots()
        .map(_threadsFromSnapshot);
  }

  Stream<List<MessageThreadItem>> watchBusinessThreads(
    List<String> businessIds,
  ) {
    final ids = businessIds
        .where((id) => id.trim().isNotEmpty)
        .take(10)
        .toList();

    if (ids.isEmpty) return Stream.value(const <MessageThreadItem>[]);

    return _threads
        .where(FirestoreFields.businessId, whereIn: ids)
        .snapshots()
        .map(_threadsFromSnapshot);
  }

  Stream<List<MessageBusinessItem>> watchActiveBusinesses({
    String? initialBusinessId,
    String? initialBusinessName,
    String? initialBusinessCategory,
  }) {
    if ((initialBusinessId ?? '').trim().isNotEmpty) {
      return Stream.value([
        MessageBusinessItem(
          id: initialBusinessId!.trim(),
          name: (initialBusinessName ?? 'İşletme').trim(),
          category: (initialBusinessCategory ?? 'Genel').trim(),
        ),
      ]);
    }

    return _businesses
        .where(FirestoreFields.businessStatus, isEqualTo: 'active')
        .where(FirestoreFields.adminApproved, isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) {
                final data = doc.data();

                return MessageBusinessItem(
                  id: data[FirestoreFields.id]?.toString() ?? doc.id,
                  name:
                      data[FirestoreFields.businessName]?.toString() ??
                      'İsimsiz işletme',
                  category:
                      data[FirestoreFields.category]?.toString() ?? 'Genel',
                  ownerUids: _ownerUidsFromBusinessData(data),
                );
              })
              .where((business) {
                final uid = currentUid ?? '';
                return uid.isEmpty || !business.isOwnedBy(uid);
              })
              .toList();

          list.sort((a, b) => a.name.compareTo(b.name));
          return list;
        });
  }

  Future<List<String>> _ownerUidsForBusiness(String businessId) async {
    final cleanBusinessId = businessId.trim();
    if (cleanBusinessId.isEmpty) return const <String>[];

    final snapshot = await _businesses.doc(cleanBusinessId).get();
    final data = snapshot.data();
    if (data == null) return const <String>[];

    return _ownerUidsFromBusinessData(data);
  }

  Future<bool> _businessBelongsToUser(String businessId, String uid) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return false;

    final ownerUids = await _ownerUidsForBusiness(businessId);
    return ownerUids.any((ownerUid) => ownerUid.trim() == cleanUid);
  }

  Future<MessageFirstSendResult> sendFirstMessage({
    required MessageBusinessItem business,
    required String topic,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Mesaj göndermek için giriş yapın.');
    }

    final messageText = text.trim();
    if (messageText.isEmpty) {
      throw ArgumentError.value(text, 'text', 'message cannot be empty');
    }

    final userDoc = await _users.doc(user.uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    if (_isBusinessOwnerUser(userData)) {
      throw StateError(
        'Kurumsal hesap kendi işletmesine bireysel mesaj gönderemez.',
      );
    }

    if (await _businessBelongsToUser(business.id, user.uid) ||
        business.isOwnedBy(user.uid)) {
      throw StateError('Kendi işletmenize mesaj gönderemezsiniz.');
    }

    final customerName =
        userData[FirestoreFields.displayName]?.toString() ??
        user.email ??
        'Bireysel kullanıcı';
    final customerPhone = userData[FirestoreFields.phone]?.toString() ?? '';
    final threadId = '${business.id}_${user.uid}';
    final now = DateTime.now().toIso8601String();
    final ownerUids = business.ownerUids.isNotEmpty
        ? business.ownerUids
        : await _ownerUidsForBusiness(business.id);
    final unreadByUid = <String, bool>{
      for (final ownerUid in ownerUids)
        if (ownerUid.trim().isNotEmpty && ownerUid.trim() != user.uid)
          ownerUid.trim(): true,
      user.uid: false,
    };

    await _threads.doc(threadId).set({
      FirestoreFields.businessId: business.id,
      FirestoreFields.businessName: business.name,
      FirestoreFields.customerUid: user.uid,
      FirestoreFields.customerName: customerName,
      FirestoreFields.customerPhone: customerPhone,
      FirestoreFields.lastMessage: messageText,
      FirestoreFields.lastMessageAt: now,
      FirestoreFields.lastSenderRole: 'customer',
      FirestoreFields.unreadForCustomer: false,
      FirestoreFields.unreadForBusiness: true,
      FirestoreFields.unreadByUid: unreadByUid,
      FirestoreFields.unreadCountsByUid: <String, int>{
        for (final entry in unreadByUid.entries) entry.key: entry.value ? 1 : 0,
      },
      FirestoreFields.readByUid: <String, bool>{user.uid: true},
      FirestoreFields.status: 'open',
      FirestoreFields.topic: topic,
      FirestoreFields.createdAt: now,
      FirestoreFields.updatedAt: now,
    }, SetOptions(merge: true));

    await _threads.doc(threadId).collection(FirestoreCollections.messages).add({
      FirestoreFields.senderUid: user.uid,
      FirestoreFields.senderName: customerName,
      FirestoreFields.senderRole: 'customer',
      FirestoreFields.text: messageText,
      FirestoreFields.messageType: 'text',
      FirestoreFields.recalled: false,
      FirestoreFields.readByCustomer: true,
      FirestoreFields.readByBusiness: false,
      FirestoreFields.createdAt: now,
    });

    return MessageFirstSendResult(
      threadId: threadId,
      currentUid: user.uid,
      currentName: customerName,
    );
  }

  Future<void> markThreadAsRead({
    required String threadId,
    required bool isBusinessOwner,
    required String currentUid,
  }) async {
    final uid = currentUid.trim();
    final field = isBusinessOwner
        ? FirestoreFields.unreadForBusiness
        : FirestoreFields.unreadForCustomer;
    final messageReadField = isBusinessOwner
        ? FirestoreFields.readByBusiness
        : FirestoreFields.readByCustomer;

    final threadRef = _threads.doc(threadId);
    final messages = await threadRef
        .collection(FirestoreCollections.messages)
        .where(messageReadField, isEqualTo: false)
        .limit(50)
        .get();

    final batch = _firestore.batch();

    for (final message in messages.docs) {
      final data = message.data();
      if (data[messageReadField] == true) continue;
      if (uid.isNotEmpty &&
          data[FirestoreFields.senderUid]?.toString() == uid) {
        continue;
      }

      batch.set(message.reference, {
        messageReadField: true,
        FirestoreFields.readAt: FieldValue.serverTimestamp(),
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final data = <String, dynamic>{
      field: false,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };

    if (uid.isNotEmpty) {
      data['${FirestoreFields.unreadByUid}.$uid'] = false;
      data['${FirestoreFields.unreadCountsByUid}.$uid'] = 0;
      data['${FirestoreFields.readByUid}.$uid'] = true;
      data['${FirestoreFields.readAt}.$uid'] = FieldValue.serverTimestamp();
    }

    batch.set(threadRef, data, SetOptions(merge: true));
    await batch.commit();
  }

  Stream<MessageThreadDetails> watchThread(String threadId) {
    return _threads.doc(threadId).snapshots().map((snapshot) {
      return MessageThreadDetails.fromData(snapshot.data() ?? {});
    });
  }

  Stream<List<MessageItem>> watchMessages(String threadId) {
    return _threads
        .doc(threadId)
        .collection(FirestoreCollections.messages)
        .orderBy(FirestoreFields.createdAt, descending: true)
        .limit(_threadMessageWindowLimit)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return MessageItem.fromData(id: doc.id, data: doc.data());
          }).toList();

          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }

  Future<void> sendMessage({
    required String threadId,
    required bool isBusinessOwner,
    required String currentUid,
    required String currentName,
    required String text,
  }) async {
    final messageText = text.trim();
    if (messageText.isEmpty) return;

    final now = DateTime.now().toIso8601String();
    final senderRole = isBusinessOwner ? 'business' : 'customer';
    final threadSnapshot = await _threads.doc(threadId).get();
    final threadData = threadSnapshot.data() ?? <String, dynamic>{};
    final customerUid =
        threadData[FirestoreFields.customerUid]?.toString() ?? '';
    final businessId = threadData[FirestoreFields.businessId]?.toString() ?? '';
    if (customerUid.trim().isNotEmpty &&
        customerUid.trim() == currentUid.trim()) {
      if (isBusinessOwner ||
          await _businessBelongsToUser(businessId, currentUid)) {
        throw StateError('Kendi işletmenize mesaj gönderemezsiniz.');
      }
    }
    final ownerUids = isBusinessOwner
        ? const <String>[]
        : await _ownerUidsForBusiness(businessId);
    final unreadUidUpdates = <String, dynamic>{
      if (isBusinessOwner && customerUid.trim().isNotEmpty)
        '${FirestoreFields.unreadByUid}.${customerUid.trim()}': true,
      if (!isBusinessOwner)
        for (final ownerUid in ownerUids)
          if (ownerUid.trim().isNotEmpty &&
              ownerUid.trim() != currentUid.trim())
            '${FirestoreFields.unreadByUid}.${ownerUid.trim()}': true,
      if (currentUid.trim().isNotEmpty)
        '${FirestoreFields.unreadByUid}.${currentUid.trim()}': false,
    };
    final unreadCountUpdates = <String, dynamic>{
      if (isBusinessOwner && customerUid.trim().isNotEmpty)
        '${FirestoreFields.unreadCountsByUid}.${customerUid.trim()}':
            FieldValue.increment(1),
      if (!isBusinessOwner)
        for (final ownerUid in ownerUids)
          if (ownerUid.trim().isNotEmpty &&
              ownerUid.trim() != currentUid.trim())
            '${FirestoreFields.unreadCountsByUid}.${ownerUid.trim()}':
                FieldValue.increment(1),
      if (currentUid.trim().isNotEmpty)
        '${FirestoreFields.unreadCountsByUid}.${currentUid.trim()}': 0,
    };

    await _threads.doc(threadId).collection(FirestoreCollections.messages).add({
      FirestoreFields.senderUid: currentUid,
      FirestoreFields.senderName: currentName,
      FirestoreFields.senderRole: senderRole,
      FirestoreFields.text: messageText,
      FirestoreFields.messageType: 'text',
      FirestoreFields.recalled: false,
      FirestoreFields.readByCustomer: !isBusinessOwner,
      FirestoreFields.readByBusiness: isBusinessOwner,
      FirestoreFields.createdAt: now,
    });

    await _threads.doc(threadId).set({
      FirestoreFields.lastMessage: messageText,
      FirestoreFields.lastMessageAt: now,
      FirestoreFields.lastSenderRole: senderRole,
      FirestoreFields.unreadForCustomer: isBusinessOwner,
      FirestoreFields.unreadForBusiness: !isBusinessOwner,
      ...unreadUidUpdates,
      ...unreadCountUpdates,
      if (currentUid.trim().isNotEmpty)
        '${FirestoreFields.readByUid}.${currentUid.trim()}': true,
      FirestoreFields.updatedAt: now,
    }, SetOptions(merge: true));

    await AppObservabilityService.instance.logMessageSent(
      threadId: threadId,
      senderRole: senderRole,
      businessId: businessId,
    );
  }

  Future<void> recallMessage({
    required String threadId,
    required String messageId,
  }) async {
    final now = DateTime.now().toIso8601String();

    await _threads
        .doc(threadId)
        .collection(FirestoreCollections.messages)
        .doc(messageId)
        .set({
          FirestoreFields.text: 'Bu mesaj geri alındı',
          FirestoreFields.messageType: 'recalled',
          FirestoreFields.recalled: true,
          FirestoreFields.updatedAt: now,
        }, SetOptions(merge: true));

    await _threads.doc(threadId).set({
      FirestoreFields.lastMessage: 'Bir mesaj geri alındı',
      FirestoreFields.lastMessageAt: now,
      FirestoreFields.updatedAt: now,
    }, SetOptions(merge: true));
  }

  Future<void> setThreadStatus({
    required String threadId,
    required String status,
  }) {
    return _threads.doc(threadId).set({
      FirestoreFields.status: status,
      FirestoreFields.updatedAt: DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  List<MessageThreadItem> _threadsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final list = snapshot.docs.map((doc) {
      return MessageThreadItem.fromData(id: doc.id, data: doc.data());
    }).toList();

    list.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return list;
  }
}

class MessageUserContext {
  const MessageUserContext({
    required this.uid,
    required this.email,
    required this.name,
    required this.isBusinessOwner,
  });

  final String uid;
  final String email;
  final String name;
  final bool isBusinessOwner;
}

class MessageFirstSendResult {
  const MessageFirstSendResult({
    required this.threadId,
    required this.currentUid,
    required this.currentName,
  });

  final String threadId;
  final String currentUid;
  final String currentName;
}

class MessageThreadItem {
  const MessageThreadItem({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.customerUid,
    required this.customerName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadForCustomer,
    required this.unreadForBusiness,
    required this.status,
    required this.topic,
  });

  factory MessageThreadItem.fromData({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return MessageThreadItem(
      id: id,
      businessId: data[FirestoreFields.businessId]?.toString() ?? '',
      businessName: data[FirestoreFields.businessName]?.toString() ?? '',
      customerUid: data[FirestoreFields.customerUid]?.toString() ?? '',
      customerName: data[FirestoreFields.customerName]?.toString() ?? '',
      lastMessage: data[FirestoreFields.lastMessage]?.toString() ?? '',
      lastMessageAt: _dateText(
        data[FirestoreFields.lastMessageAt],
        fallback: data[FirestoreFields.lastMessageAtLocalIso],
      ),
      unreadForCustomer: data[FirestoreFields.unreadForCustomer] == true,
      unreadForBusiness: data[FirestoreFields.unreadForBusiness] == true,
      status: data[FirestoreFields.status]?.toString() ?? 'open',
      topic: data[FirestoreFields.topic]?.toString() ?? 'general',
    );
  }

  final String id;
  final String businessId;
  final String businessName;
  final String customerUid;
  final String customerName;
  final String lastMessage;
  final String lastMessageAt;
  final bool unreadForCustomer;
  final bool unreadForBusiness;
  final String status;
  final String topic;
}

class MessageThreadDetails {
  const MessageThreadDetails({
    required this.businessName,
    required this.customerName,
    required this.status,
    required this.topic,
  });

  factory MessageThreadDetails.fromData(Map<String, dynamic> data) {
    return MessageThreadDetails(
      businessName: data[FirestoreFields.businessName]?.toString() ?? 'İşletme',
      customerName:
          data[FirestoreFields.customerName]?.toString() ??
          'Bireysel kullanıcı',
      status: data[FirestoreFields.status]?.toString() ?? 'open',
      topic: data[FirestoreFields.topic]?.toString() ?? 'general',
    );
  }

  final String businessName;
  final String customerName;
  final String status;
  final String topic;
}

class MessageItem {
  const MessageItem({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.readByCustomer,
    required this.readByBusiness,
    required this.createdAt,
    required this.recalled,
  });

  factory MessageItem.fromData({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return MessageItem(
      id: id,
      senderUid: data[FirestoreFields.senderUid]?.toString() ?? '',
      senderName: data[FirestoreFields.senderName]?.toString() ?? '',
      senderRole: data[FirestoreFields.senderRole]?.toString() ?? '',
      text: data[FirestoreFields.text]?.toString() ?? '',
      readByCustomer: data[FirestoreFields.readByCustomer] == true,
      readByBusiness: data[FirestoreFields.readByBusiness] == true,
      createdAt: _dateText(
        data[FirestoreFields.createdAt],
        fallback: data[FirestoreFields.createdAtLocalIso],
      ),
      recalled:
          data[FirestoreFields.recalled] == true ||
          data[FirestoreFields.messageType]?.toString() == 'recalled',
    );
  }

  final String id;
  final String senderUid;
  final String senderName;
  final String senderRole;
  final String text;
  final bool readByCustomer;
  final bool readByBusiness;
  final String createdAt;
  final bool recalled;
}

class MessageBusinessItem {
  const MessageBusinessItem({
    required this.id,
    required this.name,
    required this.category,
    this.ownerUids = const <String>[],
  });

  final String id;
  final String name;
  final String category;
  final List<String> ownerUids;

  bool isOwnedBy(String uid) {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return false;
    return ownerUids.any((ownerUid) => ownerUid.trim() == cleanUid);
  }
}

bool _isBusinessOwnerUser(Map<String, dynamic> data) {
  final values = <String>[
    data[FirestoreFields.role]?.toString() ?? '',
    data[FirestoreFields.legacyRole]?.toString() ?? '',
    data[FirestoreFields.activeRole]?.toString() ?? '',
    data[FirestoreFields.accountKind]?.toString() ?? '',
  ].map((value) => value.trim().toLowerCase()).toSet();

  return values.contains('businessowner') ||
      values.contains('corporateowner') ||
      values.contains('corporate_owner') ||
      values.contains('owner') ||
      values.contains('corporate');
}

List<String> _ownerUidsFromBusinessData(Map<String, dynamic> data) {
  final values = <String>{};

  void add(Object? value) {
    if (value == null) return;
    if (value is String) {
      final clean = value.trim();
      if (clean.isNotEmpty) values.add(clean);
      return;
    }
    if (value is Iterable) {
      for (final item in value) {
        add(item);
      }
      return;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        if (entry.value == true) {
          add(entry.key);
        } else {
          add(entry.value);
        }
      }
      return;
    }

    final clean = value.toString().trim();
    if (clean.isNotEmpty && clean != 'null') values.add(clean);
  }

  add(data[FirestoreFields.ownerUid]);
  add(data[FirestoreFields.ownerId]);
  add(data[FirestoreFields.businessOwnerUid]);
  add(data[FirestoreFields.createdBy]);
  add(data[FirestoreFields.createdByUid]);
  add(data[FirestoreFields.ownerUids]);
  add(data[FirestoreFields.owners]);

  return values.toList(growable: false);
}

String _dateText(dynamic value, {dynamic fallback}) {
  final parsed = _dateValue(value);
  if (parsed != null) return parsed.toIso8601String();

  final fallbackParsed = _dateValue(fallback);
  if (fallbackParsed != null) return fallbackParsed.toIso8601String();

  final text = value?.toString().trim() ?? '';
  if (text.isNotEmpty && text != 'null') return text;

  final fallbackText = fallback?.toString().trim() ?? '';
  return fallbackText == 'null' ? '' : fallbackText;
}

DateTime? _dateValue(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value;
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
  }
  return DateTime.tryParse(value.toString().trim());
}

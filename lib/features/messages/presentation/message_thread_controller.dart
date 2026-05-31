import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxpro_mobile/features/messages/data/messages_repository.dart';
import 'package:rxpro_mobile/features/messages/presentation/message_compose_controller.dart';

abstract class MessageThreadDataSource {
  Stream<MessageThreadDetails> watchThread(String threadId);

  Stream<List<MessageItem>> watchMessages(String threadId);

  Future<void> markThreadAsRead({
    required String threadId,
    required bool isBusinessOwner,
    required String currentUid,
  });

  Future<void> sendMessage({
    required String threadId,
    required bool isBusinessOwner,
    required String currentUid,
    required String currentName,
    required String text,
  });

  Future<void> recallMessage({
    required String threadId,
    required String messageId,
  });

  Future<void> setThreadStatus({
    required String threadId,
    required String status,
  });
}

class MessageThreadController extends ChangeNotifier {
  MessageThreadController({
    required this.threadId,
    required this.isBusinessOwner,
    required this.currentUid,
    required this.currentName,
    MessageThreadDataSource? dataSource,
    MessageComposeController? initialComposeController,
  }) : _dataSource = dataSource ?? _MessagesRepositoryThreadDataSource(),
       composeController =
           initialComposeController ?? MessageComposeController(),
       _ownsComposeController = initialComposeController == null {
    composeController.addListener(_handleComposeChanged);
  }

  final String threadId;
  final bool isBusinessOwner;
  final String currentUid;
  final String currentName;
  final MessageComposeController composeController;

  final MessageThreadDataSource _dataSource;
  final bool _ownsComposeController;
  int _lastReadMessageCount = -1;

  bool get sending => composeController.sending;

  Stream<MessageThreadDetails> watchThread() {
    return _dataSource.watchThread(threadId);
  }

  Stream<List<MessageItem>> watchMessages() {
    return _dataSource.watchMessages(threadId);
  }

  Future<void> markThreadAsRead() {
    return _dataSource.markThreadAsRead(
      threadId: threadId,
      isBusinessOwner: isBusinessOwner,
      currentUid: currentUid,
    );
  }

  void markReadForMessageList(List<MessageItem> messages) {
    if (messages.isEmpty) {
      _lastReadMessageCount = 0;
      return;
    }

    if (messages.length == _lastReadMessageCount) return;
    final hasUnreadIncoming = messages.any((message) {
      if (message.senderUid == currentUid) return false;
      return isBusinessOwner
          ? !message.readByBusiness
          : !message.readByCustomer;
    });
    if (!hasUnreadIncoming) {
      _lastReadMessageCount = messages.length;
      return;
    }

    _lastReadMessageCount = messages.length;
    unawaited(markThreadAsRead());
  }

  Future<void> sendMessage() async {
    final text = composeController.trimmedText;
    if (!composeController.canSend) return;

    composeController.setSending(true);
    try {
      await _dataSource.sendMessage(
        threadId: threadId,
        isBusinessOwner: isBusinessOwner,
        currentUid: currentUid,
        currentName: currentName,
        text: text,
      );
      composeController.clearText();
    } finally {
      composeController.setSending(false);
    }
  }

  bool canRecall(MessageItem message) {
    return message.senderUid == currentUid && !message.recalled;
  }

  Future<void> recallMessage(MessageItem message) {
    if (!canRecall(message)) return Future<void>.value();

    return _dataSource.recallMessage(threadId: threadId, messageId: message.id);
  }

  Future<void> closeThread() {
    return _dataSource.setThreadStatus(threadId: threadId, status: 'closed');
  }

  Future<void> openThread() {
    return _dataSource.setThreadStatus(threadId: threadId, status: 'open');
  }

  void _handleComposeChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    composeController.removeListener(_handleComposeChanged);
    if (_ownsComposeController) {
      composeController.dispose();
    }
    super.dispose();
  }
}

class _MessagesRepositoryThreadDataSource extends MessagesRepository
    implements MessageThreadDataSource {}

import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/messages/data/messages_repository.dart';
import 'package:rxpro_mobile/features/messages/presentation/message_compose_controller.dart';
import 'package:rxpro_mobile/features/messages/presentation/message_thread_controller.dart';

void main() {
  group('MessageThreadController', () {
    test('marks read only when message count changes', () async {
      final source = _FakeMessageThreadDataSource();
      final controller = _controller(source);
      addTearDown(controller.dispose);

      controller.markReadForMessageList(const <MessageItem>[]);
      controller.markReadForMessageList([_message('m1')]);
      controller.markReadForMessageList([_message('m1')]);
      controller.markReadForMessageList([_message('m1'), _message('m2')]);

      await Future<void>.delayed(Duration.zero);

      expect(source.markReadCalls, 2);
    });

    test('does not mark read for own or already read messages', () async {
      final source = _FakeMessageThreadDataSource();
      final controller = _controller(source);
      addTearDown(controller.dispose);

      controller.markReadForMessageList([
        _message('own', senderUid: 'uid'),
        _message('read', readByCustomer: true),
      ]);

      await Future<void>.delayed(Duration.zero);

      expect(source.markReadCalls, 0);
    });

    test('sends trimmed message and clears compose text', () async {
      final source = _FakeMessageThreadDataSource();
      final compose = MessageComposeController(initialText: '  Merhaba  ');
      final controller = _controller(source, initialComposeController: compose);
      addTearDown(() {
        controller.dispose();
        compose.dispose();
      });

      await controller.sendMessage();

      expect(source.sentTexts, ['Merhaba']);
      expect(compose.trimmedText, isEmpty);
      expect(compose.sending, isFalse);
    });

    test('does not send blank messages', () async {
      final source = _FakeMessageThreadDataSource();
      final compose = MessageComposeController(initialText: '   ');
      final controller = _controller(source, initialComposeController: compose);
      addTearDown(() {
        controller.dispose();
        compose.dispose();
      });

      await controller.sendMessage();

      expect(source.sentTexts, isEmpty);
    });

    test(
      'recalls only current user messages and controls thread status',
      () async {
        final source = _FakeMessageThreadDataSource();
        final controller = _controller(source);
        addTearDown(controller.dispose);

        await controller.recallMessage(_message('own', senderUid: 'uid'));
        await controller.recallMessage(_message('other', senderUid: 'other'));
        await controller.recallMessage(
          _message('recalled', senderUid: 'uid', recalled: true),
        );
        await controller.closeThread();
        await controller.openThread();

        expect(source.recalledMessageIds, ['own']);
        expect(source.statuses, ['closed', 'open']);
      },
    );
  });
}

MessageThreadController _controller(
  _FakeMessageThreadDataSource source, {
  MessageComposeController? initialComposeController,
}) {
  return MessageThreadController(
    threadId: 'thread1',
    isBusinessOwner: false,
    currentUid: 'uid',
    currentName: 'User',
    dataSource: source,
    initialComposeController: initialComposeController,
  );
}

MessageItem _message(
  String id, {
  String senderUid = 'other',
  bool? readByCustomer,
  bool recalled = false,
}) {
  return MessageItem(
    id: id,
    senderUid: senderUid,
    senderName: 'Sender',
    senderRole: 'customer',
    text: 'Message',
    readByCustomer: readByCustomer ?? senderUid == 'uid',
    readByBusiness: false,
    createdAt: '2026-05-29T00:00:00Z',
    recalled: recalled,
  );
}

class _FakeMessageThreadDataSource implements MessageThreadDataSource {
  int markReadCalls = 0;
  final sentTexts = <String>[];
  final recalledMessageIds = <String>[];
  final statuses = <String>[];

  @override
  Stream<MessageThreadDetails> watchThread(String threadId) {
    return Stream<MessageThreadDetails>.value(
      const MessageThreadDetails(
        businessName: 'Business',
        customerName: 'Customer',
        status: 'open',
        topic: 'general',
      ),
    );
  }

  @override
  Stream<List<MessageItem>> watchMessages(String threadId) {
    return Stream<List<MessageItem>>.value(const <MessageItem>[]);
  }

  @override
  Future<void> markThreadAsRead({
    required String threadId,
    required bool isBusinessOwner,
    required String currentUid,
  }) async {
    markReadCalls += 1;
  }

  @override
  Future<void> sendMessage({
    required String threadId,
    required bool isBusinessOwner,
    required String currentUid,
    required String currentName,
    required String text,
  }) async {
    sentTexts.add(text);
  }

  @override
  Future<void> recallMessage({
    required String threadId,
    required String messageId,
  }) async {
    recalledMessageIds.add(messageId);
  }

  @override
  Future<void> setThreadStatus({
    required String threadId,
    required String status,
  }) async {
    statuses.add(status);
  }
}

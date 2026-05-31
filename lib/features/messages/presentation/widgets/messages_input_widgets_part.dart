part of 'messages_ui_widgets.dart';

class MessageClosedNotice extends StatelessWidget {
  const MessageClosedNotice({super.key, required this.isBusinessOwner});

  final bool isBusinessOwner;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(
          RxSpace.md,
          0,
          RxSpace.md,
          RxSpace.md,
        ),
        padding: const EdgeInsets.all(RxSpace.md),
        decoration: BoxDecoration(
          color: RxColors.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(RxRadius.md),
          border: Border.all(color: RxColors.warning.withValues(alpha: 0.24)),
        ),
        child: Text(
          MessageUiPolicy.closedThreadNotice(isBusinessOwner: isBusinessOwner),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: RxColors.warning,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class MessageInputBar extends StatelessWidget {
  const MessageInputBar({
    super.key,
    required this.controller,
    required this.isBusinessOwner,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isBusinessOwner;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          RxSpace.md,
          RxSpace.sm,
          RxSpace.md,
          RxSpace.md,
        ),
        decoration: const BoxDecoration(
          color: RxColors.background,
          border: Border(top: BorderSide(color: RxColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: MessageUiPolicy.inputHint(
                    isBusinessOwner: isBusinessOwner,
                  ),
                  filled: true,
                  fillColor: RxColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: RxSpace.sm),
            SizedBox(
              width: 48,
              height: 48,
              child: FilledButton(
                onPressed: sending ? null : onSend,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

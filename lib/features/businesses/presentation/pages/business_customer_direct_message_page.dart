import 'package:flutter/material.dart';
import 'package:rxpro_mobile/features/businesses/data/business_customer_message_repository.dart';
import 'package:rxpro_mobile/features/businesses/presentation/business_customer_direct_message_controller.dart';

class BusinessCustomerDirectMessagePage extends StatefulWidget {
  const BusinessCustomerDirectMessagePage({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.customerUid,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
  });

  final String businessId;
  final String businessName;
  final String customerUid;
  final String customerName;
  final String customerEmail;
  final String customerPhone;

  @override
  State<BusinessCustomerDirectMessagePage> createState() =>
      _BusinessCustomerDirectMessagePageState();
}

class _BusinessCustomerDirectMessagePageState
    extends State<BusinessCustomerDirectMessagePage> {
  final TextEditingController _messageController = TextEditingController();
  final BusinessCustomerMessageRepository _messageRepository =
      BusinessCustomerMessageRepository();
  final BusinessCustomerDirectMessageController _controller =
      BusinessCustomerDirectMessageController();

  String get _threadId {
    final business = widget.businessId.replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
    final customer = widget.customerUid.replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
    return 'business_${business}_customer_$customer';
  }

  String _initialsOf(String raw) {
    final parts = raw
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'M';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      _show('Mesaj metni bos olamaz.');
      return;
    }

    if (widget.customerUid.trim().isEmpty || widget.customerUid == '-') {
      _show('Bireysel kullanici ID bilgisi bulunamadi.');
      return;
    }

    _controller.setSending(true);

    try {
      await _messageRepository.sendMessage(
        BusinessCustomerMessageDraft(
          threadId: _threadId,
          businessId: widget.businessId,
          businessName: widget.businessName,
          customerUid: widget.customerUid,
          customerName: widget.customerName,
          customerEmail: widget.customerEmail,
          customerPhone: widget.customerPhone,
          text: text,
        ),
      );

      if (!mounted) return;

      _messageController.clear();
      _show('Mesaj bireysel kullaniciya gonderildi.');

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _show('Mesaj gonderilemedi: $e');
    } finally {
      if (mounted) {
        _controller.setSending(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.customerName.trim().isEmpty
        ? 'Bireysel Kullanıcı'
        : widget.customerName;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Bireysel Kullanıcıyla Mesaj'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    _initialsOf(customerName),
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (widget.customerEmail.trim().isNotEmpty &&
                          widget.customerEmail != '-') ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.customerEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (widget.customerPhone.trim().isNotEmpty &&
                          widget.customerPhone != '-') ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.customerPhone,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _messageController,
            minLines: 5,
            maxLines: 8,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: 'Mesajiniz',
              hintText: 'Bireysel kullaniciya gonderilecek mesaji yazin.',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return FilledButton.icon(
                onPressed: _controller.sending ? null : _sendMessage,
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  _controller.sending ? 'Gonderiliyor...' : 'Mesaj Gonder',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

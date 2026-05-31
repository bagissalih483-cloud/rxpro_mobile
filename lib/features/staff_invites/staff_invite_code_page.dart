import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxpro_mobile/core/app_state/fix_shell_nav_state.dart';
import 'package:rxpro_mobile/features/staff_invites/presentation/staff_invite_code_controller.dart';
import 'package:rxpro_mobile/features/staff_invites/staff_invite_service.dart';

class StaffInviteCodePage extends StatefulWidget {
  const StaffInviteCodePage({super.key});

  @override
  State<StaffInviteCodePage> createState() => _StaffInviteCodePageState();
}

class _StaffInviteCodePageState extends State<StaffInviteCodePage> {
  final TextEditingController _code = TextEditingController();
  final StaffInviteService _service = StaffInviteService();
  final StaffInviteCodeController _controller = StaffInviteCodeController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFillFromClipboard();
      _loadLinkedStatus();
    });
  }

  Future<void> _autoFillFromClipboard() async {
    if (_code.text.trim().isNotEmpty) return;

    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = (data?.text ?? '').trim();

    if (text.length >= 4 &&
        text.length <= 24 &&
        RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(text)) {
      _code.text = text.toUpperCase();
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = (data?.text ?? '').trim();

    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Panoda kurumsal giriş kodu bulunamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _code.text = text.toUpperCase();
  }

  @override
  void dispose() {
    _code.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLinkedStatus() async {
    _controller.beginStatusLoad();

    try {
      final linked = await _service.currentLinkedAccount();
      if (!mounted) return;

      _controller.applyLinkedStatus(linked);
    } catch (e) {
      if (!mounted) return;

      _controller.applyError(
        'Kurumsal bağlantı durumu yüklenirken hata oluştu: $e',
      );
    } finally {
      if (mounted) {
        _controller.finishStatusLoad();
      }
    }
  }

  Future<void> _setWorkActive(bool active) async {
    if (_controller.statusLoading) return;

    _controller.beginWorkStatusMutation();

    try {
      // Rol değişimi sonrası hangi shell aktif olursa olsun kullanıcıyı
      // Keşfet'e düşürmemek için hesap sekmesi hedeflenir.
      FixShellNavState.individualIndex = 4;
      FixShellNavState.corporateIndex = 4;

      await _service.setCurrentLinkedWorkActive(active);
      final linked = await _service.currentLinkedAccount();

      if (!mounted) return;
      _controller.applyLinkedStatus(linked);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            active
                ? 'Kurumsal bağlantı aktif edildi.'
                : 'Kurumsal bağlantı pasife alındı.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Burada FixSessionGate.refreshAfterAuthChange() çağrılmıyor.
      // users/{uid} belgesi zaten AppSession stream'ini tetikler.
      // Zorla role gate refresh etmek route stack'i ve tab state'i sıfırlıyordu.
    } catch (e) {
      if (!mounted) return;
      _controller.applyError(
        'Kurumsal bağlantı durumu güncellenirken hata oluştu: $e',
      );
    } finally {
      if (mounted) {
        _controller.finishStatusLoad();
      }
    }
  }

  Future<void> _submit() async {
    final code = _code.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kurumsal giriş kodunu gir.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _controller.beginSubmit();

    try {
      final result = await _service.acceptInviteCode(code);

      if (!mounted) return;
      _controller.applyResult(result);

      if (result.success) {
        FixShellNavState.individualIndex = 4;
        FixShellNavState.corporateIndex = 4;
        _code.clear();
        await _loadLinkedStatus();
      }
    } catch (e) {
      if (!mounted) return;
      _controller.applyError(
        'Kurumsal giriş kodu kontrol edilirken hata oluştu: $e',
      );
    } finally {
      if (mounted) _controller.finishSubmit();
    }
  }

  Widget _statusLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kurumsal bağlantı durumu kontrol ediliyor...',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Mevcut personel bağlantın varsa aktif/pasif kartı birazdan açılır.',
            style: TextStyle(
              color: Color(0xFF64748B),
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inviteCodeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.badge_outlined, color: Color(0xFF2563EB), size: 34),
          const SizedBox(height: 12),
          const Text(
            'Kurumsal giriş',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'İşletmeden aldığın kurumsal giriş kodunu gir. Kod doğrulanınca hesabın yetkili personel alanına bağlanır.',
            style: TextStyle(
              color: Color(0xFF64748B),
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            enabled: !_controller.loading,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Kurumsal giriş kodu',
              hintText: 'Örn. A7K9P2',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _controller.loading ? null : _submit(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _controller.loading ? null : _pasteFromClipboard,
              icon: const Icon(Icons.content_paste_rounded),
              label: const Text('Panodan Yapıştır'),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _controller.loading ? null : _submit,
              icon: _controller.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link_rounded),
              label: Text(
                _controller.loading ? 'Bağlanıyor...' : 'Kurumsal giriş yap',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkedStatusCard() {
    final linked = _controller.linked!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kurumsal bağlantı durumun',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${linked.businessName} • ${linked.staffName}',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            linked.isWorkActive
                ? 'Durum: Kurumsal görev akışı aktif'
                : 'Durum: Kurumsal görev akışı pasif',
            style: TextStyle(
              color: linked.isWorkActive
                  ? const Color(0xFF166534)
                  : const Color(0xFF92400E),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _controller.statusLoading
                      ? null
                      : () => _setWorkActive(true),
                  icon: _controller.statusLoading && !linked.isWorkActive
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: const Text('Aktif Et'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _controller.statusLoading
                      ? null
                      : () => _setWorkActive(false),
                  icon: _controller.statusLoading && linked.isWorkActive
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.pause_circle_outline),
                  label: const Text('Pasife Al'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final result = _controller.result;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Kurumsal giriş'),
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (!_controller.initialStatusLoaded)
                _statusLoadingCard()
              else if (_controller.linked == null)
                _inviteCodeCard()
              else ...[
                const SizedBox(height: 14),
                _linkedStatusCard(),
              ],
              if (result != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: result.success
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    result.message,
                    style: TextStyle(
                      color: result.success
                          ? const Color(0xFF166534)
                          : const Color(0xFF991B1B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

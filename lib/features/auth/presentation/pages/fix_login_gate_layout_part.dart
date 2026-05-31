part of 'fix_login_gate_page.dart';

extension _FixLoginGateDesktopLayout on _FixLoginGatePageState {
  Widget _buildDesktopAuthLayout(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Center(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(28, 24, 28, 24 + bottomInset),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _FixDesktopBrandPanel(isCorporate: isCorporate),
                ),
                const SizedBox(width: 24),
                SizedBox(width: 460, child: _buildDesktopAuthCard()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopAuthCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FixSegmentedTabs<FixAuthMode>(
          value: _controller.mode,
          onChanged: _controller.loading ? null : _changeMode,
          options: const [
            FixSegmentedOption(
              value: FixAuthMode.individual,
              label: 'Bireysel',
              icon: Icons.person_outline_rounded,
            ),
            FixSegmentedOption(
              value: FixAuthMode.corporate,
              label: 'Kurumsal',
              icon: Icons.storefront_outlined,
            ),
          ],
        ),
        const SizedBox(height: 10),
        FixModeHint(isCorporate: isCorporate),
        const SizedBox(height: 10),
        FixSegmentedTabs<FixAuthAction>(
          value: _controller.action,
          compact: true,
          onChanged: _controller.loading ? null : _changeAction,
          options: const [
            FixSegmentedOption(
              value: FixAuthAction.login,
              label: 'Giriş',
              icon: Icons.login_rounded,
            ),
            FixSegmentedOption(
              value: FixAuthAction.register,
              label: 'Kaydol',
              icon: Icons.person_add_alt_1_rounded,
            ),
          ],
        ),
        const SizedBox(height: 14),
        FixLoginPanel(
          title: _panelTitle(),
          subtitle: _loginSubtitle(),
          bullets: _loginBullets(),
          notice: _controller.noticeText,
          noticeIsError: _controller.noticeIsError,
          child: _buildForm(),
        ),
        const SizedBox(height: 12),
        FixLoginGuestActions(
          loading: _controller.loading,
          onGuest: _continueAsGuest,
        ),
      ],
    );
  }
}

class _FixDesktopBrandPanel extends StatelessWidget {
  const _FixDesktopBrandPanel({required this.isCorporate});

  final bool isCorporate;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 620),
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FFF9), Color(0xFFE9F8FF)],
        ),
        border: Border.all(color: const Color(0xFFDCEBE4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17384A).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.13,
              child: Image.asset(
                'assets/images/fix_login_hero_banner.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FixAmblemMark(height: 66, width: 132),
              const SizedBox(height: 42),
              const Text(
                'Randevu ve işletme yönetimi tek yerde',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF17384A),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.06,
                ),
              ),
              const SizedBox(height: 14),
              const SizedBox(
                width: 480,
                child: Text(
                  'Bireysel kullanıcılar randevularını yönetir, işletmeler operasyonlarını güvenli panelden takip eder.',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _FixDesktopValue(
                    icon: Icons.calendar_month_outlined,
                    title: 'Randevu',
                    subtitle: 'Takvim ve müşteri akışı',
                  ),
                  _FixDesktopValue(
                    icon: Icons.payments_outlined,
                    title: 'Muhasebe',
                    subtitle: 'Adisyon ve tahsilat takibi',
                  ),
                  _FixDesktopValue(
                    icon: Icons.campaign_outlined,
                    title: 'Pazarlama',
                    subtitle: 'Kampanya ve duyurular',
                  ),
                ],
              ),
              const SizedBox(height: 42),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _FixDesktopModeNote(
                  key: ValueKey<bool>(isCorporate),
                  isCorporate: isCorporate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FixDesktopValue extends StatelessWidget {
  const _FixDesktopValue({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 186,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCEBE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1DB954), size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF17384A),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11.5,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FixDesktopModeNote extends StatelessWidget {
  const _FixDesktopModeNote({super.key, required this.isCorporate});

  final bool isCorporate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCEBE4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorporate
                ? Icons.verified_user_outlined
                : Icons.explore_outlined,
            color: const Color(0xFF1DB954),
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isCorporate
                  ? 'Güvenli işletme paneli'
                  : 'Üye olmadan keşfet, randevu için giriş yap',
              style: const TextStyle(
                color: Color(0xFF25643A),
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

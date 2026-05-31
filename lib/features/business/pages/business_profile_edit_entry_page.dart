import 'package:flutter/material.dart';
import 'package:rxpro_mobile/app/app_routes.dart';
import 'package:rxpro_mobile/core/services/auth_service.dart';

import '../data/business_profile_edit_entry_resolver_repository.dart';
import '../presentation/business_profile_edit_entry_controller.dart';
import 'business_profile_edit_page.dart';

/// 50C-K4: Business profile edit lookup behavior is unchanged.
class BusinessProfileEditEntryPage extends StatefulWidget {
  const BusinessProfileEditEntryPage({super.key});

  @override
  State<BusinessProfileEditEntryPage> createState() =>
      _BusinessProfileEditEntryPageState();
}

class _BusinessProfileEditEntryPageState
    extends State<BusinessProfileEditEntryPage> {
  final AuthService _authService = AuthService();
  final BusinessProfileEditEntryResolverRepository _resolverRepository =
      BusinessProfileEditEntryResolverRepository();
  final BusinessProfileEditEntryController _controller =
      BusinessProfileEditEntryController();

  @override
  void initState() {
    super.initState();
    _loadOwnedBusiness();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadOwnedBusiness() async {
    final user = _authService.currentUser;

    if (user == null) {
      if (!mounted) return;
      _controller.setNeedsLogin();
      return;
    }

    try {
      final foundId = await _resolverRepository.resolveOwnedBusinessId(
        uid: user.uid,
        email: user.email,
      );

      if (!mounted) return;
      _controller.setResolvedBusiness(foundId);
    } catch (e) {
      if (!mounted) return;
      _controller.setLookupError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.loading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Kurumsal Profilimi Düzenle')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final id = _controller.businessId;
        if (id != null && id.isNotEmpty) {
          return BusinessProfileEditPage(businessId: id);
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Kurumsal Profilimi Düzenle')),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.storefront_outlined,
                        size: 42,
                        color: Color(0xFF7C3AED),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Kurumsal kayıt otomatik bulunamadı',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _controller.errorMessage ??
                            'Bu hesaba bağlı kurumsal kayıt otomatik eşleşmedi. Kayıtlı kurumsal kullanıcılardan hesabınızı seçerek düzenlemeye devam edebilirsiniz.',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed(
                            AppRoutes.registeredBusinesses,
                          );
                        },
                        icon: const Icon(Icons.list_alt_rounded),
                        label: const Text(
                          'Kayıtlı Kurumsal Kullanıcılara Git',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

part of 'business_profile_edit_page.dart';

class _BusinessEditAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _BusinessEditAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Kurumsal Profil Düzenle'),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

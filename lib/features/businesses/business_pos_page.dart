import 'package:flutter/material.dart';

class BusinessPosPage extends StatelessWidget {
  const BusinessPosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Adisyon ve Satış'),
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Açık Adisyonlar'),
              Tab(text: 'Satış Yap'),
              Tab(text: 'Alış Girişi'),
              Tab(text: 'Ürünler'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OpenReceiptsTab(),
            _QuickSaleTab(),
            _PurchaseEntryTab(),
            _ReceiptProductsTab(),
          ],
        ),
      ),
    );
  }
}

class _OpenReceiptsTab extends StatelessWidget {
  const _OpenReceiptsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _HeroInfoCard(
          icon: Icons.receipt_long_rounded,
          title: 'Açık Adisyonlar',
          text:
              'Bireysel kullanıcı geldiğinde adisyon açılır. Hizmetler, ürünler, personel ve ödeme bilgileri bu dijital fişte toplanır.',
        ),
        SizedBox(height: 12),
        _ModuleStepCard(
          title: 'Bu sekmede olacaklar',
          items: [
            'Randevudan otomatik adisyon açma',
            'Walk-in bireysel kullanıcı için manuel adisyon',
            'Hizmet ve ürün kalemi ekleme',
            'Personel seçimi ve prim hesabı',
            'Adisyonu ödeme ile kapatma',
          ],
        ),
      ],
    );
  }
}

class _QuickSaleTab extends StatelessWidget {
  const _QuickSaleTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _HeroInfoCard(
          icon: Icons.point_of_sale_rounded,
          title: 'Satış Yap',
          text:
              'Randevuya bağlı olmadan hızlı ürün veya hizmet satışı yapılır. Ürün satılırsa stok düşer, gelir finans ekranına yansır.',
        ),
        SizedBox(height: 12),
        _ModuleStepCard(
          title: 'Satış akışı',
          items: [
            'Ürün veya hizmet seç',
            'Adet ve fiyat gir',
            'İsteğe bağlı bireysel kullanıcı bağla',
            'Ödeme yöntemini seç',
            'Satışı tamamla ve gelire işle',
          ],
        ),
      ],
    );
  }
}

class _PurchaseEntryTab extends StatelessWidget {
  const _PurchaseEntryTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _HeroInfoCard(
          icon: Icons.inventory_2_outlined,
          title: 'Alış Girişi',
          text:
              'Kurumsal kullanıcının satın aldığı ürünler bu alana girilir. Alış toplamı masraf kalemine düşer, ürün stoğu artar.',
        ),
        SizedBox(height: 12),
        _ModuleStepCard(
          title: 'Alış kaydı',
          items: [
            'Ürün seç veya yeni ürün oluştur',
            'Alış adedi ve birim maliyet gir',
            'Tedarikçi bilgisini ekle',
            'Stok miktarını artır',
            'Finans ve Masraf ekranına gider olarak işle',
          ],
        ),
      ],
    );
  }
}

class _ReceiptProductsTab extends StatelessWidget {
  const _ReceiptProductsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _HeroInfoCard(
          icon: Icons.shopping_bag_outlined,
          title: 'Adisyon Ürünleri',
          text:
              'Adisyon içinde kullanılacak veya satılacak ürünler buradan seçilir. Ürün halka açık ya da sadece kurum içi olabilir.',
        ),
        SizedBox(height: 12),
        _ModuleStepCard(
          title: 'Ürün davranışı',
          items: [
            'Halka açık ürün bireysel kullanıcı profilinde görünür',
            'Gizli ürün sadece kurum içinde görünür',
            'Satış olunca stok düşer',
            'Alış olunca stok artar',
            'Kâr hesabı için maliyet bilgisi tutulur',
          ],
        ),
      ],
    );
  }
}

class _HeroInfoCard extends StatelessWidget {
  const _HeroInfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleStepCard extends StatelessWidget {
  const _ModuleStepCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

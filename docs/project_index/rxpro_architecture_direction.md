# RxPro Professional Architecture Direction

## Hedef Mimari

RxPro/Fix profesyonel, servis odakli ve denetlenebilir bir mimariyle ilerler:

```text
UI -> application/use case -> domain policy -> repository/service -> Firebase/external systems
```

Detayli hedef agac:

- `docs/project_index/rxpro_target_architecture.md`
- `docs/project_index/rxpro_working_algorithm.md`

## Temel Prensipler

1. UI dosyalari dogrudan Firestore is kurali tasimaz.
2. Firestore collection/field isimleri constants uzerinden yonetilir.
3. Is kurallari policy/service/application katmaninda tutulur.
4. Repository dosyalari data erisiminin merkezi olur.
5. Her modul icin audit -> foundation -> wiring -> verification -> lock duzeni korunur.
6. Push/notification, messages, appointments, finance ve staff gorev akislari hassas kabul edilir.
7. Buyuk refactor yerine kucuk ve kilitlenebilir migration adimlari uygulanir.
8. Yeni UI/root dosyalari dogrudan Firebase acamaz; `tools/architecture_check.ps1` bu siniri denetler.
9. Dogrudan Firebase yuzeyi repository/service/domain disinda 8 onayli altyapi dosyasiyla sinirlidir.

## Proje Ici Fihrist Sistemi

Bu klasordeki dosyalar hafif kalici proje hafizasidir. Agir log/zip/snapshot dosyalari proje disindadir.

- `rxpro_code_index.md`
- `rxpro_service_repository_map.md`
- `rxpro_firestore_dictionary.md`
- `rxpro_locked_lines.md`
- `rxpro_patch_ledger.md`
- `rxpro_risk_map.md`
- `rxpro_remaining_gaps.md`
- `rxpro_target_architecture.md`
- `rxpro_working_algorithm.md`

## Kullanim

Her ana kilit veya orta boy migration sonrasinda fihrist guncellenir.

Yeni gelistirme baslamadan once:

1. Ilgili dosyanin risk seviyesi okunur.
2. Locked line notlari kontrol edilir.
3. Gerekirse once repository/service boundary eklenir.
4. `tools/architecture_check.ps1` calistirilir.
5. `tools/quality_check.ps1` ile genel kontrol tamamlanir.

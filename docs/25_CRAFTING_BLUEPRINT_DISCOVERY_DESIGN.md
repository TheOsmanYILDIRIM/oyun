# Crafting ve Blueprint Keşfi — Tasarım Defteri

> 2026-10-18 | Durum: TASARIM, keşif mekaniği henüz kararlaştırılmadı.
> Repo: TheOsmanYILDIRIM/oyun | Dal: experiment/crafting-discovery-design-20261018
> Başlangıç main: decc19e7a4d7e6eda4f33631672932c184737966
> Beyin görevi: oyun-crafting-blueprint-discovery-design-20261018
> Bu belge kod, kayıt şeması veya mevcut oyun kuralları değildir.

## Kullanıcıyla üzerinde uzlaşılan yön

- **B — Dengeli keşif, hayatta kalma, üretim ve inşa** temel oynanış yönüdür; başlangıç oyunu bir fabrika simülasyonu olmayacak.
- İleride bazı **moblar veya robotlar otomasyona** katkıda bulunabilecek; otomasyon keşif hissini ortadan kaldırmamalı.
- Oyuncu blueprint **bulabilmeli**, nesne/makine **analiziyle öğrenebilmeli** ve **kendi deneyleriyle icat edebilmeli**.
- İlk kez öğrenme güçlü **keşif/buluş hissi** vermeli. Bir kez öğrenilen tarifin sonraki üretimleri **kolay ve hızlı** olmalı; aynı bulmaca tekrar edilmemeli.
- Geleneksel **3×3 / dokuz hücreli crafting grid** yerine, malzemelerin işlevi, davranışı ve dünyadaki neden-sonuç bağlarına dayalı bir oyun mekaniği aranıyor.
- Oyuncu, insan değil, **metal büyülü-teknolojik Core ve kontrollü plazma**. Mekanik bu özgün karakter tasarımıyla anlamlı biçimde bütünleşmeli.
- Daha önce olumlu karşılanan üst düzey fikirler: eşya blueprint'i, kademeli/çok parçalı inşa blueprint'i, ileride davranış blueprint'i; plazma ile saydam yapı projeksiyonu, aşamalı malzeme teslimi, oyuncunun yapılarını plan olarak saklaması; modüler ürün geliştirme, alt-üretim zincirleri, harabe analizi, ileride öğrenilen planların robot/moblara atanması. **Ayrıntılı etkileşim, denge ve teknik sınırlar henüz karara bağlanmadı.**

## Henüz seçilmemiş keşif mekanikleri

### A. Madde Yankıları — Dünya gözlemi
Core, yağmurda iletkenleşen taş, harabedeki titreşim veya mob davranışının ardındaki malzeme/enerji ilişkilerini algılar. Oyuncu ipucunu dünyada takip eder; yalnız taramaya basmak yetmez.
- Güçlü: Arazi keşfine gerçek değer katar.
- Risk: İpuçları fazla gizliyse rastgele dolaşma ve tekrarlı grind olur.

### B. Plazma Deney Alanı — Maddeyle etkileşim
Birkaç malzeme Core çevresinde askıda durur. Oyuncu `bağla`, `ayır`, `ilet`, `ısıt`, `soğut` gibi sınırlı işlemler uygular, gözlenebilir tepkiler alır.
- Güçlü: Oyuncu gerçekten icat yapmış hisseder; Core'a özgü.
- Risk: Tam fizik simülasyonu pahalıdır; her crafting'de mini oyun zorunluluğundan kaçınılmalıdır.

### C. İşlev Devreleri — Sebep-sonuç kurma
Oyuncu girdileri 3×3 karelere dizmez. `enerji kaynağı → iletken → ışık üreten eleman` gibi kısa işlev bağlantılarını kurar; hatalı bağlantı açık geri bildirim verir.
- Güçlü: Ezberlenmiş dizilim yerine çalışma prensibini öğretir.
- Risk: Sınırsız node editörü 320–360dp portrait ekranda kullanılamaz hale gelebilir.

### D. Kayıp Teknoloji — Sistem arkeolojisi
Kırık makine, terk edilmiş tesis veya nadir mob parçası analiz edilir. Core çalışma izlerini çıkarır; oyuncu eksik ilkeyi başka dünyasal ipuçları ve kısa deneyle tamamlar.
- Güçlü: Keşif bölgeleri ve ödüller anlam kazanır.
- Risk: Tek başına kullanılırsa icat sistemi yalnız hazır harabe bulmaya indirgenir.

## Birleşik yaklaşım — YALNIZ ÖNERİ

**İz bul → İpucundan hipotez üret → Kısa deney yap → Çalışma ilkesini keşfet → Blueprint'i kalıcı öğren → Sonraki üretimi tek eyleme indir.**

Örnek (tamamı varsayımsal, kanonik item veya tarif değil): Fırtınada eski bir yön işareti yanıp söner. Core taş damarlarının iletkenliğini ve reçinenin yalıtım etkisini fark eder. Oyuncu küçük deneyde `enerji → iletken → ışık` ilişkisini kurar; yanlış bağlantı kıvılcım ve tanı ipucu üretir. İşlev çalıştığında `Fırtına Feneri` blueprint'i öğrenilir. Bundan sonra aynı feneri yapmak için yeniden keşif bulmacası gerekmez. Gelecekte robotlar bilinen üretim emirlerini uygulayabilir.

**Karar verilmedi:** İlk buluşu taşıyan asıl etkileşim çevre izini takip etmek mi, plazma deneyi mi, işlev bağlantısı mı, yoksa bunların sade bir birleşimi mi?

## UX ve oyun dengesi tasarım sınırları

- Oyuncuya anlaşılır ipucu ver; keşif rastgele yüzlerce kombinasyonun brute-force denemesi olmasın.
- Deney başarısız olduğunda bilgi üretsin; malzeme kaybı ve maliyet dengesi daha sonra kararlaştırılacak.
- Mobil portrait 320–360dp, 392–411dp ve font scale 1.3 dikkate alınsın; serbest sürükleme zorunlu olmamalı, tek dokunma/tap alternatifleri olmalı.
- Yeni keşif işlemi tekrar zorunlu bir zamanlama mini oyununa dönüşmesin.
- Serbest icat duygusu vaat edilirken sınırsız prosedürel yeni item ve kombinasyonların eksiksiz simülasyonu vaat edilmesin; kurallı işlev aileleri tanımlanabilir.
- Keşif eylemleri ileride host-authoritative, idempotent ve sürümlü kayıtlara uygun modellenmeli.

## Mevcut teknik durum ve güvenlik

- `game/love/systems/crafting.lua` ve `data/catalog/recipes/`: tarif `inputs`, `outputs`, `station_tags`, `duration_ticks` ile tanımlı; tarif keşfi, öğrenilen blueprint veya icat deneyleri henüz kodda yok.
- Stage5 12 slot, 5 hotbar, 1 odun → 4 tahta, 4 tahta → tezgâh, 0,5/1 sn başlangıç örnekleridir; tasarım kabulü değildir.
- Workbench JSON `queue_limit:2` tanımlar; çalışan tek-aktif crafting motorunun tamamlanmış üretim kuyruğu olduğu anlamına gelmez.
- Stage6 `save_v2` envanter/dünya/yerleştirme/ledger taşır; keşfedilmiş blueprint, deney durumu, gelecekte robot emirleri ve aşamalı inşaat ayrı sürümlü tasarım gerektirir. İzin ve migration olmadan mevcut kayıt sözleşmesini değiştirme.
- Stage6 görevi `oyun-stage6-save-recovery-20261016`, `experiment/stage5-stage6-integration-v1`, main ve backup, Core/Axe, plazma, fizik/kamera, stüdyolar ve kullanıcı verileri **değiştirilmez**.

## Sıradaki tek karar

Oyuncu yeni bir icadı ilk kez keşfederken ağırlıklı olarak **hangi etkileşimi** yaşamalı? (A) Dünyadaki izlerin peşine düşme; (B) Plazmayla fiziksel deney; (C) işlev devresi kurma; (D) üçünü hafifçe birleştiren bir sistem. Kullanıcı onayı olmadan seçilen varsayımı kanonik kural olarak kaydetme.

## Kaynaklar
- AGENTS.md, README.md
- docs/14_CORE_PLASMA_PROGRESSION_DESIGN.md
- docs/18_LOVE_STAGE5_AND_SAVE_V2.md
- schemas/love-world-v2.schema.json
- game/love/systems/{inventory,crafting,building}.lua

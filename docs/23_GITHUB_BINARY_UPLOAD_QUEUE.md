# Genel GitHub binary aktarımı — Supabase private queue

2026-10-17. Worker: `github-binary-upload` (Supabase `github-control-plane`).
**Bu bir kullanıma hazır genel kontrol akışıdır; açık HTTP yükleme API'si değildir.**

## Ajan kullanım yolu

Bağlı ve yetkili **Supabase MCP SQL** aracıyla `control_private` fonksiyonlarını çağır:
1. Kanonik Avenox Beyin `main/tasks/<task_id>.md` kaydını oku: `kind=task`, doğru `project=repo`, `status=active`.
2. Deney dalının GitHub'daki güncel HEAD'ini belirle. `main`, `backup` veya stable/release/production hedefleme.
3. Yerel dosyanın bayt uzunluğunu ve **SHA-256** değerini hesapla; her parçayı en fazla **65536 bayt** olacak biçimde base64 kodla.
4. SQL yönetim bağlantısından `control_private.binary_start(request_json, sha256, byte_count)` çağır. İstek alanları: `owner`, `repo`, `branch`, `task_id`, `path`, `expected_head`.
5. Dönen `upload_id` ile `control_private.binary_append(upload_id, 0, chunk0_base64)`, ardından artan sıra indeksleri için devam et. Parçaları tekrarlama; yeniden denemeden önce staging durumunu incele.
6. `control_private.binary_submit(upload_id)` tek kullanımlık worker yetkisi üreterek kuyruğa alır. Dönen `job_id` ile `control_private.jobs` kaydından `status` ve yalnız güvenli sonuç alanlarını denetle.
7. GitHub branch HEAD, blob SHA, dosya içeriği/hash ve varsa Actions durumunu ayrıca doğrula. Başarısız veya belirsiz isteği kör tekrar etme.

Bu prosedür **JWT veya BINARY_UPLOAD_SECRET'in ajana verilmesini gerektirmez**. Kimlik/yetki, bağlı Supabase yönetim bağlantısıyla sağlanır. Bağlantısı olmayan veya yeterli izin almamış ajan fonksiyonlara erişemez.

Örnek SQL (BASE64 ve hash gerçek dosyadan hesaplanmalı):

```sql
select control_private.binary_start(
  '{"owner":"TheOsmanYILDIRIM","repo":"oyun",
    "branch":"experiment/core-plasma-energy-runtime-20261016",
    "task_id":"oyun-core-plasma-art-assets-20261016",
    "path":"game/love/assets/core_plasma/core_original.png",
    "expected_head":"<live-40-char-head>"}'::jsonb,
  '<64-char-file-sha256>', <byte-count>);
-- returned upload_id
select control_private.binary_append('<upload_id>'::uuid, 0, '<base64-chunk>');
-- add remaining sequential chunks
select control_private.binary_submit('<upload_id>'::uuid);
select status,result from control_private.jobs where id='<job_id>'::uuid;
```

## Güvenlik sözleşmesi

- İzinli repolar: `oyun`, `mineclonia-texture-studio`, izole `github-control-test`. Yeni repo isteği ayrı politika incelemesi gerektirir.
- Yalnız `experiment/*` ve `test/*` dalları; `main`, backup/yedek, stable, release, production hedefleri engellenir.
- Maksimum dosya **6 MiB**, parça başına **64 KiB**, en fazla 128 sıralı parça. Büyük assetleri anlamlı, ayrı dosyalara böl.
- İzinli uzantılar: PNG, GIF, JPG/JPEG, WEBP, OGG, WAV, JSON, BIN. Worker dosya imzasını (JSON için sözdizimini) kontrol eder.
- Public REST/Data API'dan staging fonksiyonlarına `anon`/`authenticated` yürütme izni verilmez. JWT doğrulaması kapalı olan Edge Function, yalnız özel iş kuyruğunun ürettiği tek kullanımlık 256-bit capability ile çalışır.
- Görev onayı, yüklemeden önce ve worker içinde kanonik `agy-vault/main` kaynağından kontrol edilir.
- SHA-256 staging ve GitHub blob geri okumada doğrulanır. `expected_head` ile HEAD çakışması reddedilir, non-force ref güncellemesi uygulanır.
- Kuyruk son durumuna rağmen GitHub HEAD ve dosyayı geri okumadan başarı ilan edilmez.
- Tek dosya/commit atomik; **çoklu assetleri tek bir transaction olarak aktarma garantisi yoktur**. Sonraki dosya güncel HEAD'i kullanmalı.
- Servis rolü ve GitHub token yalnız Edge Function ortamında kalır; kullanıcılara ve ajanlara gösterilmez.
- `control_private.binary_uploads/binary_chunks` staging içeriğinin kalıcı temizliği ayrıca yönetilmeli. Gizli veya kişisel dosyaları gereksiz stage etme.

## Doğrulanmış testler

- Yeni v1 worker kuyruğuyla 41 bayt JSON → Github HEAD `de28f2c0785e3c6e49fb8638ee81b6659a744930`; SHA-256 `36224f8d1f098514895878d51eceb2c1030f8bd92211d364d606e064ac1005db` geri okundu.
- Eski HEAD ile iş denemesi `head_conflict` (409) sonucu verdi, dal korunarak yazma reddedildi.
- Standart `github-binary-upload` v2 adıyla aynı kuyruk yolu ikinci kez doğrulandı: HEAD `a354b1c564a98487a2cefe43b4bd6d2c0a5ab1ca`; dosya SHA aynı.
- Test JSON dosyaları deney dalından silindi. Normal `github-control-general` v4 değiştirilmedi.
- Tam boyutlu PNG/GIF transferi ve aktif oyun LÖVE render testi henüz bu kuyruğun kabul kanıtı değildir.

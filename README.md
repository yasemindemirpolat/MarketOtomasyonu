# Market Otomasyonu

## Proje Ekibi

- Menekşe Karakuş
- Hilal Karayiğit
- Yasemin Demirpolat

## Proje Tanımı ve Amacı

Bu proje, bir marketin veri yönetimini kolaylaştırmak ve müşteri deneyimini geliştirmek amacıyla bir veritabanı sistemi geliştirmeyi hedeflemektedir. Sistem, müşterilerin alışveriş geçmişini takip etmesine, indirim ve promosyonlardan faydalanmasına, ürünlerin ve tedarikçilerin yönetilmesine olanak tanıyacaktır.

## 1. Proje Gereksinimleri

### 1.1 Fonksiyonel Gereksinimler

Varlıklar arası ilişkiler nasıl kurulmuştur, bu ilişkilerde ne gibi sayısal kısıtlamalar uygulanmıştır? Farklı kullanıcı türleri için gereksinimler nelerdir?

- **Müşteri Yönetimi**: Müşterilerin kimlik bilgileri, kart bilgileri, indirimler ve alışveriş geçmişi yönetilecektir.
- **Personel Yönetimi**: Personelin kimlik bilgileri, indirimler ve yemek ücretleri gibi bilgiler tutulacaktır.
- **Ürün Yönetimi**: Ürünlerin kategori, stok durumu, fiyat bilgileri ve markaları hakkında detaylı bilgiler sunulacaktır.
- **Tedarikçi Yönetimi**: Tedarikçilerin kimlik bilgileri ve iletişim bilgileri yönetilecektir.
- **Raf Yönetimi**: Ürünlerin raflara yerleştirilmesi ve raf bilgileri tutulacaktır.

### 1.2 Kullanıcı Rolleri ve Yetkileri

a. **Müşteri**:

- Kart bilgilerini görüntüleyebilir.
- Alışveriş geçmişini inceleyebilir.
- İndirimleri uygulayabilir.

b. **Personel**:

- Ürünleri yönetebilir.
- Müşterilere yardımcı olabilir.

c. **Yönetici**:

- Tüm sistemin genel yönetimini yapabilir.
- Kullanıcı rolleri ve izinlerini düzenleyebilir.

## 2. Veri Yapıları

### Tablolar ve Alanlar

1. **Müşteriler**:

   - Müşteri_ID
   - Ad
   - Soyad
   - Kart Bilgileri
   - İndirimler
   - Alışveriş Geçmişi

2. **Personel**:

   - Personel_ID
   - Ad
   - Soyad
   - İndirim Bilgileri
   - Yemek Ücreti

3. **Ürünler**:

   - Ürün_ID
   - Kategori_ID
   - Stok Durumu
   - Alış Fiyatı
   - Satış Fiyatı
   - Raf_ID
   - Marka Bilgisi

4. **Kategoriler**:

   - Kategori_ID
   - Kategori Adı
   - Sorumlu Personel_ID
   - Stok Durumu

5. **Raflar**:

   - Raf_ID
   - Raf İçeriği

6. **Tedarikçiler**:

   - Tedarikçi_ID
   - Tedarikçi Adı
   - İletişim Bilgileri

7. **Markalar**:
   - Marka_ID
   - Marka Adı

## 3. Teknik Gereksinimler

- **Veritabanı Yönetim Sistemi (DBMS)**: SQL (MySQL, PostgreSQL vb.)
- **Güvenlik**: Verilerin şifrelenmesi ve yetkilendirme politikalarının uygulanması.
- **Yedekleme**: Düzenli veri yedekleme işlemleri.

## 4. Projede Yapılacak İşlemler

- Müşteri ve personel kayıt işlemleri.
- Ürün ekleme ve güncelleme işlemleri.
- Alışveriş kayıtlarının yönetimi.
- İndirim ve promosyon uygulama işlemleri.
- Raporlama ve analiz işlemleri.

  ![ER Diyagramı](Diyagram.png)

**PERSONEL KART**(\_KartID,\_Bakiye,\_IndirimCeki)
-MUSTERI(\_MusteriID,\_MusteriAdSoyad,\_MusteriTelNo,\_MusteriEmail,\_MusteriAdres,\_AlinanUrunID)
-MUSTERIKART(\_MusteriID,\_Indirim,\_Bakiye,\_YapilanAlisveris)
-P-ERSONEL(\_personeID,\_personelAdi,\_personelAdresi,\_personelTelNo,\_personelEmail,\_calistigiKategoriID,\_Maas)
-KATEGORI(\_kategoriID,\_kategoriAdi,\_kategoriSorumluPersonelAdi,\_kategoriStokDurumu)
-RAFBILGISI(\_RafID,\_Raficerigi)

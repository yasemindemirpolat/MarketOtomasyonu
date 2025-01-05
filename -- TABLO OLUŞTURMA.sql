-- TABLO OLUŞTURMA 

-- RAFBILGISI Tablosu
CREATE TABLE RAFBILGISI (
  RafID INT PRIMARY KEY,
  Raficerigi VARCHAR(255)
);
-- MUSTERI Tablosu
CREATE TABLE MUSTERI (
  MusteriID INT PRIMARY KEY,
  MusteriAdSoyad VARCHAR(100),
  MusteriTelNo VARCHAR(15),
  MusteriEmail VARCHAR(100),
  MusteriAdres VARCHAR(255),
);
-- MUSTERIKART Tablosu
CREATE TABLE MUSTERIKART (
  MusteriID INT PRIMARY KEY,
  Indirim DECIMAL(5, 2),
  Bakiye DECIMAL(10, 2),
  YapilanAlisveris INT,
  FOREIGN KEY (MusteriID) REFERENCES MUSTERI(MusteriID)
);
-- KATEGORI Tablosu
CREATE TABLE KATEGORI (
  KategoriID INT PRIMARY KEY,
  KategoriAdi VARCHAR(50),
  KategoriSorumluPersonelAdi VARCHAR(100),
  KategoriStokDurumu INT
);
-- ALTKATEGORI Tablosu
CREATE TABLE ALTKATEGORI (
  AltKategoriID INT PRIMARY KEY,
  AltKategoriAdi VARCHAR(255) NOT NULL,
  KategoriID INT,
  AltKategoriStok INT,
  FOREIGN KEY (KategoriID) REFERENCES KATEGORI(KategoriID)
);
-- TEDARIKCI Tablosu
CREATE TABLE TEDARIKCI (
  TedarikciID INT PRIMARY KEY,
  FirmaAdi varchar(50),
  TedarikciTelNo VARCHAR(15)
);
-- PERSONEL Tablosu
CREATE TABLE PERSONEL (
  PersonelID INT PRIMARY KEY,
  PersonelAdi VARCHAR(100),
  PersonelAdresi VARCHAR(255),
  PersonelTelNo VARCHAR(15),
  PersonelEmail VARCHAR(100),
  CalistigiKategoriID INT,
  Maas DECIMAL(10, 2),
  FOREIGN KEY (CalistigiKategoriID) REFERENCES KATEGORI(KategoriID)
);
-- PERSONEL_KART Tablosu
CREATE TABLE PERSONEL_KART (
  KartID INT PRIMARY KEY,
  Bakiye DECIMAL(10, 2),
  IndirimCeki INT,
  FOREIGN KEY (KartID) REFERENCES PERSONEL(PersonelID)
);
-- URUNLISTESI Tablosu
CREATE TABLE URUNLISTESI (
  UrunID INT PRIMARY KEY,
  KategoriID INT,
  UrunAdi VARCHAR(100),
  StokDurumu DECIMAL(10, 2),
  AlisFiyati DECIMAL(10, 2),
  SatisFiyati DECIMAL(10, 2),
  RafBilgisiID INT,
  TedarikciID INT,
  FOREIGN KEY (KategoriID) REFERENCES KATEGORI(KategoriID),
  FOREIGN KEY (RafBilgisiID) REFERENCES RAFBILGISI(RafID),
  FOREIGN KEY (TedarikciID) REFERENCES TEDARIKCI(TedarikciID)
);
-- MARKA Tablosu
CREATE TABLE MARKA (
  MarkaID INT PRIMARY KEY,
  MarkaAdi VARCHAR(50),
  MarkaStok INT,
  UrunID INT,
  FOREIGN KEY (UrunID) REFERENCES URUNLISTESI(UrunID)
);
-- INDIRIM Tablosu
CREATE TABLE INDIRIM (
  UygulananIndirimID INT PRIMARY KEY,
  UygulananMarkaID INT,
  IndirimMiktari DECIMAL(5, 2),
  FOREIGN KEY (UygulananMarkaID) REFERENCES MARKA(MarkaID)
);
-- URUN_RAF Tablosu
CREATE TABLE URUN_RAF (
  RafID INT,
  UrunID INT,
  PRIMARY KEY (RafID, UrunID),
  FOREIGN KEY (RafID) REFERENCES RAFBILGISI(RafID),
  FOREIGN KEY (UrunID) REFERENCES URUNLISTESI(UrunID)
);
-- URUNLISTESI Tablosuna MarkaID sütunu ekleyerek güncelleme
ALTER TABLE URUNLISTESI
ADD MarkaID INT;

-- Marka bilgisi ekleyerek güncelleme
UPDATE URUNLISTESI
SET MarkaID = (SELECT MarkaID FROM MARKA WHERE MARKA.UrunID = URUNLISTESI.UrunID);

-- Marka bilgisi ekleyerek güncelleme
UPDATE URUNLISTESI
SET MarkaID = (SELECT MarkaID FROM MARKA WHERE MARKA.UrunID = URUNLISTESI.UrunID);






------- TRİGGERSLAR------

--PERSONEL KART ve PERSONEL Tabloları Arasındaki Tetikleyici:
CREATE TRIGGER trg_personel_kart_guncelleme
ON PERSONEL_KART
AFTER UPDATE
AS
BEGIN
  UPDATE PERSONEL
  SET Maas = i.Bakiye
  FROM PERSONEL INNER JOIN inserted i ON PERSONEL.PersonelID = i.KartID;
END;

-------------------------------------
--ÜRÜNLİSTESİ ve MARKA Tabloları Arasındaki Tetikleyici:
CREATE TRIGGER trg_urun_ekleme
ON URUNLISTESI
AFTER INSERT
AS
BEGIN
  IF NOT EXISTS (SELECT 1 FROM MARKA WHERE UrunID = (SELECT UrunID FROM inserted))
  BEGIN
    INSERT INTO MARKA (MarkaAdi, MarkaStok, UrunID)
    VALUES ('Belirsiz', 0, (SELECT UrunID FROM inserted));
  END;
END;
--------------------------------------
--ÜRÜN_RAF ve RAFBILGISI Tabloları Arasındaki Tetikleyici:
CREATE TRIGGER trg_urun_raf_guncelleme
ON URUN_RAF
AFTER INSERT, DELETE
AS
BEGIN
  UPDATE RAFBILGISI
  SET Raficerigi = 
    CASE
      WHEN EXISTS (SELECT 1 FROM inserted) THEN 
        CONCAT(Raficerigi, ', ', (SELECT UrunID FROM inserted))
      ELSE 
        REPLACE(Raficerigi, CONCAT(', ', (SELECT UrunID FROM deleted)), '')
    END
  WHERE RafID = (SELECT RafID FROM inserted) OR RafID = (SELECT RafID FROM deleted);
END;
----------------------------------

--MÜŞTERIKART ve MÜŞTERİ Tabloları Arasındaki Tetikleyici:
CREATE TRIGGER trg_musteri_kart_guncelleme
ON MUSTERIKART
AFTER UPDATE
AS
BEGIN
  UPDATE MUSTERI
  SET MusteriAdSoyad = CONCAT('Müşteri ', i.MusteriID)
  FROM MUSTERI INNER JOIN inserted i ON MUSTERI.MusteriID = i.MusteriID;
END;
---------------------------------------

--İNDİRİM ve MARKA Tabloları Arasındaki Tetikleyici:
CREATE TRIGGER trg_indirim_guncelleme
ON INDIRIM
AFTER UPDATE
AS
BEGIN
  UPDATE MARKA
  SET MarkaStok = MarkaStok - i.IndirimMiktari
  FROM MARKA INNER JOIN inserted i ON MARKA.MarkaID = i.UygulananMarkaID;
END;

---------------------------------------

--CREATE TRIGGER trg_UrunGuncelle
--ON URUNLISTESI
--AFTER UPDATE
--AS
--BEGIN
  --UPDATE m
  --SET MarkaStok = u.StokDurumu
  --FROM MARKA m
  --INNER JOIN INSERTED i ON m.UrunID = i.UrunID
  --INNER JOIN UPDATED u ON i.UrunID = u.UrunID;
--END;

--------------------------------------

-- Tetikleyiciyi tekrar oluşturma
CREATE TRIGGER tr_urunlistesi_after_insert
ON MARKA
AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE URUNLISTESI
  SET MarkaID = i.MarkaID
  FROM URUNLISTESI u
  INNER JOIN INSERTED i ON u.UrunID = i.UrunID;
END;
--------------------------------------

--- urunlıstesı ve rafbilgisi tablosuna veri girşi yapmadan önce bu komutu çalıştır
-- URUNLISTESI tablosuna ürün eklendiğinde çalışacak trigger
CREATE TRIGGER trg_URUNLISTESI
ON URUNLISTESI
AFTER INSERT
AS
BEGIN
    DECLARE @RafID INT;
    
    -- Varsayılan bir raf seçimi, örneğin RafID = 1
    SET @RafID = 1;
    
    -- URUN_RAF tablosuna yeni ürünü ve rafı ekleyen SQL sorgusu
    INSERT INTO URUN_RAF (RafID, UrunID)
    SELECT @RafID, UrunID FROM INSERTED;
END;
------------------------------------------




--------VERI GIRISLERI-------
delete from RAFBILGISI;

---- RAFBILGISI VERI GIRISI
INSERT INTO RAFBILGISI ( RafID, Raficerigi) VALUES
(1,'Meyve – Sebze, Et - Tavuk – Balık, Süt – Kahvaltılık'),
(2, 'Temel Gıda, Meze - Hazır Yemek - Donuk, Fırın - Pastane'),
(3, 'Dondurma, Atıştırmalık, İçecek'),
(4,'Deterjan – Temizlik, Kağıt - Islak Mendil, Kişisel Temizlik - Kozmetik – Sağlık'),
(5,'Bebek, Ev – Yaşam, Kırtasiye - Oyuncak'),
(6,'Çiçek, Pet Shop, Elektronik');

---- KATEGORI VERI GIRISI
INSERT INTO KATEGORI (KategoriID, KategoriAdi, KategoriStokDurumu)
VALUES
(1,'Meyve – Sebze', 1000),
(2,'Et - Tavuk – Balık',1000),
(3,'Süt – Kahvaltılık',1000),
(4,'Temel Gıda',1000),
(5,'Meze - Hazır Yemek - Donuk',1000),
(6,'Fırın – Pastane',1000),
(7,'Dondurma',1000),
(8,'Atıştırmalık',1000),
(9,'İçecek',1000),
(10,'Deterjan – Temizlik',1000),
(11,'Kağıt - Islak Mendil',1000),
(12,'Kişisel Temizlik - Kozmetik – Sağlık',1000),
(13,'Bebek',1000),
(14,'Ev – Yaşam',1000),
(15,'Kitap - Kırtasiye - Oyuncak',1000),
(16,'Çiçek',1000),
(17,'Pet Shop',1000),
(18,'Elektronik',1000);

-- PERSONEL tablosunda PersonelID'yı Identity kısmını yes ayarla

---- PERSONEL VERI GIRISI
INSERT INTO PERSONEL (PersonelAdi, PersonelEmail, PersonelAdresi, PersonelTelNo)
VALUES ('Yelda Özbek', 'yelda.ozbek@gmail.com', 'Yozgat', '09403409075'),
('Zara Yanar', 'zara.yanar@gmail.com', 'Çorum', '05350787528'),
('Naz Narin', 'naz.narin@gmail.com', 'Kahramanmaraş', '02590935708'),
('Elvan Çimşek', 'elvan.cimsek@gmail.com', 'Zonguldak', '07122319891'),
('Merve Yıldız', 'merve.yildiz@gmail.com', 'Ardahan', '07808986913'),
('Gözde Karadeniz', 'gozde.karadeniz@gmail.com', 'Diyarbakır', '02417759526'),
('Eylül Kurtuluş', 'eylul.kurtulus@gmail.com', 'Muğla', '00289022806'),
('Eylül Kurtulan', 'eylul.kurtulan@gmail.com', 'Bartın', '00262021407'),
('Melis Kurt', 'melis.kurt@gmail.com', 'Afyonkarahisar', '08834841177'),
('Zümra Çimşek', 'zumra.cimsek@gmail.com', 'Şırnak', '08570042609'),
('Sude Erkan', 'sude.erkan@gmail.com', 'Adana', '01210762575'),
('Vildan Yalçın', 'vildan.yalcin@gmail.com', 'İzmir', '07753160772'),
('Zara Özbek', 'zara.ozbek@gmail.com', 'Aksaray', '02722654395'),
('Eylül Ziya', 'eylul.ziya@gmail.com', 'Ardahan', '03318511333'),
('Damla Karakuş', 'damla.karakus@gmail.com', 'Kocaeli', '09150105203'),
('Lara Karadağ', 'lara.karadag@gmail.com', 'Zonguldak', '09214656297'),
('Zara Güzel', 'zara.guzel@gmail.com', 'Istanbul', '06850426198'),
('Elvan Şoban', 'elvan.soban@gmail.com', 'Van', '08138551161'),
('Alya Aksoy', 'alya.aksoy@gmail.com', 'Diyarbakır', '03384866355'),
('Rabia Aktaş', 'rabia.aktas@gmail.com', 'Aksaray', '09022849098'),
('Merve Özdemir', 'merve.ozdemir@gmail.com', 'Gaziantep', '04066337070'),
('Nihan Tekin', 'nihan.tekin@gmail.com', 'Şırnak', '04121651210'),
('Elif Ayhan', 'elif.ayhan@gmail.com', 'Isparta', '05018304954'),
('Gül Saraçoğlu', 'gul.saracoglu@gmail.com', 'Sakarya', '09131110626'),
('Göktürk Toprak', 'gokturk.toprak@gmail.com', 'Tokat', '04621778711'),
('Ceyda Şoban', 'ceyda.soban@gmail.com', 'Zonguldak', '06580075580'),
('Yasmin Karakuş', 'yasmin.karakus@gmail.com', 'Muğla', '00487034845'),
('Leyla Arslan', 'leyla.arslan@gmail.com', 'Isparta', '03549195110'),
('Burcu Tuncer', 'burcu.tuncer@gmail.com', 'Van', '03516600771'),
('Elif Özbek', 'elif.ozbek@gmail.com', 'Van', '04514695742'),
('Eylül Arslan', 'eylul.arslan@gmail.com', 'Adıyaman', '03160518711'),
('Alya Yücel', 'alya.yucel@gmail.com', 'Manisa', '00243074937'),
('Gözde Şen', 'gozde.sen@gmail.com', 'Hatay', '06723190971'),
('Göktürk Gül', 'gokturk.gul@gmail.com', 'Erzurum', '05611050066'),
('Merve Tekin', 'merve.tekin@gmail.com', 'Kahramanmaraş', '05152045087'),
('Naz Narin', 'naz.narin@gmail.com', 'Antalya', '08152362940'),
('Zara Erkan', 'zara.erkan@gmail.com', 'Bursa', '02165102765'),
('Nisan Yalçın', 'nisan.yalcin@gmail.com', 'Istanbul', '08122454125'),
('Vildan Şoban', 'vildan.soban@gmail.com', 'Amasya', '04422020541'),
('Rabia Özer', 'rabia.ozer@gmail.com', 'Rize', '01655203901'),
('Esra Çetin', 'esra.cetin@gmail.com', 'Denizli', '06281039182'),
('Selin Aydemir', 'selin.aydemir@gmail.com', 'Zonguldak', '09421762480'),
('Naz Karadağ', 'naz.karadag@gmail.com', 'Tekirdağ', '05359890608'),
('Naz Şahin', 'naz.sahin@gmail.com', 'Sivas', '06485303247'),
('Esra Aslan', 'esra.aslan@gmail.com', 'Hakkari', '04926908530'),
('Gül Çelik', 'gul.celik@gmail.com', 'İzmir', '01099361157'),
('Begüm Yıldız', 'begum.yildiz@gmail.com', 'Kırıkkale', '06697643711'),
('Esra Mete', 'esra.mete@gmail.com', 'Afyonkarahisar', '00128461450'),
('İlkay Arslan', 'ilkay.arslan@gmail.com', 'Sakarya', '06947403109'),
('Cansu Özkan', 'cansu.ozkan@gmail.com', 'Mardin', '01511045433'),
('Umay Ay', 'umay.ay@gmail.com', 'Adana', '05814426101'),
('Asena Karakuş', 'asena.karakus@gmail.com', 'Tunceli', '09092980678'),
('Oya Korkmaz', 'oya.korkmaz@gmail.com', 'Bursa', '07162922783'),
('Efsun Akbulut', 'efsun.akbulut@gmail.com', 'Kars', '08228768669'),
('İlknur Öztürk', 'ilknur.ozturk@gmail.com', 'Isparta', '04723308399'),
('Deniz Karakuş', 'deniz.karakus@gmail.com', 'Tokat', '03882167150'),
('Leyla Çimşek', 'leyla.cimsek@gmail.com', 'Bingöl', '04261031120'),
('Elif Öztürk', 'elif.ozturk@gmail.com', 'Hatay', '00554200769'),
('Ela Şenel', 'ela.senel@gmail.com', 'Tokat', '03610019379'),
('Hande Çetin', 'hande.cetin@gmail.com', 'Kütahya', '07836206316'),
('Cemre Özbek', 'cemre.ozbek@gmail.com', 'Mardin', '01266067975'),
('Merve Yanar', 'merve.yanar@gmail.com', 'Uşak', '01738898852'),
('Deniz Kaya', 'deniz.kaya@gmail.com', 'Sinop', '03807801364'),
('Umay Çelik', 'umay.celik@gmail.com', 'Kırıkkale', '07723596150'),
('Sema Kaya', 'sema.kaya@gmail.com', 'Malatya', '02672936258'),
('Oya Şoban', 'oya.soban@gmail.com', 'Karabük', '09515848692'),
('İrem Tuncer', 'irem.tuncer@gmail.com', 'Sakarya', '00422233992'),
('Gözde Duran', 'gozde.duran@gmail.com', 'Adıyaman', '07902891674'),
('Nisan Kurt', 'nisan.kurt@gmail.com', 'Kırklareli', '07746331376'),
('Yasmin Şoban', 'yasmin.soban@gmail.com', 'Kırşehir', '00915644514'),
('Derya Karadeniz', 'derya.karadeniz@gmail.com', 'Kırıkkale', '03959351815'),
('Rana Mete', 'rana.mete@gmail.com', 'Kırklareli', '00841933132'),
('Nisan Ziya', 'nisan.ziya@gmail.com', 'Bayburt', '08384786320'),
('Damla Erdoğan', 'damla.erdogan@gmail.com', 'Kars', '02544734087'),
('Eylül Karadeniz', 'eylul.karadeniz@gmail.com', 'Kırklareli', '06580994165'),
('İlkay Yalçın', 'ilkay.yalcin@gmail.com', 'Tekirdağ', '07869769654'),
('Derya Ayhan', 'derya.ayhan@gmail.com', 'Mardin', '01439929439'),
('Yaren Aslan', 'yaren.aslan@gmail.com', 'Muş', '09148335948'),
('Aslı Taşkın', 'asli.taskin@gmail.com', 'Kars', '01644603571'),
('Eylül Özer', 'eylul.ozer@gmail.com', 'Osmaniye', '00155752147'),
('Rana Aydemir', 'rana.aydemir@gmail.com', 'Kırıkkale', '08160936009'),
('Oya Özbek', 'oya.ozbek@gmail.com', 'Trabzon', '01694070277'),
('Gül Kaya', 'gul.kaya@gmail.com', 'Bitlis', '00721577975'),
('Elvan Özbek', 'elvan.ozbek@gmail.com', 'Kahramanmaraş', '09844284298'),
('Ebru Yıldız', 'ebru.yildiz@gmail.com', 'Çanakkale', '07191068270'),
('Elçin Özer', 'elcin.ozer@gmail.com', 'Diyarbakır', '02234618819'),
('Cemre Kaplan', 'cemre.kaplan@gmail.com', 'Rize', '09435131612'),
('Dilara Saraçoğlu', 'dilara.saracoglu@gmail.com', 'Ordu', '01817918488'),
('Yasemin Çelik', 'yasemin.celik@gmail.com', 'Kocaeli', '00392359450'),
('Elvan Kaplan', 'elvan.kaplan@gmail.com', 'Edirne', '00736229680'),
('Yasemin Yılmaz', 'yasemin.yilmaz@gmail.com', 'Samsun', '04452157534'),
('Burcu Tekin', 'burcu.tekin@gmail.com', 'Şırnak', '04211752443'),
('Pınar Yıldırım', 'pinar.yildirim@gmail.com', 'Manisa', '07569234997'),
('Lara Mete', 'lara.mete@gmail.com', 'Nevşehir', '00177593497'),
('Lara Aslan', 'lara.aslan@gmail.com', 'Malatya', '01339931858'),
('İclal Şahin', 'iclal.sahin@gmail.com', 'Adana', '06784245379'),
('Damla Ayhan', 'damla.ayhan@gmail.com', 'Denizli', '00553281058'),
('Irmak Özkan', 'irmak.ozkan@gmail.com', 'Gaziantep', '01987097725'),
('Leyla Karakuş', 'leyla.karakus@gmail.com', 'Şanlıurfa', '00303639741'),
('Nisa Karakuş', 'nisa.karakus@gmail.com', 'Osmaniye', '03236155457'),
('Irmak Özgür', 'irmak.ozgur@gmail.com', 'Niğde', '07298412526'),
('Selma Güneş', 'selma.gunes@gmail.com', 'Istanbul', '04840673179'),
('Selin Şoban', 'selin.soban@gmail.com', 'Mersin', '08537033631'),
('Gizem Erkan', 'gizem.erkan@gmail.com', 'Düzce', '01363302850'),
('Oya Kurtuluş', 'oya.kurtulus@gmail.com', 'Bilecik', '00706271648'),
('Büşra Özdemir', 'busra.ozdemir@gmail.com', 'Kayseri', '02730056470'),
('Oya Yalın', 'oya.yalin@gmail.com', 'Yalova', '06760473992'),
('Asena Saraçoğlu', 'asena.saracoglu@gmail.com', 'Bilecik', '06947415539'),
('Eylül Karadağ', 'eylul.karadag@gmail.com', 'Yalova', '05576138440'),
('Cemre Karadağ', 'cemre.karadag@gmail.com', 'Trabzon', '04380654093'),
('Ece Tekin', 'ece.tekin@gmail.com', 'Edirne', '02719939989'),
('Selin Çelik', 'selin.celik@gmail.com', 'Gaziantep', '09409856159'),
('Dilara Koç', 'dilara.koc@gmail.com', 'Malatya', '09870089594'),
('Alya Soydan', 'alya.soydan@gmail.com', 'Mardin', '02916154630'),
('Elvan Kurt', 'elvan.kurt@gmail.com', 'Bayburt', '02348987356'),
('Hande Yalın', 'hande.yalin@gmail.com', 'Siirt', '02941910311'),
('Gül Demir', 'gul.demir@gmail.com', 'Antalya', '01984246483'),
('Cansu Koç', 'cansu.koc@gmail.com', 'Düzce', '00868535306'),
('Elçin Aksoy', 'elcin.aksoy@gmail.com', 'Erzurum', '07984246258'),
('Selma Tekin', 'selma.tekin@gmail.com', 'Nevşehir', '05332445387'),
('Rana Aydemir', 'rana.aydemir@gmail.com', 'Yozgat', '07847365101'),
('Ezgi Özbek', 'ezgi.ozbek@gmail.com', 'Bilecik', '09902207154'),
('Asena Kaplan', 'asena.kaplan@gmail.com', 'Hatay', '00309694288'),
('Zümra Kurtulan', 'zumra.kurtulan@gmail.com', 'Zonguldak', '02964315433'),
('Selma Ayhan', 'selma.ayhan@gmail.com', 'Bursa', '07647386812'),
('Rabia Kurtulan', 'rabia.kurtulan@gmail.com', 'İzmir', '07146794390'),
('Tuna Aktaş', 'tuna.aktas@gmail.com', 'Manisa', '02278000285'),
('Eylül Özkan', 'eylul.ozkan@gmail.com', 'Iğdır', '08359107800'),
('Asya Karadeniz', 'asya.karadeniz@gmail.com', 'Kırıkkale', '04346646456'),
('Leyla Duran', 'leyla.duran@gmail.com', 'Mersin', '03682948836'),
('Selin Karadeniz', 'selin.karadeniz@gmail.com', 'Yozgat', '01463361290'),
('Alya Şoban', 'alya.soban@gmail.com', 'Sinop', '08070121565'),
('Göktürk Ay', 'gokturk.ay@gmail.com', 'Ağrı', '04258878059'),
('Derya Aksoy', 'derya.aksoy@gmail.com', 'Sakarya', '05792882091'),
('Ece Arslan', 'ece.arslan@gmail.com', 'Artvin', '08924614150'),
('Cemre Narin', 'cemre.narin@gmail.com', 'Bursa', '02906111814'),
('Melike Koç', 'melike.koc@gmail.com', 'Hakkari', '03695694148'),
('Elif Koç', 'elif.koc@gmail.com', 'Kars', '01802467032'),
('Selin Yıldırım', 'selin.yildirim@gmail.com', 'Adana', '07544813269'),
('Naz Akbulut', 'naz.akbulut@gmail.com', 'Kırklareli', '00456534883'),
('Asya Acar', 'asya.acar@gmail.com', 'Iğdır', '03404424960'),
('Serra Korkmaz', 'serra.korkmaz@gmail.com', 'Diyarbakır', '02644909719'),
('Hande Duran', 'hande.duran@gmail.com', 'Erzurum', '08516216172'),
('Selin Gül', 'selin.gul@gmail.com', 'Bartın', '04305864848'),
('Lara Yıldırım', 'lara.yildirim@gmail.com', 'İzmir', '07322167450'),
('Cemre Erkan', 'cemre.erkan@gmail.com', 'Amasya', '07903296598'),
('İclal Aslan', 'iclal.aslan@gmail.com', 'Bingöl', '06082405268'),
('Damla Yıldızoğlu', 'damla.yildizoglu@gmail.com', 'Adıyaman', '01787872247'),
('Zeliha Erkan', 'zeliha.erkan@gmail.com', 'Tunceli', '04433049225'),
('Eylül Özgür', 'eylul.ozgur@gmail.com', 'Istanbul', '09353638346'),
('İclal Şoban', 'iclal.soban@gmail.com', 'Uşak', '01252423744'),
('Nihan Güzel', 'nihan.guzel@gmail.com', 'Çorum', '05234747996'),
('Gizem Yücel', 'gizem.yucel@gmail.com', 'Van', '09560384695'),
('Begüm Karadeniz', 'begum.karadeniz@gmail.com', 'Muş', '07215518799'),
('Zeliha Kurt', 'zeliha.kurt@gmail.com', 'Aydın', '08624964636'),
('Ceren Kurtulan', 'ceren.kurtulan@gmail.com', 'Denizli', '03795381066'),
('Leyla Gül', 'leyla.gul@gmail.com', 'Bartın', '04680815761'),
('Esra Ziya', 'esra.ziya@gmail.com', 'Hatay', '02406099645'),
('Tuna Aktaş', 'tuna.aktas@gmail.com', 'Ankara', '08654097168'),
('Eylül Narin', 'eylul.narin@gmail.com', 'Bilecik', '00937049526'),
('Zara Aksoy', 'zara.aksoy@gmail.com', 'Kars', '09762472122'),
('Umay Kurtuluş', 'umay.kurtulus@gmail.com', 'Karabük', '01426589105'),
('Efsun Ayhan', 'efsun.ayhan@gmail.com', 'Kastamonu', '06622603423'),
('Sude Akbulut', 'sude.akbulut@gmail.com', 'Çorum', '05465593445'),
('Sema Özgür', 'sema.ozgur@gmail.com', 'Erzurum', '09675814142'),
('Eylül Özbek', 'eylul.ozbek@gmail.com', 'Kilis', '03715815218'),
('Melike Ayhan', 'melike.ayhan@gmail.com', 'Düzce', '01766914115'),
('Rabia Gül', 'rabia.gul@gmail.com', 'Eskişehir', '07928364412'),
('İlayda Özkan', 'ilayda.ozkan@gmail.com', 'Kırklareli', '05417010503'),
('Lara Yücel', 'lara.yucel@gmail.com', 'Hatay', '00760621482'),
('Merve Öztürk', 'merve.ozturk@gmail.com', 'Aydın', '00279198180'),
('Nisan Toprak', 'nisan.toprak@gmail.com', 'Elazığ', '04102777905'),
('Zeynep Saraçoğlu', 'zeynep.saracoglu@gmail.com', 'Çanakkale', '03534056121'),
('Asya Özgür', 'asya.ozgur@gmail.com', 'Trabzon', '09397177992'),
('Leyla Özkan', 'leyla.ozkan@gmail.com', 'Hatay', '05776426854'),
('Begüm Tuncer', 'begum.tuncer@gmail.com', 'Çanakkale', '07617450775'),
('Nazlı Kurt', 'nazli.kurt@gmail.com', 'Burdur', '02736595534'),
('Aylin Koç', 'aylin.koc@gmail.com', 'Adıyaman', '01944404400'),
('Pınar Arslan', 'pinar.arslan@gmail.com', 'Mardin', '04676259198'),
('Lina Şenel', 'lina.senel@gmail.com', 'Denizli', '02553931132'),
('Derya Yalın', 'derya.yalin@gmail.com', 'Hatay', '09231991447'),
('Vildan Öztürk', 'vildan.ozturk@gmail.com', 'Adıyaman', '02569431153'),
('Rüya Yılmaz', 'ruya.yilmaz@gmail.com', 'Sakarya', '01062908343'),
('Serra Tuncer', 'serra.tuncer@gmail.com', 'Tunceli', '00969441668'),
('Eylül Ziya', 'eylul.ziya@gmail.com', 'Tunceli', '02573573099'),
('İclal Yanar', 'iclal.yanar@gmail.com', 'Mardin', '03654722684'),
('Ece Gül', 'ece.gul@gmail.com', 'Batman', '04801822720'),
('Alya Şen', 'alya.sen@gmail.com', 'Adana', '04095795042'),
('Yasemin Taşkın', 'yasemin.taskin@gmail.com', 'Siirt', '04397638521'),
('Melis Yalın', 'melis.yalin@gmail.com', 'Çanakkale', '03063155008'),
('Asya Güneş', 'asya.gunes@gmail.com', 'Kayseri', '06476473324'),
('Bilge Yaman', 'bilge.yaman@gmail.com', 'Kars', '04791094165'),
('İlkay Duran', 'ilkay.duran@gmail.com', 'Niğde', '06752220752'),
('İlkay Çelik', 'ilkay.celik@gmail.com', 'Bolu', '01130221867'),
('Ceren Özdemir', 'ceren.ozdemir@gmail.com', 'Burdur', '09417092357'),
('Eylül Yıldız', 'eylul.yildiz@gmail.com', 'Tokat', '06408123684'),
('Rana Başaran', 'rana.basaran@gmail.com', 'Antalya', '05611530124'),
('Yasemin Ziya', 'yasemin.ziya@gmail.com', 'Afyonkarahisar', '05802258155'),
('Pınar Özdemir', 'pinar.ozdemir@gmail.com', 'Edirne', '04045625763'),
('Umay Özer', 'umay.ozer@gmail.com', 'Adıyaman', '00403279066');

---- kategori sorumlu personle verisini girme, 
---- personel tablosunun verisi girildikten sonra bu komutu
---- çalıştır. rastgele sorumlu ataması yapar

WITH RandomizedPersonel AS (
SELECT
KATEGORI.KategoriID,
PERSONEL.PersonelAdi,
ROW_NUMBER() OVER (PARTITION BY KATEGORI.KategoriID ORDER BY NEWID()) AS RowNum
FROM
KATEGORI
CROSS JOIN PERSONEL
)
UPDATE KATEGORI
SET KategoriSorumluPersonelAdi = RandomizedPersonel.PersonelAdi
FROM KATEGORI
INNER JOIN RandomizedPersonel ON KATEGORI.KategoriID = RandomizedPersonel.KategoriID
WHERE RandomizedPersonel.RowNum = 1;

-- ALTKATEGORI tablosunda ıdentity kısmını yes ayarla

---- ALTKATEGORI VERI GIRISI
INSERT INTO ALTKATEGORI (AltKategoriAdi, KategoriID, AltKategoriStok)
VALUES
('Meyve' , 1, 500),
('Sebze',1, 500),
('Kırmızı Et', 2, 250),
('Beyaz Et', 2,250),
('Balık - Deniz Ürünleri', 2, 250),
('Et Şarküteri',2,250),
('Süt', 3,111),
('Peynir', 3,111),
('Yoğurt',3,111),
('Tereyağı', 3,111),
('Margarin', 3,111),
('Yumurta',3,111),
('Zeytin',3,111),
('Sütlü - Tatlı Krema',3,111),
('Kahvaltılık',3,112),
('Makarna',4,100 ),
('Bakliyat',4,100),
('Sıvı Yağ',4,100),
('Tuz - Baharat - Harç',4,100),
('Bulyon',4,100),
('Konserve',4,100),
('Sos',4,100),
('Un',4,100),
('Şeker',4,100),
('Sağlıklı Yaşam Ürünleri',4,100),
('Meze',5,250),
('Paketli Sandviç', 5,250 ),
('Pratik Yemek',5,250),
('Dondurulmuş Gıda',5,250),
('Ekmek' , 6,125 ),
('Sabah Sıcakları',6,125 ),
('Hamur, Pasta Malzemeleri',6,125),
('Yufka, Erişte, Mantı',6, 125),
('Kuru Pasta',6, 125),
('Pasta',6,125 ),
('Galete, Grissini, Gevrek',6,125 ),
('Tatlı',6,125),
('Kap Dondurma',7,333),
('Tek Dondurma',7,333),
('Buz',7, 334),
('Kuru Meyve',8,90),
('Kuruyemiş',8,90 ),
('Cips',8, 90),
('Çikolata',8,90),
('Gofret',8,90),
('Bar',8,90),
('Bisküvi',8,90),
('Kek',8,90),
('Kraker',8,90),
('Şekerleme',8,90),
('Sakız',8,100),
('Gazlı İçecek',9,166),
('Gazsız İçecek',9,166),
('Çay',9,166),
('Kahve',9,166),
('Su',9,166),
('Maden Suyu',9,170),
('Çamaşır Yıkama',10,142),
('Bulaşık Yıkama',10,142),
('Genel Temizlik',10,142),
('Temizlik Malzemeleri',10,142),
('Banyo Gereçleri',10,142),
('Çamaşır Gereçleri',10,142),
('Çöp Poşetleri',10,148),
('Islak Mendil',11,200),
('Tuvalet Kağıdı',11,200),
('Kağıt Havlu',11,200),
('Peçete',11,200),
('Kağıt Mendil',11,200),
('Güneş Bakımı',12,83),
('Hijyenik Ped',12,83),
('Ağız Bakım Ürünleri',12,83),
('Saç Bakım',12,83),
('Duş, Banyo, Sabun',12,83),
('Tıraş Malzemeleri',12,83),
('Ağda, Epilasyon',12,83),
('Cilt Bakım',12,100),
('Kolonya',12,83),
('Parfüm, Deodrant',12,83),
('Makyaj',12,83),
('Sağlık Ürünleri',12,87),
('Bebek Bezi',13,142),
('Bebek Bakım',13,142),
('Bebek Beslenme',13,142),
('Bebek Deterjan ve Yumuşatıcı',13,142),
('Bebek Taşıma',13,142),
('Bebek Tekstil',13,142),
('Anne Ürünleri',13,148),
('Mutfak Eşyaları',14,125),
('Mobilya, Dekorasyon',14,125),
('Bahçe ve Piknik Malzemeleri',14,125),
('Spor, Outdoor',14,125),
('Ev Tekstil',14,125),
('Giyim',14,125),
('Pil',14,125),
('Oto Aksesuar',14,125),
('Kitap, Dergi, Gazete',15,333),
('Kırtasiye',15,333),
('Oyuncak',15,334),
('Canlı Bitki',16,500),
('Yapay Çicek',16,500),
('Köpek',17,250),
('Kedi',17,250),
('Kuş',17,250),
('Pet Aksesuarı',17,250),
('Telefon ve Aksesuarları',18,250),
('Bilgisayar ve Aksesuarları',18,250),
('Giyilebilir teknoloji',18,250),
('Elektrikli Ev aletleri',18,250);

-- TEDARIKCI Tablosu Veri Girişi (KATEGORI Tablosuna Uygun)
INSERT INTO TEDARIKCI (TedarikciID, FirmaAdi, TedarikciTelNo) VALUES
(1, 'MeyveTedarik', '1112223344'), -- Meyve – Sebze
(2, 'EtTop', '5556667788'), -- Et - Tavuk – Balık
(3, 'SutMamulleri', '9990001122'), -- Süt – Kahvaltılık
(4, 'TemelGida', '3334445566'), -- Temel Gıda
(5, 'MezeDonuk', '88899996666'), -- Meze - Hazır Yemek - Donuk
(6, 'FirinLezzetleri', '7778889900'), -- Fırın – Pastane
(7, 'DondurmaDunya', '1234567890'), -- Dondurma
(8, 'AtistirmalikDunya', '9876543210'), -- Atıştırmalık
(9, 'IcecekKosesi', '5551234567'), -- İçecek
(10, 'TemizlikUrunleri', '4445678901'), -- Deterjan – Temizlik
(11, 'IslakMendilKose', '6669998888'), -- Kağıt - Islak Mendil
(12, 'KisiselBakimKosesi', '1112223344'), -- Kişisel Temizlik - Kozmetik – Sağlık
(13, 'BebekDunyasi', '5556667788'), -- Bebek
(14, 'EvYasamDunyasi', '9990001122'), -- Ev – Yaşam
(15, 'KirtasiyeKose', '3334445566'), -- Kitap - Kırtasiye - Oyuncak
(16, 'CicekKose', '7778889900'), -- Çiçek
(17, 'PetShop', '1234567890'), -- Pet Shop
(18, 'ElektronikDunyasi', '9876543210'); -- Elektronik

-- Önce mevcut tetikleyiciyi sil
DROP TRIGGER trg_urun_ekleme;
GO

-- Daha sonra güncellenmiş tetikleyiciyi ekleyin
CREATE TRIGGER trg_urun_ekleme
ON URUNLISTESI
AFTER INSERT
AS
BEGIN
  DECLARE @UrunID INT;
  SELECT @UrunID = UrunID FROM inserted;

  IF NOT EXISTS (SELECT 1 FROM MARKA WHERE UrunID = @UrunID)
  BEGIN
    INSERT INTO MARKA (MarkaAdi, MarkaStok, UrunID)
    VALUES ('Belirsiz', 0, @UrunID);
  END;
END;

-- Tetikleyiciyi kaldırma
DROP TRIGGER IF EXISTS trg_UrunGuncelle;

-- Tetikleyiciyi oluşturma
CREATE TRIGGER trg_UrunGuncelle
ON URUNLISTESI
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF (UPDATE(StokDurumu))
    BEGIN
        UPDATE URUNLISTESI
        SET URUNLISTESI.SatisFiyati = IIF(INSERTED.StokDurumu > 100, URUNLISTESI.SatisFiyati * 1.1, URUNLISTESI.SatisFiyati)
        FROM URUNLISTESI
        INNER JOIN INSERTED ON URUNLISTESI.UrunID = INSERTED.UrunID;
    END
END;
-----------
-- Eğer mevcut tetikleyici varsa silelim
IF OBJECT_ID('trg_urun_raf_guncelleme', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER trg_urun_raf_guncelleme;
END;
GO

-- Yeni tetikleyiciyi oluşturalım
CREATE TRIGGER trg_urun_raf_guncelleme
ON URUN_RAF
AFTER INSERT, DELETE
AS
BEGIN
    UPDATE RAFBILGISI
    SET Raficerigi =
        (
            SELECT STRING_AGG(UrunID, ', ') WITHIN GROUP (ORDER BY UrunID)
            FROM URUN_RAF
            WHERE RafID = RAFBILGISI.RafID
        )
    FROM RAFBILGISI
    WHERE RafID IN (SELECT RafID FROM inserted) OR RafID IN (SELECT RafID FROM deleted);
END;

---

delete from URUNLISTESI;

-- URUNLISTESI tablosunda UrunID ıdentity kısmını yes yap
-- URUNLISTESI Tablosuna örnek veri ekleme (Meyve – Sebze kategorisi için)
INSERT INTO URUNLISTESI (KategoriID, UrunAdi, StokDurumu, AlisFiyati, SatisFiyati, RafBilgisiID, TedarikciID) VALUES
(1, 'Elma', 150, 1.50, 2.50, 1, 1),
(1, 'Muz', 120, 2.00, 3.50, 1, 1),
(1, 'Domates', 180, 1.75, 3.00, 1, 1),
(1, 'Salatalık', 200, 2.50, 4.00, 1, 1),
(1, 'Portakal', 130, 2.00, 3.00, 1, 1),

-- URUNLISTESI Tablosuna örnek veri ekleme (Et - Tavuk – Balık kategorisi için)
(2, 'Dana Kuyma', 100, 10.00, 15.00, 1, 2),
(2, 'Tavuk Göğsü', 120, 8.00, 12.00, 1, 2),
(2, 'Somon Balığı', 90, 18.00, 25.00, 1, 2),
(2, 'Tavuk But', 80, 7.50, 10.00, 1, 2),
(2, 'Balık Fileto', 110, 15.00, 20.00, 1, 2),

-- URUNLISTESI Tablosuna örnek veri ekleme (Süt – Kahvaltılık kategorisi için)
(3, 'Süt', 200, 2.00, 3.50, 1, 3),
(3, 'Peynir', 180, 5.00, 8.00, 1, 3),
(3, 'Yumurta', 150, 0.25, 0.50, 1, 3),
(3, 'Reçel', 120, 3.50, 6.00, 1, 3),
(3, 'Zeytin', 100, 4.00, 7.00, 1, 3),

-- URUNLISTESI Tablosuna örnek veri ekleme (Temel Gıda kategorisi için)
(4, 'Un', 150, 2.00, 3.50, 2, 4),
(4, 'Şeker', 180, 2.50, 4.00, 2, 4),
(4, 'Yağ', 120, 5.00, 8.00, 2, 4),
(4, 'Pirinç', 100, 3.00, 5.00, 2, 4),
(4, 'Tuz', 130, 1.00, 2.00, 2, 4),

-- URUNLISTESI Tablosuna örnek veri ekleme (Meze - Hazır Yemek - Donuk kategorisi için)
(5, 'Hummus', 80, 7.00, 10.00, 2, 5),
(5, 'Köfte', 100, 10.00, 15.00, 2, 5),
(5, 'Pizza', 90, 18.00, 25.00, 2, 5),
(5, 'Börek', 70, 12.50, 20.00, 2, 5),
(5, 'Dondurma', 60, 8.00, 12.00, 2, 5),

-- URUNLISTESI Tablosuna örnek veri ekleme (Fırın – Pastane kategorisi için)
(6, 'Ekmek', 180, 1.50, 2.50, 2, 6),
(6, 'Pasta', 120, 12.00, 18.00, 2, 6),
(6, 'Kurabiye', 150, 6.00, 9.00, 2, 6),
(6, 'Simit', 100, 1.75, 3.00, 2, 6),
(6, 'Çörek', 80, 4.50, 7.00, 2, 6),

-- URUNLISTESI Tablosuna örnek veri ekleme (Dondurma kategorisi için)
(7, 'Vanilya Dondurma', 150, 5.00, 7.50, 3, 7),
(7, 'Çikolata Dondurma', 120, 5.50, 8.00, 3, 7),
(7, 'Meyveli Dondurma', 180, 6.00, 9.00, 3, 7),
(7, 'Dondurma Kasesi', 200, 3.00, 4.50, 3, 7),
(7, 'Dondurma Çubuğu', 130, 2.50, 3.50, 3, 7),

-- URUNLISTESI Tablosuna örnek veri ekleme (Atıştırmalık kategorisi için)
(8, 'Cips', 100, 3.00, 5.00, 3, 8),
(8, 'Kuruyemiş Karışımı', 120, 8.00, 12.00, 3, 8),
(8, 'Kraker', 90, 2.50, 4.00, 3, 8),
(8, 'Patlamış Mısır', 80, 1.50, 3.00, 3, 8),
(8, 'Bisküvi', 110, 4.00, 6.00, 3, 8),

-- URUNLISTESI Tablosuna örnek veri ekleme (İçecek kategorisi için)
(9, 'Gazlı İçecek', 200, 2.50, 4.00, 3, 9),
(9, 'Meyve Suyu', 180, 3.00, 5.00, 3, 9),
(9, 'Çay', 150, 1.00, 2.00, 3, 9),
(9, 'Kahve', 120, 4.00, 6.00, 3, 9),
(9, 'Su', 100, 0.50, 1.00, 3, 9),

-- URUNLISTESI Tablosuna örnek veri ekleme (Deterjan – Temizlik kategorisi için)
(10, 'Çamaşır Deterjanı', 150, 8.00, 12.00, 4, 10),
(10, 'Bulaşık Deterjanı', 120, 5.00, 8.00, 4, 10),
(10, 'Genel Temizlik Malzemesi', 180, 6.50, 10.00, 4, 10),
(10, 'Temizlik Bezi', 200, 2.00, 4.00, 4, 10),
(10, 'Sprey Temizleyici', 130, 4.00, 7.00, 4, 10),

-- URUNLISTESI Tablosuna örnek veri ekleme (Kağıt - Islak Mendil kategorisi için)
(11, 'Tuvalet Kağıdı', 100, 3.00, 5.00, 4, 11),
(11, 'Islak Mendil', 120, 2.50, 4.00, 4, 1),
(11, 'Peçete', 90, 1.00, 2.00, 4, 11),
(11, 'Mutfak Rulosu', 80, 1.50, 3.00, 4, 11),
(11, 'Kağıt Havlu', 110, 4.00, 6.00, 4, 11),

-- URUNLISTESI Tablosuna örnek veri ekleme (Kişisel Temizlik - Kozmetik – Sağlık kategorisi için)
(12, 'Diş Fırçası', 150, 2.00, 3.50, 4, 12),
(12, 'Şampuan', 180, 7.00, 10.00, 4, 12),
(12, 'Sabun', 120, 1.50, 2.50, 4, 12),
(12, 'Parfüm', 100, 15.00, 20.00, 4, 12),
(12, 'El Kremi', 130, 4.50, 7.00, 4, 12),

-- URUNLISTESI Tablosuna örnek veri ekleme (Bebek kategorisi için)
(13, 'Bebek Bezi', 150, 10.00, 15.00, 5, 13),
(13, 'Bebek Şampuanı', 120, 5.50, 8.00, 5, 13),
(13, 'Bebek Losyonu', 180, 4.00, 6.00, 5, 13),
(13, 'Bebek Maması', 200, 3.00, 5.00, 5, 13),
(13, 'Emzik', 130, 2.50, 4.00, 5, 13),

-- URUNLISTESI Tablosuna örnek veri ekleme (Ev – Yaşam kategorisi için)
(14, 'Halı', 100, 50.00, 75.00, 5, 14),
(14, 'Yatak Örtüsü', 120, 30.00, 45.00, 5, 14),
(14, 'Perde', 90, 25.00, 40.00, 5, 14),
(14, 'Tablo Lambası', 80, 15.00, 25.00, 5, 14),
(14, 'Bulaşık Makinesi', 110, 400.00, 550.00, 5, 14),

-- URUNLISTESI Tablosuna örnek veri ekleme (Kitap - Kırtasiye - Oyuncak kategorisi için)
(15, 'Roman Kitabı', 150, 10.00, 15.00, 5, 15),
(15, 'Defter', 180, 2.50, 4.00, 5, 15),
(15, 'Kalem Seti', 120, 5.00, 8.00, 5, 15),
(15, 'Oyuncak Araba', 100, 8.00, 12.00, 5, 15),
(15, 'Oyun Hamuru', 130, 1.50, 3.00, 5, 15),

-- URUNLISTESI Tablosuna örnek veri ekleme (Çiçek kategorisi için)
(16, 'Gül Buketi', 150, 20.00, 30.00, 6, 16),
(16, 'Orkide', 120, 25.00, 35.00, 6, 16),
(16, 'Saksı Çiçeği', 180, 15.00, 25.00, 6, 16),
(16, 'Çiçek Sepeti', 200, 40.00, 55.00, 6, 16),
(16, 'Yapay Çiçek Aranjmanı', 130, 10.00, 20.00, 6, 16),

-- URUNLISTESI Tablosuna örnek veri ekleme (Pet Shop kategorisi için)
(17, 'Köpek Maması', 100, 8.00, 12.00, 6, 17),
(17, 'Kedi Kumu', 120, 5.50, 8.00, 6, 17),
(17, 'Kuş Yemi', 90, 4.00, 6.00, 6, 17),
(17, 'Oyuncak Kuş', 80, 2.50, 4.00, 6, 17),
(17, 'Akvaryum Süsleri', 110, 3.00, 5.00, 6, 17),

-- URUNLISTESI Tablosuna örnek veri ekleme (Elektronik kategorisi için)
(18, 'Akıllı Telefon', 150, 1000.00, 1200.00, 6, 18),
(18, 'Laptop Bilgisayar', 180, 1200.00, 1500.00, 6, 18),
(18, 'Kulaklık', 120, 50.00, 70.00, 6, 18),
(18, 'Bluetooth Hoparlör', 100, 30.00, 45.00, 6, 18),
(18, 'Akıllı Saat', 130, 80.00, 100.00, 6, 18);

-- hata alırsan eğer
-- Tetikleyiciyi sil
--DROP TRIGGER trg_urun_raf_guncelleme;
--CREATE TRIGGER trg_urun_raf_guncelleme
--ON URUN_RAF
--AFTER INSERT, DELETE
--AS
--BEGIN
--  SET NOCOUNT ON;

--  DECLARE @InsertedUrunID INT, @DeletedUrunID INT;

--  -- Inserted tablosundan UrunID değerini al
--  SELECT TOP 1 @InsertedUrunID = UrunID FROM inserted;

--  -- Deleted tablosundan UrunID değerini al
--  SELECT TOP 1 @DeletedUrunID = UrunID FROM deleted;

--  -- Geri kalan işlemleri bu değerlerle gerçekleştir
--  UPDATE RAFBILGISI
--  SET Raficerigi = 
--    CASE
--      WHEN @InsertedUrunID IS NOT NULL THEN 
--        CONCAT(Raficerigi, ', ', @InsertedUrunID)
--      ELSE 
--        REPLACE(Raficerigi, CONCAT(', ', @DeletedUrunID), '')
--    END
--  WHERE RafID IN (SELECT RafID FROM inserted UNION SELECT RafID FROM deleted);
--END;
--kısmı çalıştır

UPDATE RAFBILGISI
SET Raficerigi = 'Meyve – Sebze, Et - Tavuk – Balık, Süt – Kahvaltılık'
WHERE RafID = 1;

-- MARKA Tablosuna örnek veri ekleme (UrunID'yi 721'den başlatarak)
INSERT INTO MARKA (MarkaAdi, MarkaStok, UrunID) VALUES
('MeyveCo', 50, 721), ('MuzCaddesi', 60, 722), ('SebzeDepo', 40, 723), ('TarlaTaze', 55, 724), ('PortakalPlus', 45, 725),
('EtLezzet', 30, 726), ('TavukDünyası', 40, 727), ('DenizLezzeti', 25, 728), ('TavukTadı', 35, 729), ('BalıkCazibe', 50, 730),
('SütLezzet', 60, 731), ('PeynirKöşesi', 45, 732), ('YumurtaBahçesi', 55, 733), ('ReçelDurağı', 30, 734), ('ZeytinCenneti', 40, 735),
('UnHarika', 35, 736), ('ŞekerKeyfi', 50, 737), ('YağLezzet', 40, 738), ('PirinçDünyası', 25, 739), ('TuzBereketi', 60, 740),
('MezeKeyfi', 45, 741), ('KöfteKral', 55, 742), ('PizzaDünyası', 30, 743), ('BörekLezzet', 40, 744), ('DondurmaCenneti', 35, 745),
('EkmekKöşesi', 50, 746), ('PastaDünyası', 40, 747), ('KurabiyeLezzet', 25, 748), ('SimitPazarı', 35, 749), ('ÇörekFırını', 45, 750),
('VanilyaLezzet', 60, 751), ('ÇikolataKeyfi', 55, 752), ('MeyveliDondurma', 50, 753), ('DondurmaKeyfi', 45, 754), ('DondurmaÇubuğu', 35, 755),
('CipsCenneti', 30, 756), ('KuruyemişDünyası', 40, 757), ('KrakerLezzet', 25, 758), ('PatlamışMısır', 35, 759), ('BisküviKral', 50, 760),
('Gazlıİçecek', 60, 761), ('MeyveSuyuDünyası', 45, 762), ('ÇayLezzet', 55, 763), ('KahveDurağı', 30, 764), ('SuDeposu', 40, 765),
('ÇamaşırDünyası', 35, 766), ('BulaşıkKeyfi', 50, 767), ('TemizlikMarkası', 40, 768), ('TemizlikBezi', 25, 769), ('SpreyDünyası', 60, 770),
('TuvaletKağıdı', 45, 771), ('IslakMendil', 55, 772), ('PeçeteDünyası', 30, 773), ('MutfakRulosu', 40, 774), ('KağıtHavlu', 35, 775),
('DişFırçası', 50, 776), ('ŞampuanMarkası', 40, 777), ('SabunLezzet', 25, 778), ('ParfümDünyası', 35, 779), ('ElKremi', 45, 780),
('BebekBeziDünyası', 60, 781), ('BebekŞampuanı', 55, 782), ('BebekLosyonu', 50, 783), ('BebekMaması', 40, 784), ('EmzikDünyası', 30, 785),
('HalıMarkası', 45, 786), ('YatakÖrtüsü', 35, 787), ('PerdeDünyası', 25, 788), ('LambaDünyası', 40, 789), ('BulaşıkMakinesi', 50, 790),
('RomanDünyası', 55, 791), ('DefterMarkası', 30, 792), ('KalemSeti', 40, 793), ('OyuncakAraba', 35, 794), ('OyunHamuru', 25, 795),
('GülBahçesi', 60, 796), ('OrkideDünyası', 45, 797), ('SaksıÇiçeği', 55, 798), ('ÇiçekSepeti', 30, 799), ('YapayÇiçekAranjmanı', 40, 800),
('KöpekMaması', 35, 801), ('KediKumu', 50, 802), ('KuşYemi', 40, 803), ('OyuncakKuş', 25, 804), ('AkvaryumSüsleri', 60, 805),
('AkıllıTelefon', 45, 806), ('LaptopDünyası', 35, 807), ('KulaklıkMarkası', 25, 808), ('BluetoothHoparlör', 40, 809), ('AkıllıSaat', 50, 810);

-- MUSTERI tablosunda MuaterıID ıdentitiy kısmını yes yap

---- MUSTERI VERI GIRISI
INSERT INTO MUSTERI (MusteriAdSoyad,MusteriEmail, MusteriAdres,MusteriTelNo) VALUES
('Yasemin Yıldız', 'yasemin.yildiz@gmail.com', 'Adana', '04244570106'),
('Asena Yalın', 'asena.yalin@gmail.com', 'Uşak', '00685120898'),
('İclal Saraçoğlu', 'iclal.saracoglu@gmail.com', 'Aydın', '02369763641'),
('Oya Güneş', 'oya.gunes@gmail.com', 'Artvin', '08525568297'),
('Göktürk Korkmaz', 'gokturk.korkmaz@gmail.com', 'Bursa', '02578672379'),
('Buse Çenel', 'buse.cenel@gmail.com', 'Osmaniye', '08650896046'),
('Duygu Karadeniz', 'duygu.karadeniz@gmail.com', 'Gaziantep', '06238477674'),
('Ebru Yücel', 'ebru.yucel@gmail.com', 'Denizli', '00946271391'),
('İlkay Duran', 'ilkay.duran@gmail.com', 'Çorum', '03399951060'),
('Cansu Çenel', 'cansu.cenel@gmail.com', 'Karabük', '00492125969'),
('Gizem Erdogan', 'gizem.erdogan@gmail.com', 'Bursa', '01441345561'),
('Selvi Duran', 'selvi.duran@gmail.com', 'Samsun', '06336829857'),
('İclal Güneş', 'iclal.gunes@gmail.com', 'Karabük', '03947593672'),
('Sude Şahin', 'sude.sahin@gmail.com', 'Ankara', '04582247784'),
('Gözde Ziya', 'gozde.ziya@gmail.com', 'Ordu', '05724376927'),
('Oya Kurtuluş', 'oya.kurtulus@gmail.com', 'Bingöl', '05854501538'),
('Nur Çenel', 'nur.cenel@gmail.com', 'Isparta', '03858457081'),
('Ezgi Yanar', 'ezgi.yanar@gmail.com', 'Van', '07045516324'),
('Eylül Özgür', 'eylul.ozgur@gmail.com', 'Yalova', '01561502220'),
('Oya Arslan', 'oya.arslan@gmail.com', 'Antalya', '09408267219'),
('Sude Arslan', 'sude.arslan@gmail.com', 'Sakarya', '08630623073'),
('Eylül Güzel', 'eylul.guzel@gmail.com', 'Isparta', '02999676262'),
('Asena Tekin', 'asena.tekin@gmail.com', 'Osmaniye', '05405118186'),
('Aslı Tuncer', 'asli.tuncer@gmail.com', 'İzmir', '03026243652'),
('Eylül Acar', 'eylul.acar@gmail.com', 'Bilecik', '02717618033'),
('Leyla Yanar', 'leyla.yanar@gmail.com', 'Kırıkkale', '06411254624'),
('Buse Soydan', 'buse.soydan@gmail.com', 'Manisa', '03121403930'),
('Yelda Kurtulan', 'yelda.kurtulan@gmail.com', 'Erzincan', '09533806541'),
('Irmak Akbulut', 'irmak.akbulut@gmail.com', 'Tokat', '07988373973'),
('Aslı Narin', 'asli.narin@gmail.com', 'Bayburt', '09863002591'),
('Serra Erkan', 'serra.erkan@gmail.com', 'Gaziantep', '09887928142'),
('Simge Günes', 'simge.gunes@gmail.com', 'Isparta', '04029418080'),
('Efsun Demir', 'efsun.demir@gmail.com', 'Siirt', '00943560450'),
('Derya Çetin', 'derya.cetin@gmail.com', 'Gaziantep', '01165690767'),
('Ebru Aksoy', 'ebru.aksoy@gmail.com', 'Rize', '04541419141'),
('Burcu Çelik', 'burcu.celik@gmail.com', 'Bilecik', '06322770136'),
('Elif Güzel', 'elif.guzel@gmail.com', 'Osmaniye', '06904947256'),
('İlkay Karakuş', 'ilkay.karakus@gmail.com', 'Manisa', '04696629106'),
('Lina Yanar', 'lina.yanar@gmail.com', 'Edirne', '08419177924'),
('Ceyda Kaplan', 'ceyda.kaplan@gmail.com', 'Adıyaman', '02307239206'),
('Selin Şoban', 'selin.soban@gmail.com', 'Bingöl', '07811145455'),
('Cansu Ayhan', 'cansu.ayhan@gmail.com', 'Erzincan', '00527374938'),
('İlkay Kaya', 'ilkay.kaya@gmail.com', 'Gaziantep', '09231182034'),
('Derya Gül', 'derya.gul@gmail.com', 'Van', '06059832188'),
('Lara Yalçın', 'lara.yalcin@gmail.com', 'Van', '03954277782'),
('Elif Özbek', 'elif.ozbek@gmail.com', 'Kırklareli', '03131541209'),
('Büşra Erkan', 'busra.erkan@gmail.com', 'Trabzon', '06308090418'),
('Cemre Kurtulan', 'cemre.kurtulan@gmail.com', 'Mardin', '09129833158'),
('Derya Yücel', 'derya.yucel@gmail.com', 'Kars', '04901501941'),
('Ece Güzel', 'ece.guzel@gmail.com', 'Balıkesir', '05339300402'),
('Duygu Başaran', 'duygu.basaran@gmail.com', 'İzmir', '07593521885'),
('Lara Özer', 'lara.ozer@gmail.com', 'Burdur', '04411431245'),
('Dilara Kurtuluş', 'dilara.kurtulus@gmail.com', 'Uşak', '01410682372'),
('Elçin Koç', 'elcin.koc@gmail.com', 'Bartın', '04353852611'),
('Beril Aydemir', 'beril.aydemir@gmail.com', 'Sinop', '07945916191'),
('Zeliha Başaran', 'zeliha.basaran@gmail.com', 'Bartın', '08989851719'),
('Nihan Yanar', 'nihan.yanar@gmail.com', 'Hatay', '03576616480'),
('Oya Çetin', 'oya.cetin@gmail.com', 'Konya', '01449569361'),
('Sude Güzel', 'sude.guzel@gmail.com', 'Tunceli', '02474458989'),
('Elif Tekin', 'elif.tekin@gmail.com', 'Balıkesir', '02024388182'),
('Yasemin Narin', 'yasemin.narin@gmail.com', 'Ordu', '01520108118'),
('Ebru Erdogan', 'ebru.erdogan@gmail.com', 'Iğdır', '04055090344'),
('Elif Şahin', 'elif.sahin@gmail.com', 'Kars', '08872271296'),
('Ece Erdogan', 'ece.erdogan@gmail.com', 'Ankara', '01499901959'),
('Büşra Erdogan', 'busra.erdogan@gmail.com', 'Ordu', '03305468140'),
('Efsun Yanar', 'efsun.yanar@gmail.com', 'Bitlis', '08643474190'),
('Esra Karadağ', 'esra.karadag@gmail.com', 'Iğdır', '00964159945'),
('Ceren Özkan', 'ceren.ozkan@gmail.com', 'Trabzon', '03279414279'),
('Burcu Arslan', 'burcu.arslan@gmail.com', 'Mardin', '05547331231'),
('Leyla Erdogan', 'leyla.erdogan@gmail.com', 'Samsun', '04603682472'),
('Beril Aydemir', 'beril.aydemir@gmail.com', 'Giresun', '08877797742'),
('İlknur Saraçoğlu', 'ilknur.saracoglu@gmail.com', 'Gaziantep', '02944858339'),
('Nisan Gunes', 'nisan.gunes@gmail.com', 'Çanakkale', '07223469357'),
('Eylül Öztürk', 'eylul.ozturk@gmail.com', 'Denizli', '05900752925'),
('Nisa Aydemir', 'nisa.aydemir@gmail.com', 'Kırklareli', '08605308375'),
('Zeliha Karadag', 'zeliha.karadag@gmail.com', 'Kars', '01306874438'),
('İlknur Karadag', 'ilknur.karadag@gmail.com', 'Hatay', '06420381207'),
('Umay Çelik', 'umay.celik@gmail.com', 'Muğla', '02310038908'),
('Zümra Yıldız', 'zumra.yildiz@gmail.com', 'Bartın', '07018984266'),
('Yasemin Soban', 'yasemin.soban@gmail.com', 'İzmir', '00006780702'),
('Elvan Yılmaz', 'elvan.yilmaz@gmail.com', 'Isparta', '08107357443'),
('Gül Ozdemir', 'gul.ozdemir@gmail.com', 'Yozgat', '01808386212'),
('İlknur Kurt', 'ilknur.kurt@gmail.com', 'Ordu', '04529268576'),
('Simge Aydemir', 'simge.aydemir@gmail.com', 'Burdur', '00225974226'),
('İrem Kurt', 'irem.kurt@gmail.com', 'Hakkari', '02117927277'),
('Nazlı Tuncer', 'nazli.tuncer@gmail.com', 'Artvin', '04314235293'),
('Sude Ziya', 'sude.ziya@gmail.com', 'Sakarya', '00574833141'),
('Bilge Yıldözoğlu', 'bilge.yildozoglu@gmail.com', 'Siirt', '03816552786'),
('Yasmin Karadag', 'yasmin.karadag@gmail.com', 'Kahramanmaraş', '04899138544'),
('Günes Yildiz', 'gunes.yildiz@gmail.com', 'Elazığ', '04242632811'),
('Büşra Guzel', 'busra.guzel@gmail.com', 'Aydın', '07403150973'),
('Vildan Demir', 'vildan.demir@gmail.com', 'Kayseri', '09240017532'),
('İclal Koc', 'iclal.koc@gmail.com', 'Bingöl', '03353861577'),
('Ela Kaplan', 'ela.kaplan@gmail.com', 'Edirne', '00876245107'),
('Zara Simsek', 'zara.simsek@gmail.com', 'Erzurum', '01072469666'),
('İrem Karakus', 'irem.karakus@gmail.com', 'Burdur', '09944016478'),
('Ezgi Yıldırım', 'ezgi.yildirim@gmail.com', 'Denizli', '05658118354'),
('Simge Sahin', 'simge.sahin@gmail.com', 'Karabük', '09020745429'),
('Zara Narin', 'zara.narin@gmail.com', 'Artvin', '00488528898'),
('Cansu Kurtulus', 'cansu.kurtulus@gmail.com', 'Bolu', '03739548240'),
('Selin Yıldırım', 'selin.yildirim@gmail.com', 'Osmaniye', '05358764041'),
('Derya Aydemir', 'derya.aydemir@gmail.com', 'Adıyaman', '00630686670'),
('Derya Yanar', 'derya.yanar@gmail.com', 'Elazığ', '08831102046'),
('Pınar Yıldözoğlu', 'pinar.yildozoglu@gmail.com', 'Kahramanmaraş', '04752564285'),
('Nur Çetin', 'nur.cetin@gmail.com', 'Bartın', '08077910650'),
('Rana Erkan', 'rana.erkan@gmail.com', 'Diyarbakır', '00153417910'),
('Gizem Koç', 'gizem.koc@gmail.com', 'Gaziantep', '09939486754'),
('Rüya Arslan', 'ruya.arslan@gmail.com', 'Çanakkale', '09758920280'),
('Zeliha Ayhan', 'zeliha.ayhan@gmail.com', 'Amasya', '01259526329'),
('Umay Şoban', 'umay.soban@gmail.com', 'Tunceli', '09973628859'),
('Ezgi Korkmaz', 'ezgi.korkmaz@gmail.com', 'Adıyaman', '09267432020'),
('Bilge Acar', 'bilge.acar@gmail.com', 'Denizli', '03966948199'),
('Eylül Özen', 'eylul.ozen@gmail.com', 'Kayseri', '03498391266'),
('Ezgi Soydan', 'ezgi.soydan@gmail.com', 'Hatay', '03442744602'),
('Leyla Yalçın', 'leyla.yalcin@gmail.com', 'Aksaray', '03469267277'),
('Gizem Erdogan', 'gizem.erdogan@gmail.com', 'Istanbul', '02311266992'),
('İclal Ayhan', 'iclal.ayhan@gmail.com', 'Burdur', '08595384648'),
('Eylül Ayhan', 'eylul.ayhan@gmail.com', 'Düzce', '01889046870'),
('Rüya Toprak', 'ruya.toprak@gmail.com', 'Tekirdağ', '08346918402'),
('Rana Demir', 'rana.demir@gmail.com', 'Bilecik', '02076191398'),
('Selin Aydemir', 'selin.aydemir@gmail.com', 'Şırnak', '03877771724'),
('Leyla Özbek', 'leyla.ozbek@gmail.com', 'Niğde', '01683562620'),
('Beril Koç', 'beril.koc@gmail.com', 'Rize', '05219382707'),
('Ece Çelik', 'ece.celik@gmail.com', 'Van', '06854488228'),
('Ebru Çenel', 'ebru.cenel@gmail.com', 'Edirne', '00729413703'),
('Ezgi Özer', 'ezgi.ozer@gmail.com', 'Niğde', '08574921929'),
('Yelda Şen', 'yelda.sen@gmail.com', 'Konya', '08827079389'),
('Efsun Şahin', 'efsun.sahin@gmail.com', 'Ankara', '02382069216'),
('Irmak Demir', 'irmak.demir@gmail.com', 'Niğde', '07841978318'),
('Gizem Kurt', 'gizem.kurt@gmail.com', 'Kırklareli', '07156849478'),
('Zeynep Güzel', 'zeynep.guzel@gmail.com', 'Çanakkale', '06636893782'),
('Leyla Çenel', 'leyla.cenel@gmail.com', 'Giresun', '06465882694'),
('Irmak Karadeniz', 'irmak.karadeniz@gmail.com', 'Kayseri', '07646250317'),
('Ceren Kaplan', 'ceren.kaplan@gmail.com', 'Burdur', '05372541142'),
('Alya Toprak', 'alya.toprak@gmail.com', 'Elazığ', '07017924811'),
('Sude Kurtuluş', 'sude.kurtulus@gmail.com', 'Tokat', '05289305167'),
('Eylül Şen', 'eylul.sen@gmail.com', 'Şanlıurfa', '04536539529'),
('İlayda Korkmaz', 'ilayda.korkmaz@gmail.com', 'Adıyaman', '01314587367'),
('Elvan Toprak', 'elvan.toprak@gmail.com', 'Ordu', '03021071001'),
('Esra Yıldız', 'esra.yildiz@gmail.com', 'Mardin', '08642815585'),
('Leyla Toprak', 'leyla.toprak@gmail.com', 'Bilecik', '02476441116'),
('Aylin Başaran', 'aylin.basaran@gmail.com', 'Bursa', '07997374700'),
('Yaren Mete', 'yaren.mete@gmail.com', 'Konya', '09288686409'),
('Vildan Aydemir', 'vildan.aydemir@gmail.com', 'Ankara', '01402836277'),
('Umay Karakuş', 'umay.karakus@gmail.com', 'Ordu', '05445384644'),
('Melis Saraçoğlu', 'melis.saracoglu@gmail.com', 'Karabük', '06496202654'),
('Eylül Ay', 'eylul.ay@gmail.com', 'Balıkesir', '01103036548'),
('Göktürk Özen', 'gokturk.ozen@gmail.com', 'Karaman', '02010155691'),
('Eylül Yıldırım', 'eylul.yildirim@gmail.com', 'Bitlis', '03977984594'),
('Selin Yücel', 'selin.yucel@gmail.com', 'Van', '01036057820'),
('Zara Aslan', 'zara.aslan@gmail.com', 'Batman', '06641580028'),
('Selvi Ziya', 'selvi.ziya@gmail.com', 'Afyonkarahisar', '05029380248'),
('Sema Tekin', 'sema.tekin@gmail.com', 'Hakkari', '04810550763'),
('Iclal Aksoy', 'iclal.aksoy@gmail.com', 'Van', '01830173842'),
('Ezgi Yildiz', 'ezgi.yildiz@gmail.com', 'Siirt', '07204875471'),
('Ayse Tekin', 'ayse.tekin@gmail.com', 'Karaman', '02871086879'),
('Asli Ozen', 'asli.ozen@gmail.com', 'Erzurum', '02414315967'),
('Eylul Aksoy', 'eylul.aksoy@gmail.com', 'Ankara', '05332289700'),
('Umay Yucel', 'umay.yucel@gmail.com', 'Gaziantep', '06267114569'),
('Ezgi Gul', 'ezgi.gul@gmail.com', 'Edirne', '06622205699'),
('Zara Tekin', 'zara.tekin@gmail.com', 'Bitlis', '04393955016'),
('Gozde Aydin', 'gozde.aydin@gmail.com', 'Siirt', '06130227605'),
('Nihan Yilmaz', 'nihan.yilmaz@gmail.com', 'Erzincan', '06081242134'),
('Beril Yildizoglu', 'beril.yildizoglu@gmail.com', 'Erzincan', '09789308212'),
('Lina Yilmaz', 'lina.yilmaz@gmail.com', 'Kocaeli', '08570658412'),
('Ilayda Kurtulus', 'ilayda.kurtulus@gmail.com', 'Sirnak', '02212477030'),
('Damla Ay', 'damla.ay@gmail.com', 'Denizli', '07082847141'),
('Efsun Yildiz', 'efsun.yildiz@gmail.com', 'Samsun', '03981043371'),
('Lavinya Ozturk', 'lavinya.ozturk@gmail.com', 'Corum', '06412147176'),
('Hande Ayhan', 'hande.ayhan@gmail.com', 'Nigde', '02485112744'),
('Iclal Ozen', 'iclal.ozen@gmail.com', 'Sirnak', '08083599918'),
('Ece Karadeniz', 'ece.karadeniz@gmail.com', 'Canakkale', '01666209145'),
('Hande Arslan', 'hande.arslan@gmail.com', 'Mugla', '06321169711'),
('Asli Kurtulus', 'asli.kurtulus@gmail.com', 'Antalya', '07268426036'),
('Elcin Arslan', 'elcin.arslan@gmail.com', 'Izmir', '05474430024'),
('Selin Kurtulan', 'selin.kurtulan@gmail.com', 'Amasya', '00921380513'),
('Zara Basaran', 'zara.basaran@gmail.com', 'Bayburt', '07147429407'),
('Ilayda Narin', 'ilayda.narin@gmail.com', 'Bolu', '05115965544'),
('Selma Setin', 'selma.setin@gmail.com', 'Sinop', '04840251432'),
('Ela Ozdemir', 'ela.ozdemir@gmail.com', 'Artvin', '05153399858'),
('Ayse Tekin', 'ayse.tekin@gmail.com', 'Canakkale', '03153048688'),
('Gunes Simek', 'gunes.simek@gmail.com', 'Edirne', '00687458545'),
('Yelda Ayhan', 'yelda.ayhan@gmail.com', 'Burdur', '05291468822'),
('Gizem Narin', 'gizem.narin@gmail.com', 'Sanliurfa', '05057958502'),
('Asli Yildizoglu', 'asli.yildizoglu@gmail.com', 'Kirklareli', '02477900851'),
('Ilayda Taskin', 'ilayda.taskin@gmail.com', 'Aydin', '05642723658'),
('Umay Gul', 'umay.gul@gmail.com', 'Edirne', '03708968658'),
('Ela Celik', 'ela.celik@gmail.com', 'Kayseri', '00097863227'),
('Burcu Ay', 'burcu.ay@gmail.com', 'Ankara', '07158133494'),
('Melis Yalcin', 'melis.yalcin@gmail.com', 'Kirikkale', '02248753927'),
('Rana Aktas', 'rana.aktas@gmail.com', 'Trabzon', '00450721931'),
('Ebru Erkan', 'ebru.erkan@gmail.com', 'Balikesir', '05311882545'),
('Simge Aslan', 'simge.aslan@gmail.com', 'Siirt', '07583762093'),
('Zeynep Celik', 'zeynep.celik@gmail.com', 'Mardin', '05921450722'),
('Ilayda Acar', 'ilayda.acar@gmail.com', 'Istanbul', '06338883094'),
('Sude Basaran', 'sude.basaran@gmail.com', 'Usak', '07060154899'),
('Cemre Aslan', 'cemre.aslan@gmail.com', 'Sanliurfa', '07185648912'),
('Ela Yalcin', 'ela.yalcin@gmail.com', 'Izmir', '06715394346'),
('Merve Tekin', 'merve.tekin@gmail.com', 'Tekirdag', '04897722770'),
('Ayse Aktas', 'ayse.aktas@gmail.com', 'Ankara', '09764769575');

-- INDIRIM tablosunda UygulananIndirimID identitiy kısmını yes yap
--INDIRIM TABLOSU 
-- Rastgele 20 ürün seçme
WITH RastgeleUrunler AS (
    SELECT TOP 20 UrunID
    FROM URUNLISTESI
    ORDER BY NEWID()  -- NEWID() ile rastgele sıralama
)

-- INDIRIM tablosuna veri ekleme
INSERT INTO INDIRIM (UygulananMarkaID, IndirimMiktari)
SELECT
    URUNLISTESI.MarkaID,
    FLOOR(RAND() * 50) + 1  -- Rastgele indirim miktarı (1-50 arası)
FROM RastgeleUrunler
JOIN URUNLISTESI ON RastgeleUrunler.UrunID = URUNLISTESI.UrunID;

-- PERSONEL_KART Tablosuna veri ekleme (ilk 20 personel için)
INSERT INTO PERSONEL_KART (KartID, Bakiye, IndirimCeki)
VALUES
    (1, 1000.00, 50),
    (2, 800.00, 30),
    (3, 1200.00, 40),
    (4, 1500.00, 60),
    (5, 900.00, 20),
    (6, 1100.00, 25),
    (7, 1300.00, 35),
    (8, 950.00, 15),
    (9, 850.00, 10),
    (10, 1000.00, 30),
    (11, 1200.00, 40),
    (12, 950.00, 25),
    (13, 1100.00, 20),
    (14, 1300.00, 15),
    (15, 900.00, 10),
    (16, 1000.00, 50),
    (17, 800.00, 30),
    (18, 1200.00, 40),
    (19, 1500.00, 60),
    (20, 900.00, 20),

	-- PERSONEL_KART Tablosuna veri ekleme (21-40 arası personel için)

    (21, 950.00, 15),
    (22, 850.00, 10),
    (23, 1000.00, 30),
    (24, 1200.00, 40),
    (25, 900.00, 20),
    (26, 1100.00, 25),
    (27, 1300.00, 35),
    (28, 950.00, 15),
    (29, 850.00, 10),
    (30, 1000.00, 30),
    (31, 1200.00, 40),
    (32, 950.00, 25),
    (33, 1100.00, 20),
    (34, 1300.00, 15),
    (35, 900.00, 10),
    (36, 1000.00, 50),
    (37, 800.00, 30),
    (38, 1200.00, 40),
    (39, 1500.00, 60),
    (40, 900.00, 20),

-- PERSONEL_KART Tablosuna veri ekleme (41-60 arası personel için)

    (41, 1000.00, 20),
    (42, 1200.00, 30),
    (43, 900.00, 15),
    (44, 1100.00, 25),
    (45, 1300.00, 35),
    (46, 950.00, 10),
    (47, 850.00, 15),
    (48, 1000.00, 20),
    (49, 1200.00, 25),
    (50, 900.00, 30),
    (51, 1100.00, 35),
    (52, 1300.00, 40),
    (53, 950.00, 45),
    (54, 850.00, 50),
    (55, 1000.00, 55),
    (56, 1200.00, 60),
    (57, 900.00, 25),
    (58, 1100.00, 20),
    (59, 1300.00, 15),
    (60, 950.00, 10),

	-- PERSONEL_KART Tablosuna veri ekleme (61-100 arası personel için)

    (61, 1000.00, 20),
    (62, 1200.00, 30),
    (63, 900.00, 15),
    (64, 1100.00, 25),
    (65, 1300.00, 35),
    (66, 950.00, 10),
    (67, 850.00, 15),
    (68, 1000.00, 20),
    (69, 1200.00, 25),
    (70, 900.00, 30),
    (71, 1100.00, 35),
    (72, 1300.00, 40),
    (73, 950.00, 45),
    (74, 850.00, 50),
    (75, 1000.00, 55),
    (76, 1200.00, 60),
    (77, 900.00, 25),
    (78, 1100.00, 20),
    (79, 1300.00, 15),
    (80, 950.00, 10),
    (81, 1000.00, 20),
    (82, 1200.00, 30),
    (83, 900.00, 15),
    (84, 1100.00, 25),
    (85, 1300.00, 35),
    (86, 950.00, 10),
    (87, 850.00, 15),
    (88, 1000.00, 20),
    (89, 1200.00, 25),
    (90, 900.00, 30),
    (91, 1100.00, 35),
    (92, 1300.00, 40),
    (93, 950.00, 45),
    (94, 850.00, 50),
    (95, 1000.00, 55),
    (96, 1200.00, 60),
    (97, 900.00, 25),
    (98, 1100.00, 20),
    (99, 1300.00, 15),
    (100, 950.00, 10),

	-- PERSONEL_KART Tablosuna veri ekleme (101-140 arası personel için)

    (101, 1000.00, 20),
    (102, 1200.00, 30),
    (103, 900.00, 15),
    (104, 1100.00, 25),
    (105, 1300.00, 35),
    (106, 950.00, 10),
    (107, 850.00, 15),
    (108, 1000.00, 20),
    (109, 1200.00, 25),
    (110, 900.00, 30),
    (111, 1100.00, 35),
    (112, 1300.00, 40),
    (113, 950.00, 45),
    (114, 850.00, 50),
    (115, 1000.00, 55),
    (116, 1200.00, 60),
    (117, 900.00, 25),
    (118, 1100.00, 20),
    (119, 1300.00, 15),
    (120, 950.00, 10),
    (121, 1000.00, 20),
    (122, 1200.00, 30),
    (123, 900.00, 15),
    (124, 1100.00, 25),
    (125, 1300.00, 35),
    (126, 950.00, 10),
    (127, 850.00, 15),
    (128, 1000.00, 20),
    (129, 1200.00, 25),
    (130, 900.00, 30),
    (131, 1100.00, 35),
    (132, 1300.00, 40),
    (133, 950.00, 45),
    (134, 850.00, 50),
    (135, 1000.00, 55),
    (136, 1200.00, 60),
    (137, 900.00, 25),
    (138, 1100.00, 20),
    (139, 1300.00, 15),
    (140, 950.00, 10),

	-- PERSONEL_KART Tablosuna veri ekleme (141-200 arası personel için)

    (141, 1000.00, 20),
    (142, 1200.00, 30),
    (143, 900.00, 15),
    (144, 1100.00, 25),
    (145, 1300.00, 35),
    (146, 950.00, 10),
    (147, 850.00, 15),
    (148, 1000.00, 20),
    (149, 1200.00, 25),
    (150, 900.00, 30),
    (151, 1100.00, 35),
    (152, 1300.00, 40),
    (153, 950.00, 45),
    (154, 850.00, 50),
    (155, 1000.00, 55),
    (156, 1200.00, 60),
    (157, 900.00, 25),
    (158, 1100.00, 20),
    (159, 1300.00, 15),
    (160, 950.00, 10),
    (161, 1000.00, 20),
    (162, 1200.00, 30),
    (163, 900.00, 15),
    (164, 1100.00, 25),
    (165, 1300.00, 35),
    (166, 950.00, 10),
    (167, 850.00, 15),
    (168, 1000.00, 20),
    (169, 1200.00, 25),
    (170, 900.00, 30),
    (171, 1100.00, 35),
    (172, 1300.00, 40),
    (173, 950.00, 45),
    (174, 850.00, 50),
    (175, 1000.00, 55),
    (176, 1200.00, 60),
    (177, 900.00, 25),
    (178, 1100.00, 20),
    (179, 1300.00, 15),
    (180, 950.00, 10),
    (181, 1000.00, 20),
    (182, 1200.00, 30),
    (183, 900.00, 15),
    (184, 1100.00, 25),
    (185, 1300.00, 35),
    (186, 950.00, 10),
    (187, 850.00, 15),
    (188, 1000.00, 20),
    (189, 1200.00, 25),
    (190, 900.00, 30),
    (191, 1100.00, 35),
    (192, 1300.00, 40),
    (193, 950.00, 45),
    (194, 850.00, 50),
    (195, 1000.00, 55),
    (196, 1200.00, 60),
    (197, 900.00, 25),
    (198, 1100.00, 20),
    (199, 1300.00, 15),
    (200, 950.00, 10),

-- PERSONEL ve PERSONEL_KART tablolarını birleştirme
SELECT PERSONEL.PersonelID, PERSONEL.PersonelAdi, PERSONEL.PersonelEmail, PERSONEL_KART.Bakiye, PERSONEL_KART.IndirimCeki
FROM PERSONEL
JOIN PERSONEL_KART ON PERSONEL.PersonelID = PERSONEL_KART.KartID;

-- MUSTERIKART Tablosuna veri ekleme (ilk 40 müşteri)
INSERT INTO MUSTERIKART (MusteriID, Indirim, Bakiye, YapilanAlisveris)
VALUES
    (1, 10.00, 500.00, 5),
    (2, 15.00, 700.00, 8),
    (3, 8.00, 450.00, 4),
    (4, 12.00, 600.00, 7),
    (5, 20.00, 800.00, 10),
    (6, 14.00, 550.00, 6),
    (7, 18.00, 720.00, 9),
    (8, 22.00, 850.00, 12),
    (9, 16.00, 670.00, 8),
    (10, 25.00, 950.00, 15),
    (11, 11.00, 520.00, 5),
    (12, 19.00, 780.00, 11),
    (13, 13.00, 620.00, 7),
    (14, 17.00, 700.00, 10),
    (15, 21.00, 830.00, 13),
    (16, 15.00, 690.00, 8),
    (17, 9.00, 480.00, 5),
    (18, 23.00, 920.00, 14),
    (19, 14.00, 580.00, 7),
    (20, 20.00, 750.00, 11),
    (21, 18.00, 800.00, 10),
    (22, 10.00, 550.00, 6),
    (23, 16.00, 700.00, 9),
    (24, 12.00, 620.00, 8),
    (25, 22.00, 870.00, 13),
    (26, 19.00, 790.00, 12),
    (27, 15.00, 680.00, 8),
    (28, 11.00, 530.00, 5),
    (29, 25.00, 980.00, 16),
    (30, 17.00, 720.00, 9),
    (31, 13.00, 610.00, 7),
    (32, 21.00, 850.00, 12),
    (33, 14.00, 690.00, 8),
    (34, 8.00, 470.00, 4),
    (35, 23.00, 910.00, 14),
    (36, 15.00, 600.00, 7),
    (37, 19.00, 760.00, 10),
    (38, 20.00, 780.00, 11),
    (39, 9.00, 510.00, 6),
    (40, 16.00, 690.00, 8),

	-- MUSTERIKART Tablosuna veri ekleme (41-80 arası müşteriler)

    (41, 10.00, 500.00, 5),
    (42, 15.00, 700.00, 8),
    (43, 8.00, 450.00, 4),
    (44, 12.00, 600.00, 7),
    (45, 20.00, 800.00, 10),
    (46, 14.00, 550.00, 6),
    (47, 18.00, 720.00, 9),
    (48, 22.00, 850.00, 12),
    (49, 16.00, 670.00, 8),
    (50, 25.00, 950.00, 15),
    (51, 11.00, 520.00, 5),
    (52, 19.00, 780.00, 11),
    (53, 13.00, 620.00, 7),
    (54, 17.00, 700.00, 10),
    (55, 21.00, 830.00, 13),
    (56, 15.00, 690.00, 8),
    (57, 9.00, 480.00, 5),
    (58, 23.00, 920.00, 14),
    (59, 14.00, 580.00, 7),
    (60, 20.00, 750.00, 11),
    (61, 18.00, 800.00, 10),
    (62, 10.00, 550.00, 6),
    (63, 16.00, 700.00, 9),
    (64, 12.00, 620.00, 8),
    (65, 22.00, 870.00, 13),
    (66, 19.00, 790.00, 12),
    (67, 15.00, 680.00, 8),
    (68, 11.00, 530.00, 5),
    (69, 25.00, 980.00, 16),
    (70, 17.00, 720.00, 9),
    (71, 13.00, 610.00, 7),
    (72, 21.00, 850.00, 12),
    (73, 14.00, 690.00, 8),
    (74, 8.00, 470.00, 4),
    (75, 23.00, 910.00, 14),
    (76, 15.00, 600.00, 7),
    (77, 19.00, 760.00, 10),
    (78, 20.00, 780.00, 11),
    (79, 9.00, 510.00, 6),
    (80, 16.00, 690.00, 8),

	-- MUSTERIKART Tablosuna veri ekleme (81-120 arası müşteriler)

    (81, 12.00, 600.00, 7),
    (82, 18.00, 720.00, 9),
    (83, 22.00, 850.00, 12),
    (84, 16.00, 670.00, 8),
    (85, 25.00, 950.00, 15),
    (86, 11.00, 520.00, 5),
    (87, 19.00, 780.00, 11),
    (88, 13.00, 620.00, 7),
    (89, 17.00, 700.00, 10),
    (90, 21.00, 830.00, 13),
    (91, 15.00, 690.00, 8),
    (92, 9.00, 480.00, 5),
    (93, 23.00, 920.00, 14),
    (94, 14.00, 580.00, 7),
    (95, 20.00, 750.00, 11),
    (96, 18.00, 800.00, 10),
    (97, 10.00, 550.00, 6),
    (98, 16.00, 700.00, 9),
    (99, 12.00, 620.00, 8),
    (100, 22.00, 870.00, 13),
    (101, 19.00, 790.00, 12),
    (102, 15.00, 680.00, 8),
    (103, 11.00, 530.00, 5),
    (104, 25.00, 980.00, 16),
    (105, 17.00, 720.00, 9),
    (106, 13.00, 610.00, 7),
    (107, 21.00, 850.00, 12),
    (108, 14.00, 690.00, 8),
    (109, 8.00, 470.00, 4),
    (110, 23.00, 910.00, 14),
    (111, 15.00, 600.00, 7),
    (112, 19.00, 760.00, 10),
    (113, 20.00, 780.00, 11),
    (114, 9.00, 510.00, 6),
    (115, 16.00, 690.00, 8),
    (116, 12.00, 600.00, 7),
    (117, 18.00, 720.00, 9),
    (118, 22.00, 850.00, 12),
    (119, 16.00, 670.00, 8),
    (120, 25.00, 950.00, 15),

	-- MUSTERIKART Tablosuna veri ekleme (121-160 arası müşteriler)

    (121, 13.00, 630.00, 7),
    (122, 19.00, 780.00, 10),
    (123, 24.00, 920.00, 13),
    (124, 15.00, 700.00, 8),
    (125, 26.00, 980.00, 16),
    (126, 11.00, 530.00, 6),
    (127, 20.00, 800.00, 11),
    (128, 14.00, 650.00, 8),
    (129, 18.00, 730.00, 9),
    (130, 23.00, 880.00, 14),
    (131, 16.00, 710.00, 9),
    (132, 10.00, 550.00, 6),
    (133, 25.00, 970.00, 15),
    (134, 12.00, 590.00, 7),
    (135, 21.00, 820.00, 12),
    (136, 17.00, 750.00, 10),
    (137, 9.00, 490.00, 5),
    (138, 15.00, 710.00, 8),
    (139, 12.00, 620.00, 7),
    (140, 22.00, 880.00, 13),
    (141, 18.00, 780.00, 11),
    (142, 16.00, 690.00, 8),
    (143, 10.00, 530.00, 6),
    (144, 26.00, 1000.00, 17),
    (145, 17.00, 730.00, 9),
    (146, 13.00, 610.00, 7),
    (147, 21.00, 840.00, 12),
    (148, 14.00, 700.00, 8),
    (149, 8.00, 480.00, 5),
    (150, 24.00, 930.00, 14),
    (151, 16.00, 640.00, 8),
    (152, 20.00, 800.00, 11),
    (153, 21.00, 820.00, 12),
    (154, 11.00, 520.00, 6),
    (155, 18.00, 740.00, 10),
    (156, 14.00, 660.00, 8),
    (157, 19.00, 790.00, 11),
    (158, 9.00, 510.00, 6),
    (159, 23.00, 890.00, 13),
    (160, 15.00, 720.00, 9),

	-- MUSTERIKART Tablosuna veri ekleme (161-200 arası müşteriler)

    (161, 22.00, 870.00, 12),
    (162, 16.00, 720.00, 9),
    (163, 12.00, 590.00, 7),
    (164, 19.00, 790.00, 10),
    (165, 25.00, 960.00, 15),
    (166, 18.00, 780.00, 11),
    (167, 10.00, 550.00, 6),
    (168, 21.00, 820.00, 12),
    (169, 14.00, 650.00, 8),
    (170, 20.00, 810.00, 11),
    (171, 26.00, 1000.00, 16),
    (172, 15.00, 700.00, 9),
    (173, 11.00, 530.00, 7),
    (174, 17.00, 740.00, 10),
    (175, 13.00, 610.00, 8),
    (176, 23.00, 890.00, 14),
    (177, 8.00, 480.00, 5),
    (178, 14.00, 670.00, 8),
    (179, 21.00, 840.00, 13),
    (180, 16.00, 730.00, 9),
    (181, 19.00, 770.00, 10),
    (182, 12.00, 560.00, 7),
    (183, 25.00, 970.00, 15),
    (184, 15.00, 690.00, 8),
    (185, 10.00, 520.00, 6),
    (186, 24.00, 930.00, 14),
    (187, 18.00, 770.00, 10),
    (188, 22.00, 860.00, 12),
    (189, 11.00, 530.00, 7),
    (190, 17.00, 720.00, 9),
    (191, 14.00, 650.00, 8),
    (192, 9.00, 500.00, 6),
    (193, 23.00, 920.00, 13),
    (194, 13.00, 590.00, 7),
    (195, 20.00, 820.00, 11),
    (196, 15.00, 710.00, 9),
    (197, 26.00, 990.00, 16),
    (198, 18.00, 760.00, 10),
    (199, 12.00, 550.00, 7),
    (200, 24.00, 950.00, 14);



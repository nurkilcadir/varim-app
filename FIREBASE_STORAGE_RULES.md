# Firebase Storage Rules - Hızlı Düzeltme

## Sorun
Görsel yükleme zaman aşımına uğruyor veya izin hatası veriyor.

## Çözüm: Firebase Storage Rules'ı Güncelle

### Adım 1: Firebase Console'a Git
1. [Firebase Console](https://console.firebase.google.com) aç
2. Projeni seç (`varim-app-a390d`)
3. Sol menüden **Storage** seç
4. **Rules** sekmesine tıkla

### Adım 2: Rules'ı Güncelle

Aşağıdaki kuralları yapıştır:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Events klasörü için: Authenticated kullanıcılar yazabilir
    match /events/{allPaths=**} {
      allow read: if true; // Herkes okuyabilir
      allow write: if request.auth != null; // Sadece giriş yapmış kullanıcılar yazabilir
    }
    
    // Diğer dosyalar için varsayılan kural
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### Adım 3: Publish Et
1. **Publish** butonuna tıkla
2. Değişiklikler birkaç saniye içinde aktif olur

### Adım 4: Test Et
Uygulamada tekrar görsel yüklemeyi dene.

---

## Alternatif: Daha Güvenli Kurallar (Production için)

Eğer sadece admin kullanıcıların yüklemesini istiyorsan:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /events/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

**Not:** Bu kural için Firestore'da `users/{uid}` dokümanında `isAdmin: true` field'ı olmalı.

---

## Hata Ayıklama

Eğer hala sorun varsa:

1. **Browser Console'u aç** (F12)
2. **Network** sekmesine git
3. Görsel yüklemeyi tekrar dene
4. Hata mesajını kontrol et:
   - `403 Forbidden` → Rules sorunu
   - `401 Unauthorized` → Auth sorunu
   - `Timeout` → Network veya Rules sorunu

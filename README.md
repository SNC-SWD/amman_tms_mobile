# Struktur Project & Konfigurasi Penting

## 1. Struktur Direktori Utama

```
.
├── android/                # Project Android native (build, konfigurasi, signing, dsb)
│   ├── app/                # Konfigurasi dan source utama Android
│   │   ├── build.gradle.kts
│   │   ├── google-services.json
│   │   └── src/
│   │       ├── main/       # AndroidManifest.xml, res, java/kotlin
│   │       ├── debug/      # Konfigurasi debug
│   │       └── profile/    # Konfigurasi profile
│   ├── build.gradle.kts    # Build config project Android
│   ├── gradle.properties   # Properti build gradle
│   ├── settings.gradle.kts # Setting project gradle
│   └── ...
├── assets/                 # Asset statis aplikasi
│   ├── image/              # Gambar UI, splash, dsb
│   ├── fonts/              # Font custom (Poppins)
│   └── logo/               # Logo aplikasi
├── ios/                    # Project iOS native (build, konfigurasi, dsb)
│   ├── Runner.xcodeproj/   # Konfigurasi Xcode project
│   ├── Runner/             # Source utama iOS
│   └── Flutter/            # Konfigurasi build Flutter di iOS
├── lib/                    # Source code utama aplikasi Flutter
│   ├── main.dart           # Entry point aplikasi
│   ├── screens/            # Halaman-halaman aplikasi
│   ├── models/             # Model data aplikasi
│   ├── widgets/            # Widget custom aplikasi
│   └── core/               # Core logic, service, config, API
├── test/                   # Unit/widget test
├── pubspec.yaml            # Konfigurasi dependency & asset Flutter
├── analysis_options.yaml   # Konfigurasi linter/analyzer Dart
├── README.md               # Dokumentasi project
└── ...
```

## 2. Penjelasan Folder/File Utama

- **android/**: Semua konfigurasi dan source code terkait build Android native.
  - **app/build.gradle.kts**: Konfigurasi build, signing, dependency Android.
  - **app/google-services.json**: Konfigurasi Firebase untuk Android.
  - **src/main/AndroidManifest.xml**: Manifest aplikasi Android.
- **ios/**: Semua konfigurasi dan source code terkait build iOS native.
  - **Runner.xcodeproj/project.pbxproj**: Konfigurasi project Xcode.
  - **Flutter/Debug.xcconfig, Release.xcconfig**: Konfigurasi build Flutter di iOS.
- **assets/**: Asset statis seperti gambar, font, dan logo.
- **lib/**: Source code utama aplikasi Flutter.
  - **main.dart**: Entry point aplikasi, inisialisasi Firebase, notifikasi, dsb.
  - **screens/**: Kumpulan halaman (UI) aplikasi (login, home, map, dsb).
  - **models/**: Model data (bus, trip, user, dsb).
  - **widgets/**: Widget custom reusable (card, list item, dsb).
  - **core/**: Konfigurasi, service, dan API client.
    - **services/**: Service utama (auth, bus, trip, dsb).
    - **api/**: Konfigurasi endpoint API.
    - **config/**: Konfigurasi tambahan & utilitas.
- **test/**: Unit test dan widget test.
- **pubspec.yaml**: Konfigurasi dependency, asset, dan font Flutter.
- **analysis_options.yaml**: Konfigurasi linter dan analyzer Dart.

## 3. Konfigurasi Penting

### pubspec.yaml
- **dependencies**: Berisi package utama seperti `firebase_core`, `firebase_auth`, `firebase_messaging`, `dio`, `http`, `shared_preferences`, `flutter_map`, dsb.
- **dev_dependencies**: Untuk testing dan linter (`flutter_test`, `flutter_lints`).
- **flutter**:
  - **assets**: Mendefinisikan asset yang digunakan (`assets/logo/`, `assets/image/`).
  - **fonts**: Mendefinisikan font custom (Poppins).
- **flutter_icons**: Konfigurasi icon aplikasi (Android & iOS).

### analysis_options.yaml
- Menggunakan linter dari `flutter_lints` untuk menjaga kualitas kode.
- Bisa dikustomisasi sesuai kebutuhan project.

### android/app/build.gradle.kts
- Konfigurasi build Android, dependency, signing config, dan integrasi Firebase.
- Signing config menggunakan file `key.jks` dan `key.properties`.

### ios/Runner.xcodeproj/project.pbxproj & Flutter/*.xcconfig
- Konfigurasi build, dependency, dan environment iOS.
- Integrasi asset, info plist, dsb.

## 4. Konfigurasi Tools/Library Khusus

- **Firebase**: Integrasi melalui `firebase_core`, `firebase_auth`, `firebase_messaging`, dan file `google-services.json` (Android).
- **Flutter Lints**: Standar linter untuk menjaga kualitas kode.
- **Flutter Launcher Icons**: Otomatisasi pembuatan icon aplikasi.
- **Shared Preferences**: Penyimpanan data lokal sederhana.
- **Dio & HTTP**: Untuk komunikasi HTTP/REST API.
- **Custom Font**: Menggunakan Poppins (lihat konfigurasi di pubspec.yaml).

---

> Dokumentasi ini dihasilkan otomatis berdasarkan struktur dan konfigurasi project pada saat pembuatan file. 
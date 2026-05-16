# 📱 Utility Toolkit App (Flutter) - DocSathi

A modern, scalable **all-in-one utility app** built with Flutter.  
Designed for everyday needs like **Photo → PDF**, **Image Resize (Govt Forms)**, **PDF Tools**, and more — all in one clean, fast, offline-first experience.

---

## 🚀 Features

### ✅ Current (MVP)

#### 🧾 Create Documents

##### 📸 Photo to PDF
- Select multiple images from gallery
- Reorder pages before generating PDF
- Generate high-quality PDF documents
- Save locally or share instantly

#### 🖼️ Optimize Images

##### 🖼️ Image Resize (Govt Form Ready)
- Change width/height for exact form dimensions
- Preset modes:
  - Passport Photo
  - Signature Upload
  - Custom Dimensions

---

### 🔜 Upcoming Features (Category-wise)

#### 🧾 Create Documents
- 📷 Document Scanner (camera capture + auto cleanup)

#### 🖼️ Optimize Images
- 🗜️ Compress Image (reduce KB/MB while preserving dimensions)

#### 📄 Manage PDFs
- 📄 PDF Merge & Split  
- ✏️ PDF Editor (Reorder, Delete pages)  

#### 🤖 Extract & Secure
- 🔍 OCR (Text extraction from images)  
- 🧾 Watermark & Digital Signature  

#### ☁️ Organize & Sync
- ☁️ Cloud Backup & Sync  
- 📁 File Manager Dashboard  

---

## 🧠 Architecture

This project follows a **Modular Feature-First Clean Architecture** to ensure long-term scalability and maintainability.

### 📂 Folder Structure

```
lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
│
├── core/
│   ├── constants/
│   ├── config/
│   ├── errors/
│   ├── services/
│   │   ├── file_service.dart
│   │   ├── permission_service.dart
│   │   ├── image_service.dart
│   │   └── pdf_service.dart
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── photo_to_pdf/
│   ├── image_resize/
│   ├── pdf_editor/
│   ├── file_manager/
│   └── settings/
│
├── shared/
│   ├── models/
│   ├── widgets/
│   └── providers/
│
└── main.dart
```

---

### 🧩 Feature Module Structure

Each feature is built as an independent module:

```
feature_name/
├── data/
├── domain/
├── presentation/
└── controllers/
```

---

### 🧠 Architecture Principles

- Feature-based modular design
- Separation of concerns (data / domain / presentation)
- Reusable shared services
- Offline-first approach
- Scalable for future tools

---

## 🛠️ Tech Stack

| Layer | Technology |
|------|-----------|
| Framework | Flutter |
| Language | Dart |
| State Management | Riverpod |
| Routing | GoRouter |
| Local Storage | Hive |
| PDF Engine | pdf, printing |
| Image Processing | image |
| File Access | path_provider |
| Permissions | permission_handler |
| CI/CD | GitHub Actions |
| Cloud Dev | GitHub Codespaces |
| Build System | Gradle |
| Signing | Android Keystore |

---

## ⚙️ Development Setup

### ☁️ Option 1: Cloud Development (Recommended)

Use **GitHub Codespaces**:

1. Open repository on GitHub
2. Click on `Code`
3. Select `Codespaces`
4. Launch a new Codespace

This gives you:
- Full VS Code-like environment
- Terminal access
- Flutter SDK ready

---

### 💻 Option 2: Local Development

```bash
flutter pub get
flutter run
```

---

## 🏭 CI/CD Pipeline

This project uses **GitHub Actions** for automated builds.

### 🔄 Pipeline Flow

```
Push Code
   ↓
GitHub Actions Trigger
   ↓
Setup Flutter + Java
   ↓
Install Dependencies
   ↓
Build APK & AAB
   ↓
Upload Artifacts
   ↓
Release Ready
```

---

### 📦 Build Outputs

| File | Purpose |
|------|--------|
| app-debug.apk | Testing on device |
| app-release.apk | Direct install |
| app-release.aab | Upload to Play Store |

---

## 🔐 App Signing (Production)

To publish on Play Store, app must be signed securely.

### 🔑 Required GitHub Secrets

```
KEYSTORE_BASE64
KEY_ALIAS
KEY_PASSWORD
STORE_PASSWORD
```

### 🔒 Security Notes

- Keystore file is NOT stored in repo
- It is encoded using Base64
- Decoded during CI build
- Ensures secure signing pipeline

---

## ⚡ Performance Strategy

To ensure smooth performance:

- Image compression before processing
- Background processing using isolates
- Lazy loading of features
- Memory-efficient image handling
- Optimized file I/O operations

---

## 🎨 UI/UX Philosophy

- Material 3 Design System
- Minimal & clean interface
- Fast, responsive interactions
- One-tap workflows
- Dark mode support
- Mobile-first experience

---

## 🧩 Core Services

Shared across all features:

- 📁 File Service (save, delete, manage files)
- 🖼️ Image Service (resize, compress)
- 📄 PDF Service (generate, merge, edit)
- 🔐 Permission Service (storage, camera)

---

## 📈 Future Scope

- AI-powered document scanning
- Smart auto-cropping
- OCR text recognition
- Cloud sync (Firebase/Supabase)
- Multi-device access
- Premium subscription features

---

## 💰 Monetization (Planned)

- Ads (AdMob)
- Premium tools unlock
- Watermark removal
- Advanced PDF editing features

---

## 🤝 Contributing

Contributions are welcome!

Steps:
1. Fork the repository
2. Create your feature branch
3. Commit changes
4. Open a Pull Request

---

## 📄 License

MIT License

---

## 💡 Vision

> Build one powerful app that replaces multiple small utility apps.

---

## ⭐ Support

If you like this project:

- Star ⭐ the repository
- Share it with others
- Suggest new features

---

Made with ❤️ using Flutter

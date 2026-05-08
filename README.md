# 📄 Photos to PDF – Flutter App

A fast, offline-first Android app built with Flutter that converts multiple images into high-quality PDF documents with a smooth, modern UI.

---

## ✨ Features

* 📸 Select multiple images from gallery
* 🔀 Reorder pages via drag & drop
* 🧾 Convert images into PDF instantly
* 📝 Rename PDF before saving
* 💾 Save locally on device
* 📤 Share PDF directly
* 🌙 Dark mode support
* ⚡ Fully offline (no backend required)

---

## 🏗️ Tech Stack

* **Framework:** Flutter
* **Language:** Dart
* **State Management:** Riverpod
* **Architecture:** Feature-first Clean Architecture
* **CI/CD:** GitHub Actions
* **Storage:** Hive (local storage)

---

## 📦 Packages Used

* `image_picker` – select images
* `pdf` – generate PDF files
* `printing` – preview/share PDFs
* `path_provider` – file system access
* `permission_handler` – runtime permissions
* `flutter_riverpod` – state management
* `hive` – lightweight local storage

---

## 📁 Project Structure

```
lib/
├── app/
├── core/
├── features/
│   └── pdf_creator/
├── shared/
└── main.dart
```

---

## ⚙️ Development Setup (Cloud-Based)

This project is designed to work fully with:
* GitHub Codespaces
* GitHub Actions

### Steps
1. Open repo in Codespaces
2. Run:
```bash
flutter pub get
flutter run
```

---

## 🚀 Build & CI/CD Pipeline

Automated using GitHub Actions.

On every push:
```
Code Push
   ↓
GitHub Actions Triggered
   ↓
Flutter Build Runs
   ↓
APK + AAB Generated
   ↓
Artifacts Uploaded
```

### Build Outputs
* `app-debug.apk` → testing
* `app-release.apk` → manual install
* `app-release.aab` → Play Store

---

## 🔐 App Signing (Production)

App signing is handled securely using GitHub Secrets.

### Required Secrets
* `KEYSTORE_BASE64`
* `KEY_ALIAS`
* `KEY_PASSWORD`
* `STORE_PASSWORD`

Keystore is encoded using Base64 and injected during build.

---

## 📲 Installation

### Debug APK
Download from GitHub Actions → install directly on device.

### Play Store
Upload `.aab` file to Google Play Console.

---

## 📈 Future Roadmap

* 📄 OCR (Text extraction)
* ✍️ PDF signatures
* 🔒 Password-protected PDFs
* ☁️ Cloud backup
* 🧠 AI auto-cropping & enhancement

---

## 🧠 Architecture Philosophy

* Modular feature-based structure
* Scalable for future features
* Clean separation of concerns
* Optimized for performance on low-end devices

---

## ⚡ Performance Strategy

* Image compression before PDF generation
* Efficient memory handling
* Background processing using isolates

---

## 🤝 Contributing

Contributions are welcome.
Feel free to fork and improve the project.

---

## 📜 License

MIT License

---

## 👨‍💻 Author

Built with ❤️ by AALOK

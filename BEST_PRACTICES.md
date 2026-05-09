# World-Class Flutter App Development: Best Practices & Guidelines

This document outlines the core principles, build strategies, and architectural decisions required to maintain "Photos to PDF" as a world-class, highly optimized, and scalable application. These rules ensure maximum performance, minimal app size, and exceptional code quality.

## 1. App Size Optimization (The "No Bloat" Rule)

A smaller app installs faster, converts better on the Play Store, and respects the user's storage limits.

### Build Formats
Never distribute a "Universal APK" (Fat APK) unless absolutely necessary for an environment that strictly requires it. Universal APKs bundle binaries for all architectures (arm64, armeabi, x86), ballooning the size.

*   **Play Store (Production):** Always build an App Bundle (`.aab`). The Google Play Store uses this to generate tiny, device-specific APKs automatically.
    ```bash
    flutter build appbundle --release
    ```
*   **Direct Distribution (Website, GitHub Releases, QA):** Build Split APKs. This generates separate APKs for each architecture. You provide the `arm64-v8a` to most modern users, keeping their download small.
    ```bash
    flutter build apk --release --split-per-abi
    ```

### Code Shrinking & Obfuscation (R8/ProGuard)
Always ensure `minifyEnabled` and `shrinkResources` are set to `true` in `android/app/build.gradle.kts` for the `release` build type. This strips out unused Dart code, Java/Kotlin engine code, and unused assets.

### Dependency Auditing
*   **Zero Unused Dependencies:** Regularly audit `pubspec.yaml`. If a package is not actively used (e.g., leaving `sqflite` in while using `hive`), remove it.
*   **Avoid Redundant Packages:** Don't include `cupertino_icons` if the app is strictly adhering to Material Design.
*   **Prefer Lightweight Packages:** Before adding a new dependency, check its size impact and whether a lighter alternative exists, or if the functionality can be easily written natively.

### Asset Management
*   **Vector Over Raster:** Use `.svg` (via `flutter_svg`) or built-in icon fonts instead of `.png` or `.jpg` whenever possible.
*   **WebP Compression:** If you *must* use raster images, convert them to `.webp` format. It provides significantly better compression than PNG or JPEG with identical quality.

## 2. Architecture & Scalability (Feature-First Clean Architecture)

To ensure the codebase remains maintainable as the app grows, strictly adhere to a Feature-First modular approach.

*   **Separation of Concerns:** Keep UI (`presentation`), business logic (`application`/`domain`), and data access (`data`) strictly separated.
*   **State Management (Riverpod):**
    *   Never put business logic in UI widgets.
    *   Use Riverpod's `AsyncValue` to gracefully handle loading, error, and data states.
    *   Keep providers focused and scoped.
*   **Dependency Injection:** Ensure repositories and services are injected, making them easily mockable for testing.

## 3. Offline-First Reliability

As a "Photos to PDF" utility, the app must function flawlessly without an internet connection.

*   **Local Storage (Hive):** Use fast, synchronous local storage (like Hive) for document metadata and user preferences.
*   **File System:** Manage generated PDFs and cached images efficiently using `path_provider`. Always clean up temporary files (like intermediate cropped images) to prevent the app cache from growing out of control over time.
*   **No Blocking Operations on Main Thread:** Image processing (compression, PDF generation) is CPU intensive. Always use `compute()` or Isolates to move heavy work off the UI thread to prevent frame drops and UI freezes.

## 4. Quality Assurance & Performance

*   **Zero Warnings:** Treat all analyzer warnings as errors. The code must compile cleanly.
*   **Const Constructors:** Use `const` everywhere possible for UI widgets. This dramatically reduces the burden on the Flutter garbage collector and improves frame rates.
*   **Logging:** Avoid using `print()` in production code. Use a structured logging package (like `logger`) and ensure debug logs are stripped or disabled in release builds.

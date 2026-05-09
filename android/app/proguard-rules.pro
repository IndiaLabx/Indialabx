# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class plugins.flutter.io.**  { *; }

# Hive / Plugins
-keep class com.jhomlala.catchme.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class me.carda.awesome_notifications.** { *; }

# Prevent obfuscation of platform channels (if any custom channels are used)
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Ignore warnings from common libraries
-dontwarn io.flutter.**
-dontwarn java.lang.invoke.*

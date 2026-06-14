# Flutter-specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# url_launcher
-keep class androidx.lifecycle.DefaultLifecycleObserver

# play_core (deferred components etc — keeps shrinker quiet)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Keep our model classes (riverpod uses reflection-light, but be safe)
-keep class kz.nuva.** { *; }

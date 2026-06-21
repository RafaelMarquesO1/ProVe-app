# Preservar classes de bootstrap e de ciclo de vida do Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# NÃO otimizar ou apagar a sua MainActivity
-keep class com.leituraprove.app.MainActivity { *; }
-keep class com.leituraprove.app.** { *; }

# Classes do play.core.tasks referenciadas internamente pelo Flutter (deferred components)
# O app não usa deferred components, então essas referências nunca são chamadas em runtime.
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

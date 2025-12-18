pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // [Fix] Update AGP to 8.8.0 (Latest Stable)
    id("com.android.application") version "8.8.0" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false
    // [Fix] Update Kotlin to 2.1.0 as requested by the warning
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
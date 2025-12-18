plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.easymoney.app.easymoney"
    compileSdk = 36 // Required by your plugins

    defaultConfig {
        applicationId = "com.easymoney.app.easymoney"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // [Fix 1] Enable MultiDex for desugaring
        multiDexEnabled = true 
    }

    compileOptions {
        // [Fix 1] Enable Core Library Desugaring
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
}

dependencies {
    // [Fix 1] Required for Desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("androidx.multidex:multidex:2.0.1")
}

// [Fix 2] Force older activity version to satisfy AGP 8.8.0
configurations.all {
    resolutionStrategy {
        force("androidx.activity:activity:1.9.3")
        force("androidx.activity:activity-ktx:1.9.3")
    }
}

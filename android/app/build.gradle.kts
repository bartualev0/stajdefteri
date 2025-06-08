plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.myapp"
    // DÜZELTME 1: Hata mesajının önerdiği gibi compileSdk versiyonunu manuel olarak
    // 34'e yükseltmek, genellikle bu tür desugaring sorunlarına yardımcı olur.
    compileSdk = 35
    // DÜZELTME 2: NDK sürümünü manuel olarak belirtin.
    ndkVersion = "27.0.12077973"

    compileOptions {
        // DÜZELTME 3: Core library desugaring'i etkinleştirin.
        isCoreLibraryDesugaringEnabled = true
        // Bu iki satır sizde zaten vardı, olduğu gibi bırakın.
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.myapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// DÜZELTME 4: Desugaring için gerekli kütüphane bağımlılığını ekleyin.
// Bu bloğu dosyanın en sonuna ekleyebilirsiniz.
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
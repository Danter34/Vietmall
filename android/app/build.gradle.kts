import org.gradle.api.JavaVersion
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.vietmall"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        // BẮT BUỘC cho flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Khai báo theo DSL mới (không dùng kotlinOptions cũ)
    kotlin {
        jvmToolchain(17)
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        applicationId = "com.example.vietmall"
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

flutter {
    source = "../.."
}

dependencies {
    // ✅ Thư viện desugar JDK (bắt buộc khi bật isCoreLibraryDesugaringEnabled)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // (Không cần thêm kotlin-stdlib, plugin Kotlin tự thêm)
}

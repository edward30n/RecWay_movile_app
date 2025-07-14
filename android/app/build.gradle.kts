plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.test1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        // Needed for desugaring which allows us to use java.time APIs
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.test1"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isDebuggable = true
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    
    packagingOptions {
        pickFirst("**/armeabi-v7a/libc++_shared.so")
        pickFirst("**/arm64-v8a/libc++_shared.so")
        pickFirst("**/x86/libc++_shared.so")
        pickFirst("**/x86_64/libc++_shared.so")
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.window:window:1.2.0")
    implementation("androidx.window:window-java:1.2.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Google Play Core for Flutter Engine compatibility
    implementation("com.google.android.play:core:1.10.3")
    implementation("com.google.android.play:core-ktx:1.8.1")
}

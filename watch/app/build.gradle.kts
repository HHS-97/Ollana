plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

android {
    namespace = "com.c104.ollana"
    compileSdk = 35


    signingConfigs {
        // 기존에 있는 debug 설정에 접근해서 수정
        getByName("debug") {
            storeFile = file("${rootProject.rootDir}/app/debug.keystore")
            storePassword = "ssafy1234";
            keyAlias = "ollanadebugkey";
            keyPassword = "ssafy1234";
        }

        // release는 새로 생성
        create("release") {
            storeFile = file("${rootProject.rootDir}/app/my-release-key.jks")
            storePassword = "ssafy1234"
            keyAlias = "ollana"
            keyPassword = "ssafy1234"
        }
    }

    defaultConfig {
        applicationId = "com.c104.ollana"
        minSdk = 31
        targetSdk = 35
        versionCode=2
        versionName= "1.0.1"
    }
    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            isMinifyEnabled = true
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
    buildFeatures {
        compose = true
    }
}

dependencies {
    implementation(libs.play.services.wearable)
    implementation(platform(libs.compose.bom))
    implementation(libs.ui)
    implementation(libs.ui.graphics)
    implementation(libs.ui.tooling.preview)
    implementation(libs.compose.material)
    implementation(libs.compose.foundation)
    implementation(libs.wear.tooling.preview)
    implementation(libs.activity.compose)
    implementation(libs.core.splashscreen)
    implementation(libs.material3.android)
    implementation(libs.gson)

    androidTestImplementation(platform(libs.compose.bom))
    androidTestImplementation(libs.ui.test.junit4)

    debugImplementation(libs.ui.tooling)
    debugImplementation(libs.ui.test.manifest)
    implementation(libs.coil.compose)

    implementation(libs.coil.gif)
}

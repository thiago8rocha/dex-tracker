plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ─── SIGNING ──────────────────────────────────────────────────────
// Para gerar o keystore de produção (fazer UMA VEZ antes do primeiro upload):
//
//   keytool -genkey -v -keystore android/app/dexcurator-release.jks \
//     -keyalg RSA -keysize 2048 -validity 10000 -alias dexcurator
//
// Depois criar android/key.properties com:
//   storePassword=<sua_senha>
//   keyPassword=<sua_senha_da_chave>
//   keyAlias=dexcurator
//   storeFile=dexcurator-release.jks
//
// O arquivo key.properties JÁ ESTÁ no .gitignore — nunca commitar.
// O arquivo .jks JÁ ESTÁ no .gitignore — nunca commitar.

def keystoreProperties = new java.util.Properties()
def keystorePropertiesFile = rootProject.file('app/key.properties')
def hasKeystore = keystorePropertiesFile.exists()
if (hasKeystore) {
    keystorePropertiesFile.withInputStream { keystoreProperties.load(it) }
}

android {
    namespace = "com.thiago8rocha.dexcurator"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // IMPORTANTE: applicationId NÃO pode ser alterado após publicar na Play Store.
        // Formato: com.thiago8rocha.dexcurator
        applicationId = "com.thiago8rocha.dexcurator"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"]
                keyPassword = keystoreProperties["keyPassword"]
                storeFile = file(keystoreProperties["storeFile"]!!)
                storePassword = keystoreProperties["storePassword"]
            }
        }
    }

    buildTypes {
        release {
            // Usa keystore de produção se disponível; debug caso contrário.
            // Em CI/CD, garantir que key.properties está presente antes do build.
            signingConfig = if (hasKeystore)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")

            // Minificação — habilitar antes de publicar na Play Store
            // minifyEnabled = true
            // shrinkResources = true
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

flutter {
    source = "../.."
}

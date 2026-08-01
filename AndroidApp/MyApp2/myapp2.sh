# 1. 念のため必要なフォルダ構造を再確認・作成
mkdir -p app/src/main/java/hiro/MyApp
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values

echo "=========================================="
echo " [1/3] ルートの settings.gradle を修正中..."
echo "=========================================="
# ルート直下の settings.gradle でサブプロジェクト 'app' を確実に認識させます
cat << 'EOF' > settings.gradle
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "MyApp2"
include ':app'
EOF

echo "=========================================="
echo " [2/3] app フォルダ内に build.gradle を作成中..."
echo "=========================================="
# Android プラグインを適用し、assembleDebug タスクを生成させる心臓部です
cat << 'EOF' > app/build.gradle
plugins {
    id 'hiro.MyApp2'
}

android {
    namespace 'hiro.MyApp2'
    compileSdk 34

    defaultConfig {
        applicationId "hiro.MyApp2"
        minSdk 1
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
        }
    }
}
EOF

echo "=========================================="
echo " [3/3] ルート用の空の build.gradle を作成中..."
echo "=========================================="
# ルートディレクトリ自体にはプラグインを置かず、空にしておくのがAndroidの標準構成です
touch build.gradle

echo "----------------------------------------------------"
echo " 設定ファイルの配置が完了しました。"
echo " 以下の手順で assembleDebug タスクの存在確認とビルドを行ってください。"
echo "----------------------------------------------------"

@echo off
rem ============================================================================
rem  特製 Gradle Wrapper シミュレーター (gradlew.bat)
rem  Gradleプロセスを使わず、Android SDKツール群をパイプライン実行してAPKを生成
rem ============================================================================
setlocal enabledelayedexpansion

rem ---- [環境設定] ご自身の環境に合わせてパスを修正してください ----
set "JAVA_HOME=C:\java\jdk1.8.0_202"
set "ANDROID_HOME=c:\Sdk"
set "BUILD_TOOLS_VERSION=34.0.0"

set "JAVAC=%JAVA_HOME%\bin\javac.exe"
set "BUILD_TOOLS=%ANDROID_HOME%\build-tools\%BUILD_TOOLS_VERSION%"
set "PLATFORM=%ANDROID_HOME%\platforms\android-34\android.jar"

rem ---- [プロジェクト設定] ----
set "PROJECT_NAME=MyApp2"
set "PACKAGE_PATH=hiro\MyApp2"
set "PKG_NAME=hiro.MyApp2"

set "SRC_DIR=app\src\main"
set "GEN_DIR=app\build\generated\sources"
set "OBJ_DIR=app\build\intermediates\classes"
set "DEX_DIR=app\build\intermediates\dex"
set "OUT_DIR=app\build\outputs\apk\debug"

rem ============================================================================
rem  引数（タスク）の解析
rem ============================================================================
if "%~1"=="" (
    echo [INFO] タスクが指定されていません。利用可能なタスク: assembleDebug, clean, tasks
    exit /b 0
)

if "%~1"=="clean" (
    echo ^> Task :clean
    if exist app\build rmdir /s /q app\build
    echo [SUCCESS] build ディレクトリをクリーンアップしました。
    exit /b 0
)

if "%~1"=="tasks" (
    echo ^> Task :tasks
    echo 可用タスク一覧:
    echo   assembleDebug - ソースコードからデバッグ用APKを生成・署名します
    echo   clean         - 過去のビルド成果物を削除します
    exit /b 0
)

if not "%~1"=="assembleDebug" (
    echo [ERROR] タスク '%~1' が見つかりません。'assembleDebug' を指定してください。
    exit /b 1
)

echo ============================================================================
echo  Starting Pipeline for ':app:assembleDebug' (Gradle-free Native Build)
echo ============================================================================

rem 必要な一時フォルダの作成
if not exist "%GEN_DIR%" mkdir "%GEN_DIR%"
if not exist "%OBJ_DIR%" mkdir "%OBJ_DIR%"
if not exist "%DEX_DIR%" mkdir "%DEX_DIR%"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

rem ----------------------------------------------------------------------------
rem  Stage 1: リソースのコンパイルと R.java の自動生成 (:app:processDebugResources)
rem ----------------------------------------------------------------------------
echo ^> Task :app:processDebugResources
if not exist "app\build\intermediates\res" mkdir "app\build\intermediates\res"

rem aapt2 を使ってリソースをコンパイル
"%BUILD_TOOLS%\aapt2.exe" compile --dir "%SRC_DIR%\res" -o app\build\intermediates\res\resources.zip >nul 2>&1
if %ERRORLEVEL% neq 0 (
    rem resフォルダが空、または無い場合のフォールバック用にダミーでリンクを通す
    echo [INFO] カスタムresリソースがないため、デフォルト設定で進めます。
)

rem マニフェストとリソースをリンクし、R.java を生成する
"%BUILD_TOOLS%\aapt2.exe" link ^
    -I "%PLATFORM%" ^
    --manifest "%SRC_DIR%\AndroidManifest.xml" ^
    --java "%GEN_DIR%" ^
    -o "%OUT_DIR%\app-debug-unaligned.apk"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] aapt2 link に失敗しました。AndroidManifest.xmlを確認してください。
    exit /b 1
)

rem ----------------------------------------------------------------------------
rem  Stage 2: Javaソースコードのコンパイル (:app:compileDebugJavaWithJavac)
rem ----------------------------------------------------------------------------
echo ^> Task :app:compileDebugJavaWithJavac

rem 自動生成された R.java と、人間が書いた MainActivity.java をまとめてコンパイル
"%JAVAC%" -target 1.8 -source 1.8 ^
    -bootclasspath "%PLATFORM%" ^
    -d "%OBJ_DIR%" ^
    "%GEN_DIR%\hiro\MyApp\R.java" ^
    "%SRC_DIR%\java\%PACKAGE_PATH%\MainActivity.java"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Javaコンパイル(javac)に失敗しました。ソースコードを確認してください。
    exit /b 1
)

rem ----------------------------------------------------------------------------
rem  Stage 3: デックス変換 (DEX化) (:app:dexBuilderDebug)
rem ----------------------------------------------------------------------------
echo ^> Task :app:dexBuilderDebug

rem コンパイルされた .class ファイル群を、Android専用の classes.dex に変換
call "%BUILD_TOOLS%\d8.bat" ^
    --lib "%PLATFORM%" ^
    --output "%DEX_DIR%" ^
    "%OBJ_DIR%\hiro\MyApp\*.class"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] D8によるDex変換に失敗しました。
    exit /b 1
)

rem ----------------------------------------------------------------------------
rem  Stage 4: パッケージングと署名 (:app:packageDebug)
rem ----------------------------------------------------------------------------
echo ^> Task :app:packageDebug

rem 1. 一時的に作成したベースのAPK（リソース入り）を作業フォルダにコピー
copy /y "%OUT_DIR%\app-debug-unaligned.apk" "%OUT_DIR%\app-debug-unsigned.apk" >nul

rem 2. jar/zip コマンド相当の処理で classes.dex を APK 内に追加
cd "%DEX_DIR%"
"%JAVA_HOME%\bin\jar.exe" uf "..\..\..\..\%OUT_DIR%\app-debug-unsigned.apk" classes.dex
cd ..\..\..\..\

rem 3. zipalign による最適化
if exist "%OUT_DIR%\app-debug.apk" del "%OUT_DIR%\app-debug.apk"
"%BUILD_TOOLS%\zipalign.exe" -v 4 "%OUT_DIR%\app-debug-unsigned.apk" "%OUT_DIR%\app-debug.apk" >nul

rem 4. デバッグ署名の適用 (debug.keystore がない場合は、apksigner標準の自己署名、またはローカルの鍵を使用)
rem ※ここでは簡易的に apksigner でデバッグキーストアを自動生成または適用するコマンドを走らせます
echo ^> Task :app:validateSigningDebug

rem ユーザーフォルダの .android/debug.keystore を探索
set "KEYSTORE=%USERPROFILE%\.android\debug.keystore"
if not exist "%KEYSTORE%" (
    echo [INFO] デバッグキーストアを自動生成しています...
    if not exist "%USERPROFILE%\.android" mkdir "%USERPROFILE%\.android"
    "%JAVA_HOME%\bin\keytool.exe" -genkeypair -v -keystore "%KEYSTORE%" -alias androiddebugkey -keypass android -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 10000 -keyalg RSA -keysize 2048
)

rem APKへ電子署名を行う
call "%BUILD_TOOLS%\apksigner.bat" sign ^
    --ks "%KEYSTORE%" ^
    --ks-key-alias androiddebugkey ^
    --ks-pass pass:android ^
    --key-pass pass:android ^
    "%OUT_DIR%\app-debug.apk"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] APKの署名(apksigner)に失敗しました。
    exit /b 1
)

echo ============================================================================
echo  BUILD SUCCESSFUL in Native Pipeline
echo  Output: %OUT_DIR%\app-debug.apk
echo ============================================================================
endlocal
exit /b 0
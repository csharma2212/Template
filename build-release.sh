#!/usr/bin/env bash
set -e

echo ">>> [1/4] Configuring environment variables..."
export ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
echo "sdk.dir=$ANDROID_HOME" > local.properties

if [ -z "$JAVA_HOME" ] || [[ "$JAVA_HOME" == *"25"* ]]; then
    JAVA_17_PATH=$(find /usr/local/sdkman/candidates/java "$HOME/.sdkman/candidates/java" /usr/lib/jvm -maxdepth 1 -name "*17*" 2>/dev/null | head -n 1)
    if [ -n "$JAVA_17_PATH" ]; then
        export JAVA_HOME="$JAVA_17_PATH"
        export PATH="$JAVA_HOME/bin:$PATH"
    fi
fi

echo "Using Java runtime at: ${JAVA_HOME:-default}"

echo ">>> [2/4] Verifying execution permissions..."
chmod +x ./gradlew

echo ">>> [3/4] Compiling Signed Release APK via Gradle CLI..."
./gradlew clean assembleRelease --no-daemon --console=plain

echo ">>> [4/4] Verifying APK generation..."
APK_PATH="app/build/outputs/apk/release/app-release.apk"

if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo ""
    echo "================================================================="
    echo ">>> BUILD SUCCESSFUL!"
    echo "Release APK Location: $APK_PATH"
    echo "File Size:            $APK_SIZE"
    echo "-----------------------------------------------------------------"
    echo "HOW TO DOWNLOAD ON MOBILE:"
    echo "1. In VS Code file explorer (left sidebar), expand the tree:"
    echo "   app -> build -> outputs -> apk -> release"
    echo "2. Tap & hold (or tap three dots next to) 'app-release.apk'"
    echo "3. Tap 'Download...'"
    echo "4. Open your phone's Downloads folder and tap to install."
    echo "================================================================="
else
    echo ">>> Build completed, but $APK_PATH was not found."
    exit 1
fi

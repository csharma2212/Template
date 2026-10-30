#!/usr/bin/env bash

echo ">>> [1/5] Configuring Android SDK environment..."
export ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
echo "sdk.dir=$ANDROID_HOME" > local.properties

# Export path for cmdline-tools
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

echo ">>> [2/5] Ensuring template-release-key.jks exists for Gradle model validation..."
if [ ! -f "template-release-key.jks" ]; then
    keytool -genkeypair -v \
        -keystore "template-release-key.jks" \
        -alias "template_alias" \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -storepass "template_store_pass" \
        -keypass "template_store_pass" \
        -dname "CN=CodespaceDev, OU=Mobile, O=TemplateDev, L=Cloud, ST=Global, C=US"
    echo "    -> Generated template-release-key.jks"
fi

echo ">>> [3/5] Verifying Gradle wrapper files..."
mkdir -p gradle/wrapper

# Check wrapper properties
if [ ! -f "gradle/wrapper/gradle-wrapper.properties" ]; then
    cat << 'PROPS' > gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.9-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
PROPS
fi

# Ensure gradle-wrapper.jar binary exists
if [ ! -s "gradle/wrapper/gradle-wrapper.jar" ]; then
    echo "    -> Fetching gradle-wrapper.jar..."
    curl -fL -sS -o gradle/wrapper/gradle-wrapper.jar https://raw.githubusercontent.com/gradle/gradle/v8.9.0/gradle/wrapper/gradle-wrapper.jar
fi

# Ensure gradlew executable script exists
if [ ! -s "./gradlew" ]; then
    echo "    -> Fetching gradlew shell script..."
    curl -fL -sS -o gradlew https://raw.githubusercontent.com/gradle/gradle/v8.9.0/gradlew
fi
chmod +x ./gradlew

echo ">>> [4/5] Testing Gradle Wrapper initialization..."
./gradlew -v --no-daemon --console=plain

if [ $? -ne 0 ]; then
    echo "[ERROR] Gradle wrapper failed to initialize. Check your Java version (must be Java 17)."
    exit 1
fi

echo ">>> [5/5] Pre-caching project dependencies..."
./gradlew tasks --no-daemon --console=plain

if [ $? -eq 0 ]; then
    echo "=================================================="
    echo "[SUCCESS] Dependencies and plugins cached!"
    echo "=================================================="
else
    echo "[ERROR] Dependency resolution failed. Run with --stacktrace to view logs:"
    ./gradlew tasks --no-daemon --stacktrace
    exit 1
fi

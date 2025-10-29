#!/bin/bash

# rebuild-and-test.sh - 重新建置並測試 ARM64 Docker 映像
set -e

echo "=========================================="
echo "🔧 重新建置 QGroundControl ARM64 Docker 映像"
echo "=========================================="

# 清理舊的映像以確保完全重建
echo "🧹 清理舊映像..."
docker rmi qgc-arm64-builder:latest 2>/dev/null || true

# 設定 QEMU 支援
echo "🔧 設定 QEMU ARM64 支援..."
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# 重新建置映像
echo "🔨 重新建置 Docker 映像（包含穩定性修正）..."
docker build \
    --platform linux/arm64 \
    --file docker/Dockerfile.arm64 \
    --tag qgc-arm64-builder:latest \
    --progress=plain \
    .

echo "✅ Docker 映像建置完成！"

# 驗證映像
echo "🔍 驗證映像內容..."
docker run --rm --platform linux/arm64 qgc-arm64-builder:latest bash -c "
    echo '=== 系統資訊 ==='
    uname -a
    echo '=== 編譯器版本 ==='
    gcc --version | head -1
    g++ --version | head -1
    echo '=== Qt 版本 ==='
    find /opt/Qt -name 'Qt6StateMachine' -type d
    echo '=== 環境變數 ==='
    echo \"CC=\$CC\"
    echo \"CXX=\$CXX\"
    echo \"CFLAGS=\$CFLAGS\"
    echo \"CXXFLAGS=\$CXXFLAGS\"
    echo \"MAKEFLAGS=\$MAKEFLAGS\"
"

echo "=========================================="
echo "🚀 執行測試建置..."
echo "=========================================="

# 執行實際建置測試
docker run --rm \
    --platform linux/arm64 \
    -v "$(pwd)":/workspace \
    -v "$HOME/.cache/bazel":/root/.cache/bazel \
    -w /workspace \
    qgc-arm64-builder:latest \
    bash -c "
        echo '=== 準備建置環境 ==='
        cp BUILD.bazel.native BUILD.bazel
        
        echo '=== 嘗試下載 QGC 原始碼（測試網路）==='
        timeout 300 bazel fetch //:qgroundcontrol_cmake || {
            echo '⚠️  網路下載超時，但繼續嘗試建置...'
        }
        
        echo '=== 開始建置（限制記憶體使用）==='
        # 使用更保守的設定
        bazel build //:qgroundcontrol_cmake \\
            --verbose_failures \\
            --spawn_strategy=standalone \\
            --jobs=1 \\
            --local_ram_resources=2048 \\
            --local_cpu_resources=1 \\
            --subcommands
    "

echo "=========================================="
echo "✅ 測試完成！"
echo "=========================================="
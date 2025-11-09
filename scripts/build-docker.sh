#!/bin/bash
# build-docker.sh - 使用 Docker 進行本地 ARM64 建構測試

set -e

echo "� 設定 QEMU 支援 ARM64 模擬..."
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

echo "�🐳 建構 ARM64 QGroundControl Docker 映像..."
docker buildx build --platform linux/arm64 -f Dockerfile.arm64 -t qgc-arm64-builder .

echo "🚀 在 ARM64 容器中建構 QGroundControl..."
docker run --rm \
    --platform linux/arm64 \
    -v "$(pwd):/workspace" \
    -v "$HOME/.cache/bazel:/root/.cache/bazel" \
    -w /workspace \
    qgc-arm64-builder \
    bash -c "
        echo '📦 建構環境資訊:'
        uname -a
        bazel version
        echo
        echo '🔨 開始建構 QGroundControl...'
        # 使用簡化的原生配置
        cp BUILD.bazel BUILD.bazel
        
        
        bazel build //:qgroundcontrol_cmake
    "

echo "✅ 建構完成！檢查輸出："
ls -la bazel-bin/qgroundcontrol_cmake/ || echo "建構目錄不存在"

echo "🎯 如果建構成功，您可以在 bazel-bin/qgroundcontrol_cmake/ 找到 ARM64 版本的 QGroundControl"
#!/bin/bash

# build-docker-amd64.sh - 本機 AMD64 Docker 建置腳本
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$HOME/.cache/bazel"

echo "=========================================="
echo "🔨 建置 QGroundControl AMD64 Docker 環境"
echo "=========================================="

# 建置 Docker 映像
echo "🔧 建置 (multi-stage) Docker 映像 (含預先編譯) ..."
docker build \
    --file docker/Dockerfile.amd64 \
    --tag qgc-amd64-builder:latest \
    --progress=plain \
    . || { echo "❌ 映像建置失敗"; exit 1; }

echo "✅ Docker 映像建置完成！"

# 驗證映像
echo "🔍 驗證 build 階段環境與預置產物..."
docker run --rm --entrypoint bash qgc-amd64-builder:latest -c "
    echo '=== 系統資訊 ==='; uname -a; \
    echo '=== QGroundControl binary (若存在) ==='; ls -l /opt/qgc-dist/QGroundControl || echo 'Not found'; \
    echo '=== Plugins (subset) ==='; ls -1 /opt/qgc-dist/plugins/platforms 2>/dev/null | head || echo 'No plugins'; \
    echo '=== 預檢結束 ==='"

echo "=========================================="
echo "🚀 執行 QGroundControl 建置測試"
echo "=========================================="

# 確保快取目錄存在
mkdir -p "$CACHE_DIR"

JOBS=$(nproc || echo 4)
echo "🔧 動態並行編譯 jobs=$JOBS"

echo "🚧 進行本地源碼二次建置（可選，用於覆蓋預置 binary）..."
docker run --rm \
  -v "$PROJECT_ROOT":/workspace \
  -v "$CACHE_DIR":/root/.cache/bazel \
  -w /workspace \
  --env DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  qgc-amd64-builder:latest bash -c "
    echo '=== 使用原生建置設定 ==='; cp BUILD.bazel BUILD.bazel; \
    echo '=== 開始建置 (覆蓋) ==='; bazel build //:qgroundcontrol_cmake --jobs=$JOBS --verbose_failures || exit 1; \
    BIN=
$(echo 'FIND_BIN=$(find /root/.cache/bazel -path '*qgroundcontrol_cmake/bin/QGroundControl' -type f | head -1 || true); echo $FIND_BIN') \
    ; REAL_BIN=\"$(find /root/.cache/bazel -path '*qgroundcontrol_cmake/bin/QGroundControl' -type f | head -1 || true)\"; \
    if [ -n \"$REAL_BIN\" ]; then echo '✅ Binary:' $REAL_BIN; cp \"$REAL_BIN\" /workspace/QGroundControl_local; fi; \
    ls -l /workspace/QGroundControl_local || echo '❌ 未複製 binary'; \
  "

echo "📦 建置完成，主機上的本地複製: ./QGroundControl_local (若存在)"

echo "=========================================="
echo "✅ AMD64 建置測試完成！"
echo "=========================================="
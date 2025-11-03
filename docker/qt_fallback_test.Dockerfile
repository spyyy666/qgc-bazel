# qt_fallback_test.Dockerfile - minimal arm64 CDN fallback validation for Qt 6.10.0
# Build with: docker buildx build --platform linux/arm64 -f docker/qt_fallback_test.Dockerfile -t qt-fallback:arm64 .


# --- Stage 1: Qt module acquisition and validation ---
FROM ubuntu:24.04 AS qtbuild
ARG QT_VERSION=6.10.0
ARG QT_PATH=/opt/Qt
RUN echo "[Env] uname=$(uname -m)" && apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates p7zip-full python3-pip pipx build-essential cmake \
    libatspi2.0-dev libfontconfig1-dev libfreetype-dev libgtk-3-dev libsm-dev \
    libx11-dev libx11-xcb-dev libxcb-cursor-dev libxcb-glx0-dev libxcb-icccm4-dev \
    libxcb-image0-dev libxcb-keysyms1-dev libxcb-present-dev libxcb-randr0-dev \
    libxcb-render-util0-dev libxcb-render0-dev libxcb-shape0-dev libxcb-shm0-dev \
    libxcb-sync-dev libxcb-util-dev libxcb-xfixes0-dev libxcb-xinerama0-dev \
    libxcb-xkb-dev libxcb1-dev libxext-dev libxfixes-dev libxi-dev libxkbcommon-dev \
    libxkbcommon-x11-dev libxrender-dev libunwind-dev \
    && rm -rf /var/lib/apt/lists/*
ENV PATH="/root/.local/bin:${PATH}"
RUN echo "[AQT] Install pipx/aqtinstall" && pipx ensurepath && pipx install aqtinstall
RUN echo "[AQT] List available Qt versions for linux_arm64:" && aqt list-qt linux desktop --arch linux_arm64 || echo "[AQT][FAIL] list-qt"
RUN echo "[AQT] Try install-qt linux_arm64 6.10.0 (qtbase qtdeclarative):" && aqt install-qt linux desktop 6.10.0 linux_arm64 -O /opt/Qt/aqt-arm64-6100 -m qtbase qtdeclarative || echo "[AQT][FAIL] install-qt"
RUN echo "[Test] CDN fallback only (Qt ${QT_VERSION})" && \
    QT_CDN_BASE="https://download.qt.io/online/qtsdkrepository/linux_arm64/desktop/qt6_6100/qt6_6100/" && \
    QT_CORE_MODULES="qtbase qtdeclarative" && \
    QT_ADDON_MODULES="qtcharts qtlocation qtpositioning qtspeech qt5compat qtmultimedia qtserialport qtimageformats qtshadertools qtconnectivity qtquick3d qtsensors" && \
    QT_ALL_MODULES="${QT_CORE_MODULES} ${QT_ADDON_MODULES}" && \
    mkdir -p ${QT_PATH}/${QT_VERSION}/arm64 && cd ${QT_PATH}/${QT_VERSION}/arm64 && \
    echo "[CDN][Index] Fetch base directory listing" && \
    if command -v curl >/dev/null 2>&1; then LISTING=$(curl -fsSL "$QT_CDN_BASE" || true); else LISTING=$(wget -q -O - "$QT_CDN_BASE" || true); fi && \
    echo "[CDN][Index][Len] $(echo "$LISTING" | wc -c) bytes" && \
    if [ -z "$LISTING" ]; then echo "[CDN][Index][EMPTY] Listing fetch failed"; fi && \
    echo "$LISTING" | head -100 | sed 's/^/[CDN][Dir] /' && \
    SUMMARY_FILE="/tmp/qt_arm64_summary.txt" && echo "Module Status ComponentDir" > $SUMMARY_FILE && \
    CORE_DIR="qt.qt6.6100.linux_gcc_arm64/" && CORE_URL="${QT_CDN_BASE}${CORE_DIR}" && \
    if command -v curl >/dev/null 2>&1; then CORE_LIST=$(curl -fsSL "$CORE_URL" || true); else CORE_LIST=$(wget -q -O - "$CORE_URL" || true); fi && \
    echo "[CDN][CoreDir] $CORE_DIR size=$(echo "$CORE_LIST" | wc -c)" && echo "$CORE_LIST" | head -50 | sed 's/^/[CDN][Core] /' && \
    for MOD in $QT_CORE_MODULES; do \
        ARCHIVE_NAME=$(echo "$CORE_LIST" | grep -oE "[0-9.\-]+${MOD}-Linux-[A-Za-z0-9_\.\-]*AARCH64\.7z" | head -1); \
        if [ -z "$ARCHIVE_NAME" ]; then echo "[CDN][MISS][CoreArchive] $MOD"; echo "$MOD PENDING $CORE_DIR" >> $SUMMARY_FILE; continue; fi; \
        echo "[CDN][CoreArchive] $MOD -> $ARCHIVE_NAME"; \
        if wget -q "${CORE_URL}${ARCHIVE_NAME}" -O "$ARCHIVE_NAME"; then \
            SHA1_NAME="${ARCHIVE_NAME}.sha1"; \
            if echo "$CORE_LIST" | grep -q "$SHA1_NAME"; then wget -q "${CORE_URL}${SHA1_NAME}" -O "$SHA1_NAME" && sha1sum -c "$SHA1_NAME" >/dev/null 2>&1 && echo "[CDN][SHA1][OK] $MOD" || echo "[CDN][SHA1][FAIL] $MOD"; else echo "[CDN][SHA1][MISS] $MOD"; fi; \
            EXTRACT_DIR="extract_$MOD"; mkdir -p "$EXTRACT_DIR"; 7z x "$ARCHIVE_NAME" -o"$EXTRACT_DIR" >/dev/null 2>&1 && cp -a "$EXTRACT_DIR"/. . && echo "$MOD PUBLISHED $CORE_DIR" >> $SUMMARY_FILE || { echo "[CDN][Extract][FAIL] $MOD"; echo "$MOD ARCHIVE_EXTRACT_FAIL $CORE_DIR" >> $SUMMARY_FILE; }; \
            rm -rf "$ARCHIVE_NAME" "$SHA1_NAME" "$EXTRACT_DIR"; \
        else echo "[CDN][DownloadFail][Core] $MOD"; echo "$MOD ARCHIVE_DOWNLOAD_FAIL $CORE_DIR" >> $SUMMARY_FILE; fi; \
    done && \
    for MOD in $QT_ADDON_MODULES; do \
        COMP_DIR=$(echo "$LISTING" | grep -E "qt\\.qt6\\.6100\\..*$MOD.*linux_gcc_arm64/" | sed -E 's/.*href=\"([^\"]+)\".*/\1/' | head -1); \
        if [ -z "$COMP_DIR" ]; then echo "[CDN][MISS][Dir] $MOD"; echo "$MOD PENDING -" >> $SUMMARY_FILE; continue; fi; \
        COMP_URL="${QT_CDN_BASE}${COMP_DIR}"; \
        if command -v curl >/dev/null 2>&1; then SUBLIST=$(curl -fsSL "$COMP_URL" || true); else SUBLIST=$(wget -q -O - "$COMP_URL" || true); fi; \
        ARCHIVE_NAME=$(echo "$SUBLIST" | grep -oE "[0-9.\-]+${MOD}-Linux-[A-Za-z0-9_\.\-]*AARCH64\.7z" | head -1); \
        if [ -z "$ARCHIVE_NAME" ]; then echo "[CDN][MISS][Archive] $MOD"; echo "$MOD PENDING $COMP_DIR" >> $SUMMARY_FILE; continue; fi; \
        echo "[CDN][AddonArchive] $MOD -> $ARCHIVE_NAME"; \
        if wget -q "${COMP_URL}${ARCHIVE_NAME}" -O "$ARCHIVE_NAME"; then \
            SHA1_NAME="${ARCHIVE_NAME}.sha1"; \
            if echo "$SUBLIST" | grep -q "$SHA1_NAME"; then wget -q "${COMP_URL}${SHA1_NAME}" -O "$SHA1_NAME" && sha1sum -c "$SHA1_NAME" >/dev/null 2>&1 && echo "[CDN][SHA1][OK] $MOD" || echo "[CDN][SHA1][FAIL] $MOD"; else echo "[CDN][SHA1][MISS] $MOD"; fi; \
            EXTRACT_DIR="extract_$MOD"; mkdir -p "$EXTRACT_DIR"; 7z x "$ARCHIVE_NAME" -o"$EXTRACT_DIR" >/dev/null 2>&1 && cp -a "$EXTRACT_DIR"/. . && echo "$MOD PUBLISHED $COMP_DIR" >> $SUMMARY_FILE || { echo "[CDN][Extract][FAIL] $MOD"; echo "$MOD ARCHIVE_EXTRACT_FAIL $COMP_DIR" >> $SUMMARY_FILE; }; \
            rm -rf "$ARCHIVE_NAME" "$SHA1_NAME" "$EXTRACT_DIR"; \
        else echo "[CDN][DownloadFail][Archive] $MOD"; echo "$MOD ARCHIVE_DOWNLOAD_FAIL $COMP_DIR" >> $SUMMARY_FILE; fi; \
    done && \
    echo "[CDN][Summary]" && cat $SUMMARY_FILE && \
    echo "[Gate] Check core modules published" && \
    (grep -E '^(qtbase|qtdeclarative) ' $SUMMARY_FILE | grep -v 'PUBLISHED' && echo "[Gate][FAIL] Core module missing" && exit 1 || echo "[Gate][OK] Core modules present") && \
    cd / && \
    ln -s ${QT_PATH}/${QT_VERSION}/arm64 /opt/Qt/current && \
    echo "[Result] List CMake configs:" && find /opt/Qt/current -maxdepth 3 -name 'Qt6*Config.cmake' | sed 's#.*/Qt6\\(.*\\)Config.cmake#\\1#' | sort

# Build and install ICU 73.1 from source if not present
RUN set -e; \
    if ! ldconfig -p 2>/dev/null | grep -q 'libicui18n.so.73'; then \
        echo "[ICU][Source] Building ICU 73.1 from source"; \
        apt-get update && apt-get install -y --no-install-recommends wget build-essential; \
        cd /tmp; \
        wget -q https://github.com/unicode-org/icu/releases/download/release-73-1/icu4c-73_1-src.tgz; \
        tar xf icu4c-73_1-src.tgz; \
        cd icu/source; \
        ./configure --prefix=/usr/local >/dev/null 2>&1; \
        make -j$(nproc) >/dev/null 2>&1; \
        make install >/dev/null 2>&1; \
        export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH; \
        ldconfig; \
        cd / && rm -rf /tmp/icu /tmp/icu4c-73_1-src.tgz; \
        if ! ldconfig -p 2>/dev/null | grep -q 'libicui18n.so.73'; then echo "[ICU][Source][FAIL] Still missing libicui18n.so.73"; exit 1; fi; \
    else echo "[ICU][Source] Not needed (already present)"; fi
ENV LD_LIBRARY_PATH="/usr/local/lib:/usr/lib/aarch64-linux-gnu:${LD_LIBRARY_PATH}"
RUN /opt/Qt/current/bin/qmake6 -version || { echo '[ICU][FAIL] qmake6 still not runnable'; exit 1; }

# --- Stage 2: Minimal runtime image ---
FROM ubuntu:24.04 AS qtruntime
ARG QT_VERSION=6.10.0
ARG QT_PATH=/opt/Qt
RUN apt-get update && apt-get install -y --no-install-recommends \
    libfontconfig1 libfreetype6 libgtk-3-0 libsm6 libx11-6 libx11-xcb1 libxcb-cursor0 libxcb-glx0 libxcb-icccm4 \
    libxcb-image0 libxcb-keysyms1 libxcb-present0 libxcb-randr0 libxcb-render-util0 libxcb-render0 libxcb-shape0 \
    libxcb-shm0 libxcb-sync1 libxcb-util1 libxcb-xfixes0 libxcb-xinerama0 libxcb-xkb1 libxcb1 libxext6 libxfixes3 \
    libxi6 libxkbcommon0 libxkbcommon-x11-0 libxrender1 libunwind8 libatspi2.0-0 \
    && rm -rf /var/lib/apt/lists/*
ENV LD_LIBRARY_PATH="/usr/local/lib:/usr/lib/aarch64-linux-gnu:${LD_LIBRARY_PATH}"
COPY --from=qtbuild /opt/Qt/current /opt/Qt/current
COPY --from=qtbuild /usr/local/lib/libicu* /usr/local/lib/
RUN /opt/Qt/current/bin/qmake6 -version || { echo '[ICU][FAIL] qmake6 still not runnable'; exit 1; }
CMD ["bash", "-c", "echo '[Run] Inspect tree'; ls -1 /opt/Qt/current/lib/cmake | head -50"]

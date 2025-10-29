# GitHub CLI 多帳號管理系統

## 🎯 目標
解決 GitHub CLI 多帳號切換問題，讓你可以在 `PoyuanShih-ASUS` 和 `spyyy666` 之間輕鬆切換。

## 📁 文件結構
```
~/.config/gh-profiles/
├── spyyy666/          # spyyy666 帳號的配置
│   └── hosts.yml      # GitHub 認證資訊
├── PoyuanShih-ASUS/   # PoyuanShih-ASUS 帳號的配置
│   └── hosts.yml      # GitHub 認證資訊
```

## 🚀 快速開始

### 1. 設定 spyyy666 帳號
```bash
./setup-spyyy666.sh
```
這個腳本會：
- 清除當前的 GH_TOKEN 環境變數
- 引導你登入 spyyy666 帳號
- 設定獨立的配置目錄

### 2. 使用帳號管理工具
```bash
# 列出所有帳號
./gh-switch.sh list

# 切換到 spyyy666
./gh-switch.sh switch spyyy666

# 切換到 PoyuanShih-ASUS
./gh-switch.sh switch PoyuanShih-ASUS

# 查看當前帳號
./gh-switch.sh current

# 查看認證狀態
./gh-switch.sh status
```

## 📋 完整使用流程

### 步驟 1: 設定 spyyy666 帳號
```bash
cd /home/poyuan_shih/ProjectPool/qgc-bazel-build
./setup-spyyy666.sh
```

### 步驟 2: 測試 workflow
```bash
# 切換到 spyyy666 帳號
./gh-switch.sh switch spyyy666

# 查看 workflow runs
gh run list --repo spyyy666/qgc-bazel

# 手動觸發 workflow
gh workflow run "Build QGroundControl for arm64 (Original Method)" --repo spyyy666/qgc-bazel

# 監控 workflow 執行
gh run watch --repo spyyy666/qgc-bazel
```

### 步驟 3: 後續切換
```bash
# 當需要使用個人帳號時
./gh-switch.sh switch PoyuanShih-ASUS

# 當需要操作 qgc-bazel 專案時
./gh-switch.sh switch spyyy666
```

## 🔧 自動環境載入 (可選)

如果你希望在每次開啟終端時自動載入正確的帳號配置：

```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
echo 'source /home/poyuan_shih/ProjectPool/qgc-bazel-build/gh-env.sh' >> ~/.bashrc

# 重新載入 shell 配置
source ~/.bashrc
```

這樣你就可以使用別名：
```bash
gh-switch spyyy666      # 切換帳號
gh-list                 # 列出帳號
gh-current              # 查看當前帳號
gh-status               # 查看狀態
```

## 🧪 驗證設定

設定完成後，你可以驗證：

```bash
# 切換到 spyyy666
./gh-switch.sh switch spyyy666

# 確認身份
gh auth status

# 應該顯示 spyyy666 帳號資訊
```

## 🎯 下一步：測試原始 workflow

一旦 spyyy666 帳號設定完成，你就可以：

1. 在命令列監控 workflow
2. 手動觸發測試
3. 查看詳細的錯誤日誌
4. 比較 Docker 方法和原生 ARM64 方法的差異

這樣你就能完全在命令列中管理和測試你的 GitHub Actions workflow 了！
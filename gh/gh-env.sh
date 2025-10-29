#!/bin/bash
# gh-env.sh - GitHub CLI 環境載入腳本
# 在 .bashrc 或 .zshrc 中 source 這個檔案來自動載入環境

PROFILES_DIR="$HOME/.config/gh-profiles"
CURRENT_PROFILE_FILE="$HOME/.config/gh-current-profile"

# 自動載入當前選擇的帳號配置
if [ -f "$CURRENT_PROFILE_FILE" ]; then
    current_account=$(cat "$CURRENT_PROFILE_FILE")
    if [ "$current_account" != "none" ] && [ -d "$PROFILES_DIR/$current_account" ]; then
        export GH_CONFIG_DIR="$PROFILES_DIR/$current_account"
        # 可選：顯示當前帳號
        # echo "GitHub CLI: 使用帳號 $current_account"
    fi
fi

# 建立別名讓切換更容易
alias gh-switch='source /home/poyuan_shih/ProjectPool/qgc-bazel-build/gh-switch.sh switch'
alias gh-list='bash /home/poyuan_shih/ProjectPool/qgc-bazel-build/gh-switch.sh list'
alias gh-current='bash /home/poyuan_shih/ProjectPool/qgc-bazel-build/gh-switch.sh current'
alias gh-status='bash /home/poyuan_shih/ProjectPool/qgc-bazel-build/gh-switch.sh status'
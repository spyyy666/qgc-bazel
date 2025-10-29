#!/bin/bash
# gh-switch.sh - GitHub CLI 帳號切換工具

PROFILES_DIR="$HOME/.config/gh-profiles"
CURRENT_PROFILE_FILE="$HOME/.config/gh-current-profile"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_usage() {
    echo -e "${BLUE}GitHub CLI 多帳號管理工具${NC}"
    echo "使用方法: $0 [指令] [帳號名稱]"
    echo ""
    echo "指令:"
    echo "  list                     - 列出所有可用的帳號配置"
    echo "  switch <account>         - 切換到指定帳號"
    echo "  current                  - 顯示當前使用的帳號"
    echo "  setup <account>          - 設定新的帳號配置"
    echo "  status                   - 顯示當前帳號的認證狀態"
    echo ""
    echo "範例:"
    echo "  $0 list"
    echo "  $0 switch spyyy666"
    echo "  $0 setup myaccount"
}

list_accounts() {
    echo -e "${BLUE}可用的 GitHub 帳號配置:${NC}"
    if [ -d "$PROFILES_DIR" ]; then
        for profile in "$PROFILES_DIR"/*; do
            if [ -d "$profile" ]; then
                account=$(basename "$profile")
                if [ -f "$profile/hosts.yml" ]; then
                    echo -e "  ${GREEN}✓${NC} $account (已配置)"
                else
                    echo -e "  ${YELLOW}○${NC} $account (未配置)"
                fi
            fi
        done
    else
        echo -e "  ${RED}沒有找到帳號配置${NC}"
    fi
}

get_current_account() {
    if [ -f "$CURRENT_PROFILE_FILE" ]; then
        cat "$CURRENT_PROFILE_FILE"
    else
        echo "none"
    fi
}

switch_account() {
    local account="$1"
    local profile_dir="$PROFILES_DIR/$account"
    
    if [ ! -d "$profile_dir" ]; then
        echo -e "${RED}錯誤: 帳號配置 '$account' 不存在${NC}"
        echo "使用 '$0 setup $account' 來創建新配置"
        return 1
    fi
    
    # 設定 GH_CONFIG_DIR 環境變數
    export GH_CONFIG_DIR="$profile_dir"
    echo "$account" > "$CURRENT_PROFILE_FILE"
    
    echo -e "${GREEN}已切換到帳號: $account${NC}"
    echo "配置目錄: $profile_dir"
    
    # 檢查是否已登入
    if [ -f "$profile_dir/hosts.yml" ]; then
        echo -e "${GREEN}帳號已登入${NC}"
        gh auth status 2>/dev/null || echo -e "${YELLOW}警告: 無法檢查認證狀態${NC}"
    else
        echo -e "${YELLOW}帳號尚未登入，請執行: gh auth login${NC}"
    fi
}

setup_account() {
    local account="$1"
    local profile_dir="$PROFILES_DIR/$account"
    
    mkdir -p "$profile_dir"
    echo -e "${BLUE}設定帳號: $account${NC}"
    echo "配置目錄: $profile_dir"
    
    # 切換到新配置並登入
    export GH_CONFIG_DIR="$profile_dir"
    echo "$account" > "$CURRENT_PROFILE_FILE"
    
    echo -e "${YELLOW}開始登入流程...${NC}"
    gh auth login
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}帳號 '$account' 設定完成！${NC}"
    else
        echo -e "${RED}帳號設定失敗${NC}"
    fi
}

show_current() {
    local current=$(get_current_account)
    if [ "$current" = "none" ]; then
        echo -e "${YELLOW}目前沒有選擇任何帳號配置${NC}"
    else
        echo -e "${GREEN}當前帳號: $current${NC}"
        if [ -n "$GH_CONFIG_DIR" ]; then
            echo "配置目錄: $GH_CONFIG_DIR"
        fi
    fi
}

show_status() {
    local current=$(get_current_account)
    if [ "$current" = "none" ]; then
        echo -e "${YELLOW}目前沒有選擇任何帳號配置${NC}"
        return 1
    fi
    
    echo -e "${BLUE}帳號狀態: $current${NC}"
    export GH_CONFIG_DIR="$PROFILES_DIR/$current"
    gh auth status
}

# 主程式邏輯
case "$1" in
    "list")
        list_accounts
        ;;
    "switch")
        if [ -z "$2" ]; then
            echo -e "${RED}錯誤: 請指定帳號名稱${NC}"
            show_usage
            exit 1
        fi
        switch_account "$2"
        ;;
    "current")
        show_current
        ;;
    "setup")
        if [ -z "$2" ]; then
            echo -e "${RED}錯誤: 請指定帳號名稱${NC}"
            show_usage
            exit 1
        fi
        setup_account "$2"
        ;;
    "status")
        show_status
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
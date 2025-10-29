#!/bin/bash
# gh-switch-env.sh - 環境變數設置腳本 (需要用 source 執行)

PROFILES_DIR="$HOME/.config/gh-profiles"
CURRENT_PROFILE_FILE="$HOME/.config/gh-current-profile"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

gh-switch() {
    local account="$1"
    
    if [ -z "$account" ]; then
        echo -e "${RED}請指定帳號名稱${NC}"
        echo "使用方法: gh-switch <account>"
        echo "可用帳號: spyyy666, PoyuanShih-ASUS"
        return 1
    fi
    
    local profile_dir="$PROFILES_DIR/$account"
    
    if [ ! -d "$profile_dir" ]; then
        echo -e "${RED}錯誤: 帳號配置 '$account' 不存在${NC}"
        return 1
    fi
    
    # 設定環境變數 (這次會在當前 shell 中生效)
    export GH_CONFIG_DIR="$profile_dir"
    echo "$account" > "$CURRENT_PROFILE_FILE"
    
    echo -e "${GREEN}已切換到帳號: $account${NC}"
    echo "配置目錄: $profile_dir"
    
    # 驗證切換是否成功
    echo -e "${BLUE}驗證認證狀態:${NC}"
    gh auth status 2>/dev/null
}

gh-current() {
    if [ -f "$CURRENT_PROFILE_FILE" ]; then
        local current=$(cat "$CURRENT_PROFILE_FILE")
        echo -e "${GREEN}當前帳號: $current${NC}"
        echo "配置目錄: $GH_CONFIG_DIR"
        echo "實際 gh 認證:"
        gh auth status 2>/dev/null
    else
        echo -e "${YELLOW}目前沒有選擇任何帳號配置${NC}"
    fi
}

gh-list() {
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

# 如果腳本被直接執行而不是 source，顯示使用說明
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    echo -e "${YELLOW}請使用 source 來載入這個腳本:${NC}"
    echo "source $0"
    echo ""
    echo "然後你就可以使用:"
    echo "  gh-switch spyyy666"
    echo "  gh-switch PoyuanShih-ASUS"
    echo "  gh-current"
    echo "  gh-list"
fi
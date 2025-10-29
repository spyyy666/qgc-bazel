#!/bin/bash
# setup-spyyy666.sh - 設定 spyyy666 帳號的專用腳本

echo "🔧 設定 spyyy666 帳號"
echo "===================="
echo ""

# 步驟 1: 清除環境變數
echo "步驟 1: 清除當前的 GH_TOKEN 環境變數"
unset GH_TOKEN

# 步驟 2: 設定配置目錄
PROFILE_DIR="$HOME/.config/gh-profiles/spyyy666"
export GH_CONFIG_DIR="$PROFILE_DIR"
echo "配置目錄: $PROFILE_DIR"

# 步驟 3: 開始登入流程
echo ""
echo "步驟 2: 開始 GitHub 登入流程"
echo "請在接下來的對話中："
echo "  - 選擇 GitHub.com"
echo "  - 選擇 HTTPS"
echo "  - 選擇 Login with a web browser"
echo "  - 在瀏覽器中使用 spyyy666 帳號登入"
echo ""
read -p "按 Enter 繼續..."

gh auth login

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ spyyy666 帳號設定成功！"
    echo ""
    echo "記錄當前帳號:"
    echo "spyyy666" > "$HOME/.config/gh-current-profile"
    
    echo "驗證登入狀態:"
    gh auth status
    
    echo ""
    echo "🎉 現在你可以使用以下指令:"
    echo "  ./gh-switch.sh switch spyyy666    # 切換到 spyyy666"
    echo "  ./gh-switch.sh switch PoyuanShih-ASUS  # 切換到 PoyuanShih-ASUS"
    echo "  ./gh-switch.sh current            # 查看當前帳號"
    echo "  ./gh-switch.sh status             # 查看認證狀態"
else
    echo ""
    echo "❌ 帳號設定失敗，請檢查網路連線和登入資訊"
fi
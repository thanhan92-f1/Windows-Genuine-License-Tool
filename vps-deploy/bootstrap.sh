#!/bin/bash
# ============================================================
#  BOOTSTRAP - Tai va chay setup.sh truc tiep
#  Lenh: curl -sSL URL/bootstrap.sh | sudo bash
#
#  Hoac truyen cau hinh truoc:
#  INPUT_DOMAIN=your.com INPUT_PORT=80 curl -sSL URL/bootstrap.sh | sudo bash
# ============================================================

SCRIPT_URL="https://raw.githubusercontent.com/thanhan92-f1/Windows-Genuine-License-Tool/main/vps-deploy/setup.sh"
TMP_SCRIPT="/tmp/pho-tue-setup-$(date +%s).sh"

echo ""
echo "  Dang tai script setup..."
curl -sSL "$SCRIPT_URL" -o "$TMP_SCRIPT"
chmod +x "$TMP_SCRIPT"

echo "  Dang chay setup..."
echo ""

# Chay script voi stdin tu terminal
bash "$TMP_SCRIPT" < /dev/tty

# Xoa file tam
rm -f "$TMP_SCRIPT"

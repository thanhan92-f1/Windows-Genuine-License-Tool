#!/bin/bash
# ============================================================
#  BOOTSTRAP - Tai va chay setup.sh truc tiep
#  Lenh: curl -sSL URL/bootstrap.sh | sudo bash
# ============================================================

SCRIPT_URL="https://raw.githubusercontent.com/thanhan92-f1/Windows-Genuine-License-Tool/main/vps-deploy/setup.sh"
TMP_SCRIPT="/tmp/pho-tue-setup.sh"

echo ""
echo "  Dang tai script setup..."
curl -sSL "$SCRIPT_URL" -o "$TMP_SCRIPT"
chmod +x "$TMP_SCRIPT"

echo "  Dang chay setup..."
echo ""
bash "$TMP_SCRIPT"

# Xoa file tam sau khi chay
rm -f "$TMP_SCRIPT"

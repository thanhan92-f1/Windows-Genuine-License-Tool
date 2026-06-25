#!/bin/bash
# ============================================================
#  VPS SETUP SCRIPT - Pho Tue SoftWare Solutions JSC
#  Chay 1 lenh duy nhat tren VPS Linux:
#  curl -sSL https://raw.githubusercontent.com/thanhan92-f1/Windows-Genuine-License-Tool/main/vps-deploy/setup.sh | sudo bash
# ============================================================

set -e

# Mau sac
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PORT="${PORT:-8888}"
INSTALL_DIR="/opt/pho-tue-scripts"
REPO_RAW="https://raw.githubusercontent.com/thanhan92-f1/Windows-Genuine-License-Tool/main"
DOMAIN="irm-genuine-license-windows.hitechcloud.vn"

echo ""
echo -e "  ${CYAN}============================================================${NC}"
echo -e "  ${GREEN}VPS SETUP - Pho Tue SoftWare Solutions JSC${NC}"
echo -e "  ${CYAN}============================================================${NC}"
echo ""

# Kiem tra root
if [ "$EUID" -ne 0 ]; then
    echo -e "  ${RED}[LOI] Can chay voi quyen root: sudo bash setup.sh${NC}"
    exit 1
fi

# Buoc 1: Cai dat dependencies
echo -e "  ${YELLOW}[1/5] Kiem tra Python...${NC}"
if ! command -v python3 &> /dev/null; then
    echo "        Dang cai dat Python3..."
    if command -v apt-get &> /dev/null; then
        apt-get update -qq && apt-get install -y -qq python3 curl wget
    elif command -v yum &> /dev/null; then
        yum install -y python3 curl wget
    elif command -v dnf &> /dev/null; then
        dnf install -y python3 curl wget
    else
        echo -e "        ${RED}[!] Khong the cai Python3. Hay cai thu cong.${NC}"
        exit 1
    fi
fi
echo -e "        ${GREEN}[OK] Python3: $(python3 --version)${NC}"

# Buoc 2: Tao thu muc & download scripts
echo -e "  ${YELLOW}[2/5] Tao thu muc cai dat...${NC}"
mkdir -p "$INSTALL_DIR/scripts"

echo -e "  ${YELLOW}[3/5] Download scripts tu GitHub...${NC}"

# Download server.py
curl -sSL "$REPO_RAW/vps-deploy/server.py" -o "$INSTALL_DIR/server.py"
echo -e "        ${GREEN}[OK] Da tai: server.py${NC}"

# Download Windows_License_Cleanup.ps1
curl -sSL "$REPO_RAW/Windows_License_Cleanup.ps1" -o "$INSTALL_DIR/scripts/Windows_License_Cleanup.ps1"
echo -e "        ${GREEN}[OK] Da tai: Windows_License_Cleanup.ps1${NC}"

# Download HUONG_DAN_SU_DUNG_IRM.txt
curl -sSL "$REPO_RAW/HUONG_DAN_SU_DUNG_IRM.txt" -o "$INSTALL_DIR/HUONG_DAN_SU_DUNG_IRM.txt" 2>/dev/null || true

# Buoc 4: Mo firewall
echo -e "  ${YELLOW}[4/5] Cau hinh firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow $PORT/tcp 2>/dev/null && echo -e "        ${GREEN}[OK] UFW: da mo port $PORT${NC}" || true
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=$PORT/tcp 2>/dev/null
    firewall-cmd --reload 2>/dev/null
    echo -e "        ${GREEN}[OK] firewalld: da mo port $PORT${NC}"
else
    echo -e "        ${YELLOW}[!] Khong tim thay firewall. Hay tu mo port $PORT neu can.${NC}"
fi

# Buoc 5: Tao systemd service
echo -e "  ${YELLOW}[5/5] Tao systemd service...${NC}"

cat > /etc/systemd/system/pho-tue-scripts.service << EOF
[Unit]
Description=Pho Tue Script Server - Windows License Cleanup
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/python3 $INSTALL_DIR/server.py
Restart=always
RestartSec=5
Environment=PORT=$PORT
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable pho-tue-scripts.service
systemctl start pho-tue-scripts.service

echo -e "        ${GREEN}[OK] Service da duoc tao va khoi dong${NC}"

# Lay IP public
PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "YOUR-VPS-IP")

# Hoan tat
echo ""
echo -e "  ${GREEN}============================================================${NC}"
echo -e "  ${GREEN}CAI DAT THANH CONG!${NC}"
echo -e "  ${GREEN}============================================================${NC}"
echo ""
echo -e "  Server dang chay tren port: ${CYAN}$PORT${NC}"
echo ""
echo -e "  Client su dung lenh:"
echo ""
echo -e "  ${GREEN}  irm https://$DOMAIN | iex${NC}"
echo ""
echo -e "  (hoac: ${CYAN}irm http://$PUBLIC_IP:$PORT | iex${NC})"
echo ""
echo -e "  ${YELLOW}Quan ly service:${NC}"
echo -e "    systemctl status pho-tue-scripts    # Xem trang thai"
echo -e "    systemctl restart pho-tue-scripts    # Khoi dong lai"
echo -e "    systemctl stop pho-tue-scripts       # Dung service"
echo -e "    journalctl -u pho-tue-scripts -f     # Xem log"
echo ""
echo -e "  Thu muc cai dat: ${CYAN}$INSTALL_DIR${NC}"
echo ""
echo -e "  ${GREEN}============================================================${NC}"
echo ""

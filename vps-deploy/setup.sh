#!/bin/bash
# ============================================================
#  VPS SETUP SCRIPT - Pho Tue SoftWare Solutions JSC
#  Chay 1 lenh duy nhat tren VPS Linux:
#  curl -sSL https://raw.githubusercontent.com/thanhan92-f1/Windows-Genuine-License-Tool/main/vps-deploy/bootstrap.sh | sudo bash
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
SERVICE_NAME="pho-tue-scripts"

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

# ============================================================
#  BUOC 0: CAU HINH HE THONG
# ============================================================
echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "  ${CYAN}║${NC}  ${YELLOW}BUOC 0: CAU HINH HE THONG${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Nhan Enter de su dung gia tri mac dinh (dang trong ngoac).${NC}"
echo ""

# Nhap domain
read -p "  Domain [${DOMAIN}]: " input_domain < /dev/tty
DOMAIN="${input_domain:-$DOMAIN}"

# Nhap port
read -p "  Port phuc vu [${PORT}]: " input_port < /dev/tty
PORT="${input_port:-$PORT}"

# Nhap thu muc cai dat
read -p "  Thu muc cai dat [${INSTALL_DIR}]: " input_dir < /dev/tty
INSTALL_DIR="${input_dir:-$INSTALL_DIR}"

echo ""
echo -e "  ${CYAN}── Cau hinh cua ban ──────────────────────────────────────${NC}"
echo -e "  Domain:      ${GREEN}$DOMAIN${NC}"
echo -e "  Port:        ${GREEN}$PORT${NC}"
echo -e "  Thu muc:     ${GREEN}$INSTALL_DIR${NC}"
echo -e "  ${CYAN}────────────────────────────────────────────────────────────${NC}"
echo ""

read -p "  Xac nhan cau hinh? [Y/n]: " confirm < /dev/tty
confirm="${confirm:-y}"
if [[ ! "$confirm" =~ ^[Yy] ]]; then
    echo -e "  ${RED}Da huy. Chay lai script de cau hinh lai.${NC}"
    exit 0
fi

# Cap nhat DOMAIN vao server.py sau khi download
# (se lam o buoc download scripts)

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

# Download index.html (trang docs cho browser)
mkdir -p "$INSTALL_DIR/templates"
curl -sSL "$REPO_RAW/vps-deploy/templates/index.html" -o "$INSTALL_DIR/templates/index.html"
echo -e "        ${GREEN}[OK] Da tai: index.html${NC}"

# Cap nhat DOMAIN trong server.py va index.html
echo -e "  ${YELLOW}  Cap nhat domain: $DOMAIN${NC}"
sed -i "s|irm-genuine-license-windows.hitechcloud.vn|$DOMAIN|g" "$INSTALL_DIR/server.py" 2>/dev/null
sed -i "s|irm-genuine-license-windows.hitechcloud.vn|$DOMAIN|g" "$INSTALL_DIR/templates/index.html" 2>/dev/null
sed -i "s|irm-genuine-license-windows.hitechcloud.vn|$DOMAIN|g" "$INSTALL_DIR/scripts/Windows_License_Cleanup.ps1" 2>/dev/null
echo -e "        ${GREEN}[OK] Da cap nhat domain trong tat ca scripts${NC}"

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

cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
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
Environment=DOMAIN=$DOMAIN
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable pho-tue-scripts.service
systemctl start pho-tue-scripts.service

echo -e "        ${GREEN}[OK] Service da duoc tao va khoi dong${NC}"

# Kiem tra service
sleep 2
if systemctl is-active --quiet ${SERVICE_NAME}.service; then
    echo -e "        ${GREEN}[OK] Service dang chay binh thuong${NC}"
else
    echo -e "        ${YELLOW}[!] Service co the chua khoi dong. Kiem tra: journalctl -u ${SERVICE_NAME} -n 20${NC}"
fi

# ============================================================
#  BUOC 6: NGINX + SSL (TUY CHON)
# ============================================================
echo ""
echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "  ${CYAN}║${NC}  ${YELLOW}BUOC 6: NGINX + SSL (TUY CHON)${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Nginx se reverse proxy HTTPS -> localhost:${PORT}${NC}"
echo -e "  Giup client su dung: ${GREEN}irm https://$DOMAIN | iex${NC}"
echo ""

INSTALL_NGINX="n"
NGINX_EXISTS="n"

# Kiem tra Nginx da co chua
if command -v nginx &> /dev/null; then
    NGINX_EXISTS="y"
    echo -e "  ${GREEN}[OK] Nginx da co san: $(nginx -v 2>&1)${NC}"
    echo ""
    read -p "  Ban van muon cau hinh Nginx reverse proxy? [Y/n]: " nginx_choice < /dev/tty
    nginx_choice="${nginx_choice:-y}"
    if [[ "$nginx_choice" =~ ^[Yy] ]]; then
        INSTALL_NGINX="y"
    fi
else
    read -p "  Ban co muon cai dat Nginx + SSL? [Y/n]: " nginx_choice < /dev/tty
    nginx_choice="${nginx_choice:-y}"
    if [[ "$nginx_choice" =~ ^[Yy] ]]; then
        INSTALL_NGINX="y"
    fi
fi

if [ "$INSTALL_NGINX" = "y" ]; then
    echo ""

    # Cai dat Nginx neu chua co
    if [ "$NGINX_EXISTS" = "n" ]; then
        echo -e "  ${YELLOW}[6a] Cai dat Nginx...${NC}"
        if command -v apt-get &> /dev/null; then
            apt-get install -y -qq nginx > /dev/null 2>&1
        elif command -v yum &> /dev/null; then
            yum install -y nginx > /dev/null 2>&1
        elif command -v dnf &> /dev/null; then
            dnf install -y nginx > /dev/null 2>&1
        fi
        echo -e "        ${GREEN}[OK] Nginx da duoc cai dat${NC}"
    else
        echo -e "  ${GREEN}[6a] Nginx da co san - bo qua cai dat${NC}"
    fi

    # Cau hinh Nginx reverse proxy
    echo -e "  ${YELLOW}[6b] Cau hinh Nginx reverse proxy...${NC}"

    NGINX_CONF="/etc/nginx/sites-available/${SERVICE_NAME}"
    NGINX_ENABLED="/etc/nginx/sites-enabled/${SERVICE_NAME}"

    # Backup cau hinh cu neu co
    if [ -f "$NGINX_CONF" ]; then
        cp "$NGINX_CONF" "${NGINX_CONF}.bak.$(date +%Y%m%d%H%M%S)"
        echo -e "        ${CYAN}[i] Da backup cau hinh cu${NC}"
    fi

    # Tao cau hinh HTTP (de certbot xac thuc)
    cat > "$NGINX_CONF" << EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Khong cache scripts
        proxy_no_cache 1;
        proxy_cache_bypass 1;
    }

    # Security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
}
EOF

    # Kich active config
    if [ -d "/etc/nginx/sites-enabled" ]; then
        ln -sf "$NGINX_CONF" "$NGINX_ENABLED"
        rm -f /etc/nginx/sites-enabled/default 2>/dev/null
    elif [ -d "/etc/nginx/conf.d" ]; then
        cp "$NGINX_CONF" "/etc/nginx/conf.d/${SERVICE_NAME}.conf"
    fi

    # Test va reload Nginx
    if nginx -t 2>/dev/null; then
        systemctl reload nginx 2>/dev/null || systemctl restart nginx 2>/dev/null
        echo -e "        ${GREEN}[OK] Nginx reverse proxy da duoc cau hinh${NC}"
    else
        echo -e "        ${RED}[!] Nginx config loi. Hay sua thu cong: $NGINX_CONF${NC}"
    fi

    # ============================================================
    #  SSL VOI LET'S ENCRYPT
    # ============================================================
    echo ""
    echo -e "  ${CYAN}── SSL Certificate ────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${YELLOW}Luu y:${NC} Domain ${GREEN}$DOMAIN${NC} phai tro den IP cua VPS nay."
    echo ""

    INSTALL_SSL="n"
    read -p "  Ban co muon cai dat SSL (Let's Encrypt)? [Y/n]: " ssl_choice < /dev/tty
    ssl_choice="${ssl_choice:-y}"
    if [[ "$ssl_choice" =~ ^[Yy] ]]; then
        INSTALL_SSL="y"
    fi

    if [ "$INSTALL_SSL" = "y" ]; then
        echo ""
        echo -e "  ${YELLOW}[6c] Cai dat SSL voi Let's Encrypt...${NC}"

        # Cai dat certbot neu chua co
        if ! command -v certbot &> /dev/null; then
            if command -v apt-get &> /dev/null; then
                apt-get install -y -qq certbot python3-certbot-nginx > /dev/null 2>&1
            elif command -v yum &> /dev/null; then
                yum install -y certbot python3-certbot-nginx > /dev/null 2>&1
            elif command -v dnf &> /dev/null; then
                dnf install -y certbot python3-certbot-nginx > /dev/null 2>&1
            fi
            echo -e "        ${GREEN}[OK] Certbot da duoc cai dat${NC}"
        else
            echo -e "        ${GREEN}[OK] Certbot da co san - bo qua cai dat${NC}"
        fi

        # Lay SSL certificate
        echo ""
        echo -e "  ${YELLOW}Dang lay SSL certificate cho $DOMAIN...${NC}"
        echo ""

        certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect

        if [ $? -eq 0 ]; then
            echo -e "        ${GREEN}[OK] SSL certificate da duoc cai dat thanh cong!${NC}"
            echo -e "        ${GREEN}[OK] HTTPS da hoat dong: https://$DOMAIN${NC}"
        else
            echo -e "        ${YELLOW}[!] Khong the lay SSL tu dong. Hay thu thu cong:${NC}"
            echo -e "            ${CYAN}certbot --nginx -d $DOMAIN${NC}"
        fi

        # Setup auto-renew
        (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'") | crontab -
        echo -e "        ${GREEN}[OK] SSL auto-renew da duoc cau hinh (3:00 AM hang ngay)${NC}"
    else
        echo -e "  ${YELLOW}[!] Bo qua SSL. Client se su dung HTTP.${NC}"
    fi
else
    echo -e "  ${YELLOW}[!] Bo qua Nginx. Client se ket noi truc tiep port $PORT.${NC}"
fi

# ============================================================
#  HOAN TAT
# ============================================================
PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "YOUR-VPS-IP")

echo ""
echo -e "  ${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "  ${GREEN}║${NC}                                                              ${GREEN}║${NC}"
echo -e "  ${GREEN}║${NC}   ${WHITE}${BOLD}CAI DAT THANH CONG!${NC}                                       ${GREEN}║${NC}"
echo -e "  ${GREEN}║${NC}                                                              ${GREEN}║${NC}"
echo -e "  ${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$INSTALL_NGINX" = "y" ] && [ "$INSTALL_SSL" = "y" ]; then
    echo -e "  ${BOLD}Client su dung lenh:${NC}"
    echo ""
    echo -e "  ${GREEN}  irm https://$DOMAIN | iex${NC}"
    echo ""
    echo -e "  HTTPS da hoat dong! Khong can chi dinh port."
else
    echo -e "  ${BOLD}Client su dung lenh:${NC}"
    echo ""
    echo -e "  ${GREEN}  irm http://${PUBLIC_IP}:${PORT} | iex${NC}"
    echo ""
    if [ "$INSTALL_NGINX" = "n" ]; then
        echo -e "  ${YELLOW}Muon su dung domain + HTTPS?${NC}"
        echo -e "  ${CYAN}  Chay lai script va chon cai Nginx + SSL.${NC}"
    fi
fi

echo ""
echo -e "  ${CYAN}── Thong tin he thong ──────────────────────────────────────${NC}"
echo -e "  Thu muc:     ${WHITE}$INSTALL_DIR${NC}"
echo -e "  Port:        ${WHITE}$PORT${NC}"
echo -e "  Domain:      ${WHITE}$DOMAIN${NC}"
echo -e "  IP Public:   ${WHITE}$PUBLIC_IP${NC}"
echo -e "  Service:     ${WHITE}$SERVICE_NAME${NC}"
echo ""
echo -e "  ${CYAN}── Quan ly service ──────────────────────────────────────────${NC}"
echo -e "  systemctl status $SERVICE_NAME       ${WHITE}# Xem trang thai${NC}"
echo -e "  systemctl restart $SERVICE_NAME      ${WHITE}# Khoi dong lai${NC}"
echo -e "  systemctl stop $SERVICE_NAME         ${WHITE}# Dung service${NC}"
echo -e "  journalctl -u $SERVICE_NAME -f       ${WHITE}# Xem log realtime${NC}"
echo ""

if [ "$INSTALL_NGINX" = "y" ]; then
    echo -e "  ${CYAN}── Quan ly Nginx ────────────────────────────────────────────${NC}"
    echo -e "  systemctl status nginx               ${WHITE}# Xem trang thai Nginx${NC}"
    echo -e "  nginx -t                             ${WHITE}# Test cau hinh${NC}"
    echo -e "  systemctl reload nginx               ${WHITE}# Reload cau hinh${NC}"
    echo ""
fi

echo -e "  ${CYAN}── Cau hinh lai ─────────────────────────────────────────────${NC}"
echo -e "  Service:    /etc/systemd/system/${SERVICE_NAME}.service"
if [ "$INSTALL_NGINX" = "y" ]; then
    echo -e "  Nginx:      /etc/nginx/sites-available/${SERVICE_NAME}"
fi
echo -e "  Scripts:    ${INSTALL_DIR}/scripts/"
echo -e "  Templates:  ${INSTALL_DIR}/templates/"
echo ""
echo -e "  ${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo ""

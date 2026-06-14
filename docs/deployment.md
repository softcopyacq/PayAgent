# PayAgent Production Deployment Guide

## Overview

This guide covers deploying PayAgent to production with:
- **Nginx** reverse proxy + SSL (Let's Encrypt)
- **Systemd** service (auto-restart)
- **Monad mainnet** smart contract
- **HTTPS-only** endpoints
- **A+ SSL rating** (HSTS, CSP)

---

## Prerequisites

- **OS:** Ubuntu 20.04 LTS or later
- **Node.js:** v20.0+
- **Domain:** Registered domain (e.g., `payagent.yourdomain.com`)
- **Firewall:** Allow ports 80 (HTTP), 443 (HTTPS)
- **Accounts:**
  - Cleanverse API key (sandbox or production)
  - Monad wallet with MON for gas

---

## Step 1: Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y \n  nodejs npm nginx certbot python3-certbot-nginx \n  git curl wget unzip build-essential

# Verify Node.js version
node --version  # Should be v20+
```

---

## Step 2: Clone & Install PayAgent

```bash
# Create app directory
sudo mkdir -p /opt/payagent
cd /opt/payagent

# Clone repository
sudo git clone https://github.com/softcopyacq/PayAgent.git .

# Install npm dependencies
sudo npm install --production

# Create .env with your configuration
sudo cp .env.example .env
sudo nano .env
# Edit with your Cleanverse API key, JWT secret, etc.
```

---

## Step 3: SSL Certificate (Let's Encrypt)

```bash
# Stop Nginx (if running)
sudo systemctl stop nginx

# Generate certificate
sudo certbot certonly --standalone \n  -d payagent.yourdomain.com \n  --email your-email@example.com \n  --agree-tos

# Verify certificate
sudo ls /etc/letsencrypt/live/payagent.yourdomain.com/
```

---

## Step 4: Nginx Reverse Proxy

```bash
# Create Nginx config
sudo tee /etc/nginx/sites-available/payagent > /dev/null <<EOF
upstream payagent_backend {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    server_name payagent.yourdomain.com;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name payagent.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/payagent.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/payagent.yourdomain.com/privkey.pem;

    # SSL Configuration (A+ rating)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # HSTS (HTTP Strict Transport Security) — 2 years
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

    # Security headers
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/payagent.access.log combined;
    error_log /var/log/nginx/payagent.error.log;

    # Reverse proxy to Node.js
    location / {
        proxy_pass http://payagent_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/payagent /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx config
sudo nginx -t

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

---

## Step 5: Systemd Service

```bash
# Create systemd service file
sudo tee /etc/systemd/system/payagent.service > /dev/null <<EOF
[Unit]
Description=PayAgent — Verified AI Agent Payments
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=payagent
WorkingDirectory=/opt/payagent
EnvironmentFile=/opt/payagent/.env
ExecStart=/usr/bin/node /opt/payagent/server.js

# Restart policy
Restart=always
RestartSec=10
StartLimitInterval=60
StartLimitBurst=3

# Security
NoNewPrivileges=true
PrivateTmp=true

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=payagent

[Install]
WantedBy=multi-user.target
EOF

# Create payagent user
sudo useradd --system --no-create-home payagent || true

# Set permissions
sudo chown -R payagent:payagent /opt/payagent
sudo chmod 750 /opt/payagent
sudo chmod 600 /opt/payagent/.env

# Reload systemd
sudo systemctl daemon-reload

# Start service
sudo systemctl start payagent
sudo systemctl enable payagent

# Check status
sudo systemctl status payagent

# View logs
sudo journalctl -u payagent -f
```

---

## Step 6: Certificate Auto-Renewal

```bash
# Create renewal hook script
sudo tee /etc/letsencrypt/renewal-hooks/post/payagent.sh > /dev/null <<EOF
#!/bin/bash
sudo systemctl reload nginx
sudo systemctl restart payagent
EOF

sudo chmod +x /etc/letsencrypt/renewal-hooks/post/payagent.sh

# Test renewal (dry-run)
sudo certbot renew --dry-run

# Enable auto-renewal cron
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

---

## Step 7: Verify Deployment

### Health Check

```bash
curl -I https://payagent.yourdomain.com/api/health
```

**Expected response:**
```
HTTP/2 200 OK
strict-transport-security: max-age=63072000; includeSubDomains; preload
x-content-type-options: nosniff
x-frame-options: DENY
```

### SSL Grade

Test at https://www.ssllabs.com/ssltest/

Expect: **A+** rating ✅

### API Test

```bash
curl -X POST https://payagent.yourdomain.com/api/generate_apass \
  -H "Authorization: Bearer your_token_here" \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "agent-001-lisbon",
    "kycSource": "Sumsub",
    "subTier": 5
  }'
```

---

## Step 8: Smart Contract Deployment (Monad Mainnet)

```bash
cd /opt/payagent

# Compile contracts
npx hardhat compile

# Deploy to Monad mainnet
npx hardhat run deploy.js --network monad
```

**Output:**
```
✅  DEPLOYED SUCCESSFULLY

📄  Contract address: 0x...
🔗  Tx hash:          0x...
🌐  Explorer: https://explorer.monad.xyz/address/0x...
```

Save the contract address in `.env`:
```bash
sudo nano /opt/payagent/.env
# Add: PAYAGENT_CONTRACT_ADDRESS=0x...
```

---

## Monitoring & Maintenance

### View Logs

```bash
# Real-time logs
sudo journalctl -u payagent -f

# Last 100 lines
sudo journalctl -u payagent -n 100

# Nginx logs
sudo tail -f /var/log/nginx/payagent.access.log
sudo tail -f /var/log/nginx/payagent.error.log
```

### Check Service Health

```bash
# Service status
sudo systemctl status payagent

# Resource usage
ps aux | grep "node server.js"

# Port listening
sudo netstat -tlnp | grep :3000
```

### Restart Service

```bash
sudo systemctl restart payagent
```

### Update PayAgent

```bash
cd /opt/payagent
sudo git pull origin main
sudo npm install --production
sudo systemctl restart payagent
```

---

## Troubleshooting

### Service won't start

```bash
# Check for syntax errors
node /opt/payagent/server.js

# Verify .env is readable
ls -la /opt/payagent/.env

# Check for port conflicts
sudo lsof -i :3000
```

### SSL certificate issues

```bash
# Check certificate expiry
sudo openssl x509 -in /etc/letsencrypt/live/payagent.yourdomain.com/fullchain.pem -noout -dates

# Renew manually
sudo certbot renew --force-renewal
```

### Nginx reverse proxy errors

```bash
# Test Nginx config
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

---

## Production Checklist

- [ ] Node.js v20+ installed
- [ ] `.env` configured with production credentials
- [ ] SSL certificate installed (A+ rating)
- [ ] Nginx reverse proxy configured
- [ ] Systemd service enabled
- [ ] Certificate auto-renewal working
- [ ] Logs configured and monitored
- [ ] Firewall allows 80, 443
- [ ] Smart contract deployed on Monad
- [ ] Health check passes
- [ ] API endpoints tested
- [ ] Backups scheduled

---

## Support

For issues:
- Check `/var/log/nginx/payagent.error.log`
- Run `sudo journalctl -u payagent -f` for live logs
- Review Cleanverse API status
- Verify Monad RPC connectivity

---

*Cleanverse Build: Verified Finance Hackathon · Track 02: Trusted AI Agent Transactions*

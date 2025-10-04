# 📘 Hướng Dẫn Tự Động Thiết Lập Domain - RocketVPS

## 🌟 Tính Năng Mới v1.4.0

### 1. Global Command `rocketvps`

**Sau khi cài đặt RocketVPS, bạn có thể gõ `rocketvps` từ bất kỳ đâu:**

```bash
# Chỉ cần gõ lệnh này từ bất kỳ thư mục nào
rocketvps

# Không cần:
# cd /opt/rocketvps
# ./rocketvps.sh
```

**Cách hoạt động:**
- Script cài đặt tự động tạo symlink: `/usr/local/bin/rocketvps` → `/opt/rocketvps/rocketvps.sh`
- Lệnh `rocketvps` có sẵn toàn hệ thống
- Tiện lợi và chuyên nghiệp

---

### 2. Tự Động Setup phpMyAdmin Khi Thêm Domain

**Tính năng:**
Khi thêm domain PHP/WordPress/Laravel, RocketVPS tự động:
- ✅ Tạo phpMyAdmin với đường dẫn ngẫu nhiên (bảo mật)
- ✅ Generate username và password ngẫu nhiên
- ✅ Thiết lập HTTP Basic Authentication
- ✅ Cấu hình Nginx tối ưu
- ✅ Lưu credentials an toàn
- ✅ Hiển thị đầy đủ thông tin

---

## 🚀 Quick Start

### Bước 1: Cài Đặt RocketVPS

```bash
# Clone repository
git clone https://github.com/yourusername/rocketvps.git
cd rocketvps

# Chạy installer
sudo bash install.sh
```

**Sau khi cài đặt xong:**
```
✓ RocketVPS installed successfully!

Installation Directory: /opt/rocketvps
Command: rocketvps

Quick Start:
  1. Run: rocketvps
  2. Choose option 1 to install Nginx
  3. Choose option 2 to add your first domain
```

### Bước 2: Mở RocketVPS

```bash
# Gõ lệnh từ bất kỳ đâu
rocketvps
```

### Bước 3: Thêm Domain Mới

```
ROCKETVPS MAIN MENU:
  1) Nginx Management
  2) Domain Management    ← Chọn option này
  3) SSL Management
  ...
```

**Chọn: 2 → 1 (Add New Domain)**

---

## 📋 Quy Trình Thêm Domain (Chi Tiết)

### Input Yêu Cầu

```
Enter domain name: example.com
Enter root directory: /var/www/example.com/public_html (hoặc để trống dùng default)

Select site type:
  1) Static HTML
  2) PHP               ← phpMyAdmin tự động setup
  3) PHP with Cache    ← phpMyAdmin tự động setup
  4) WordPress         ← phpMyAdmin tự động setup
  5) Laravel           ← phpMyAdmin tự động setup
  6) Node.js Proxy

Enter choice: 2
```

### Quá Trình Tự Động

```
✓ Domain example.com added successfully
ℹ Setting up phpMyAdmin for example.com...
✓ phpMyAdmin configured automatically
```

### Kết Quả Hiển Thị

```
╔═══════════════════════════════════════════════════════════════╗
║           DOMAIN SETUP COMPLETED SUCCESSFULLY! 🎉            ║
╚═══════════════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════════════════
📌 DOMAIN INFORMATION
═══════════════════════════════════════════════════════════════

Domain Name:           example.com
Alternative:           www.example.com

═══════════════════════════════════════════════════════════════
📁 DIRECTORY STRUCTURE
═══════════════════════════════════════════════════════════════

Root Directory:        /var/www/example.com/public_html
Website Files:         /var/www/example.com/public_html/
Nginx Config:          /etc/nginx/sites-available/example.com
Access Logs:           /var/log/nginx/example.com_access.log
Error Logs:            /var/log/nginx/example.com_error.log

═══════════════════════════════════════════════════════════════
🔐 PHPMYADMIN ACCESS (Auto-configured)
═══════════════════════════════════════════════════════════════

Access URL:            http://example.com/phpmyadmin_a3f2e1
Username:              admin_f8a2c4d1
Password:              xK9mP2nL5qR8wT3v
Credentials File:      /opt/rocketvps/config/phpmyadmin_example.com_credentials.txt

⚠  Note: Save these credentials securely!

═══════════════════════════════════════════════════════════════
🖥  SERVER INFORMATION
═══════════════════════════════════════════════════════════════

Server IP:             192.168.1.100
HTTP Port:             80
HTTPS Port:            443 (after SSL setup)

═══════════════════════════════════════════════════════════════
🌐 DNS CONFIGURATION REQUIRED
═══════════════════════════════════════════════════════════════

Add these DNS records at your domain registrar:

  Record Type    Name    Value
  ──────────────────────────────────────────
  A              @       192.168.1.100
  A              www     192.168.1.100
  CNAME          www     example.com

DNS propagation may take 5-60 minutes

═══════════════════════════════════════════════════════════════
⚡ QUICK COMMANDS
═══════════════════════════════════════════════════════════════

Upload files via FTP:
  Host: 192.168.1.100
  Directory: /var/www/example.com/public_html

View files:            ls -lah /var/www/example.com/public_html
Edit Nginx config:     nano /etc/nginx/sites-available/example.com
Test Nginx config:     nginx -t
Reload Nginx:          systemctl reload nginx
View access logs:      tail -f /var/log/nginx/example.com_access.log
View error logs:       tail -f /var/log/nginx/example.com_error.log

═══════════════════════════════════════════════════════════════
📋 RECOMMENDED NEXT STEPS
═══════════════════════════════════════════════════════════════

  1. Configure DNS records (see above)
  2. Upload your website files to: /var/www/example.com/public_html
  3. Install SSL certificate (Menu → 3 → SSL Management)
  4. Setup FTP access (Menu → 7 → FTP Management)
  5. Configure firewall (Menu → 8 → CSF Firewall)
  6. Setup automatic backups (Menu → 10 → Backup & Restore)

═══════════════════════════════════════════════════════════════

✓ Complete information saved to: /opt/rocketvps/config/domain_example.com_info.txt
```

---

## 🔐 Bảo Mật phpMyAdmin

### Tính Năng Bảo Mật Tự Động

**1. Đường Dẫn Ngẫu Nhiên**
```
❌ Không dùng: /phpmyadmin (dễ bị tấn công)
✅ Tự động dùng: /phpmyadmin_a3f2e1 (khó đoán)
```

**2. HTTP Basic Authentication**
```
Username: admin_f8a2c4d1  (random 8 chars)
Password: xK9mP2nL5qR8wT3v (random 16 chars, alphanumeric)
```

**3. Nginx Security Configuration**
```nginx
location /phpmyadmin_a3f2e1 {
    alias /usr/share/phpmyadmin;
    
    # HTTP Basic Authentication
    auth_basic "Database Administration";
    auth_basic_user_file /etc/nginx/htpasswd/example.com_phpmyadmin;
    
    # PHP processing
    location ~ ^/phpmyadmin_a3f2e1/(.+\.php)$ {
        # Secure PHP configuration
    }
}
```

**4. Credentials Storage**
```bash
# File: /opt/rocketvps/config/phpmyadmin_example.com_credentials.txt
# Permissions: 600 (only root can read)
```

---

## 📁 Files & Directories

### Config Files Được Tạo

```
/opt/rocketvps/config/
├── domains.list                              # Danh sách domain
├── phpmyadmin_domains.list                   # Danh sách domain có phpMyAdmin
├── phpmyadmin_example.com_credentials.txt    # Credentials phpMyAdmin
└── domain_example.com_info.txt               # Thông tin đầy đủ domain
```

### Nginx Configuration

```
/etc/nginx/sites-available/
└── example.com                               # Vhost config

/etc/nginx/sites-enabled/
└── example.com → ../sites-available/example.com

/etc/nginx/htpasswd/
└── example.com_phpmyadmin                    # HTTP Auth file
```

### Website Files

```
/var/www/example.com/
└── public_html/
    ├── index.php
    └── (your website files)
```

---

## 🎯 Use Cases

### Use Case 1: Blog Cá Nhân

```bash
rocketvps
→ 2) Domain Management
→ 1) Add New Domain

Domain: myblog.com
Type: 4) WordPress
```

**Kết quả:**
- ✅ WordPress-optimized Nginx config
- ✅ phpMyAdmin tự động: `http://myblog.com/phpmyadmin_x7k2m9`
- ✅ Credentials lưu an toàn
- ✅ Sẵn sàng cài WordPress

### Use Case 2: Website Công Ty

```bash
rocketvps
→ 2) Domain Management
→ 1) Add New Domain

Domain: company.vn
Type: 2) PHP
```

**Kết quả:**
- ✅ PHP-FPM optimized
- ✅ phpMyAdmin: `http://company.vn/phpmyadmin_a3f2e1`
- ✅ Database admin ready
- ✅ Upload code qua FTP

### Use Case 3: Laravel Application

```bash
rocketvps
→ 2) Domain Management
→ 1) Add New Domain

Domain: api.example.com
Type: 5) Laravel
```

**Kết quả:**
- ✅ Laravel-specific Nginx config
- ✅ phpMyAdmin cho database management
- ✅ Artisan commands ready
- ✅ `.env` configuration ready

---

## 🔧 Advanced Configuration

### Xem Credentials Đã Lưu

```bash
# Xem file credentials
cat /opt/rocketvps/config/phpmyadmin_example.com_credentials.txt

# Xem domain info
cat /opt/rocketvps/config/domain_example.com_info.txt
```

### Thay Đổi phpMyAdmin Password

```bash
# Tạo password mới
NEW_PASSWORD="YourNewPassword123"

# Update htpasswd file
echo "admin_f8a2c4d1:$(openssl passwd -apr1 $NEW_PASSWORD)" > \
  /etc/nginx/htpasswd/example.com_phpmyadmin

# Reload Nginx
systemctl reload nginx
```

### Thêm IP Whitelist cho phpMyAdmin

```bash
# Edit Nginx config
nano /etc/nginx/sites-available/example.com

# Thêm vào location phpMyAdmin:
location /phpmyadmin_a3f2e1 {
    # Add IP whitelist
    allow 203.0.113.10;    # Your office IP
    allow 198.51.100.20;   # Your home IP
    deny all;
    
    # ... existing config ...
}

# Test và reload
nginx -t && systemctl reload nginx
```

### Disable phpMyAdmin Cho Domain

```bash
# Edit Nginx config
nano /etc/nginx/sites-available/example.com

# Comment out hoặc xóa phpMyAdmin location block
# location /phpmyadmin_xxx { ... }

# Test và reload
nginx -t && systemctl reload nginx
```

---

## 🛠️ Troubleshooting

### Vấn Đề 1: Lệnh `rocketvps` Không Hoạt Động

**Triệu chứng:**
```bash
$ rocketvps
rocketvps: command not found
```

**Giải pháp:**
```bash
# Kiểm tra symlink
ls -l /usr/local/bin/rocketvps

# Nếu không có, tạo lại
sudo ln -sf /opt/rocketvps/rocketvps.sh /usr/local/bin/rocketvps

# Kiểm tra permissions
sudo chmod +x /opt/rocketvps/rocketvps.sh
sudo chmod +x /usr/local/bin/rocketvps
```

### Vấn Đề 2: phpMyAdmin Không Tự Động Setup

**Triệu chứng:**
```
phpMyAdmin setup skipped (not installed or failed)
```

**Giải pháp:**
```bash
# Cài phpMyAdmin trước
rocketvps
→ 15) phpMyAdmin Management
→ 1) Install phpMyAdmin

# Sau đó thêm domain lại
```

### Vấn Đề 3: Không Truy Cập Được phpMyAdmin

**Triệu chứng:**
```
403 Forbidden hoặc 401 Unauthorized
```

**Giải pháp:**
```bash
# Kiểm tra htpasswd file
ls -l /etc/nginx/htpasswd/example.com_phpmyadmin

# Kiểm tra permissions
sudo chmod 644 /etc/nginx/htpasswd/example.com_phpmyadmin

# Kiểm tra Nginx error log
tail -f /var/log/nginx/example.com_error.log

# Test Nginx config
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### Vấn Đề 4: Quên phpMyAdmin Credentials

**Giải pháp:**
```bash
# Xem credentials file
sudo cat /opt/rocketvps/config/phpmyadmin_example.com_credentials.txt

# Hoặc xem domain info
sudo cat /opt/rocketvps/config/domain_example.com_info.txt

# Nếu file bị mất, reset password:
NEW_USERNAME="admin"
NEW_PASSWORD="NewSecurePassword123"

echo "$NEW_USERNAME:$(openssl passwd -apr1 $NEW_PASSWORD)" | \
  sudo tee /etc/nginx/htpasswd/example.com_phpmyadmin

sudo systemctl reload nginx
```

### Vấn Đề 5: Domain Không Load

**Giải pháp:**
```bash
# 1. Kiểm tra DNS
nslookup example.com
dig example.com

# 2. Kiểm tra Nginx config
sudo nginx -t

# 3. Kiểm tra Nginx enabled
ls -l /etc/nginx/sites-enabled/example.com

# 4. Kiểm tra Nginx running
sudo systemctl status nginx

# 5. Xem error logs
sudo tail -f /var/log/nginx/example.com_error.log

# 6. Reload Nginx
sudo systemctl reload nginx
```

---

## 📊 Comparison: Before vs After

### Before v1.4.0 (Manual Setup)

```
⏱ Time: 15-30 minutes
👤 User actions: 20+ steps

Steps:
1. Add domain manually
2. Configure Nginx manually
3. Install phpMyAdmin manually
4. Configure phpMyAdmin for domain manually
5. Create htpasswd file manually
6. Generate random credentials manually
7. Edit Nginx config manually
8. Test Nginx manually
9. Reload Nginx manually
10. Document credentials manually
11. Note down all URLs manually
12. Configure DNS manually

❌ Error-prone
❌ Time-consuming
❌ Inconsistent
❌ Manual documentation
```

### After v1.4.0 (Auto Setup)

```
⏱ Time: 2-3 minutes
👤 User actions: 3 steps

Steps:
1. Run: rocketvps
2. Choose: 2 → 1 (Add Domain)
3. Enter: domain name + site type

✅ Automatic phpMyAdmin
✅ Random secure credentials
✅ Complete information display
✅ Saved credentials
✅ DNS guide included
✅ Quick commands provided

✅ Fast
✅ Consistent
✅ Secure
✅ Professional
```

---

## 💡 Tips & Best Practices

### 1. Luôn Backup Credentials

```bash
# Copy credentials sang máy local
scp root@server:/opt/rocketvps/config/*_credentials.txt ~/backup/

# Hoặc dùng password manager (1Password, Bitwarden, etc.)
```

### 2. Setup SSL Ngay Sau Khi Thêm Domain

```bash
rocketvps
→ 3) SSL Management
→ 2) Install SSL Certificate
→ Enter domain: example.com
```

### 3. Enable Firewall

```bash
rocketvps
→ 8) CSF Firewall Management
→ 1) Install CSF Firewall
```

### 4. Setup Auto Backup

```bash
rocketvps
→ 10) Backup & Restore
→ 1) Full Backup
→ 11) Cronjob Management → Schedule daily backup
```

### 5. Monitor Logs

```bash
# Access logs (traffic monitoring)
tail -f /var/log/nginx/example.com_access.log

# Error logs (troubleshooting)
tail -f /var/log/nginx/example.com_error.log

# phpMyAdmin access attempts
grep "phpmyadmin" /var/log/nginx/example.com_access.log
```

### 6. Regular Security Updates

```bash
# Update system
apt update && apt upgrade -y

# Update phpMyAdmin
rocketvps
→ 15) phpMyAdmin Management
→ 1) Install phpMyAdmin (overwrite để update)
```

---

## 🎓 FAQ

### Q1: Có thể thay đổi đường dẫn phpMyAdmin không?

**A:** Có. Edit Nginx config:
```bash
nano /etc/nginx/sites-available/example.com
# Thay đổi: location /phpmyadmin_xxx {...}
# Thành: location /your-custom-path {...}
nginx -t && systemctl reload nginx
```

### Q2: phpMyAdmin có tự động setup cho Static HTML không?

**A:** Không. phpMyAdmin chỉ setup cho PHP-based sites:
- PHP (site type 2)
- PHP with Cache (site type 3)
- WordPress (site type 4)
- Laravel (site type 5)

### Q3: Có thể disable auto phpMyAdmin setup không?

**A:** Có. Edit `modules/domain.sh`:
```bash
nano /opt/rocketvps/modules/domain.sh

# Comment dòng này trong function add_domain():
# if auto_setup_phpmyadmin_for_domain "$domain_name" "$root_dir"; then
```

### Q4: Credentials file bị mất thì sao?

**A:** Reset password:
```bash
NEW_PASSWORD="YourNewPassword"
echo "admin_xxx:$(openssl passwd -apr1 $NEW_PASSWORD)" > \
  /etc/nginx/htpasswd/example.com_phpmyadmin
systemctl reload nginx
```

### Q5: Có thể xem lại domain info sau này không?

**A:** Có:
```bash
# Xem file info
cat /opt/rocketvps/config/domain_example.com_info.txt

# Xem credentials
cat /opt/rocketvps/config/phpmyadmin_example.com_credentials.txt
```

### Q6: Multiple domains có thể dùng chung phpMyAdmin không?

**A:** Mỗi domain có phpMyAdmin riêng với:
- Đường dẫn riêng (random)
- Credentials riêng (random)
- Bảo mật riêng

Tốt cho isolation và security.

### Q7: Command `rocketvps` có hoạt động với sudo không?

**A:** Có:
```bash
# Cả hai đều hoạt động
rocketvps
sudo rocketvps
```

Nhưng một số operations yêu cầu root, nên dùng `sudo` hoặc login root.

---

## 📚 Related Documentation

- **[README.md](README.md)** - Tổng quan RocketVPS
- **[PHPMYADMIN_GUIDE.md](PHPMYADMIN_GUIDE.md)** - Chi tiết phpMyAdmin
- **[WORDPRESS_GUIDE.md](WORDPRESS_GUIDE.md)** - WordPress Management
- **[VPS_OPTIMIZATION_GUIDE.md](VPS_OPTIMIZATION_GUIDE.md)** - VPS Optimization

---

## 🎉 Conclusion

RocketVPS v1.4.0 mang đến:

✅ **Global Command**: Gõ `rocketvps` từ mọi nơi
✅ **Auto phpMyAdmin**: Setup tự động, secure, random credentials
✅ **Complete Info Display**: Mọi thông tin cần thiết ngay sau setup
✅ **Professional**: Tiết kiệm thời gian, giảm lỗi, tăng bảo mật

**Từ 30 phút setup thủ công → 3 phút tự động! 🚀**

---

*Developed by RocketVPS Team - October 4, 2025*

*"Domain setup made simple, fast, and secure."* ✨

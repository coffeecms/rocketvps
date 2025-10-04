# 🗄️ RocketVPS - Hướng Dẫn phpMyAdmin

## 📖 Giới Thiệu

Module phpMyAdmin cho phép bạn dễ dàng cài đặt và quản lý phpMyAdmin cho từng domain riêng biệt. Mỗi domain có thể có cấu hình phpMyAdmin độc lập với đường dẫn truy cập, bảo mật, và quyền hạn khác nhau.

## ✨ Tính Năng Chính

### 1. 📦 Cài Đặt Đơn Giản
- Tự động tải phiên bản mới nhất
- Cài đặt dependencies tự động
- Cấu hình bảo mật mặc định
- Không cần cấu hình thủ công

### 2. 🌐 Quản Lý Theo Domain
- Thêm phpMyAdmin vào bất kỳ domain nào
- Mỗi domain có đường dẫn riêng
- Cấu hình độc lập cho từng domain
- Dễ dàng thêm/xóa

### 3. 🔒 Bảo Mật Đa Lớp
- **IP Whitelist**: Chỉ cho phép IP cụ thể
- **HTTP Basic Auth**: Username/Password
- **Session Timeout**: Tự động logout
- **Blowfish Encryption**: Mã hóa session
- **Disable Root**: Vô hiệu hóa đăng nhập root
- **2FA Support**: Xác thực 2 lớp

### 4. 🛠️ Quản Lý Dễ Dàng
- Update lên phiên bản mới
- Xóa khỏi domain cụ thể
- Liệt kê tất cả domain đã cài
- Cấu hình bảo mật nâng cao
- Gỡ cài đặt hoàn toàn

## 🎯 Hướng Dẫn Sử Dụng

### Bước 1: Cài Đặt phpMyAdmin

```bash
rocketvps
# Chọn: 15) phpMyAdmin Management
# Chọn: 1) Install phpMyAdmin

# Hệ thống sẽ:
1. Tải phiên bản mới nhất từ phpmyadmin.net
2. Cài đặt dependencies (php-mbstring, php-zip, etc.)
3. Tạo cấu hình bảo mật
4. Tạo thư mục tmp với quyền phù hợp
5. Generate Blowfish secret ngẫu nhiên
```

**Output mẫu:**
```
✓ Installing phpMyAdmin...
✓ Downloading latest phpMyAdmin...
✓ Extracting files...
✓ Configuring security settings...
✓ Setting permissions...
✓ phpMyAdmin installed successfully
ℹ Installation directory: /usr/share/phpmyadmin
```

### Bước 2: Thêm phpMyAdmin Cho Domain

```bash
rocketvps
# Chọn: 15) phpMyAdmin Management
# Chọn: 2) Add phpMyAdmin to Domain
```

#### 2.1. Chọn Domain

```
Available domains:
1. example.com
2. demo.vn
3. shop.com

Enter domain name: example.com
```

#### 2.2. Chọn Đường Dẫn Truy Cập

```
Choose phpMyAdmin access path:
  1) /phpmyadmin (default)
  2) /pma
  3) /database
  4) Custom path

Enter choice [1-4]: 1
```

**Khuyến nghị đường dẫn:**
- `/phpmyadmin` - Chuẩn, dễ nhớ
- `/pma` - Ngắn gọn, khó đoán hơn
- `/database` - Thân thiện
- Custom - Bảo mật cao nhất (VD: `/my-secret-db-2024`)

#### 2.3. Cấu Hình IP Whitelist (Tùy chọn)

```
Enable IP whitelist? (y/n): y

Enter allowed IP addresses (one per line, empty line to finish):
IP address: 123.45.67.89
IP address: 98.76.54.32
IP address: [Enter để kết thúc]

✓ IP whitelist configured
  - Allowed: 123.45.67.89, 98.76.54.32
  - All other IPs will be blocked
```

**Lợi ích:**
- Chỉ bạn mới truy cập được
- Chặn 99% brute force attack
- Không ảnh hưởng tốc độ

#### 2.4. Cấu Hình HTTP Authentication (Tùy chọn)

```
Enable HTTP Basic Authentication? (y/n): y

Enter username: admin_dbuser
Enter password: ******

✓ HTTP Authentication configured
ℹ Users must enter this username/password before accessing phpMyAdmin
```

**Khuyến nghị:**
- Username: Không dùng "admin" hoặc "root"
- Password: Tối thiểu 16 ký tự, có chữ hoa, chữ thường, số, ký tự đặc biệt

#### 2.5. Hoàn Tất

```
✓ phpMyAdmin configured for example.com
ℹ Access URL: http://example.com/phpmyadmin
ℹ HTTP Auth: admin_dbuser
```

### Bước 3: Truy Cập phpMyAdmin

1. Mở trình duyệt
2. Truy cập: `http://example.com/phpmyadmin`
3. Nếu có HTTP Auth: Nhập username/password
4. Đăng nhập MySQL: Nhập user/pass database

## 📚 Các Tính Năng Chi Tiết

### 1. Danh Sách Domain Đã Cài

```bash
rocketvps → 15) phpMyAdmin Management → 4) List Domains with phpMyAdmin

# Output:
Configured domains:

  Domain: example.com
  Access: http://example.com/phpmyadmin
  HTTP Auth: Yes

  Domain: demo.vn
  Access: http://demo.vn/pma
  HTTP Auth: No

  Domain: shop.com
  Access: http://shop.com/my-secret-db-2024
  HTTP Auth: Yes
```

### 2. Xóa phpMyAdmin Khỏi Domain

```bash
rocketvps → 15) → 3) Remove phpMyAdmin from Domain

Domains with phpMyAdmin:
1. example.com
2. demo.vn
3. shop.com

Enter domain name: demo.vn

# Hệ thống sẽ:
1. Backup cấu hình Nginx
2. Xóa location block phpMyAdmin
3. Xóa htpasswd file (nếu có)
4. Test Nginx config
5. Reload Nginx

✓ phpMyAdmin removed from demo.vn
```

### 3. Cập Nhật phpMyAdmin

```bash
rocketvps → 15) → 5) Update phpMyAdmin

⚠ This will update phpMyAdmin to the latest version
Continue? (y/n): y

# Hệ thống sẽ:
1. Backup toàn bộ phpMyAdmin hiện tại
2. Backup file config
3. Tải phiên bản mới nhất
4. Cài đặt phiên bản mới
5. Restore lại config cũ

✓ phpMyAdmin updated successfully
ℹ Backup saved to: /opt/rocketvps/backups/phpmyadmin_20241003_143022.tar.gz
```

### 4. Cấu Hình Bảo Mật

```bash
rocketvps → 15) → 6) Configure Security Settings

Security Options:

  1) Change Blowfish Secret
  2) Disable Root Login
  3) Set Cookie Validity (Session Timeout)
  4) Enable Two-Factor Authentication
  5) Apply All Security Hardening

Enter choice [1-5]:
```

#### Option 1: Thay Đổi Blowfish Secret

```bash
# Chọn 1
✓ Blowfish secret updated
ℹ All users will need to login again
```

**Khi nào cần:**
- Nghi ngờ bị hack
- Định kỳ mỗi 3-6 tháng
- Sau khi có thay đổi lớn

#### Option 2: Vô Hiệu Hóa Đăng Nhập Root

```bash
# Chọn 2
✓ Root login disabled
ℹ Create separate database users instead
```

**Lợi ích:**
- Root không thể login từ phpMyAdmin
- Bắt buộc dùng user có quyền hạn giới hạn
- Giảm nguy cơ bị hack toàn bộ database

#### Option 3: Session Timeout

```bash
# Chọn 3
Enter session timeout in seconds (default 3600): 1800

✓ Session timeout set to 1800 seconds
ℹ Users will be logged out after 30 minutes of inactivity
```

**Khuyến nghị:**
- Office network: 3600 (1 giờ)
- Public network: 1800 (30 phút)
- High security: 900 (15 phút)

#### Option 4: Two-Factor Authentication

```bash
# Chọn 4
✓ Two-factor authentication enabled
ℹ Users need to configure 2FA in their account settings
```

**Lưu ý:**
- Mỗi user phải tự setup 2FA
- Dùng Google Authenticator hoặc tương tự
- Bảo vệ 99% brute force attacks

#### Option 5: Áp Dụng Tất Cả

```bash
# Chọn 5
✓ All security hardening applied
  - New Blowfish secret generated
  - Root login disabled
  - Session timeout: 3600 seconds
  - Auto logout on browser close
  - PHP info hidden
  - Server info hidden
  - Version check disabled
  - Arbitrary server disabled
```

### 5. Gỡ Cài Đặt Hoàn Toàn

```bash
rocketvps → 15) → 7) Uninstall phpMyAdmin

⚠ This will completely remove phpMyAdmin
⚠ All domain configurations will be removed
Are you sure? (yes/no): yes

# Hệ thống sẽ:
1. Xóa phpMyAdmin khỏi TẤT CẢ domains
2. Backup toàn bộ trước khi xóa
3. Xóa thư mục /usr/share/phpmyadmin
4. Xóa tất cả file cấu hình
5. Reload Nginx

✓ phpMyAdmin uninstalled successfully
ℹ Backup saved to: /opt/rocketvps/backups/phpmyadmin_final_20241003_150022.tar.gz
```

## 🔐 Cấu Hình Bảo Mật Nâng Cao

### Cấu Hình 1: Bảo Mật Tối Đa (Recommended)

```bash
# 1. Custom access path
Access path: /my-db-admin-2024

# 2. IP Whitelist
Allowed IPs:
- Your office IP
- Your home IP
- VPN IP

# 3. HTTP Authentication
Username: custom_admin_name
Password: Very$trong@P@ssw0rd#2024

# 4. Disable Root
Yes

# 5. Session timeout
1800 seconds (30 minutes)

# 6. Enable 2FA
Yes
```

**Mức độ bảo mật: ⭐⭐⭐⭐⭐ (5/5)**

### Cấu Hình 2: Bảo Mật Cơ Bản (Basic)

```bash
# 1. Standard path
Access path: /phpmyadmin

# 2. No IP Whitelist
(If you have dynamic IP)

# 3. HTTP Authentication
Username: dbadmin
Password: Str0ngP@ss

# 4. Session timeout
3600 seconds (1 hour)
```

**Mức độ bảo mật: ⭐⭐⭐ (3/5)**

### Cấu Hình 3: Cho Development Server

```bash
# 1. Easy path
Access path: /pma

# 2. Local IP only
Allowed IPs: 127.0.0.1, ::1

# 3. Simple HTTP Auth
Username: dev
Password: Dev12345

# 4. Long session
7200 seconds (2 hours)
```

**Mức độ bảo mật: ⭐⭐ (2/5)** - Chỉ dùng cho dev server

## 🎓 Best Practices

### 1. Khi Nào Nên Cài phpMyAdmin?

✅ **NÊN cài khi:**
- Cần quản lý database qua giao diện web
- Không quen với MySQL command line
- Cần import/export database lớn
- Muốn dễ dàng browse data

❌ **KHÔNG NÊN cài khi:**
- Production server với security cao
- Chỉ dùng automated scripts
- Có thể dùng SSH + MySQL CLI
- Server public trên internet không có firewall

### 2. Nguyên Tắc Bảo Mật

#### 🔴 PHẢI LÀM:
- ✅ Luôn dùng HTTPS (SSL certificate)
- ✅ Dùng custom access path khó đoán
- ✅ Bật IP whitelist nếu có IP tĩnh
- ✅ Bật HTTP Authentication
- ✅ Disable root login
- ✅ Đặt session timeout ngắn
- ✅ Update thường xuyên
- ✅ Monitor access logs

#### 🟡 NÊN LÀM:
- ⚠️ Bật 2FA cho tất cả users
- ⚠️ Dùng firewall (CSF/UFW)
- ⚠️ Chỉ cài trên domain cần thiết
- ⚠️ Tạo database user riêng, không dùng root
- ⚠️ Backup trước khi update

#### 🔴 KHÔNG ĐƯỢC LÀM:
- ❌ Dùng đường dẫn mặc định `/phpmyadmin`
- ❌ Không có authentication
- ❌ Allow all IPs
- ❌ Dùng root để login
- ❌ Session timeout quá dài
- ❌ Không update lâu năm

### 3. Quy Trình Bảo Mật Hàng Tuần

```bash
# Tuần 1: Check access logs
tail -100 /var/log/nginx/access.log | grep phpmyadmin

# Tuần 2: Check failed login attempts
# Xem trong phpMyAdmin logs

# Tuần 3: Update nếu có phiên bản mới
rocketvps → 15) → 5) Update phpMyAdmin

# Tuần 4: Review users và permissions
# Login phpMyAdmin → User accounts
```

### 4. Backup Strategy

```bash
# Auto backup trước mỗi thay đổi
# Backup location: /opt/rocketvps/backups/

# Manual backup:
tar -czf phpmyadmin_backup_$(date +%Y%m%d).tar.gz /usr/share/phpmyadmin

# Backup database:
rocketvps → 6) Database Management → 3) Backup Database
```

## 📊 Ví Dụ Thực Tế

### Ví Dụ 1: WordPress Hosting Company

**Yêu cầu:**
- 50 WordPress sites
- Mỗi site 1 database
- Clients cần truy cập phpMyAdmin

**Giải pháp:**
```bash
# Cài phpMyAdmin 1 lần
rocketvps → 15) → 1) Install phpMyAdmin

# Thêm vào domain chính
Domain: hosting.com
Path: /clientarea/database
IP Whitelist: Office IP
HTTP Auth: Yes

# Tạo database user cho mỗi client
# Mỗi user chỉ thấy database của mình

# Result:
# Clients access: https://hosting.com/clientarea/database
# Login với credentials riêng
# Chỉ thấy database của mình
```

### Ví Dụ 2: E-commerce Site

**Yêu cầu:**
- 1 domain duy nhất: shop.com
- Chỉ admin truy cập database
- Security cao

**Giải pháp:**
```bash
Domain: shop.com
Path: /admin-db-x7k2p9m  # Random path
IP Whitelist: 
  - Admin home IP
  - Office IP
HTTP Auth: Yes
  - Username: admin_shop_2024
  - Password: [Very strong 24 chars]
Disable Root: Yes
Session: 1800 seconds
2FA: Enabled

# Result:
# URL: https://shop.com/admin-db-x7k2p9m
# Triple authentication: IP + HTTP Auth + MySQL
# Auto logout after 30 mins
```

### Ví Dụ 3: Development Team

**Yêu cầu:**
- 5 developers
- Multiple projects
- Quick access cần thiết

**Giải pháp:**
```bash
Domain: dev.company.com
Path: /pma
IP Whitelist: 
  - Office network: 192.168.1.0/24
  - VPN: 10.8.0.0/24
HTTP Auth: Yes
  - Username: devteam
  - Password: [Shared team password]
Session: 7200 seconds (2 hours)

# Mỗi dev có MySQL user riêng
# Grant permissions phù hợp vai trò

# Result:
# Easy access for team
# Still secure with IP + HTTP Auth
# Audit trail qua MySQL users
```

## 🆘 Xử Lý Sự Cố

### Vấn Đề 1: Không Truy Cập Được phpMyAdmin

**Triệu chứng:**
- 404 Not Found
- 403 Forbidden
- Connection refused

**Giải pháp:**

```bash
# 1. Kiểm tra Nginx
nginx -t
systemctl status nginx

# 2. Kiểm tra phpMyAdmin location
cat /etc/nginx/sites-available/example.com | grep phpmyadmin

# 3. Kiểm tra quyền
ls -la /usr/share/phpmyadmin
# Phải là www-data:www-data

# 4. Kiểm tra PHP-FPM
systemctl status php8.1-fpm

# 5. Test direct access
curl http://localhost/phpmyadmin

# 6. Check logs
tail -50 /var/log/nginx/error.log
```

### Vấn Đề 2: Bị Chặn Bởi IP Whitelist

**Triệu chứng:**
- 403 Forbidden
- "Access denied"

**Giải pháp:**

```bash
# 1. Check IP hiện tại
curl ifconfig.me

# 2. Tạm thời disable IP whitelist
# Edit: /etc/nginx/sites-available/domain
# Comment out:
# allow xxx.xxx.xxx.xxx;
# deny all;

# 3. Reload Nginx
systemctl reload nginx

# 4. Add IP mới
rocketvps → 15) → 2) Add to Domain (reconfigure)
```

### Vấn Đề 3: Không Login Được MySQL

**Triệu chứng:**
- "Access denied for user"
- "Cannot log in to MySQL server"

**Giải pháp:**

```bash
# 1. Check MySQL service
systemctl status mysql

# 2. Check user permissions
mysql -u root -p
SHOW GRANTS FOR 'username'@'localhost';

# 3. Check config
cat /usr/share/phpmyadmin/config.inc.php | grep host

# 4. Check MySQL bind-address
cat /etc/mysql/mysql.conf.d/mysqld.cnf | grep bind-address
# Phải là: bind-address = 127.0.0.1

# 5. Reset password
ALTER USER 'username'@'localhost' IDENTIFIED BY 'newpassword';
FLUSH PRIVILEGES;
```

### Vấn Đề 4: Session Timeout Quá Nhanh

**Triệu chứng:**
- Bị logout sau vài phút
- "Your session has expired"

**Giải pháp:**

```bash
# 1. Increase session timeout
rocketvps → 15) → 6) Configure Security
# Option 3 → Enter longer timeout (e.g., 7200)

# 2. Check PHP session settings
cat /etc/php/8.1/fpm/php.ini | grep session.gc_maxlifetime
# Phải >= phpMyAdmin timeout

# 3. Restart PHP-FPM
systemctl restart php8.1-fpm
```

### Vấn Đề 5: Lỗi "The $cfg['TempDir'] is not accessible"

**Triệu chứng:**
- Không import được database
- Không export được

**Giải pháp:**

```bash
# 1. Tạo temp directory
mkdir -p /usr/share/phpmyadmin/tmp

# 2. Set permissions
chmod 777 /usr/share/phpmyadmin/tmp
chown www-data:www-data /usr/share/phpmyadmin/tmp

# 3. Check config
cat /usr/share/phpmyadmin/config.inc.php | grep TempDir
# Phải có: $cfg['TempDir'] = '/usr/share/phpmyadmin/tmp';

# 4. Test
# Login phpMyAdmin → Try import
```

## 📈 Monitoring & Maintenance

### 1. Access Log Analysis

```bash
# Daily check
tail -100 /var/log/nginx/access.log | grep phpmyadmin

# Failed login attempts
tail -500 /var/log/nginx/access.log | grep "phpmyadmin.*403"

# Geographic analysis (if GeoIP enabled)
awk '/phpmyadmin/ {print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn

# Peak hours
awk '/phpmyadmin/ {print $4}' /var/log/nginx/access.log | cut -d: -f2 | sort | uniq -c
```

### 2. Security Audit

```bash
# Check for brute force attempts
grep "phpmyadmin" /var/log/nginx/access.log | grep "POST" | wc -l

# Check suspicious IPs
awk '/phpmyadmin.*403/ {print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn

# Check config security
cat /usr/share/phpmyadmin/config.inc.php | grep -E "AllowNoPassword|AllowRoot"
```

### 3. Performance Monitoring

```bash
# Response time
tail -100 /var/log/nginx/access.log | grep phpmyadmin | awk '{print $NF}' | awk '{sum+=$1; count++} END {print sum/count}'

# Request count per day
grep "$(date +%d/%b/%Y)" /var/log/nginx/access.log | grep phpmyadmin | wc -l

# Most accessed pages
grep phpmyadmin /var/log/nginx/access.log | awk '{print $7}' | sort | uniq -c | sort -rn | head
```

## 💡 Tips & Tricks

### 1. Nhiều phpMyAdmin Instances

```bash
# Có thể cài phpMyAdmin cho nhiều domains
# Mỗi domain có cấu hình riêng

# Domain 1: example.com/phpmyadmin → Public access
# Domain 2: admin.example.com/db → Admin only
# Domain 3: dev.example.com/pma → Developers only
```

### 2. Tích Hợp Với Fail2Ban

```bash
# /etc/fail2ban/jail.local
[nginx-phpmyadmin]
enabled = true
port = http,https
filter = nginx-phpmyadmin
logpath = /var/log/nginx/access.log
maxretry = 3
bantime = 3600

# /etc/fail2ban/filter.d/nginx-phpmyadmin.conf
[Definition]
failregex = ^<HOST>.*"POST /phpmyadmin.* HTTP/.*" 401
            ^<HOST>.*"POST /pma.* HTTP/.*" 401
ignoreregex =
```

### 3. Cảnh Báo Qua Email

```bash
# Cron job check failed attempts
0 * * * * /opt/rocketvps/scripts/phpmyadmin_alert.sh

# Script content:
#!/bin/bash
FAILED=$(grep "phpmyadmin.*403" /var/log/nginx/access.log | wc -l)
if [ $FAILED -gt 10 ]; then
    echo "phpMyAdmin: $FAILED failed attempts in last hour" | \
    mail -s "Security Alert" admin@example.com
fi
```

### 4. Custom Themes

```bash
# Download theme
cd /usr/share/phpmyadmin/themes/
wget https://example.com/custom-theme.zip
unzip custom-theme.zip

# Apply theme
# Login phpMyAdmin → Settings → Theme
```

## 📚 Tài Nguyên Tham Khảo

- [phpMyAdmin Documentation](https://docs.phpmyadmin.net/)
- [phpMyAdmin Security Guide](https://docs.phpmyadmin.net/en/latest/setup.html#security)
- [MySQL User Management](https://dev.mysql.com/doc/refman/8.0/en/user-account-management.html)

## 🎉 Kết Luận

Module phpMyAdmin giúp bạn:
- ✅ Cài đặt phpMyAdmin trong 2 phút
- ✅ Quản lý database qua web dễ dàng
- ✅ Bảo mật đa lớp cho từng domain
- ✅ Update và maintain đơn giản
- ✅ Tùy chỉnh linh hoạt theo nhu cầu

**Bắt đầu ngay:**
```bash
rocketvps
# → 15) phpMyAdmin Management
# → 1) Install phpMyAdmin
# → 2) Add phpMyAdmin to Domain
```

🚀 **Happy Database Managing!**

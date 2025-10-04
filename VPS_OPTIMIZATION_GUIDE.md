# 🚀 RocketVPS - Hướng Dẫn Tối Ưu VPS

## 📖 Giới Thiệu

Module VPS Optimization tự động tối ưu hóa toàn bộ cấu hình VPS của bạn dựa trên tài nguyên thực tế (RAM, CPU). Tất cả các thông số sẽ được tính toán thông minh để đảm bảo hiệu suất tốt nhất.

## ✨ Tính Năng Chính

### 1. 💾 Tối Ưu SWAP Memory

**SWAP là gì?**
- SWAP là vùng bộ nhớ ảo trên ổ cứng, hỗ trợ khi RAM đầy
- Giúp hệ thống ổn định hơn, tránh bị crash khi hết RAM
- Cải thiện hiệu suất cho các ứng dụng nặng

**Công Thức Tự Động:**
- RAM ≤ 2GB → SWAP = RAM × 2 (ví dụ: 1GB RAM = 2GB SWAP)
- 2GB < RAM ≤ 8GB → SWAP = RAM (ví dụ: 4GB RAM = 4GB SWAP)
- 8GB < RAM ≤ 16GB → SWAP = RAM / 2 (ví dụ: 12GB RAM = 6GB SWAP)
- RAM > 16GB → SWAP = 8GB (cố định)

**Tối Ưu Thêm:**
- `vm.swappiness=10` - Chỉ dùng SWAP khi thực sự cần thiết
- `vm.vfs_cache_pressure=50` - Cân bằng cache filesystem

### 2. 🗄️ Tối Ưu MySQL/MariaDB

**Các Thông Số Được Tối Ưu:**

#### InnoDB Buffer Pool (70% RAM)
- Là cache chính cho InnoDB tables
- 1GB RAM → 700MB buffer pool
- 4GB RAM → 2.8GB buffer pool
- 8GB RAM → 5.6GB buffer pool

#### Max Connections
- ≤ 1GB RAM → 50 connections
- ≤ 2GB RAM → 100 connections
- ≤ 4GB RAM → 150 connections
- > 4GB RAM → 200 connections

#### InnoDB Log File Size
- ≤ 1GB RAM → 64MB
- ≤ 2GB RAM → 128MB
- ≤ 4GB RAM → 256MB
- > 4GB RAM → 512MB

#### Các Tối Ưu Khác:
- Query Cache: 64MB
- Thread Cache: Theo số CPU cores
- Table Cache: 4096 tables
- Slow Query Log: Bật để theo dõi query chậm

### 3. 🌐 Tối Ưu Nginx

**Worker Processes:**
- Tự động = Số CPU cores
- 1 core → 1 worker
- 4 cores → 4 workers
- 8 cores → 8 workers

**Worker Connections:**
- ≤ 1GB RAM → 1,024 connections/worker
- ≤ 2GB RAM → 2,048 connections/worker
- ≤ 4GB RAM → 4,096 connections/worker
- > 4GB RAM → 8,192 connections/worker

**Các Tối Ưu Thêm:**
- **FastCGI Cache**: Tăng tốc PHP
- **Gzip Compression**: Giảm băng thông 60-70%
- **File Cache**: Cache file descriptor
- **Buffer Optimization**: Tối ưu buffer cho PHP/Proxy
- **Keep-Alive**: Tăng tốc kết nối

### 4. 🐘 Tối Ưu PostgreSQL

**Shared Buffers (25% RAM):**
- 1GB RAM → 256MB
- 4GB RAM → 1GB
- 8GB RAM → 2GB

**Effective Cache Size (75% RAM):**
- 1GB RAM → 768MB
- 4GB RAM → 3GB
- 8GB RAM → 6GB

**Work Memory:**
- = RAM / 64
- Giúp query phức tạp chạy nhanh hơn

**Parallel Workers:**
- = Số CPU cores
- Tận dụng đa luồng cho query lớn

## 🎯 Hướng Dẫn Sử Dụng

### Cách 1: Tối Ưu Từng Dịch Vụ

```bash
rocketvps
# Chọn: 14) VPS Optimization

# Menu VPS Optimization:
1) Setup/Resize SWAP Memory         # Chỉ tối ưu SWAP
2) Optimize MySQL/MariaDB           # Chỉ tối ưu MySQL
3) Optimize Nginx                   # Chỉ tối ưu Nginx
4) Optimize PostgreSQL              # Chỉ tối ưu PostgreSQL
```

**Ví Dụ: Tối Ưu MySQL**
```bash
# Chọn option 2
# Hệ thống sẽ:
1. Phát hiện RAM và CPU
2. Tính toán thông số tối ưu
3. Backup cấu hình cũ
4. Áp dụng cấu hình mới
5. Restart MySQL
6. Hiển thị kết quả
```

### Cách 2: Tối Ưu Toàn Bộ (Khuyến Nghị)

```bash
rocketvps
# Chọn: 14) VPS Optimization
# Chọn: 5) Optimize All Services

# Hệ thống sẽ tự động:
1. Tối ưu SWAP
2. Tối ưu Nginx (nếu có)
3. Tối ưu MySQL (nếu có)
4. Tối ưu PostgreSQL (nếu có)
```

### Cách 3: Xem Trạng Thái

```bash
rocketvps
# Chọn: 14) VPS Optimization
# Chọn: 6) View Optimization Status

# Xem:
- SWAP hiện tại
- Nginx worker processes
- MySQL buffer pool
- PostgreSQL shared buffers
- System load
```

### Cách 4: Khôi Phục Cấu Hình Cũ

```bash
rocketvps
# Chọn: 14) VPS Optimization
# Chọn: 7) Restore Default Configurations

# Chọn file backup cần restore
# Có sẵn backup tự động trước mỗi lần thay đổi
```

## 📊 Ví Dụ Cụ Thể

### VPS 1: 1GB RAM, 1 CPU Core

**Trước Tối Ưu:**
- SWAP: 0MB → Website crash khi hết RAM
- MySQL: Default → Chậm, timeout
- Nginx: 1 worker, 512 connections → Giới hạn 512 users đồng thời

**Sau Tối Ưu:**
- SWAP: 2GB → Ổn định hơn
- MySQL Buffer: 700MB, 50 connections → Nhanh hơn 3-5 lần
- Nginx: 1 worker, 1024 connections → Phục vụ 1024 users

**Kết Quả:**
- ✅ Website tải nhanh hơn 50%
- ✅ Giảm lỗi 502/503
- ✅ Xử lý được nhiều traffic hơn

### VPS 2: 4GB RAM, 2 CPU Cores

**Trước Tối Ưu:**
- SWAP: 512MB → Không đủ
- MySQL: 128MB buffer → Quá ít cho 4GB RAM
- Nginx: 1 worker → Lãng phí CPU

**Sau Tối Ưu:**
- SWAP: 4GB → Đủ dùng
- MySQL Buffer: 2.8GB, 150 connections → Tận dụng RAM
- Nginx: 2 workers, 4096 connections → Tận dụng 2 cores

**Kết Quả:**
- ✅ Query database nhanh hơn 5-10 lần
- ✅ Xử lý 8000+ requests/giây (thay vì 2000)
- ✅ CPU sử dụng cân bằng

### VPS 3: 8GB RAM, 4 CPU Cores

**Sau Tối Ưu:**
- SWAP: 4GB (không cần quá nhiều)
- MySQL Buffer: 5.6GB, 200 connections
- Nginx: 4 workers, 8192 connections
- PostgreSQL: 2GB shared buffers, 6GB cache

**Kết Quả:**
- ✅ Có thể chạy 20-30 WordPress sites
- ✅ Xử lý 20,000+ requests/giây
- ✅ Database query < 10ms

## 🎓 Best Practices

### 1. Khi Nào Nên Tối Ưu?

✅ **NÊN tối ưu khi:**
- Mới cài đặt VPS lần đầu
- Nâng cấp RAM/CPU
- Website chạy chậm
- Thường xuyên lỗi 502/503
- CPU/RAM sử dụng cao
- Database query chậm

❌ **KHÔNG NÊN khi:**
- VPS đang chạy ổn định
- Không có vấn đề hiệu suất
- Chưa backup dữ liệu

### 2. Thứ Tự Khuyến Nghị

```bash
# Bước 1: Backup trước (Quan trọng!)
rocketvps → 10) Backup & Restore → 1) Full Backup

# Bước 2: Tối ưu SWAP trước
rocketvps → 14) VPS Optimization → 1) Setup SWAP

# Bước 3: Test hệ thống
# Chạy website 1-2 giờ, xem có lỗi không

# Bước 4: Tối ưu dịch vụ khác
rocketvps → 14) VPS Optimization → 5) Optimize All

# Bước 5: Monitor sau tối ưu
rocketvps → 14) VPS Optimization → 6) View Status
```

### 3. Kiểm Tra Sau Tối Ưu

```bash
# 1. Kiểm tra SWAP
free -h

# 2. Kiểm tra MySQL
systemctl status mysql
mysql -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"

# 3. Kiểm tra Nginx
systemctl status nginx
nginx -t

# 4. Kiểm tra website
curl -I http://yourdomain.com

# 5. Kiểm tra load
top
htop
```

## 🔄 Tối Ưu Theo Loại Website

### WordPress Sites

```bash
# Khuyến nghị:
1. Tối ưu MySQL (Quan trọng nhất!)
2. Tối ưu Nginx với FastCGI cache
3. SWAP = RAM (ổn định)
4. PHP OPcache enabled

# Kết quả mong đợi:
- Page load: < 1 second
- TTFB: < 200ms
- Database query: < 50ms
```

### Laravel/PHP Applications

```bash
# Khuyến nghị:
1. Tối ưu MySQL + Redis cache
2. Tối ưu Nginx
3. PHP 8.2+ với OPcache
4. Composer cache enabled

# Kết quả mong đợi:
- API response: < 100ms
- Queue processing: Fast
- Session handling: Redis
```

### Node.js Applications

```bash
# Khuyến nghị:
1. Tối ưu Nginx (reverse proxy)
2. SWAP = RAM
3. PM2 cluster mode (số CPU cores)

# Kết quả mong đợi:
- High concurrent connections
- Load balancing tự động
```

## ⚠️ Lưu Ý Quan Trọng

### 1. Backup Tự Động
- ✅ Mọi thay đổi đều được backup tự động
- ✅ Backup lưu tại: `/opt/rocketvps/backups/`
- ✅ Format: `service_YYYYMMDD_HHMMSS.conf`

### 2. Rollback An Toàn
```bash
# Nếu có vấn đề, restore ngay:
rocketvps → 14) → 7) Restore Default Configurations
# Chọn file backup gần nhất
```

### 3. Test Trước Production
- ⚠️ Nên test trên staging server trước
- ⚠️ Monitor hệ thống sau khi tối ưu
- ⚠️ Có plan rollback

### 4. Tài Nguyên Tối Thiểu
- MySQL: Cần ít nhất 512MB RAM
- PostgreSQL: Cần ít nhất 512MB RAM
- Nginx: Chạy được với 128MB RAM
- SWAP: Cần ít nhất 1GB disk trống

## 📈 Monitoring Sau Tối Ưu

### 1. Theo Dõi Ngay Lập Tức (5-10 phút đầu)

```bash
# Terminal 1: Watch system resources
watch -n 1 'free -h && echo && uptime'

# Terminal 2: Monitor services
watch -n 2 'systemctl status nginx mysql'

# Terminal 3: Check logs
tail -f /var/log/nginx/error.log
tail -f /var/log/mysql/error.log
```

### 2. Theo Dõi Ngắn Hạn (1-24 giờ)

```bash
# CPU usage
top -b -n 1 | head -20

# Memory usage
free -h

# Disk I/O
iostat -x 1 5

# Network
iftop
```

### 3. Metrics Cần Theo Dõi

| Metric | Trước | Mục Tiêu Sau |
|--------|-------|--------------|
| RAM Usage | 80-90% | 60-70% |
| SWAP Usage | 0% hoặc 100% | 5-15% |
| CPU Load | > 4.0 | < 2.0 |
| MySQL Query Time | > 1s | < 100ms |
| Page Load | > 3s | < 1s |
| Nginx Errors | Nhiều | Gần 0 |

## 🆘 Xử Lý Sự Cố

### Vấn Đề 1: MySQL Không Start

```bash
# Nguyên nhân: InnoDB buffer quá lớn
# Giải pháp:
1. Xem log: tail -f /var/log/mysql/error.log
2. Restore backup
3. Giảm innodb_buffer_pool_size
4. Restart MySQL
```

### Vấn Đề 2: Nginx Configuration Error

```bash
# Test config:
nginx -t

# Nếu lỗi:
rocketvps → 14) → 7) Restore nginx backup

# Hoặc manual:
cp /opt/rocketvps/backups/nginx_YYYYMMDD_*.conf /etc/nginx/nginx.conf
systemctl reload nginx
```

### Vấn Đề 3: SWAP Không Hoạt Động

```bash
# Check:
free -h
swapon --show

# Fix:
swapoff -a
swapon /swapfile
swapon --show

# Make permanent:
echo "/swapfile none swap sw 0 0" >> /etc/fstab
```

### Vấn Đề 4: Website Chậm Hơn Sau Tối Ưu

```bash
# Có thể do:
1. Cache cần warm-up (đợi 5-10 phút)
2. Cấu hình quá cao cho VPS nhỏ
3. Cần restart PHP-FPM

# Giải pháp:
systemctl restart php8.1-fpm  # Thay đổi version
systemctl restart nginx
```

## 📚 Tài Nguyên Tham Khảo

- [MySQL Performance Tuning](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)
- [Nginx Optimization Guide](https://nginx.org/en/docs/)
- [Linux SWAP Management](https://wiki.archlinux.org/title/Swap)
- [PostgreSQL Performance](https://www.postgresql.org/docs/current/performance-tips.html)

## 💡 Tips & Tricks

### 1. Tối Ưu Theo Loại Workload

**High Traffic Website (Nhiều visitors):**
```bash
# Tăng Nginx workers và connections
# Giảm MySQL connections
# Tăng FastCGI cache
```

**Database-Heavy Application:**
```bash
# Tăng MySQL buffer pool (80% RAM)
# Tăng query cache
# Enable slow query log
```

**Static Content Site:**
```bash
# Giảm PHP-FPM processes
# Tăng Nginx file cache
# Enable Gzip compression
```

### 2. Tối Ưu Chi Phí

**VPS 512MB RAM:**
```bash
# Không cài PostgreSQL (nặng)
# Dùng MySQL thay vì MariaDB
# SWAP = 1GB
# Nginx: 1 worker, 512 connections
# MySQL: 256MB buffer
```

**VPS 1GB RAM:**
```bash
# Đủ cho 3-5 WordPress sites
# SWAP = 2GB
# MySQL: 700MB buffer
# Có thể cài Redis
```

### 3. Auto-Optimization Script

```bash
# Tạo cronjob tự động optimize mỗi tuần:
crontab -e

# Thêm dòng:
0 3 * * 0 /opt/rocketvps/scripts/weekly_optimize.sh

# Script content:
#!/bin/bash
echo "Weekly optimization $(date)" >> /var/log/auto-optimize.log
# Gọi các hàm tối ưu từ module
```

---

## 🎉 Kết Luận

Module VPS Optimization giúp bạn:
- ✅ Tối ưu VPS chỉ với vài click
- ✅ Tự động tính toán thông số phù hợp
- ✅ Backup an toàn trước mỗi thay đổi
- ✅ Restore dễ dàng nếu có vấn đề
- ✅ Tăng hiệu suất 3-10 lần
- ✅ Giảm chi phí server

**Bắt đầu ngay:**
```bash
rocketvps
# → 14) VPS Optimization
# → 5) Optimize All Services
```

🚀 **Happy Optimizing!**

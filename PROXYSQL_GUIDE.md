# 🔀 ProxySQL Management Guide

Complete guide for managing ProxySQL - A high-performance MySQL proxy with load balancing, query caching, and intelligent query routing.

## 📋 Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Architecture](#architecture)
- [Server Management](#server-management)
- [User Management](#user-management)
- [Query Rules](#query-rules)
- [Read/Write Split](#readwrite-split)
- [Load Balancing](#load-balancing)
- [Query Caching](#query-caching)
- [Monitoring](#monitoring)
- [Backup & Restore](#backup--restore)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

### What is ProxySQL?

ProxySQL is a high-performance MySQL proxy layer that sits between your application and MySQL servers. It provides:

- **Query Routing**: Intelligently route queries to appropriate servers
- **Load Balancing**: Distribute traffic across multiple MySQL servers
- **Query Caching**: Cache query results to reduce database load
- **Read/Write Split**: Automatically separate read and write operations
- **Failover**: Automatic failover when servers become unavailable
- **Query Rewriting**: Modify queries on-the-fly
- **Connection Pooling**: Efficient connection management

### Key Features

✅ **High Performance**: Written in C++, minimal latency overhead
✅ **Query Statistics**: Detailed metrics for query performance
✅ **Hot Reload**: Apply configuration changes without restart
✅ **MySQL Compatible**: Works with MySQL and MariaDB
✅ **Advanced Routing**: Regex-based query routing rules
✅ **Query Cache**: TTL-based result caching
✅ **Health Monitoring**: Automatic server health checks

### Architecture

```
Application
    ↓
ProxySQL (Port 6033)
    ↓
MySQL Master (Write) ← Hostgroup 0
MySQL Slave 1 (Read) ← Hostgroup 1
MySQL Slave 2 (Read) ← Hostgroup 1
```

## 🚀 Installation

### Option 1: Using RocketVPS Menu

```bash
rocketvps
# Select: 26) ProxySQL (MySQL Proxy)
# Select: 1) Install ProxySQL
```

The installation will:
1. Add ProxySQL official repository
2. Install ProxySQL package
3. Generate random admin credentials
4. Configure admin interface
5. Start ProxySQL service
6. Save credentials to config file

### Option 2: Manual Installation

**Ubuntu/Debian:**
```bash
wget -O - 'https://repo.proxysql.com/ProxySQL/proxysql-2.5.x/repo_pub_key' | apt-key add -
echo "deb https://repo.proxysql.com/ProxySQL/proxysql-2.5.x/$(lsb_release -sc)/ ./" \
    > /etc/apt/sources.list.d/proxysql.list
apt-get update
apt-get install -y proxysql
systemctl start proxysql
systemctl enable proxysql
```

**CentOS/RHEL:**
```bash
cat > /etc/yum.repos.d/proxysql.repo <<'EOF'
[proxysql]
name=ProxySQL YUM repository
baseurl=https://repo.proxysql.com/ProxySQL/proxysql-2.5.x/centos/$releasever
gpgcheck=1
gpgkey=https://repo.proxysql.com/ProxySQL/proxysql-2.5.x/repo_pub_key
EOF

yum install -y proxysql
systemctl start proxysql
systemctl enable proxysql
```

### Configuration Files

After installation, important files:

- **Admin Config**: `/opt/rocketvps/config/proxysql.conf`
- **Database**: `/var/lib/proxysql/proxysql.db`
- **Logs**: `/var/lib/proxysql/proxysql.log`
- **Backups**: `/opt/proxysql/backup/`

### Default Credentials

After installation, save these credentials (displayed once):

```
Admin Interface:
  Host: 127.0.0.1
  Port: 6032
  User: admin
  Password: <randomly_generated>

MySQL Interface:
  Host: 127.0.0.1 or your_server_ip
  Port: 6033
```

## 🖥️ Server Management

### Add MySQL Backend Server

**Via RocketVPS Menu:**
```bash
# Select: 4) Add MySQL Backend Server
# Enter server details:
#   - Hostname/IP
#   - Port (default 3306)
#   - Hostgroup ID (0=writer, 1=reader)
#   - Weight (1-1000)
#   - Max connections
```

**Via MySQL CLI:**
```sql
-- Connect to admin interface
mysql -h127.0.0.1 -P6032 -uadmin -p<your_password>

-- Add master server (write group)
INSERT INTO mysql_servers(hostgroup_id, hostname, port, weight) 
VALUES (0, '10.0.0.1', 3306, 1);

-- Add slave servers (read group)
INSERT INTO mysql_servers(hostgroup_id, hostname, port, weight) 
VALUES (1, '10.0.0.2', 3306, 1);

INSERT INTO mysql_servers(hostgroup_id, hostname, port, weight) 
VALUES (1, '10.0.0.3', 3306, 2); -- Higher weight = more traffic

-- Apply configuration
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

### Configure Server Groups (Replication)

```sql
-- Define writer/reader relationship
INSERT INTO mysql_replication_hostgroups (writer_hostgroup, reader_hostgroup, comment)
VALUES (0, 1, 'Production DB');

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

### List Backend Servers

**Via Menu:**
```bash
# Select: 5) List Backend Servers
```

**Via SQL:**
```sql
-- View configured servers
SELECT * FROM mysql_servers ORDER BY hostgroup_id, hostname;

-- View server status with stats
SELECT hostgroup, srv_host, srv_port, status, Queries, Latency_us 
FROM stats_mysql_connection_pool;
```

### Server Status Meanings

- `ONLINE`: Server is healthy and accepting connections
- `SHUNNED`: Server temporarily unavailable (auto-retry)
- `OFFLINE_SOFT`: Server being drained (no new connections)
- `OFFLINE_HARD`: Server manually disabled

### Remove Backend Server

```sql
DELETE FROM mysql_servers 
WHERE hostname='10.0.0.2' AND port=3306 AND hostgroup_id=1;

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

## 👥 User Management

### Add MySQL User to ProxySQL

**Via Menu:**
```bash
# Select: 9) Add MySQL User
# Enter:
#   - MySQL username
#   - MySQL password
#   - Default hostgroup (0=writer, 1=reader)
#   - Max connections
```

**Via SQL:**
```sql
-- Add user with default routing to writers
INSERT INTO mysql_users(username, password, default_hostgroup, max_connections, active)
VALUES ('app_user', 'SecurePass123', 0, 1000, 1);

-- Add read-only user (defaults to readers)
INSERT INTO mysql_users(username, password, default_hostgroup, max_connections, active)
VALUES ('report_user', 'ReportPass456', 1, 500, 1);

-- Apply configuration
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

### User Configuration Options

```sql
-- Transaction persistent (1 = keep connection during transaction)
UPDATE mysql_users 
SET transaction_persistent=1 
WHERE username='app_user';

-- Fast forward (bypass some routing rules for performance)
UPDATE mysql_users 
SET fast_forward=1 
WHERE username='simple_app';

-- Frontend settings
UPDATE mysql_users 
SET max_connections=2000, 
    use_ssl=1 
WHERE username='app_user';

LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

### List Users

```sql
SELECT username, default_hostgroup, max_connections, active, transaction_persistent 
FROM mysql_users;
```

### Delete User

```sql
DELETE FROM mysql_users WHERE username='old_user';
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

## 📋 Query Rules

Query rules control how ProxySQL routes, caches, rewrites, or blocks queries.

### Rule Execution Order

Rules are matched in order by `rule_id`. First matching rule is applied.

### Add Route Rule

**Route all SELECT queries to read replicas:**
```sql
INSERT INTO mysql_query_rules(rule_id, match_pattern, destination_hostgroup, apply, active)
VALUES (1, '^SELECT', 1, 1, 1);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

### Add Cache Rule

**Cache product queries for 1 hour:**
```sql
INSERT INTO mysql_query_rules(rule_id, match_pattern, cache_ttl, apply, active)
VALUES (2, '^SELECT.*FROM products', 3600000, 1, 1);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

### Add Rewrite Rule

**Force query to use index:**
```sql
INSERT INTO mysql_query_rules(
    rule_id, 
    match_pattern, 
    replace_pattern, 
    apply, 
    active
)
VALUES (
    3, 
    '^SELECT \* FROM users WHERE', 
    'SELECT * FROM users USE INDEX(idx_username) WHERE', 
    1, 
    1
);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

### Add Block Rule

**Block dangerous queries:**
```sql
INSERT INTO mysql_query_rules(
    rule_id, 
    match_pattern, 
    error_msg, 
    apply, 
    active
)
VALUES (
    4, 
    '^(DELETE|DROP|TRUNCATE).*', 
    'Write operations blocked in maintenance mode', 
    1, 
    1
);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

### List Query Rules

```sql
SELECT rule_id, match_pattern, destination_hostgroup, cache_ttl, apply, active 
FROM mysql_query_rules 
ORDER BY rule_id;
```

### Delete Query Rule

```sql
DELETE FROM mysql_query_rules WHERE rule_id=5;
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

## 🔄 Read/Write Split

### Automatic Configuration via Menu

**Via RocketVPS Menu:**
```bash
# Select: 16) Configure Read/Write Split
# This automatically creates rules:
#   - SELECT FOR UPDATE → Writers (hostgroup 0)
#   - SELECT → Readers (hostgroup 1)
#   - INSERT/UPDATE/DELETE → Writers (hostgroup 0)
```

### Manual Configuration

**Step 1: Configure hostgroups**
```sql
INSERT INTO mysql_replication_hostgroups (writer_hostgroup, reader_hostgroup)
VALUES (0, 1);
```

**Step 2: Add servers**
```sql
-- Master (writes)
INSERT INTO mysql_servers(hostgroup_id, hostname, port) 
VALUES (0, 'master.db.local', 3306);

-- Slaves (reads)
INSERT INTO mysql_servers(hostgroup_id, hostname, port) 
VALUES (1, 'slave1.db.local', 3306);

INSERT INTO mysql_servers(hostgroup_id, hostname, port) 
VALUES (1, 'slave2.db.local', 3306);

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

**Step 3: Create routing rules**
```sql
-- Priority 1: SELECT FOR UPDATE to master
INSERT INTO mysql_query_rules(rule_id, match_pattern, destination_hostgroup, apply, active)
VALUES (1, '^SELECT.*FOR UPDATE', 0, 1, 1);

-- Priority 2: All SELECT to slaves
INSERT INTO mysql_query_rules(rule_id, match_pattern, destination_hostgroup, apply, active)
VALUES (2, '^SELECT', 1, 1, 1);

-- Priority 3: Writes to master (explicit)
INSERT INTO mysql_query_rules(rule_id, match_pattern, destination_hostgroup, apply, active)
VALUES (3, '^(INSERT|UPDATE|DELETE)', 0, 1, 1);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

**Step 4: Configure users**
```sql
-- Users default to writer group, rules will override
INSERT INTO mysql_users(username, password, default_hostgroup)
VALUES ('app_user', 'password', 0);

LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

### Verify Read/Write Split

```sql
-- Check query routing stats
SELECT hostgroup, schemaname, username, digest_text, count_star
FROM stats_mysql_query_digest
ORDER BY count_star DESC;

-- Check connection distribution
SELECT hostgroup, srv_host, Queries
FROM stats_mysql_connection_pool;
```

### Test from Application

```bash
# Connect to ProxySQL instead of direct MySQL
mysql -h proxy_host -P6033 -uapp_user -p

# Run queries - they'll be automatically routed
mysql> SELECT * FROM users WHERE id=1;  -- Routed to slave
mysql> SELECT * FROM users FOR UPDATE;   -- Routed to master
mysql> UPDATE users SET name='test';     -- Routed to master
```

## ⚖️ Load Balancing

### Weight-Based Load Balancing

```sql
-- Higher weight = more traffic
UPDATE mysql_servers SET weight=10 WHERE hostname='slave1.db.local';
UPDATE mysql_servers SET weight=5 WHERE hostname='slave2.db.local';

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

**Result:** slave1 receives ~67% traffic, slave2 receives ~33% traffic

### Connection Pooling

```sql
-- Set max connections per backend server
UPDATE mysql_servers SET max_connections=1000 
WHERE hostgroup_id=1;

-- Global connection pool settings
UPDATE global_variables 
SET variable_value='2000' 
WHERE variable_name='mysql-max_connections';

UPDATE global_variables 
SET variable_value='10' 
WHERE variable_name='mysql-connect_timeout_server_max';

LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
```

### Verify Load Distribution

```sql
-- Check queries per server
SELECT hostgroup, srv_host, srv_port, Queries, Bytes_data_sent
FROM stats_mysql_connection_pool
ORDER BY hostgroup, Queries DESC;
```

## 💾 Query Caching

### Enable Global Query Cache

```sql
-- Set default cache TTL (milliseconds)
UPDATE global_variables 
SET variable_value='60000' 
WHERE variable_name='mysql-default_query_timeout';

LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
```

### Add Cacheable Query Rules

**Cache product catalog (1 hour):**
```sql
INSERT INTO mysql_query_rules(
    rule_id, 
    match_pattern, 
    cache_ttl, 
    apply, 
    active
)
VALUES (10, '^SELECT.*FROM products.*', 3600000, 1, 1);
```

**Cache user profiles (5 minutes):**
```sql
INSERT INTO mysql_query_rules(
    rule_id, 
    match_pattern, 
    cache_ttl, 
    apply, 
    active
)
VALUES (11, '^SELECT.*FROM user_profiles.*', 300000, 1, 1);
```

**Apply rules:**
```sql
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

### View Cache Statistics

```sql
-- Check cache hit rate
SELECT * FROM stats_mysql_global 
WHERE Variable_Name LIKE '%cache%';

-- Query-level cache stats
SELECT 
    hostgroup, 
    digest_text, 
    count_star, 
    sum_time,
    count_star / sum_time as efficiency
FROM stats_mysql_query_digest 
WHERE digest_text LIKE '%cache%'
ORDER BY count_star DESC;
```

### Clear Query Cache

```bash
# Via menu
# Select: 24) Configure Query Cache
# Or via SQL:
```

```sql
-- ProxySQL auto-manages cache, but you can disable rules
UPDATE mysql_query_rules SET active=0 WHERE cache_ttl > 0;
LOAD MYSQL QUERY RULES TO RUNTIME;
```

## 📊 Monitoring

### View ProxySQL Status

**Via Menu:**
```bash
# Select: 17) View ProxySQL Status
```

**Via CLI:**
```bash
systemctl status proxysql
proxysql --version
```

### Connection Statistics

```sql
-- Frontend connections (from apps)
SELECT * FROM stats_mysql_global 
WHERE Variable_Name LIKE 'Client_%';

-- Backend connections (to MySQL servers)
SELECT 
    hostgroup, 
    srv_host, 
    status, 
    ConnUsed, 
    ConnFree, 
    Queries,
    Bytes_data_sent,
    Latency_us
FROM stats_mysql_connection_pool;
```

### Query Performance Statistics

```sql
-- Top queries by count
SELECT 
    hostgroup, 
    username,
    digest_text, 
    count_star, 
    sum_time,
    sum_time/count_star as avg_time_us
FROM stats_mysql_query_digest 
ORDER BY count_star DESC 
LIMIT 20;

-- Slow queries (avg > 1 second)
SELECT 
    hostgroup,
    digest_text, 
    count_star,
    sum_time/count_star as avg_time_us
FROM stats_mysql_query_digest 
WHERE sum_time/count_star > 1000000 
ORDER BY avg_time_us DESC;
```

### Server Health Monitoring

```sql
-- Check server health
SELECT 
    hostgroup_id,
    hostname,
    port,
    status,
    weight,
    max_connections
FROM mysql_servers;

-- Connection pool status
SELECT 
    hostgroup,
    srv_host,
    status,
    ConnUsed,
    ConnFree,
    Latency_us
FROM stats_mysql_connection_pool;
```

### Error Monitoring

**View logs:**
```bash
tail -f /var/lib/proxysql/proxysql.log

# Or via menu
# Select: 20) View Error Log
```

**Query errors in SQL:**
```sql
SELECT * FROM stats_mysql_global 
WHERE Variable_Name LIKE '%error%';
```

### Real-Time Monitoring Dashboard

```sql
-- Create monitoring script
cat > /opt/proxysql/monitor.sh <<'EOF'
#!/bin/bash
while true; do
  clear
  echo "=== ProxySQL Status ==="
  date
  echo ""
  echo "Backend Servers:"
  mysql -h127.0.0.1 -P6032 -uadmin -p$ADMIN_PASS -e \
    "SELECT hostgroup, srv_host, status, Queries, Latency_us FROM stats_mysql_connection_pool;"
  
  echo ""
  echo "Top Queries:"
  mysql -h127.0.0.1 -P6032 -uadmin -p$ADMIN_PASS -e \
    "SELECT digest_text, count_star FROM stats_mysql_query_digest ORDER BY count_star DESC LIMIT 10;"
  
  sleep 5
done
EOF

chmod +x /opt/proxysql/monitor.sh
```

## 💾 Backup & Restore

### Backup Configuration

**Via Menu:**
```bash
# Select: 26) Backup Configuration
# Backup saved to: /opt/proxysql/backup/proxysql_config_YYYYMMDD_HHMMSS.sql
```

**Manual backup:**
```bash
# Backup SQLite database
cp /var/lib/proxysql/proxysql.db /opt/proxysql/backup/proxysql_$(date +%Y%m%d).db

# Export configuration as SQL
mysql -h127.0.0.1 -P6032 -uadmin -p <<EOF > /opt/proxysql/backup/config.sql
SELECT * FROM mysql_servers;
SELECT * FROM mysql_users;
SELECT * FROM mysql_query_rules;
SELECT * FROM mysql_replication_hostgroups;
SELECT * FROM global_variables;
EOF
```

### Restore Configuration

**Via Menu:**
```bash
# Select: 27) Restore Configuration
# Select backup file to restore
```

**Manual restore:**
```bash
# Stop ProxySQL
systemctl stop proxysql

# Restore database
cp /opt/proxysql/backup/proxysql_20240101.db /var/lib/proxysql/proxysql.db

# Start ProxySQL
systemctl start proxysql
```

### Scheduled Backups

```bash
# Add to crontab
crontab -e

# Backup daily at 2 AM
0 2 * * * cp /var/lib/proxysql/proxysql.db /opt/proxysql/backup/proxysql_$(date +\%Y\%m\%d).db

# Cleanup old backups (keep 30 days)
0 3 * * * find /opt/proxysql/backup -name "proxysql_*.db" -mtime +30 -delete
```

## 🎯 Best Practices

### 1. Security

**✅ DO:**
- Change default admin password immediately
- Restrict admin interface to localhost (127.0.0.1)
- Use strong passwords for MySQL users
- Enable SSL for backend connections if sensitive data
- Regularly backup configuration

**❌ DON'T:**
- Expose admin interface (port 6032) to public internet
- Use same password for admin and MySQL users
- Store passwords in plain text in scripts

### 2. Performance

**✅ DO:**
- Set appropriate connection pool sizes
- Use query caching for read-heavy workloads
- Monitor query performance regularly
- Set appropriate server weights for load distribution
- Use transaction persistent for applications with many transactions

**❌ DON'T:**
- Set connection pools too small (causes bottlenecks)
- Cache queries that change frequently
- Ignore slow query logs
- Use equal weights if servers have different capacity

### 3. High Availability

**✅ DO:**
- Configure health checks for automatic failover
- Use multiple read replicas
- Test failover scenarios
- Monitor server health continuously
- Keep ProxySQL updated

**❌ DON'T:**
- Rely on single slave for reads
- Ignore SHUNNED server alerts
- Skip testing disaster recovery
- Run outdated versions

### 4. Query Routing

**✅ DO:**
- Order rules by specificity (most specific first)
- Test rules before applying to production
- Document rule purposes
- Use regex carefully (performance impact)
- Route SELECT FOR UPDATE to master

**❌ DON'T:**
- Create overlapping rules without clear precedence
- Use overly complex regex patterns
- Route writes to read replicas
- Forget to reload after changes

### 5. Monitoring

**✅ DO:**
- Monitor query latency
- Track connection pool utilization
- Alert on SHUNNED servers
- Review slow query logs weekly
- Track cache hit rates

**❌ DON'T:**
- Ignore warning signs (high latency, errors)
- Run without monitoring in production
- Disable logging completely
- Forget to rotate logs

## 🔧 Troubleshooting

### Issue: Can't Connect to ProxySQL

**Symptoms:**
```
ERROR 1045 (28000): Access denied for user 'app_user'@'localhost' (using password: YES)
```

**Solutions:**
```sql
-- 1. Verify user exists in ProxySQL
SELECT * FROM mysql_users WHERE username='app_user';

-- 2. Verify user is active
UPDATE mysql_users SET active=1 WHERE username='app_user';
LOAD MYSQL USERS TO RUNTIME;

-- 3. Check ProxySQL is running
systemctl status proxysql

-- 4. Check port is open
netstat -tlnp | grep 6033
```

### Issue: Queries Routing to Wrong Server

**Symptoms:**
Writes going to slaves, reads going to master

**Solutions:**
```sql
-- 1. Check query rules order
SELECT rule_id, match_pattern, destination_hostgroup 
FROM mysql_query_rules 
ORDER BY rule_id;

-- 2. Check which rule matched
SELECT digest_text, match_digest 
FROM stats_mysql_query_digest 
WHERE digest_text LIKE '%YOUR_QUERY%';

-- 3. Verify server groups
SELECT * FROM mysql_replication_hostgroups;

-- 4. Check server assignments
SELECT hostgroup_id, hostname FROM mysql_servers;
```

### Issue: Server Marked as SHUNNED

**Symptoms:**
```
srv_host: db1.local
status: SHUNNED
```

**Causes & Solutions:**

1. **Server is down**
   ```bash
   # Check server is accessible
   ping db1.local
   mysql -h db1.local -u user -p
   ```

2. **Too many connection errors**
   ```sql
   -- Check error counts
   SELECT * FROM stats_mysql_connection_pool 
   WHERE srv_host='db1.local';
   
   -- Increase error threshold
   UPDATE global_variables 
   SET variable_value='10' 
   WHERE variable_name='mysql-shun_on_failures';
   
   LOAD MYSQL VARIABLES TO RUNTIME;
   ```

3. **Health check failing**
   ```sql
   -- Check monitor settings
   SELECT * FROM global_variables 
   WHERE variable_name LIKE 'mysql-monitor%';
   
   -- Verify monitor user exists on backend
   -- mysql> GRANT USAGE ON *.* TO 'monitor'@'%';
   ```

### Issue: High Latency

**Symptoms:**
Queries slower through ProxySQL than direct

**Solutions:**

1. **Check backend server latency**
   ```sql
   SELECT hostgroup, srv_host, Latency_us 
   FROM stats_mysql_connection_pool;
   ```

2. **Increase connection pool**
   ```sql
   UPDATE global_variables 
   SET variable_value='1000' 
   WHERE variable_name='mysql-max_connections';
   
   LOAD MYSQL VARIABLES TO RUNTIME;
   ```

3. **Check for query pileup**
   ```sql
   SELECT digest_text, count_star, sum_time 
   FROM stats_mysql_query_digest 
   ORDER BY sum_time DESC 
   LIMIT 10;
   ```

4. **Verify no CPU/memory bottleneck**
   ```bash
   top -p $(pidof proxysql)
   ```

### Issue: Configuration Not Persisting

**Symptoms:**
Changes lost after restart

**Solution:**
```sql
-- Always save after loading to runtime
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;  -- <-- Don't forget this!

LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

### Issue: Cache Not Working

**Symptoms:**
All queries hitting database

**Solutions:**

1. **Verify cache rules exist**
   ```sql
   SELECT rule_id, match_pattern, cache_ttl 
   FROM mysql_query_rules 
   WHERE cache_ttl > 0;
   ```

2. **Check cache is enabled**
   ```sql
   SELECT * FROM global_variables 
   WHERE variable_name LIKE '%cache%';
   ```

3. **Verify queries match pattern**
   ```sql
   -- Test pattern matching
   SELECT * FROM stats_mysql_query_digest 
   WHERE digest_text LIKE '%your_table%';
   ```

### Issue: Lost Admin Password

**Solution:**
```bash
# Stop ProxySQL
systemctl stop proxysql

# Remove ProxySQL database
rm /var/lib/proxysql/proxysql.db

# Start ProxySQL (creates new DB with default admin/admin)
systemctl start proxysql

# Connect with default credentials
mysql -h127.0.0.1 -P6032 -uadmin -padmin

# Change password immediately
UPDATE global_variables 
SET variable_value='admin:NewSecurePassword' 
WHERE variable_name='admin-admin_credentials';

LOAD ADMIN VARIABLES TO RUNTIME;
SAVE ADMIN VARIABLES TO DISK;
```

### Enable Debug Logging

```sql
-- Enable query logging
SET mysql-eventslog_filename='/var/lib/proxysql/queries.log';
SET mysql-eventslog_default_log=1;

LOAD MYSQL VARIABLES TO RUNTIME;

-- View queries in real-time
tail -f /var/lib/proxysql/queries.log
```

## 📚 Advanced Scenarios

### Multi-Datacenter Setup

```sql
-- Datacenter 1 (primary)
INSERT INTO mysql_servers(hostgroup_id, hostname, port, weight) 
VALUES (0, 'dc1-master', 3306, 10);

INSERT INTO mysql_servers(hostgroup_id, hostname, port, weight) 
VALUES (1, 'dc1-slave1', 3306, 10);

-- Datacenter 2 (secondary)
INSERT INTO mysql_servers(hostgroup_id, hostname, port, weight) 
VALUES (1, 'dc2-slave1', 3306, 5);  -- Lower weight = less traffic

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

### Application-Specific Routing

```sql
-- Route analytics queries to dedicated server
INSERT INTO mysql_query_rules(
    rule_id, 
    username, 
    match_pattern, 
    destination_hostgroup
)
VALUES (100, 'analytics_user', '.*', 2);

-- Add analytics-specific server
INSERT INTO mysql_servers(hostgroup_id, hostname, port) 
VALUES (2, 'analytics-slave', 3306);

LOAD MYSQL SERVERS TO RUNTIME;
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
SAVE MYSQL QUERY RULES TO DISK;
```

### Maintenance Mode

```sql
-- Block all writes
INSERT INTO mysql_query_rules(
    rule_id, 
    match_pattern, 
    error_msg, 
    apply, 
    active
)
VALUES (
    999, 
    '^(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER)', 
    'System in maintenance mode', 
    1, 
    1
);

LOAD MYSQL QUERY RULES TO RUNTIME;

-- Re-enable after maintenance
DELETE FROM mysql_query_rules WHERE rule_id=999;
LOAD MYSQL QUERY RULES TO RUNTIME;
```

## 📖 Additional Resources

- **Official Documentation**: https://proxysql.com/documentation/
- **GitHub Repository**: https://github.com/sysown/proxysql
- **Community Forum**: https://proxysql.com/forum/
- **Blog**: https://proxysql.com/blog/

## 🤝 Support

For issues or questions:
1. Check this guide first
2. Review ProxySQL logs: `/var/lib/proxysql/proxysql.log`
3. Check RocketVPS logs: `/opt/rocketvps/logs/rocketvps.log`
4. Visit ProxySQL documentation
5. Contact RocketVPS support

---

**Last Updated**: 2024
**ProxySQL Version**: 2.5.x
**RocketVPS Version**: 2.0.0

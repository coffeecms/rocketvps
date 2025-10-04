# ProxySQL Quick Reference

## 🚀 Quick Start

### Connect to Admin Interface
```bash
# Read credentials from config
cat /opt/rocketvps/config/proxysql.conf

# Connect
mysql -h127.0.0.1 -P6032 -uadmin -p<password>
```

### Connect Application to ProxySQL
```bash
# Instead of connecting directly to MySQL:
mysql -h your_mysql_server -P3306 -uapp_user -p

# Connect through ProxySQL:
mysql -h your_proxysql_server -P6033 -uapp_user -p
```

## 📋 Essential Commands

### Backend Servers

```sql
-- Add server
INSERT INTO mysql_servers(hostgroup_id, hostname, port, weight) 
VALUES (0, '10.0.0.1', 3306, 1);
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

-- List servers
SELECT * FROM mysql_servers;

-- Check server status
SELECT hostgroup, srv_host, status, Queries FROM stats_mysql_connection_pool;

-- Remove server
DELETE FROM mysql_servers WHERE hostname='10.0.0.1';
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

### Users

```sql
-- Add user
INSERT INTO mysql_users(username, password, default_hostgroup) 
VALUES ('app_user', 'password', 0);
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;

-- List users
SELECT username, default_hostgroup, max_connections FROM mysql_users;

-- Delete user
DELETE FROM mysql_users WHERE username='app_user';
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

### Query Rules

```sql
-- Route SELECT to readers (hostgroup 1)
INSERT INTO mysql_query_rules(rule_id, match_pattern, destination_hostgroup, apply, active)
VALUES (1, '^SELECT', 1, 1, 1);

-- Route writes to writers (hostgroup 0)
INSERT INTO mysql_query_rules(rule_id, match_pattern, destination_hostgroup, apply, active)
VALUES (2, '^(INSERT|UPDATE|DELETE)', 0, 1, 1);

-- Cache query for 1 hour
INSERT INTO mysql_query_rules(rule_id, match_pattern, cache_ttl, apply, active)
VALUES (3, '^SELECT.*FROM products', 3600000, 1, 1);

-- Apply rules
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;

-- List rules
SELECT rule_id, match_pattern, destination_hostgroup, cache_ttl FROM mysql_query_rules;
```

### Monitoring

```sql
-- Top queries
SELECT digest_text, count_star, sum_time/count_star as avg_time 
FROM stats_mysql_query_digest 
ORDER BY count_star DESC LIMIT 20;

-- Connection stats
SELECT * FROM stats_mysql_connection_pool;

-- Global stats
SELECT * FROM stats_mysql_global;

-- Cache stats
SELECT * FROM stats_mysql_query_cache;
```

## 🔄 Read/Write Split Setup

### Step 1: Configure Replication Groups
```sql
INSERT INTO mysql_replication_hostgroups (writer_hostgroup, reader_hostgroup)
VALUES (0, 1);
```

### Step 2: Add Servers
```sql
-- Master (writes)
INSERT INTO mysql_servers(hostgroup_id, hostname, port) 
VALUES (0, 'master.db', 3306);

-- Slaves (reads)
INSERT INTO mysql_servers(hostgroup_id, hostname, port) 
VALUES (1, 'slave1.db', 3306), (1, 'slave2.db', 3306);

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

### Step 3: Create Rules
```sql
-- SELECT FOR UPDATE to master
INSERT INTO mysql_query_rules(rule_id, match_pattern, destination_hostgroup, apply)
VALUES (1, '^SELECT.*FOR UPDATE', 0, 1);

-- All SELECT to slaves
INSERT INTO mysql_query_rules(rule_id, match_pattern, destination_hostgroup, apply)
VALUES (2, '^SELECT', 1, 1);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

## ⚡ Performance Tuning

```sql
-- Connection pool
UPDATE global_variables SET variable_value='2000' 
WHERE variable_name='mysql-max_connections';

-- Connection timeout
UPDATE global_variables SET variable_value='10000' 
WHERE variable_name='mysql-connect_timeout_server_max';

-- Query timeout
UPDATE global_variables SET variable_value='3600000' 
WHERE variable_name='mysql-default_query_timeout';

-- Apply changes
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
```

## 🔧 Common Tasks

### Reload Configuration
```sql
LOAD MYSQL SERVERS TO RUNTIME;
LOAD MYSQL USERS TO RUNTIME;
LOAD MYSQL QUERY RULES TO RUNTIME;
LOAD MYSQL VARIABLES TO RUNTIME;
```

### Save Configuration
```sql
SAVE MYSQL SERVERS TO DISK;
SAVE MYSQL USERS TO DISK;
SAVE MYSQL QUERY RULES TO DISK;
SAVE MYSQL VARIABLES TO DISK;
```

### View Configuration
```sql
-- Runtime config
SELECT * FROM runtime_mysql_servers;
SELECT * FROM runtime_mysql_users;
SELECT * FROM runtime_mysql_query_rules;

-- Disk config
SELECT * FROM mysql_servers;
SELECT * FROM mysql_users;
SELECT * FROM mysql_query_rules;
```

### Backup
```bash
# Backup database
cp /var/lib/proxysql/proxysql.db /opt/proxysql/backup/proxysql_$(date +%Y%m%d).db

# Or use RocketVPS menu: 26) Backup Configuration
```

### Restart ProxySQL
```bash
systemctl restart proxysql

# Or via menu: 30) Restart ProxySQL
```

## 📊 Monitoring Queries

### Identify Slow Queries
```sql
SELECT 
    digest_text, 
    count_star,
    sum_time/count_star as avg_time_us
FROM stats_mysql_query_digest 
WHERE sum_time/count_star > 1000000  -- Slower than 1 second
ORDER BY avg_time_us DESC;
```

### Check Server Load Distribution
```sql
SELECT 
    hostgroup, 
    srv_host, 
    Queries, 
    Bytes_data_sent,
    Latency_us
FROM stats_mysql_connection_pool
ORDER BY hostgroup, Queries DESC;
```

### Monitor Connection Pool
```sql
SELECT 
    srv_host,
    status,
    ConnUsed,
    ConnFree,
    Queries
FROM stats_mysql_connection_pool;
```

## 🚨 Troubleshooting

### Server is SHUNNED
```sql
-- Check error count
SELECT * FROM mysql_server_connect_log ORDER BY time_start_us DESC LIMIT 10;

-- Increase shun threshold
UPDATE global_variables SET variable_value='10' 
WHERE variable_name='mysql-shun_on_failures';
LOAD MYSQL VARIABLES TO RUNTIME;

-- Manual recovery (if needed)
UPDATE mysql_servers SET status='ONLINE' WHERE hostname='problematic_server';
LOAD MYSQL SERVERS TO RUNTIME;
```

### Queries Not Routing Correctly
```sql
-- Check which rule matched
SELECT rule_id, match_pattern, destination_hostgroup 
FROM stats_mysql_query_rules 
WHERE hits > 0 
ORDER BY hits DESC;

-- View query digest to see routing
SELECT hostgroup, digest_text, count_star 
FROM stats_mysql_query_digest 
ORDER BY count_star DESC;
```

### High Latency
```bash
# Check ProxySQL CPU/memory
top -p $(pidof proxysql)

# Check backend latency
mysql -h127.0.0.1 -P6032 -uadmin -p -e \
  "SELECT hostgroup, srv_host, Latency_us FROM stats_mysql_connection_pool;"

# Check for connection pool exhaustion
mysql -h127.0.0.1 -P6032 -uadmin -p -e \
  "SELECT srv_host, ConnUsed, ConnFree FROM stats_mysql_connection_pool;"
```

## 🎯 Best Practices

✅ **Always save to disk** after loading to runtime
✅ **Order query rules** by specificity (most specific first)
✅ **Monitor server health** regularly
✅ **Backup configuration** before major changes
✅ **Test failover** scenarios
✅ **Use connection pooling** efficiently
✅ **Cache read-heavy queries**
✅ **Set appropriate server weights**

❌ **Don't expose admin port** (6032) to public
❌ **Don't forget SAVE TO DISK**
❌ **Don't use overly complex regex** in rules
❌ **Don't ignore SHUNNED alerts**
❌ **Don't route writes to slaves**

## 📞 Port Reference

- **6032**: Admin interface (localhost only)
- **6033**: MySQL interface (applications connect here)
- **6080**: Web interface (if enabled)

## 🔗 Useful Links

- Full Guide: `/opt/rocketvps/PROXYSQL_GUIDE.md`
- Official Docs: https://proxysql.com/documentation/
- GitHub: https://github.com/sysown/proxysql

---

**RocketVPS Version**: 2.0.0

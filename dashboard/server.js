#!/usr/bin/env node

/**
 * RocketVPS v2.2.0 - Web Dashboard Server with Authentication
 * 
 * Description: Express server with RESTful API, WebSocket, and JWT auth
 * Version: 2.2.0
 * Phase: Phase 2 Week 11-12
 */

require('dotenv').config();
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const { exec } = require('child_process');
const { promisify } = require('util');
const fs = require('fs').promises;
const path = require('path');

// Import authentication module
const auth = require('./auth');

const execAsync = promisify(exec);

// ==============================================================================
// CONFIGURATION
// ==============================================================================

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';
const ROCKETVPS_PATH = process.env.ROCKETVPS_PATH || '/opt/rocketvps';

// ==============================================================================
// EXPRESS APP SETUP
// ==============================================================================

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: process.env.CORS_ORIGIN || '*',
        methods: ['GET', 'POST'],
        credentials: true
    }
});

// Middleware
app.use(helmet({
    contentSecurityPolicy: false  // Allow inline scripts for dashboard
}));
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true
}));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(cookieParser());

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// ==============================================================================
// INITIALIZE AUTHENTICATION
// ==============================================================================

// Initialize users database
auth.initializeUsers().catch(err => {
    console.error('❌ Failed to initialize auth:', err.message);
});

// ==============================================================================
// UTILITY FUNCTIONS
// ==============================================================================

/**
 * Execute bash command and return output
 */
async function runCommand(command) {
    try {
        const { stdout, stderr } = await execAsync(command);
        if (stderr && !stdout) {
            throw new Error(stderr);
        }
        return { success: true, output: stdout.trim(), error: null };
    } catch (error) {
        return { success: false, output: null, error: error.message };
    }
}

/**
 * Source RocketVPS modules and run function
 */
async function runRocketVPSFunction(moduleName, functionName, args = []) {
    const argsStr = args.map(arg => `"${arg}"`).join(' ');
    const command = `bash -c 'source ${ROCKETVPS_PATH}/modules/${moduleName}.sh && ${functionName} ${argsStr}'`;
    return await runCommand(command);
}

/**
 * Read JSON file
 */
async function readJsonFile(filePath) {
    try {
        const data = await fs.readFile(filePath, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        return null;
    }
}

/**
 * Write JSON file
 */
async function writeJsonFile(filePath, data) {
    try {
        await fs.writeFile(filePath, JSON.stringify(data, null, 2));
        return true;
    } catch (error) {
        return false;
    }
}

// ==============================================================================
// API ROUTES - AUTHENTICATION
// ==============================================================================

/**
 * POST /api/auth/login - User login
 */
app.post('/api/auth/login', auth.handleLogin);

/**
 * POST /api/auth/logout - User logout
 */
app.post('/api/auth/logout', auth.authenticate, auth.handleLogout);

/**
 * POST /api/auth/refresh - Refresh access token
 */
app.post('/api/auth/refresh', auth.handleRefresh);

/**
 * GET /api/auth/user - Get current user
 */
app.get('/api/auth/user', auth.authenticate, auth.handleGetUser);

/**
 * POST /api/auth/change-password - Change password
 */
app.post('/api/auth/change-password', auth.authenticate, auth.handleChangePassword);

/**
 * POST /api/auth/users - Create user (admin only)
 */
app.post('/api/auth/users', auth.authenticate, auth.requireAdmin, auth.handleCreateUser);

/**
 * GET /api/auth/users - List all users (admin only)
 */
app.get('/api/auth/users', auth.authenticate, auth.requireAdmin, auth.handleListUsers);

/**
 * DELETE /api/auth/users/:username - Delete user (admin only)
 */
app.delete('/api/auth/users/:username', auth.authenticate, auth.requireAdmin, auth.handleDeleteUser);

// ==============================================================================
// API ROUTES - DOMAINS
// ==============================================================================

/**
 * GET /api/domains - List all domains
 */
app.get('/api/domains', auth.authenticate, async (req, res) => {
    try {
        const result = await runRocketVPSFunction('bulk_operations', 'discover_all_domains');
        if (result.success) {
            const domains = result.output.split('\n').filter(d => d.trim());
            res.json({ success: true, domains, count: domains.length });
        } else {
            res.status(500).json({ success: false, error: result.error });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * GET /api/domains/:domain - Get domain details
 */
app.get('/api/domains/:domain', auth.authenticate, async (req, res) => {
    try {
        const { domain } = req.params;
        
        // Get domain info
        const typeResult = await runRocketVPSFunction('auto_detect', 'detect_site_type', [domain]);
        const sizeResult = await runCommand(`du -sh /home/${domain} 2>/dev/null | awk '{print $1}'`);
        
        // Get health status
        const healthResult = await runRocketVPSFunction('health_monitor', 'check_domain_health', [domain]);
        
        res.json({
            success: true,
            domain: {
                name: domain,
                type: typeResult.success ? typeResult.output : 'UNKNOWN',
                size: sizeResult.success ? sizeResult.output : 'N/A',
                health: healthResult.success ? 'OK' : 'WARNING'
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * POST /api/domains/:domain/backup - Backup domain
 */
app.post('/api/domains/:domain/backup', auth.authenticate, async (req, res) => {
    try {
        const { domain } = req.params;
        const { type } = req.body || {};
        
        const result = await runRocketVPSFunction('smart_backup', 'smart_backup', [
            domain,
            type || 'auto'
        ]);
        
        if (result.success) {
            res.json({ 
                success: true, 
                message: `Backup started for ${domain}`,
                output: result.output
            });
        } else {
            res.status(500).json({ success: false, error: result.error });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * POST /api/domains/:domain/restore - Restore domain
 */
app.post('/api/domains/:domain/restore', auth.authenticate, async (req, res) => {
    try {
        const { domain } = req.params;
        const { backup_file } = req.body || {};
        
        if (!backup_file) {
            return res.status(400).json({ success: false, error: 'backup_file required' });
        }
        
        const result = await runRocketVPSFunction('restore', 'restore_site', [
            domain,
            backup_file
        ]);
        
        if (result.success) {
            res.json({ 
                success: true, 
                message: `Restore started for ${domain}`,
                output: result.output
            });
        } else {
            res.status(500).json({ success: false, error: result.error });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// ==============================================================================
// API ROUTES - HEALTH MONITORING
// ==============================================================================

/**
 * GET /api/health/system - Get system health
 */
app.get('/api/health/system', auth.authenticate, async (req, res) => {
    try {
        const healthFile = path.join(ROCKETVPS_PATH, 'data', 'health_status.json');
        const healthData = await readJsonFile(healthFile) || {};
        
        res.json({ 
            success: true, 
            health: healthData 
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * GET /api/health/domains - Get all domains health
 */
app.get('/api/health/domains', auth.authenticate, async (req, res) => {
    try {
        const result = await runRocketVPSFunction('health_monitor', 'check_all_domains_health');
        
        if (result.success) {
            // Parse health results
            const lines = result.output.split('\n').filter(l => l.trim());
            const domains = lines.map(line => {
                const parts = line.split(':');
                return {
                    domain: parts[0],
                    status: parts[1] || 'UNKNOWN'
                };
            });
            
            res.json({ success: true, domains });
        } else {
            res.status(500).json({ success: false, error: result.error });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * POST /api/health/check - Run health check
 */
app.post('/api/health/check', auth.authenticate, async (req, res) => {
    try {
        const { domain, type } = req.body || {};
        
        if (!domain) {
            return res.status(400).json({ success: false, error: 'domain required' });
        }
        
        const result = await runRocketVPSFunction('health_monitor', 'check_domain_health', [
            domain,
            type || 'all'
        ]);
        
        if (result.success) {
            res.json({ 
                success: true, 
                message: `Health check completed for ${domain}`,
                result: result.output
            });
        } else {
            res.status(500).json({ success: false, error: result.error });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// ==============================================================================
// API ROUTES - BULK OPERATIONS
// ==============================================================================

/**
 * POST /api/bulk/backup - Bulk backup domains
 */
app.post('/api/bulk/backup', auth.authenticate, async (req, res) => {
    try {
        const { filter_type, filter_value, backup_type, parallel } = req.body || {};
        
        const args = [
            filter_type || 'all',
            filter_value || '',
            backup_type || 'auto',
            parallel || '4'
        ];
        
        // Start bulk backup in background
        const result = await runRocketVPSFunction('bulk_operations', 'bulk_backup_filtered', args);
        
        if (result.success) {
            res.json({ 
                success: true, 
                message: 'Bulk backup started',
                output: result.output
            });
        } else {
            res.status(500).json({ success: false, error: result.error });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * GET /api/bulk/progress - Get bulk operation progress
 */
app.get('/api/bulk/progress', auth.authenticate, async (req, res) => {
    try {
        const progressFile = path.join(ROCKETVPS_PATH, 'data', 'bulk_progress.json');
        const progressData = await readJsonFile(progressFile) || {
            total: 0,
            completed: 0,
            failed: 0,
            percentage: 0
        };
        
        res.json({ 
            success: true, 
            progress: progressData 
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * GET /api/bulk/results - Get bulk operation results
 */
app.get('/api/bulk/results', auth.authenticate, async (req, res) => {
    try {
        const resultsFile = path.join(ROCKETVPS_PATH, 'data', 'bulk_results.json');
        const resultsData = await readJsonFile(resultsFile) || {
            operations: [],
            summary: {}
        };
        
        res.json({ 
            success: true, 
            results: resultsData 
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// ==============================================================================
// API ROUTES - STATISTICS
// ==============================================================================

/**
 * GET /api/stats/overview - Get dashboard overview statistics
 */
app.get('/api/stats/overview', auth.authenticate, async (req, res) => {
    try {
        // Get total domains
        const domainsResult = await runRocketVPSFunction('bulk_operations', 'discover_all_domains');
        const domains = domainsResult.success ? domainsResult.output.split('\n').filter(d => d.trim()) : [];
        
        // Get backups count
        const backupsResult = await runCommand(`find ${ROCKETVPS_PATH}/backups -type f -name "*.tar.gz" 2>/dev/null | wc -l`);
        const backupsCount = backupsResult.success ? parseInt(backupsResult.output) || 0 : 0;
        
        // Get disk usage
        const diskResult = await runCommand(`du -sh ${ROCKETVPS_PATH}/backups 2>/dev/null | awk '{print $1}'`);
        const diskUsage = diskResult.success ? diskResult.output : '0';
        
        // Get healthy domains count
        const healthyCount = domains.length; // Simplified - should check actual health
        
        res.json({
            success: true,
            stats: {
                total_domains: domains.length,
                healthy_domains: healthyCount,
                total_backups: backupsCount,
                disk_usage: diskUsage
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * GET /api/stats/domains - Get domain statistics
 */
app.get('/api/stats/domains', auth.authenticate, async (req, res) => {
    try {
        const domainsResult = await runRocketVPSFunction('bulk_operations', 'discover_all_domains');
        const domains = domainsResult.success ? domainsResult.output.split('\n').filter(d => d.trim()) : [];
        
        // Count by type (simplified - should detect actual types)
        const stats = {
            wordpress: 0,
            laravel: 0,
            nodejs: 0,
            static: 0,
            php: 0
        };
        
        res.json({
            success: true,
            stats
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// ==============================================================================
// WEBSOCKET HANDLERS
// ==============================================================================

io.on('connection', (socket) => {
    console.log('✅ Client connected:', socket.id);

    // Subscribe to updates
    socket.on('subscribe', (room) => {
        socket.join(room);
        console.log(`📡 Client ${socket.id} subscribed to ${room}`);
    });

    // Unsubscribe from updates
    socket.on('unsubscribe', (room) => {
        socket.leave(room);
        console.log(`📴 Client ${socket.id} unsubscribed from ${room}`);
    });

    socket.on('disconnect', () => {
        console.log('❌ Client disconnected:', socket.id);
    });
});

// Real-time progress updates
setInterval(async () => {
    try {
        const progressFile = path.join(ROCKETVPS_PATH, 'data', 'bulk_progress.json');
        const progressData = await readJsonFile(progressFile);
        
        if (progressData) {
            io.to('progress').emit('progress-update', progressData);
        }
    } catch (error) {
        // Ignore errors
    }
}, 2000); // Every 2 seconds

// Real-time health updates
setInterval(async () => {
    try {
        const healthFile = path.join(ROCKETVPS_PATH, 'data', 'health_status.json');
        const healthData = await readJsonFile(healthFile);
        
        if (healthData) {
            io.to('health').emit('system-health-update', healthData);
        }
    } catch (error) {
        // Ignore errors
    }
}, 10000); // Every 10 seconds

// ==============================================================================
// ERROR HANDLING
// ==============================================================================

// 404 Handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found'
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({
        success: false,
        error: err.message || 'Internal server error'
    });
});

// ==============================================================================
// START SERVER
// ==============================================================================

server.listen(PORT, HOST, () => {
    console.log('');
    console.log('='.repeat(60));
    console.log('🚀 RocketVPS Dashboard v2.2.0');
    console.log('='.repeat(60));
    console.log(`✅ Server running on http://${HOST}:${PORT}`);
    console.log('');
    console.log('📡 WebSocket: Enabled');
    console.log('🔒 Authentication: Enabled');
    console.log('');
    console.log('🌐 API Endpoints:');
    console.log('   Authentication:');
    console.log('   - POST   /api/auth/login');
    console.log('   - POST   /api/auth/logout');
    console.log('   - POST   /api/auth/refresh');
    console.log('   - GET    /api/auth/user');
    console.log('   - POST   /api/auth/change-password');
    console.log('   - GET    /api/auth/users (admin)');
    console.log('   - POST   /api/auth/users (admin)');
    console.log('   - DELETE /api/auth/users/:username (admin)');
    console.log('');
    console.log('   Domains:');
    console.log('   - GET    /api/domains');
    console.log('   - GET    /api/domains/:domain');
    console.log('   - POST   /api/domains/:domain/backup');
    console.log('   - POST   /api/domains/:domain/restore');
    console.log('');
    console.log('   Health:');
    console.log('   - GET    /api/health/system');
    console.log('   - GET    /api/health/domains');
    console.log('   - POST   /api/health/check');
    console.log('');
    console.log('   Bulk Operations:');
    console.log('   - POST   /api/bulk/backup');
    console.log('   - GET    /api/bulk/progress');
    console.log('   - GET    /api/bulk/results');
    console.log('');
    console.log('   Statistics:');
    console.log('   - GET    /api/stats/overview');
    console.log('   - GET    /api/stats/domains');
    console.log('');
    console.log('='.repeat(60));
    console.log('');
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('⚠️  SIGTERM received, shutting down gracefully...');
    server.close(() => {
        console.log('✅ Server closed');
        process.exit(0);
    });
});

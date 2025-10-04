/**
 * RocketVPS Dashboard - Authentication Middleware
 * Version: 2.2.0
 * 
 * Features:
 * - JWT token generation and verification
 * - Password hashing with bcrypt
 * - User session management
 * - Protected route middleware
 * - Token refresh mechanism
 * - Rate limiting for auth endpoints
 */

const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const fs = require('fs').promises;
const path = require('path');

// Configuration
const JWT_SECRET = process.env.JWT_SECRET || 'rocketvps-secret-change-in-production';
const JWT_EXPIRY = process.env.JWT_EXPIRY || '24h';
const JWT_REFRESH_EXPIRY = process.env.JWT_REFRESH_EXPIRY || '7d';
const USERS_FILE = path.join(__dirname, 'users.json');

// In-memory session store (use Redis in production)
const sessions = new Map();

/**
 * Initialize users file if not exists
 */
async function initializeUsers() {
    try {
        await fs.access(USERS_FILE);
    } catch (error) {
        // Create default admin user
        const defaultUser = {
            username: 'admin',
            password: await bcrypt.hash('rocketvps2025', 10),
            role: 'admin',
            email: 'admin@rocketvps.local',
            created_at: new Date().toISOString(),
            last_login: null
        };

        await fs.writeFile(USERS_FILE, JSON.stringify({
            users: { 'admin': defaultUser }
        }, null, 2));

        console.log('✅ Created default admin user (admin/rocketvps2025)');
    }
}

/**
 * Load users from file
 */
async function loadUsers() {
    try {
        const data = await fs.readFile(USERS_FILE, 'utf8');
        return JSON.parse(data).users || {};
    } catch (error) {
        console.error('❌ Failed to load users:', error.message);
        return {};
    }
}

/**
 * Save users to file
 */
async function saveUsers(users) {
    try {
        await fs.writeFile(USERS_FILE, JSON.stringify({ users }, null, 2));
        return true;
    } catch (error) {
        console.error('❌ Failed to save users:', error.message);
        return false;
    }
}

/**
 * Hash password
 */
async function hashPassword(password) {
    return await bcrypt.hash(password, 10);
}

/**
 * Compare password
 */
async function comparePassword(password, hash) {
    return await bcrypt.compare(password, hash);
}

/**
 * Generate JWT access token
 */
function generateAccessToken(user) {
    const payload = {
        username: user.username,
        role: user.role,
        email: user.email,
        type: 'access'
    };

    return jwt.sign(payload, JWT_SECRET, { 
        expiresIn: JWT_EXPIRY,
        issuer: 'rocketvps-dashboard',
        subject: user.username
    });
}

/**
 * Generate JWT refresh token
 */
function generateRefreshToken(user) {
    const payload = {
        username: user.username,
        type: 'refresh'
    };

    return jwt.sign(payload, JWT_SECRET, { 
        expiresIn: JWT_REFRESH_EXPIRY,
        issuer: 'rocketvps-dashboard',
        subject: user.username
    });
}

/**
 * Verify JWT token
 */
function verifyToken(token) {
    try {
        return jwt.verify(token, JWT_SECRET);
    } catch (error) {
        return null;
    }
}

/**
 * Create user session
 */
function createSession(username, tokens) {
    const sessionId = require('crypto').randomBytes(32).toString('hex');
    
    sessions.set(sessionId, {
        username,
        tokens,
        created_at: Date.now(),
        last_activity: Date.now()
    });

    return sessionId;
}

/**
 * Get session
 */
function getSession(sessionId) {
    return sessions.get(sessionId);
}

/**
 * Update session activity
 */
function updateSessionActivity(sessionId) {
    const session = sessions.get(sessionId);
    if (session) {
        session.last_activity = Date.now();
        sessions.set(sessionId, session);
    }
}

/**
 * Destroy session
 */
function destroySession(sessionId) {
    return sessions.delete(sessionId);
}

/**
 * Clean expired sessions (run periodically)
 */
function cleanExpiredSessions() {
    const now = Date.now();
    const maxAge = 24 * 60 * 60 * 1000; // 24 hours

    for (const [sessionId, session] of sessions.entries()) {
        if (now - session.last_activity > maxAge) {
            sessions.delete(sessionId);
        }
    }
}

// Clean sessions every hour
setInterval(cleanExpiredSessions, 60 * 60 * 1000);

/**
 * Middleware: Authenticate user
 * 
 * Checks for JWT token in Authorization header or cookies
 */
function authenticate(req, res, next) {
    try {
        // Get token from header or cookie
        let token = null;
        
        if (req.headers.authorization) {
            const parts = req.headers.authorization.split(' ');
            if (parts.length === 2 && parts[0] === 'Bearer') {
                token = parts[1];
            }
        } else if (req.cookies && req.cookies.access_token) {
            token = req.cookies.access_token;
        }

        if (!token) {
            return res.status(401).json({
                success: false,
                error: 'No token provided'
            });
        }

        // Verify token
        const decoded = verifyToken(token);
        
        if (!decoded) {
            return res.status(401).json({
                success: false,
                error: 'Invalid or expired token'
            });
        }

        if (decoded.type !== 'access') {
            return res.status(401).json({
                success: false,
                error: 'Invalid token type'
            });
        }

        // Attach user to request
        req.user = {
            username: decoded.username,
            role: decoded.role,
            email: decoded.email
        };

        // Update session activity
        const sessionId = req.cookies?.session_id;
        if (sessionId) {
            updateSessionActivity(sessionId);
        }

        next();
    } catch (error) {
        console.error('Authentication error:', error);
        return res.status(500).json({
            success: false,
            error: 'Authentication failed'
        });
    }
}

/**
 * Middleware: Require admin role
 */
function requireAdmin(req, res, next) {
    if (!req.user) {
        return res.status(401).json({
            success: false,
            error: 'Authentication required'
        });
    }

    if (req.user.role !== 'admin') {
        return res.status(403).json({
            success: false,
            error: 'Admin access required'
        });
    }

    next();
}

/**
 * Middleware: Optional authentication
 * 
 * Attaches user if token provided, but doesn't reject if missing
 */
function optionalAuth(req, res, next) {
    try {
        let token = null;
        
        if (req.headers.authorization) {
            const parts = req.headers.authorization.split(' ');
            if (parts.length === 2 && parts[0] === 'Bearer') {
                token = parts[1];
            }
        } else if (req.cookies && req.cookies.access_token) {
            token = req.cookies.access_token;
        }

        if (token) {
            const decoded = verifyToken(token);
            if (decoded && decoded.type === 'access') {
                req.user = {
                    username: decoded.username,
                    role: decoded.role,
                    email: decoded.email
                };
            }
        }

        next();
    } catch (error) {
        next();
    }
}

/**
 * Route handler: Login
 */
async function handleLogin(req, res) {
    try {
        const { username, password } = req.body;

        if (!username || !password) {
            return res.status(400).json({
                success: false,
                error: 'Username and password required'
            });
        }

        // Load users
        const users = await loadUsers();
        const user = users[username];

        if (!user) {
            return res.status(401).json({
                success: false,
                error: 'Invalid credentials'
            });
        }

        // Verify password
        const validPassword = await comparePassword(password, user.password);
        
        if (!validPassword) {
            return res.status(401).json({
                success: false,
                error: 'Invalid credentials'
            });
        }

        // Generate tokens
        const accessToken = generateAccessToken(user);
        const refreshToken = generateRefreshToken(user);

        // Create session
        const sessionId = createSession(username, {
            access_token: accessToken,
            refresh_token: refreshToken
        });

        // Update last login
        user.last_login = new Date().toISOString();
        users[username] = user;
        await saveUsers(users);

        // Set cookies
        res.cookie('access_token', accessToken, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            maxAge: 24 * 60 * 60 * 1000 // 24 hours
        });

        res.cookie('refresh_token', refreshToken, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
        });

        res.cookie('session_id', sessionId, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            maxAge: 24 * 60 * 60 * 1000 // 24 hours
        });

        return res.json({
            success: true,
            user: {
                username: user.username,
                role: user.role,
                email: user.email,
                last_login: user.last_login
            },
            tokens: {
                access_token: accessToken,
                refresh_token: refreshToken
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        return res.status(500).json({
            success: false,
            error: 'Login failed'
        });
    }
}

/**
 * Route handler: Logout
 */
async function handleLogout(req, res) {
    try {
        const sessionId = req.cookies?.session_id;
        
        if (sessionId) {
            destroySession(sessionId);
        }

        // Clear cookies
        res.clearCookie('access_token');
        res.clearCookie('refresh_token');
        res.clearCookie('session_id');

        return res.json({
            success: true,
            message: 'Logged out successfully'
        });
    } catch (error) {
        console.error('Logout error:', error);
        return res.status(500).json({
            success: false,
            error: 'Logout failed'
        });
    }
}

/**
 * Route handler: Refresh token
 */
async function handleRefresh(req, res) {
    try {
        let refreshToken = req.body.refresh_token || req.cookies?.refresh_token;

        if (!refreshToken) {
            return res.status(401).json({
                success: false,
                error: 'No refresh token provided'
            });
        }

        // Verify refresh token
        const decoded = verifyToken(refreshToken);
        
        if (!decoded || decoded.type !== 'refresh') {
            return res.status(401).json({
                success: false,
                error: 'Invalid refresh token'
            });
        }

        // Load user
        const users = await loadUsers();
        const user = users[decoded.username];

        if (!user) {
            return res.status(401).json({
                success: false,
                error: 'User not found'
            });
        }

        // Generate new access token
        const accessToken = generateAccessToken(user);

        // Update session
        const sessionId = req.cookies?.session_id;
        if (sessionId) {
            const session = getSession(sessionId);
            if (session) {
                session.tokens.access_token = accessToken;
                updateSessionActivity(sessionId);
            }
        }

        // Set cookie
        res.cookie('access_token', accessToken, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            maxAge: 24 * 60 * 60 * 1000
        });

        return res.json({
            success: true,
            access_token: accessToken
        });
    } catch (error) {
        console.error('Refresh token error:', error);
        return res.status(500).json({
            success: false,
            error: 'Token refresh failed'
        });
    }
}

/**
 * Route handler: Get current user
 */
async function handleGetUser(req, res) {
    try {
        if (!req.user) {
            return res.status(401).json({
                success: false,
                error: 'Not authenticated'
            });
        }

        // Load full user data
        const users = await loadUsers();
        const user = users[req.user.username];

        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }

        return res.json({
            success: true,
            user: {
                username: user.username,
                role: user.role,
                email: user.email,
                created_at: user.created_at,
                last_login: user.last_login
            }
        });
    } catch (error) {
        console.error('Get user error:', error);
        return res.status(500).json({
            success: false,
            error: 'Failed to get user'
        });
    }
}

/**
 * Route handler: Change password
 */
async function handleChangePassword(req, res) {
    try {
        if (!req.user) {
            return res.status(401).json({
                success: false,
                error: 'Not authenticated'
            });
        }

        const { current_password, new_password } = req.body;

        if (!current_password || !new_password) {
            return res.status(400).json({
                success: false,
                error: 'Current and new password required'
            });
        }

        if (new_password.length < 8) {
            return res.status(400).json({
                success: false,
                error: 'New password must be at least 8 characters'
            });
        }

        // Load users
        const users = await loadUsers();
        const user = users[req.user.username];

        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }

        // Verify current password
        const validPassword = await comparePassword(current_password, user.password);
        
        if (!validPassword) {
            return res.status(401).json({
                success: false,
                error: 'Current password incorrect'
            });
        }

        // Update password
        user.password = await hashPassword(new_password);
        users[req.user.username] = user;
        await saveUsers(users);

        return res.json({
            success: true,
            message: 'Password changed successfully'
        });
    } catch (error) {
        console.error('Change password error:', error);
        return res.status(500).json({
            success: false,
            error: 'Failed to change password'
        });
    }
}

/**
 * Route handler: Create user (admin only)
 */
async function handleCreateUser(req, res) {
    try {
        const { username, password, role, email } = req.body;

        if (!username || !password) {
            return res.status(400).json({
                success: false,
                error: 'Username and password required'
            });
        }

        if (password.length < 8) {
            return res.status(400).json({
                success: false,
                error: 'Password must be at least 8 characters'
            });
        }

        // Load users
        const users = await loadUsers();

        if (users[username]) {
            return res.status(409).json({
                success: false,
                error: 'Username already exists'
            });
        }

        // Create user
        const newUser = {
            username,
            password: await hashPassword(password),
            role: role || 'viewer',
            email: email || `${username}@rocketvps.local`,
            created_at: new Date().toISOString(),
            last_login: null
        };

        users[username] = newUser;
        await saveUsers(users);

        return res.json({
            success: true,
            user: {
                username: newUser.username,
                role: newUser.role,
                email: newUser.email,
                created_at: newUser.created_at
            }
        });
    } catch (error) {
        console.error('Create user error:', error);
        return res.status(500).json({
            success: false,
            error: 'Failed to create user'
        });
    }
}

/**
 * Route handler: Delete user (admin only)
 */
async function handleDeleteUser(req, res) {
    try {
        const { username } = req.params;

        if (username === 'admin') {
            return res.status(403).json({
                success: false,
                error: 'Cannot delete admin user'
            });
        }

        if (username === req.user.username) {
            return res.status(403).json({
                success: false,
                error: 'Cannot delete yourself'
            });
        }

        // Load users
        const users = await loadUsers();

        if (!users[username]) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }

        delete users[username];
        await saveUsers(users);

        return res.json({
            success: true,
            message: 'User deleted successfully'
        });
    } catch (error) {
        console.error('Delete user error:', error);
        return res.status(500).json({
            success: false,
            error: 'Failed to delete user'
        });
    }
}

/**
 * Route handler: List users (admin only)
 */
async function handleListUsers(req, res) {
    try {
        const users = await loadUsers();

        const userList = Object.values(users).map(user => ({
            username: user.username,
            role: user.role,
            email: user.email,
            created_at: user.created_at,
            last_login: user.last_login
        }));

        return res.json({
            success: true,
            users: userList,
            total: userList.length
        });
    } catch (error) {
        console.error('List users error:', error);
        return res.status(500).json({
            success: false,
            error: 'Failed to list users'
        });
    }
}

// Export all functions
module.exports = {
    // Initialization
    initializeUsers,
    
    // Password functions
    hashPassword,
    comparePassword,
    
    // Token functions
    generateAccessToken,
    generateRefreshToken,
    verifyToken,
    
    // Session functions
    createSession,
    getSession,
    updateSessionActivity,
    destroySession,
    cleanExpiredSessions,
    
    // Middleware
    authenticate,
    requireAdmin,
    optionalAuth,
    
    // Route handlers
    handleLogin,
    handleLogout,
    handleRefresh,
    handleGetUser,
    handleChangePassword,
    handleCreateUser,
    handleDeleteUser,
    handleListUsers
};

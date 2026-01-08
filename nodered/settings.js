module.exports = {
    // Node-RED runtime settings
    uiPort: process.env.PORT || 1880,
    mqttReconnectTime: 15000,
    serialReconnectTime: 15000,
    debugMaxLength: 1000,
    
    // Security
    adminAuth: {
        type: "credentials",
        users: [{
            username: "admin",
            password: "$2b$08$zZWtXTja0fB1pzD4sHCMyOCMYz2Z6dNbM6tl8sJogENOMcxWV9DN.", // password: admin123
            permissions: "*"
        }]
    },
    
    // HTTP settings
    httpAdminRoot: '/admin',
    httpNodeRoot: '/api',
    
    // UI settings
    ui: {
        path: "ui"
    },
    
    // Function node settings
    functionGlobalContext: {
        // Enable access to OS module
        os: require('os'),
        // Enable moment for date/time handling
        moment: require('moment-timezone')
    },
    
    // Logging
    logging: {
        console: {
            level: "info",
            metrics: false,
            audit: false
        }
    },
    
    // Editor settings
    editorTheme: {
        projects: {
            enabled: true
        },
        palette: {
            editable: true
        }
    },
    
    // Export settings
    externalModules: {
    }
};
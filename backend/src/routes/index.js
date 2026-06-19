const express = require('express');
const router = express.Router();

// 导入路由模块
const authRoutes = require('./auth');
const photoRoutes = require('./photo');
const familyRoutes = require('./family');

// 注册路由
router.use('/auth', authRoutes);
router.use('/photos', photoRoutes);
router.use('/families', familyRoutes);

// 健康检查路由
router.get('/health', async (req, res) => {
  try {
    const { mysqlPool } = require('../config/database');
    await mysqlPool.query('SELECT 1');
    res.status(200).json({
      status: 'ok',
      db: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (e) {
    res.status(503).json({
      status: 'degraded',
      db: 'disconnected',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
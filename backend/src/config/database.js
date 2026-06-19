const mysql = require('mysql2/promise');
const config = require('./index');

// MySQL连接池
const mysqlPool = mysql.createPool({
  host: config.mysql.host,
  port: config.mysql.port,
  user: config.mysql.user,
  password: config.mysql.password,
  database: config.mysql.database,
  connectionLimit: config.mysql.connectionLimit,
  waitForConnections: true,
  queueLimit: 0
});

// 测试MySQL连接
const testMySQLConnection = async () => {
  try {
    const connection = await mysqlPool.getConnection();
    console.log('MySQL connected successfully');
    connection.release();
  } catch (error) {
    console.error('MySQL connection error:', error);
    throw error;
  }
};

module.exports = {
  mysqlPool,
  testMySQLConnection
};

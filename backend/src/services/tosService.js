const { TosClient } = require('@volcengine/tos-sdk');
const config = require('../config');

class TOSService {
  constructor() {
    this._client = null;
  }

  getClient() {
    if (!this._client) {
      this._client = new TosClient({
        accessKeyId: config.tos.accessKeyId,
        accessKeySecret: config.tos.accessKeySecret,
        region: config.tos.region,
        endpoint: config.tos.endpoint
      });
    }
    return this._client;
  }

  // 生成上传预签名URL
  async generateUploadUrl(objectKey, expires = 600) {
    const client = this.getClient();
    try {
      const res = await client.getPreSignedUrl({
        method: 'PUT',
        bucket: config.tos.bucket,
        key: objectKey,
        expires
      });
      return {
        uploadUrl: res,
        objectKey: objectKey
      };
    } catch (error) {
      console.error('生成上传签名URL失败:', error);
      throw error;
    }
  }

  // 生成下载预签名URL
  async generateDownloadUrl(urlOrObjectKey, expires = 604800) {
    const client = this.getClient();
    
    // 如果传入的是完整URL，则提取objectKey
    let objectKey = urlOrObjectKey;
    if (urlOrObjectKey.startsWith('http')) {
      try {
        const urlObj = new URL(urlOrObjectKey);
        objectKey = urlObj.pathname.substring(1); // 移除开头的/
      } catch (e) {
        console.error('解析URL失败:', e);
        throw e;
      }
    }
    
    try {
      const res = await client.getPreSignedUrl({
        method: 'GET',
        bucket: config.tos.bucket,
        key: objectKey,
        expires
      });
      return {
        downloadUrl: res,
        objectKey: objectKey
      };
    } catch (error) {
      console.error('生成下载签名URL失败:', error);
      throw error;
    }
  }
}

module.exports = new TOSService();
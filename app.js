const express = require('express');
const cors = require('cors');
const axios = require('axios');
const app = express();

// 中间件
app.use(cors());
app.use(express.json());

// API密钥（从环境变量读取，默认值用于开发）
const API_KEY = process.env.API_KEY || 'f3808faa-8147-41ee-9795-e1c04ddf319e';

// Telegram Bot 配置
const NOTIFY_BOT_CHAT_ID = process.env.NOTIFY_BOT_CHAT_ID;
const NOTIFY_BOT_URL = process.env.NOTIFY_BOT_URL;

// 调试：打印环境变量（仅用于调试，生产环境应移除）
console.log('环境变量检查:');
console.log('NOTIFY_BOT_URL:', NOTIFY_BOT_URL);
console.log('NOTIFY_BOT_CHAT_ID:', NOTIFY_BOT_CHAT_ID);
console.log('API_KEY:', API_KEY ? '已设置' : '未设置');

// Header验证中间件
const validateApiKey = (req, res, next) => {
  const apiKey = req.headers['x-api-key'] || req.headers['authorization'];
  
  if (!apiKey) {
    return res.status(401).json({ 
      error: 'Unauthorized',
      message: 'API key is required. Please provide X-API-Key header.'
    });
  }
  
  // 如果使用 Authorization header，移除 'Bearer ' 前缀
  const key = apiKey.startsWith('Bearer ') ? apiKey.substring(7) : apiKey;
  
  if (key !== API_KEY) {
    return res.status(403).json({ 
      error: 'Forbidden',
      message: 'Invalid API key.'
    });
  }
  
  next();
};

// POST 接口 - 需要API密钥验证
app.post('/sendBot', validateApiKey, async (req, res) => {
  const { message } = req.body;
  if (!message) {
    return res.status(400).json({ 
      error: 'Bad Request',
      message: 'Message parameter is required' 
    });
  }
  
  if (!NOTIFY_BOT_CHAT_ID || !NOTIFY_BOT_URL) {
    return res.status(500).json({ 
      error: 'Internal Server Error',
      message: 'Telegram Bot configuration is missing' 
    });
  }
  
  const params = {
    chat_id: NOTIFY_BOT_CHAT_ID,
    text: message,
    parse_mode: "HTML",
  };
  
  try {
    await axios.post(NOTIFY_BOT_URL + "sendMessage", params);
    res.status(200).json({
      success: true,
      message: 'Message sent successfully'
    });
  } catch (error) {
    // 异常被忽略，但记录日志
    console.error('Failed to send message to Telegram:', error.message);
    res.status(200).json({
      success: true,
      message: 'Request processed (errors ignored)'
    });
  }
});

// 404处理
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// 错误处理中间件
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal Server Error' });
});

const PORT = process.env.PORT || 8848;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Notify API server is running on port ${PORT}`);
});


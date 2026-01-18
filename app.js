// Polyfill fetch for Node.js (required by @ardrive/turbo-sdk dependencies)
if (!globalThis.fetch) {
  globalThis.fetch = require('node-fetch');
}

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const axios = require('axios');
const multer = require('multer');
const fs = require('fs').promises;
const path = require('path');
const { TurboFactory } = require('@ardrive/turbo-sdk');
const { HexSolanaSigner } = require('@dha-team/arbundles');
const app = express();

// 允许的域名白名单
const ALLOWED_DOMAINS = ['pandatool.org', 'www.pandatool.org',"ton.pandatool.org"];
// const ALLOWED_DOMAINS = ["*"];


// 测试密钥（允许绕过域名验证）
// const TEST_KEY = 'testkey';

// 域名验证中间件
const validateDomain = (req, res, next) => {
  // 如果允许所有域名（开发模式），跳过验证
  if (ALLOWED_DOMAINS.includes('*')) {
    return next();
  }

  // 检查是否有测试密钥（通过 header 或 query 参数）

  // 如果有测试密钥，跳过域名验证
  // if (testKey === TEST_KEY) {
  //   return next();
  // }

  const origin = req.headers.origin;
  const referer = req.headers.referer;

  // 提取域名
  let domain = null;

  if (origin) {
    try {
      const url = new URL(origin);
      domain = url.hostname;
    } catch (e) {
      // 如果 URL 解析失败，尝试简单提取
      domain = origin.replace(/^https?:\/\//, '').split('/')[0].split(':')[0];
    }
  } else if (referer) {
    try {
      const url = new URL(referer);
      domain = url.hostname;
    } catch (e) {
      domain = referer.replace(/^https?:\/\//, '').split('/')[0].split(':')[0];
    }
  }

  // 如果没有 origin 和 referer，拒绝访问（不允许直接 IP 或未知来源访问）
  if (!domain) {
    return res.status(403).json({
      error: 'Forbidden',
      message: 'verification failed.'
    });
  }

  // 移除 www 前缀进行比较
  const domainWithoutWww = domain.replace(/^www\./, '');
  const isAllowed = ALLOWED_DOMAINS.some(allowed => {
    const allowedWithoutWww = allowed.replace(/^www\./, '').replace(/^\*\./, ''); // 处理 *.domain.com
    return domainWithoutWww === allowedWithoutWww;
  });

  if (!isAllowed) {
    return res.status(403).json({
      error: 'Forbidden',
      message: `Domain .`
    });
  }

  next();
};

// 中间件
app.use(cors({
  origin: function (origin, callback) {
    // 如果允许所有域名（开发模式）
    if (ALLOWED_DOMAINS.includes('*')) {
      return callback(null, true);
    }

    // 如果没有 origin（如服务器端请求），允许（会在域名验证中间件中进一步检查）
    if (!origin) {
      return callback(null, true);
    }

    const originDomain = origin.replace(/^https?:\/\//, '').replace(/^www\./, '').split(':')[0];
    const isAllowed = ALLOWED_DOMAINS.some(domain => {
      const domainWithoutWww = domain.replace(/^www\./, '').replace(/^\*\./, ''); // 处理 *.domain.com
      return originDomain === domainWithoutWww;
    });

    if (isAllowed) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true
}));
app.use(express.json());

// 应用域名验证中间件（除了根路径和健康检查）
app.use((req, res, next) => {
  // 跳过根路径和健康检查端点
  if (req.path === '/health' || req.path === '/') {
    return next();
  }
  validateDomain(req, res, next);
});

// API密钥（从环境变量读取，默认值用于开发）
const API_KEY = process.env.API_KEY || 'f3808faa-8147-41ee-9795-e1c04ddf319e';

// Telegram Bot 配置
const NOTIFY_BOT_CHAT_ID = process.env.NOTIFY_BOT_CHAT_ID;
const NOTIFY_BOT_URL = process.env.NOTIFY_BOT_URL;

// Turbo / Arweave 配置
const TURBO_PRIVATE_KEY = process.env.TURBO_PRIVATE_KEY || '5ricaNLjikwHDHyARr5UbH2CeLskeGjgATMFozKMFQLnWgcuexa4be7J2TiNx2C1B2uHobyoD7Ln4QguKDALYaDA';

// Block explorer URLs
const explorerUrl = {
  "56": "https://bscscan.com/tx/",
  "97": "https://testnet.bscscan.com/tx/",
  "1": "https://etherscan.io/tx/",
  "137": "https://polygonscan.com/tx/",
  "8453": "https://basescan.org/tx/",
  "42161": "https://arbiscan.io/tx/",
};

// Multer 配置用于文件上传
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: { fileSize: 100000 }, // 100KB limit
});

// 获取 Turbo 客户端
const getTurboClient = () => {
  const signer = new HexSolanaSigner(TURBO_PRIVATE_KEY);
  const turbo = TurboFactory.authenticated({
    signer,
    token: "solana",
  });
  return turbo;
};

// 调试：打印环境变量（仅用于调试，生产环境应移除）
console.log('环境变量检查:');
console.log('NOTIFY_BOT_URL:', NOTIFY_BOT_URL || '(未设置)');
console.log('NOTIFY_BOT_CHAT_ID:', NOTIFY_BOT_CHAT_ID || '(未设置)');
console.log('API_KEY:', API_KEY ? '已设置 (' + API_KEY.substring(0, 10) + '...)' : '未设置');
console.log('允许的域名:', ALLOWED_DOMAINS.join(', '));

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

// POST /upload_img - 上传图片到 Arweave
app.post('/upload_img', validateApiKey, upload.single('file'), async (req, res) => {
  try {
   
    if (!req.file) {
      return res.status(400).json({ code: 400, message: 'No file uploaded' });
    }

    // 检查文件大小
    if (req.file.size > 100000) {
      return res.json({ code: 406, message: 'img oversized!' });
    }

    const imageTags = [{ name: 'Content-Type', value: 'image/png' }];
    const turbo = getTurboClient();

    const imageUploadResult = await turbo.upload({
      data: new Uint8Array(req.file.buffer),
      dataItemOpts: {
        tags: imageTags,
      },
    });

    const imgURI = 'https://arweave.net/' + imageUploadResult.id;

    return res.json({ code: 200, message: 'success', imgURI: imgURI });
  } catch (e) {
    console.error('Error uploading image:', e);
    return res.json({ code: 405, message: e.message || 'Upload failed' });
  }
});

// POST /upload_logo_meta_ario - 上传 Logo 和元数据到 Arweave
app.post('/upload_logo_meta', validateApiKey, upload.single('file'), async (req, res) => {
  try {
    const {
      mainnet,
      tokenAddress,
      channelPlatform,
      imgType,
      description,
      website,
      telegram,
      twitter,
      discord,
      qqGroup,
      whitepaper,
      contact,
      payNeworkId,
      payTx
    } = req.body;

    if (!req.file) {
      return res.status(400).json({ code: 400, message: 'No file uploaded' });
    }

    // 检查文件大小
    if (req.file.size > 100000) {
      return res.json({ code: 406, message: 'img oversized!' });
    }

    // 构建元数据对象
    const metaData = {
      mainnet,
      tokenAddress,
      logo: '',
      channelPlatform,
    };

    // 添加可选字段
    if (description) metaData.description = description;
    if (website) metaData.website = website;
    if (telegram) metaData.telegram = telegram;
    if (twitter) metaData.twitter = twitter;
    if (discord) metaData.discord = discord;
    if (qqGroup) metaData.qqGroup = qqGroup;
    if (whitepaper) metaData.whitepaper = whitepaper;
    if (contact) metaData.contact = contact;

    // 上传图片
    const imageTags = [{ name: 'Content-Type', value: imgType || 'image/png' }];
    const turbo = getTurboClient();

    const imageUploadResult = await turbo.upload({
      data: new Uint8Array(req.file.buffer),
      dataItemOpts: {
        tags: imageTags,
      },
    });

    const imgURI = 'https://arweave.net/' + imageUploadResult.id;
    metaData.logo = imgURI;

    // 上传元数据
    const metaTags = [{ name: 'Content-Type', value: 'application/json' }];
    const metaDataC = {
      ...metaData,
      payUrl: explorerUrl[payNeworkId] + payTx,
    };

    const metaDataString = JSON.stringify(metaDataC, null, 2);
    const metaDataBuffer = Buffer.from(metaDataString);

    const metaUploadResult = await turbo.upload({
      data: new Uint8Array(metaDataBuffer),
      dataItemOpts: {
        tags: metaTags,
      },
    });

    const metaURI = 'https://arweave.net/' + metaUploadResult.id;

    return res.json({ code: 200, metaURI: metaURI });
  } catch (e) {
    console.error('Error uploading data:', e);
    return res.json({ code: 405, message: e.message || 'Upload failed' });
  }
});

// 根路径（允许所有域名访问，用于检查服务状态）
app.get('/', (req, res) => {
  res.json({
    message: 'Notify API is running',
    version: '1.0.0',
    allowedDomains: ALLOWED_DOMAINS
  });
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


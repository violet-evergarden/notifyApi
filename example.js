const axios = require('axios');

// 配置
const API_URL = 'http://localhost:8848'; // 本地测试，服务器部署后改为服务器地址
const API_KEY = 'f3808faa-8147-41ee-9795-e1c04ddf319e'; // 你的 API 密钥
const ENDPOINT = '/sendBot';

// 方式1: 使用 X-API-Key header
async function sendMessageWithApiKey() {
  try {
    const response = await axios.post(
      `${API_URL}${ENDPOINT}`,
      {
        message: '这是一条测试消息，使用 X-API-Key header'
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': API_KEY
        }
      }
    );
    
    console.log('✅ 消息发送成功:', response.data);
    return response.data;
  } catch (error) {
    console.error('❌ 发送失败:', error.response?.data || error.message);
    throw error;
  }
}

// 方式2: 使用 Authorization Bearer Token
async function sendMessageWithBearerToken() {
  try {
    const response = await axios.post(
      `${API_URL}${ENDPOINT}`,
      {
        message: '这是一条测试消息，使用 Bearer Token'
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${API_KEY}`
        }
      }
    );
    
    console.log('✅ 消息发送成功:', response.data);
    return response.data;
  } catch (error) {
    console.error('❌ 发送失败:', error.response?.data || error.message);
    throw error;
  }
}

// 方式3: 发送 HTML 格式消息
async function sendHtmlMessage() {
  try {
    const response = await axios.post(
      `${API_URL}${ENDPOINT}`,
      {
        message: '<b>粗体文本</b>\n<i>斜体文本</i>\n<code>代码文本</code>\n<a href="https://example.com">链接</a>'
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': API_KEY
        }
      }
    );
    
    console.log('✅ HTML 消息发送成功:', response.data);
    return response.data;
  } catch (error) {
    console.error('❌ 发送失败:', error.response?.data || error.message);
    throw error;
  }
}

// 方式4: 封装成函数，方便调用
function sendNotification(message, apiKey = API_KEY, apiUrl = API_URL) {
  return axios.post(
    `${apiUrl}${ENDPOINT}`,
    { message },
    {
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey
      }
    }
  );
}

// 使用示例
async function main() {
  console.log('=== 测试发送消息 ===\n');
  
  // 测试1: 使用 X-API-Key
  console.log('测试1: 使用 X-API-Key header');
  await sendMessageWithApiKey();
  
  console.log('\n---\n');
  
  // 测试2: 使用 Bearer Token
  console.log('测试2: 使用 Bearer Token');
  await sendMessageWithBearerToken();
  
  console.log('\n---\n');
  
  // 测试3: 发送 HTML 消息
  console.log('测试3: 发送 HTML 格式消息');
  await sendHtmlMessage();
  
  console.log('\n---\n');
  
  // 测试4: 使用封装的函数
  console.log('测试4: 使用封装的函数');
  try {
    const result = await sendNotification('这是使用封装函数发送的消息');
    console.log('✅ 消息发送成功:', result.data);
  } catch (error) {
    console.error('❌ 发送失败:', error.response?.data || error.message);
  }
}

// 如果直接运行此文件，执行测试
if (require.main === module) {
  main().catch(console.error);
}

// 导出函数供其他模块使用
module.exports = {
  sendMessageWithApiKey,
  sendMessageWithBearerToken,
  sendHtmlMessage,
  sendNotification
};


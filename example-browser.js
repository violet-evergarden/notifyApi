// 浏览器环境使用示例（需要先引入 axios）
// <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>

// 配置
const API_URL = 'http://localhost:8848'; // 本地测试，服务器部署后改为服务器地址
const API_KEY = 'f3808faa-8147-41ee-9795-e1c04ddf319e'; // 你的 API 密钥
const ENDPOINT = '/sendBot';

// 方式1: 使用 X-API-Key header
async function sendMessageWithApiKey(message) {
  try {
    const response = await axios.post(
      `${API_URL}${ENDPOINT}`,
      { message },
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

// 方式2: 使用 Promise
function sendMessagePromise(message) {
  return axios.post(
    `${API_URL}${ENDPOINT}`,
    { message },
    {
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': API_KEY
      }
    }
  )
    .then(response => {
      console.log('✅ 消息发送成功:', response.data);
      return response.data;
    })
    .catch(error => {
      console.error('❌ 发送失败:', error.response?.data || error.message);
      throw error;
    });
}

// 方式3: 使用 async/await 并处理错误
async function sendMessageSafe(message) {
  try {
    const response = await axios.post(
      `${API_URL}${ENDPOINT}`,
      { message },
      {
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': API_KEY
        }
      }
    );
    
    if (response.status === 200) {
      return {
        success: true,
        data: response.data
      };
    }
  } catch (error) {
    if (error.response) {
      // 服务器返回了错误响应
      return {
        success: false,
        error: error.response.data,
        status: error.response.status
      };
    } else if (error.request) {
      // 请求已发送但没有收到响应
      return {
        success: false,
        error: '网络错误，请检查服务器连接'
      };
    } else {
      // 其他错误
      return {
        success: false,
        error: error.message
      };
    }
  }
}

// 使用示例
async function test() {
  // 示例1: 基本使用
  await sendMessageWithApiKey('这是一条测试消息');
  
  // 示例2: 使用 Promise
  sendMessagePromise('使用 Promise 发送的消息')
    .then(data => console.log('成功:', data))
    .catch(err => console.error('失败:', err));
  
  // 示例3: 安全调用（带错误处理）
  const result = await sendMessageSafe('安全发送的消息');
  if (result.success) {
    console.log('发送成功:', result.data);
  } else {
    console.error('发送失败:', result.error);
  }
}

// 如果在浏览器中使用，可以绑定到按钮点击事件
// document.getElementById('sendBtn').addEventListener('click', async () => {
//   const message = document.getElementById('messageInput').value;
//   const result = await sendMessageSafe(message);
//   if (result.success) {
//     alert('消息发送成功！');
//   } else {
//     alert('消息发送失败：' + result.error.message);
//   }
// });


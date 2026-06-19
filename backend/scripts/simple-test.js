const http = require('http');

function postRequest(path, data, token = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: '127.0.0.1',
      port: 3000,
      path: path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(JSON.stringify(data))
      }
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(body));
        } catch (e) {
          resolve({ statusCode: res.statusCode, body });
        }
      });
    });

    req.on('error', reject);
    req.write(JSON.stringify(data));
    req.end();
  });
}

function getRequest(path, token = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: '127.0.0.1',
      port: 3000,
      path: path,
      method: 'GET',
      headers: {}
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(body));
        } catch (e) {
          resolve({ statusCode: res.statusCode, body });
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

async function test() {
  console.log('测试1: 用户注册');
  const registerRes = await postRequest('/api/v1/auth/register', {
    phone: '13800138001',
    password: '123456',
    nickname: '测试用户'
  });
  console.log('注册结果:', JSON.stringify(registerRes));

  if (registerRes.code === 0) {
    const token = registerRes.data.token;
    const userId = registerRes.data.userId;

    console.log('\n测试2: 创建家庭组');
    const familyRes = await postRequest('/api/v1/families', { name: '幸福一家' }, token);
    console.log('创建家庭组结果:', JSON.stringify(familyRes));

    if (familyRes.code === 0) {
      const familyId = familyRes.data.familyId;
      const inviteCode = familyRes.data.inviteCode;

      console.log('\n测试3: 获取家庭组列表');
      const listRes = await getRequest('/api/v1/families', token);
      console.log('家庭组列表:', JSON.stringify(listRes));

      console.log('\n测试4: 获取家庭组详情');
      const detailRes = await getRequest(`/api/v1/families/${familyId}`, token);
      console.log('家庭组详情:', JSON.stringify(detailRes));

      console.log('\n测试5: 重新生成邀请码');
      const inviteRes = await postRequest(`/api/v1/families/${familyId}/invite`, {}, token);
      console.log('重新生成邀请码结果:', JSON.stringify(inviteRes));

      console.log('\n🎉 所有测试通过!');
    }
  } else if (registerRes.code === 1001) {
    console.log('用户已存在，尝试登录');
    const loginRes = await postRequest('/api/v1/auth/login', {
      phone: '13800138001',
      password: '123456'
    });
    console.log('登录结果:', JSON.stringify(loginRes));

    if (loginRes.code === 0) {
      const token = loginRes.data.token;
      
      console.log('\n测试: 获取家庭组列表');
      const listRes = await getRequest('/api/v1/families', token);
      console.log('家庭组列表:', JSON.stringify(listRes));
    }
  }
}

test().catch(err => console.error('测试错误:', err));

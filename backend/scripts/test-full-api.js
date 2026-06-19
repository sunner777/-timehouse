/**
 * 家庭组API完整联调测试
 */
const http = require('http');

const HOST = '127.0.0.1';
const PORT = 3000;

function makeRequest(method, path, data = null, token = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: HOST,
      port: PORT,
      path: `/api/v1${path}`,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      }
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    if (data) {
      const jsonData = JSON.stringify(data);
      options.headers['Content-Length'] = Buffer.byteLength(jsonData);
    }

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const result = JSON.parse(body);
          resolve({ statusCode: res.statusCode, ...result });
        } catch (e) {
          resolve({ statusCode: res.statusCode, body });
        }
      });
    });

    req.on('error', reject);
    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

async function test() {
  console.log('🚀 开始家庭组API联调测试\n');
  
  let token1 = '';
  let token2 = '';
  let familyId = '';
  let inviteCode = '';
  let userId2 = '';

  // ================ 测试1: 用户注册 ================
  console.log('📝 测试1: 用户注册');
  try {
    // 注册用户1
    const register1 = await makeRequest('POST', '/auth/register', {
      phone: '13800138001',
      password: '123456',
      nickname: '测试用户1'
    });
    console.log(`用户1注册: ${register1.code === 0 ? '✅ 成功' : '❌ 失败'}`, register1.message);
    if (register1.code === 0) {
      token1 = register1.data.token;
    } else if (register1.code === 1001) {
      // 用户已存在，登录
      const login1 = await makeRequest('POST', '/auth/login', {
        phone: '13800138001',
        password: '123456'
      });
      console.log(`用户1登录: ${login1.code === 0 ? '✅ 成功' : '❌ 失败'}`, login1.message);
      token1 = login1.data.token;
    }

    // 注册用户2
    const register2 = await makeRequest('POST', '/auth/register', {
      phone: '13800138002',
      password: '123456',
      nickname: '测试用户2'
    });
    console.log(`用户2注册: ${register2.code === 0 ? '✅ 成功' : '❌ 失败'}`, register2.message);
    if (register2.code === 0) {
      token2 = register2.data.token;
      userId2 = register2.data.userId;
    } else if (register2.code === 1001) {
      const login2 = await makeRequest('POST', '/auth/login', {
        phone: '13800138002',
        password: '123456'
      });
      console.log(`用户2登录: ${login2.code === 0 ? '✅ 成功' : '❌ 失败'}`, login2.message);
      token2 = login2.data.token;
      userId2 = login2.data.userId;
    }
  } catch (error) {
    console.log('❌ 用户注册/登录失败:', error.message);
    return;
  }

  // ================ 测试2: 创建家庭组 ================
  console.log('\n📝 测试2: 创建家庭组');
  try {
    const createFamily = await makeRequest('POST', '/families', { name: '幸福一家' }, token1);
    console.log(`创建家庭组: ${createFamily.code === 0 ? '✅ 成功' : '❌ 失败'}`, createFamily.message);
    if (createFamily.code === 0) {
      familyId = createFamily.data.familyId;
      inviteCode = createFamily.data.inviteCode;
      console.log(`家庭组ID: ${familyId}, 邀请码: ${inviteCode}`);
    }
  } catch (error) {
    console.log('❌ 创建家庭组失败:', error.message);
  }

  // ================ 测试3: 获取家庭组列表 ================
  console.log('\n📝 测试3: 获取家庭组列表');
  try {
    const getFamilies = await makeRequest('GET', '/families', null, token1);
    console.log(`获取家庭组列表: ${getFamilies.code === 0 ? '✅ 成功' : '❌ 失败'}`);
    if (getFamilies.code === 0) {
      console.log(`家庭组数量: ${getFamilies.data.families.length}`);
    }
  } catch (error) {
    console.log('❌ 获取家庭组列表失败:', error.message);
  }

  // ================ 测试4: 获取家庭组详情 ================
  console.log('\n📝 测试4: 获取家庭组详情');
  try {
    const getFamilyDetail = await makeRequest('GET', `/families/${familyId}`, null, token1);
    console.log(`获取家庭组详情: ${getFamilyDetail.code === 0 ? '✅ 成功' : '❌ 失败'}`);
    if (getFamilyDetail.code === 0) {
      console.log(`成员数量: ${getFamilyDetail.data.members.length}`);
    }
  } catch (error) {
    console.log('❌ 获取家庭组详情失败:', error.message);
  }

  // ================ 测试5: 用户2加入家庭组 ================
  console.log('\n📝 测试5: 用户2加入家庭组');
  try {
    const joinFamily = await makeRequest('POST', '/families/join', { inviteCode }, token2);
    console.log(`用户2加入家庭组: ${joinFamily.code === 0 ? '✅ 成功' : '❌ 失败'}`, joinFamily.message);
  } catch (error) {
    console.log('❌ 加入家庭组失败:', error.message);
  }

  // ================ 测试6: 重新生成邀请码 ================
  console.log('\n📝 测试6: 重新生成邀请码');
  try {
    const regenerateInvite = await makeRequest('POST', `/families/${familyId}/invite`, null, token1);
    console.log(`重新生成邀请码: ${regenerateInvite.code === 0 ? '✅ 成功' : '❌ 失败'}`);
    if (regenerateInvite.code === 0) {
      console.log(`新邀请码: ${regenerateInvite.data.inviteCode}`);
    }
  } catch (error) {
    console.log('❌ 重新生成邀请码失败:', error.message);
  }

  // ================ 测试7: 添加成员 ================
  console.log('\n📝 测试7: 添加成员');
  try {
    // 先注册一个新用户作为测试
    const register3 = await makeRequest('POST', '/auth/register', {
      phone: '13800138003',
      password: '123456',
      nickname: '测试用户3'
    });
    if (register3.code === 0 || register3.code === 1001) {
      const addMember = await makeRequest('POST', `/families/${familyId}/members`, {
        phone: '13800138003',
        role: 'member'
      }, token1);
      console.log(`添加成员: ${addMember.code === 0 ? '✅ 成功' : '❌ 失败'}`, addMember.message);
    }
  } catch (error) {
    console.log('❌ 添加成员失败:', error.message);
  }

  // ================ 测试8: 更新成员权限 ================
  console.log('\n📝 测试8: 更新成员权限');
  try {
    const updatePermission = await makeRequest('PUT', `/families/${familyId}/members/${userId2}/permissions`, {
      role: 'admin'
    }, token1);
    console.log(`更新成员权限: ${updatePermission.code === 0 ? '✅ 成功' : '❌ 失败'}`, updatePermission.message);
  } catch (error) {
    console.log('❌ 更新成员权限失败:', error.message);
  }

  // ================ 测试9: 获取家庭组照片 ================
  console.log('\n📝 测试9: 获取家庭组照片');
  try {
    const getFamilyPhotos = await makeRequest('GET', `/families/${familyId}/photos`, null, token1);
    console.log(`获取家庭组照片: ${getFamilyPhotos.code === 0 ? '✅ 成功' : '❌ 失败'}`);
    if (getFamilyPhotos.code === 0) {
      console.log(`照片数量: ${getFamilyPhotos.data.photos.length}`);
    }
  } catch (error) {
    console.log('❌ 获取家庭组照片失败:', error.message);
  }

  // ================ 测试10: 用户2退出家庭组 ================
  console.log('\n📝 测试10: 用户2退出家庭组');
  try {
    const leaveFamily = await makeRequest('POST', `/families/${familyId}/leave`, null, token2);
    console.log(`用户2退出家庭组: ${leaveFamily.code === 0 ? '✅ 成功' : '❌ 失败'}`, leaveFamily.message);
  } catch (error) {
    console.log('❌ 退出家庭组失败:', error.message);
  }

  console.log('\n🎉 家庭组API联调测试完成!');
}

test().catch(console.error);

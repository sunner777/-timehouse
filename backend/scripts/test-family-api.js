/**
 * 家庭组API测试脚本
 */
const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api/v1';

// 测试用户信息
const testUser1 = {
  phone: '13800138001',
  password: '123456',
  nickname: '测试用户1'
};

const testUser2 = {
  phone: '13800138002',
  password: '123456',
  nickname: '测试用户2'
};

let user1Token = '';
let user1Id = '';
let user2Token = '';
let user2Id = '';
let testFamilyId = '';
let testInviteCode = '';

// 延迟函数
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// 测试注册
async function testRegister() {
  console.log('\n=== 测试用户注册 ===');
  try {
    // 注册用户1
    const res1 = await axios.post(`${BASE_URL}/auth/register`, testUser1);
    console.log('✅ 用户1注册成功:', res1.data);
    user1Token = res1.data.data.token;
    user1Id = res1.data.data.userId;

    // 注册用户2
    const res2 = await axios.post(`${BASE_URL}/auth/register`, testUser2);
    console.log('✅ 用户2注册成功:', res2.data);
    user2Token = res2.data.data.token;
    user2Id = res2.data.data.userId;
    
    return true;
  } catch (error) {
    // 如果用户已存在，尝试登录
    if (error.response && error.response.data.code === 1001) {
      console.log('⚠️ 用户已存在，尝试登录');
      return testLogin();
    }
    console.error('❌ 注册失败:', error.response?.data || error.message);
    return false;
  }
}

// 测试登录
async function testLogin() {
  console.log('\n=== 测试用户登录 ===');
  try {
    const res1 = await axios.post(`${BASE_URL}/auth/login`, {
      phone: testUser1.phone,
      password: testUser1.password
    });
    console.log('✅ 用户1登录成功:', res1.data);
    user1Token = res1.data.data.token;
    user1Id = res1.data.data.userId;

    const res2 = await axios.post(`${BASE_URL}/auth/login`, {
      phone: testUser2.phone,
      password: testUser2.password
    });
    console.log('✅ 用户2登录成功:', res2.data);
    user2Token = res2.data.data.token;
    user2Id = res2.data.data.userId;
    
    return true;
  } catch (error) {
    console.error('❌ 登录失败:', error.response?.data || error.message);
    return false;
  }
}

// 测试创建家庭组
async function testCreateFamily() {
  console.log('\n=== 测试创建家庭组 ===');
  try {
    const res = await axios.post(
      `${BASE_URL}/families`,
      { name: '幸福一家' },
      { headers: { Authorization: `Bearer ${user1Token}` } }
    );
    console.log('✅ 创建家庭组成功:', res.data);
    testFamilyId = res.data.data.familyId;
    testInviteCode = res.data.data.inviteCode;
    return true;
  } catch (error) {
    console.error('❌ 创建家庭组失败:', error.response?.data || error.message);
    return false;
  }
}

// 测试获取家庭组列表
async function testGetFamilyList() {
  console.log('\n=== 测试获取家庭组列表 ===');
  try {
    const res = await axios.get(`${BASE_URL}/families`, {
      headers: { Authorization: `Bearer ${user1Token}` }
    });
    console.log('✅ 获取家庭组列表成功:', res.data);
    return true;
  } catch (error) {
    console.error('❌ 获取家庭组列表失败:', error.response?.data || error.message);
    return false;
  }
}

// 测试获取家庭组详情
async function testGetFamilyDetail() {
  console.log('\n=== 测试获取家庭组详情 ===');
  try {
    const res = await axios.get(`${BASE_URL}/families/${testFamilyId}`, {
      headers: { Authorization: `Bearer ${user1Token}` }
    });
    console.log('✅ 获取家庭组详情成功:', res.data);
    return true;
  } catch (error) {
    console.error('❌ 获取家庭组详情失败:', error.response?.data || error.message);
    return false;
  }
}

// 测试使用邀请码加入家庭组
async function testJoinFamily() {
  console.log('\n=== 测试使用邀请码加入家庭组 ===');
  try {
    const res = await axios.post(
      `${BASE_URL}/families/join`,
      { inviteCode: testInviteCode },
      { headers: { Authorization: `Bearer ${user2Token}` } }
    );
    console.log('✅ 用户2加入家庭组成功:', res.data);
    return true;
  } catch (error) {
    console.error('❌ 加入家庭组失败:', error.response?.data || error.message);
    return false;
  }
}

// 测试重新生成邀请码
async function testGenerateInviteCode() {
  console.log('\n=== 测试重新生成邀请码 ===');
  try {
    const res = await axios.post(
      `${BASE_URL}/families/${testFamilyId}/invite`,
      {},
      { headers: { Authorization: `Bearer ${user1Token}` } }
    );
    console.log('✅ 重新生成邀请码成功:', res.data);
    testInviteCode = res.data.data.inviteCode;
    return true;
  } catch (error) {
    console.error('❌ 重新生成邀请码失败:', error.response?.data || error.message);
    return false;
  }
}

// 测试上传照片到家庭组
async function testUploadPhotoToFamily() {
  console.log('\n=== 测试上传照片到家庭组 ===');
  try {
    // 先获取TOS上传签名
    const signatureRes = await axios.post(
      `${BASE_URL}/photos/tos-upload-signature`,
      { fileName: 'test-family-photo.jpg', contentType: 'image/jpeg' },
      { headers: { Authorization: `Bearer ${user1Token}` } }
    );
    console.log('✅ 获取上传签名成功');

    // 模拟上传到TOS成功，现在上传到数据库
    const uploadRes = await axios.post(
      `${BASE_URL}/photos/upload`,
      {
        url: signatureRes.data.data.uploadUrl.split('?')[0],
        thumbnailUrl: signatureRes.data.data.uploadUrl.split('?')[0],
        fileName: 'test-family-photo.jpg',
        size: 102400,
        contentType: 'image/jpeg',
        familyId: testFamilyId
      },
      { headers: { Authorization: `Bearer ${user1Token}` } }
    );
    console.log('✅ 上传照片到家庭组成功:', uploadRes.data);
    return uploadRes.data.data.id;
  } catch (error) {
    console.error('❌ 上传照片失败:', error.response?.data || error.message);
    return null;
  }
}

// 测试获取家庭组照片
async function testGetFamilyPhotos() {
  console.log('\n=== 测试获取家庭组照片 ===');
  try {
    const res = await axios.get(`${BASE_URL}/families/${testFamilyId}/photos`, {
      headers: { Authorization: `Bearer ${user1Token}` }
    });
    console.log('✅ 获取家庭组照片成功:', res.data);
    return true;
  } catch (error) {
    console.error('❌ 获取家庭组照片失败:', error.response?.data || error.message);
    return false;
  }
}

// 测试更新成员权限
async function testUpdateMemberPermission() {
  console.log('\n=== 测试更新成员权限 ===');
  try {
    const res = await axios.put(
      `${BASE_URL}/families/${testFamilyId}/members/${user2Id}/permissions`,
      { role: 'admin' },
      { headers: { Authorization: `Bearer ${user1Token}` } }
    );
    console.log('✅ 更新成员权限成功:', res.data);
    return true;
  } catch (error) {
    console.error('❌ 更新成员权限失败:', error.response?.data || error.message);
    return false;
  }
}

// 主测试流程
async function main() {
  console.log('🚀 开始家庭组API测试...');
  
  // 1. 注册/登录
  let loginSuccess = await testRegister();
  if (!loginSuccess) {
    console.log('\n❌ 无法登录，测试终止');
    return;
  }
  
  await delay(500);
  
  // 2. 创建家庭组
  const createSuccess = await testCreateFamily();
  if (!createSuccess) return;
  
  await delay(500);
  
  // 3. 获取家庭组列表
  await testGetFamilyList();
  
  await delay(500);
  
  // 4. 获取家庭组详情
  await testGetFamilyDetail();
  
  await delay(500);
  
  // 5. 用户2加入家庭组
  await testJoinFamily();
  
  await delay(500);
  
  // 6. 重新生成邀请码
  await testGenerateInviteCode();
  
  await delay(500);
  
  // 7. 上传照片到家庭组
  const photoId = await testUploadPhotoToFamily();
  
  await delay(500);
  
  // 8. 获取家庭组照片
  if (photoId) {
    await testGetFamilyPhotos();
  }
  
  await delay(500);
  
  // 9. 更新成员权限
  await testUpdateMemberPermission();
  
  console.log('\n🎉 家庭组API测试完成!');
}

main().catch(console.error);

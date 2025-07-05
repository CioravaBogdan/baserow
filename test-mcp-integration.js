#!/usr/bin/env node

/**
 * Test MCP Integration with Baserow
 * Verifică funcționalitatea serverului MCP și conexiunea cu Baserow
 */

import * as dotenv from 'dotenv';
import axios from 'axios';

dotenv.config();

class BaserowMCPTester {
  constructor() {
    this.baserowUrl = process.env.BASEROW_URL || 'http://localhost:8010';
    this.apiToken = process.env.BASEROW_API_TOKEN;
    console.log(`🔧 Testing Baserow MCP Integration`);
    console.log(`📍 Baserow URL: ${this.baserowUrl}`);
    console.log(`🔑 API Token: ${this.apiToken ? this.apiToken.substring(0, 10) + '...' : 'NOT SET'}`);
    console.log('─'.repeat(60));
  }

  getHttpClient() {
    if (!this.apiToken) {
      throw new Error('BASEROW_API_TOKEN environment variable is required');
    }
    return axios.create({
      baseURL: `${this.baserowUrl}/api`,
      headers: {
        'Authorization': `Token ${this.apiToken}`,
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });
  }

  async testConnection() {
    console.log('🌐 Testing basic connection...');
    try {
      const response = await axios.get(this.baserowUrl, { timeout: 5000 });
      console.log('✅ Baserow server is reachable');
      return true;
    } catch (error) {
      console.log('❌ Cannot reach Baserow server:', error.message);
      return false;
    }
  }

  async testApiAuth() {
    console.log('🔐 Testing API authentication...');
    try {
      const client = this.getHttpClient();
      const response = await client.get('/groups/');
      console.log('✅ API authentication successful');
      console.log(`📊 Found ${response.data.length} groups`);
      return true;
    } catch (error) {
      console.log('❌ API authentication failed:', error.message);
      if (error.response) {
        console.log(`   Status: ${error.response.status}`);
        console.log(`   Data: ${JSON.stringify(error.response.data)}`);
      }
      return false;
    }
  }

  async testUserInfo() {
    console.log('👤 Testing user information...');
    try {
      const client = this.getHttpClient();
      const response = await client.get('/user/');
      console.log('✅ User information retrieved');
      console.log(`   Name: ${response.data.first_name} ${response.data.last_name}`);
      console.log(`   Email: ${response.data.email}`);
      console.log(`   Active: ${response.data.is_active}`);
      return true;
    } catch (error) {
      console.log('❌ Failed to get user information:', error.message);
      return false;
    }
  }

  async testApplications() {
    console.log('📊 Testing applications/databases...');
    try {
      const client = this.getHttpClient();
      const response = await client.get('/applications/');
      const apps = response.data.results || response.data;
      console.log(`✅ Found ${apps.length} applications/databases`);
      
      apps.forEach((app, index) => {
        console.log(`   ${index + 1}. ${app.name} (ID: ${app.id}, Type: ${app.type})`);
      });
      
      return true;
    } catch (error) {
      console.log('❌ Failed to get applications:', error.message);
      return false;
    }
  }

  async runAllTests() {
    console.log('🚀 Starting Baserow MCP Integration Tests\n');
    
    const tests = [
      { name: 'Connection', test: () => this.testConnection() },
      { name: 'API Auth', test: () => this.testApiAuth() },
      { name: 'User Info', test: () => this.testUserInfo() },
      { name: 'Applications', test: () => this.testApplications() }
    ];

    let passed = 0;
    let failed = 0;

    for (const { name, test } of tests) {
      try {
        const result = await test();
        if (result) {
          passed++;
        } else {
          failed++;
        }
      } catch (error) {
        console.log(`❌ ${name} test failed with error:`, error.message);
        failed++;
      }
      console.log(''); // Empty line for readability
    }

    console.log('─'.repeat(60));
    console.log(`📊 Test Results: ${passed} passed, ${failed} failed`);
    
    if (failed === 0) {
      console.log('🎉 All tests passed! MCP server should work correctly.');
      console.log('\n📋 Next steps:');
      console.log('1. Add the MCP configuration to Claude Desktop');
      console.log('2. Restart Claude Desktop');
      console.log('3. Test with: "Check my Baserow health"');
    } else {
      console.log('⚠️  Some tests failed. Please check the configuration.');
    }

    return failed === 0;
  }
}

// Run tests
const tester = new BaserowMCPTester();
tester.runAllTests().catch(console.error);

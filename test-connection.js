const fetch = require('node-fetch');

async function testBaserowConnection() {
  const apiUrl = 'http://localhost:8080/api';
  const apiToken = 'CtsgvsiPCkAzfEMXsqXQGNSlN5ZtbqTu'; // Din screenshot

  try {
    console.log('Testing Baserow API connection...');
    
    // Test health endpoint
    const healthResponse = await fetch(`${apiUrl}/_health/`);
    console.log('Health check:', healthResponse.status);

    // Test authentication
    const authResponse = await fetch(`${apiUrl}/database/tables/`, {
      headers: {
        'Authorization': `Token ${apiToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (authResponse.ok) {
      const tables = await authResponse.json();
      console.log('✅ Authentication successful!');
      console.log(`Found ${tables.count} tables in database`);
      console.log('Tables:', tables.results.map(t => ({ id: t.id, name: t.name })));
    } else {
      console.log('❌ Authentication failed:', authResponse.status);
    }

  } catch (error) {
    console.error('Connection error:', error.message);
  }
}

testBaserowConnection();
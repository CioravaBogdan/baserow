import Database from 'better-sqlite3';

try {
  console.log('Testing SQLite connection...');
  const db = new Database('dragulai_project.db');
  
  const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table'").all();
  console.log('Tables found:', tables.map(t => t.name));
  
  if (tables.length > 0) {
    console.log('Database has tables - checking first table...');
    const firstTable = tables[0].name;
    const count = db.prepare(`SELECT COUNT(*) as count FROM ${firstTable}`).get();
    console.log(`Table ${firstTable} has ${count.count} rows`);
  }
  
  db.close();
  console.log('✅ SQLite connection test: SUCCESS');
} catch(err) {
  console.error('❌ SQLite connection test: FAILED', err.message);
  process.exit(1);
}

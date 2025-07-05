# Baserow MCP Quick Reference

## Quick Function Reference Card

### 🔧 Health & Diagnostics
- `health_check` - Check Baserow server status
- `test_api_connection` - Verify API connection

### 🗄️ Database Operations
- `list_databases` - List all databases
- `get_database_info` - Get database details
- `create_database` - Create new database
- `database_schema_analysis` - Analyze database structure
- `backup_database` - Create database backup
- `duplicate_database` - Duplicate database
- `optimize_database` - Get optimization recommendations
- `database_monitoring` - Monitor database metrics
- `database_migration` - Plan/execute data migration
- `database_security_audit` - Security audit

### 📋 Table Operations
- `list_tables` - List tables in database
- `get_table_info` - Get table details
- `create_table` - Create new table
- `analyze_table_structure` - Analyze table structure

### 🏷️ Field Operations
- `list_fields` - List fields in table
- `create_field` - Create new field
- `update_field` - Update existing field
- `delete_field` - Delete field

### 📄 Row Operations
- `list_rows` - List rows with pagination/filtering
- `get_row` - Get specific row
- `create_row` - Create new row
- `update_row` - Update existing row
- `delete_row` - Delete row

### 📦 Advanced Operations
- `bulk_data_operations` - Bulk insert/update/delete
- `advanced_query_builder` - Complex queries with joins/filters

### 📈 Analytics & Content Management
- `analyze_content_performance` - Content performance analysis
- `track_viral_trends` - Track viral trends and engagement
- `generate_content_insights` - Generate content insights
- `export_analytics_report` - Export analytics reports

## Quick Start Commands for Claude

```
"Check my Baserow health and list all databases"
"Create a new database called 'Marketing' and add a table for campaigns"
"Analyze the performance of content in table 123"
"Get all customers from table 456 with pagination"
"Create a backup of database 789"
```

## Common Parameter Patterns

- **Database ID**: Usually required for database operations
- **Table ID**: Required for table-specific operations
- **Field ID**: Required for field modifications
- **Row ID**: Required for specific row operations
- **Options**: Optional parameters for filtering, pagination, etc.

## Error Handling

All functions return structured responses with:
- Success: Detailed results in JSON format
- Error: Descriptive error messages with troubleshooting hints

## Configuration Requirements

1. Valid Baserow API token in `.env`
2. Accessible Baserow server URL
3. MCP server running and configured
4. Claude Desktop with proper MCP configuration

---

*Total Functions Available: 27*  
*All functions include Romanian descriptions for Claude integration*

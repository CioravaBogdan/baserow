# Baserow MCP Functions Guide

## Complete List of Available Functions for Claude Desktop Integration

This document provides a comprehensive overview of all MCP (Model Context Protocol) functions available through the Baserow integration. These functions can be used directly by Claude Desktop when the MCP server is properly configured.

---

## 🔧 Health & Diagnostics

### `health_check`
**Description**: Verificare starea de sănătate a serverului Baserow  
**Parameters**: None  
**Usage**: Check if Baserow server is running and accessible  
**Example**: "Check the health of my Baserow instance"

### `test_api_connection`
**Description**: Testare conexiunea API și autentificarea  
**Parameters**: None  
**Usage**: Verify API token and connection status  
**Example**: "Test my Baserow API connection"

---

## 🗄️ Database Operations

### `list_databases`
**Description**: Listarea tuturor bazelor de date disponibile  
**Parameters**: None  
**Usage**: Get all databases in your Baserow workspace  
**Example**: "Show me all my databases"

### `get_database_info`
**Description**: Obținere informații detaliate despre o bază de date  
**Parameters**: 
- `database_id` (required): ID of the database  
**Usage**: Get detailed information about a specific database  
**Example**: "Get information about database 123"

### `create_database`
**Description**: Creare bază de date nouă  
**Parameters**: 
- `name` (required): Name for the new database
- `group_id` (required): Group ID where database will be created  
**Usage**: Create a new database in your workspace  
**Example**: "Create a new database called 'Customer Management'"

---

## 📋 Table Operations

### `list_tables`
**Description**: Listarea tabelelor dintr-o bază de date  
**Parameters**: 
- `database_id` (required): Database ID  
**Usage**: Get all tables in a specific database  
**Example**: "List all tables in database 123"

### `get_table_info`
**Description**: Obținere informații detaliate despre un tabel  
**Parameters**: 
- `table_id` (required): Table ID  
**Usage**: Get detailed information about a specific table  
**Example**: "Get information about table 456"

### `create_table`
**Description**: Creare tabel nou  
**Parameters**: 
- `database_id` (required): Database ID
- `name` (required): Table name
- `init_with_data` (optional): Initialize with sample data  
**Usage**: Create a new table in a database  
**Example**: "Create a table called 'Products' in database 123"

### `analyze_table_structure`
**Description**: Analiză structură tabel și recomandări optimizare  
**Parameters**: 
- `table_id` (required): Table ID
- Additional analysis options  
**Usage**: Analyze table structure and get optimization recommendations  
**Example**: "Analyze the structure of table 456"

---

## 🏷️ Field Operations

### `list_fields`
**Description**: Listarea câmpurilor dintr-un tabel  
**Parameters**: 
- `table_id` (required): Table ID  
**Usage**: Get all fields/columns in a table  
**Example**: "List all fields in table 456"

### `create_field`
**Description**: Creare câmp nou în tabel  
**Parameters**: 
- `table_id` (required): Table ID
- `type` (required): Field type (text, number, date, etc.)
- `name` (required): Field name
- `options` (optional): Additional field configuration  
**Usage**: Add a new field to a table  
**Example**: "Create a text field called 'Description' in table 456"

### `update_field`
**Description**: Actualizare câmp existent  
**Parameters**: 
- `field_id` (required): Field ID
- Additional update data  
**Usage**: Modify an existing field  
**Example**: "Update field 789 to be required"

### `delete_field`
**Description**: Ștergere câmp din tabel  
**Parameters**: 
- `field_id` (required): Field ID  
**Usage**: Remove a field from a table  
**Example**: "Delete field 789"

---

## 📄 Row Operations

### `list_rows`
**Description**: Listarea înregistrărilor dintr-un tabel  
**Parameters**: 
- `table_id` (required): Table ID
- `page` (optional): Page number
- `size` (optional): Number of rows per page
- `search` (optional): Search term
- `order_by` (optional): Sort field  
**Usage**: Get rows/records from a table with filtering and pagination  
**Example**: "Get the first 10 rows from table 456"

### `get_row`
**Description**: Obținere înregistrare specifică  
**Parameters**: 
- `table_id` (required): Table ID
- `row_id` (required): Row ID  
**Usage**: Get a specific row by ID  
**Example**: "Get row 101 from table 456"

### `create_row`
**Description**: Creare înregistrare nouă  
**Parameters**: 
- `table_id` (required): Table ID
- `data` (required): Row data object
- `before_id` (optional): Insert before specific row  
**Usage**: Add a new row to a table  
**Example**: "Create a new row in table 456 with name 'John Doe'"

### `update_row`
**Description**: Actualizare înregistrare existentă  
**Parameters**: 
- `table_id` (required): Table ID
- `row_id` (required): Row ID
- `data` (required): Updated data  
**Usage**: Modify an existing row  
**Example**: "Update row 101 in table 456 with new email address"

### `delete_row`
**Description**: Ștergere înregistrare  
**Parameters**: 
- `table_id` (required): Table ID
- `row_id` (required): Row ID  
**Usage**: Remove a row from a table  
**Example**: "Delete row 101 from table 456"

---

## 🔍 Advanced Database Management

### `database_schema_analysis`
**Description**: Analiză detaliată structură bază de date  
**Parameters**: 
- `database_id` (required): Database ID
- Additional analysis options  
**Usage**: Get comprehensive schema analysis with recommendations  
**Example**: "Analyze the complete schema of database 123"

### `backup_database`
**Description**: Backup complet bază de date  
**Parameters**: 
- `database_id` (required): Database ID
- `backup_type` (optional): Type of backup  
**Usage**: Create a backup of the database  
**Example**: "Create a backup of database 123"

### `duplicate_database`
**Description**: Duplicare bază de date  
**Parameters**: 
- `source_database_id` (required): Source database ID
- `new_database_name` (required): Name for the duplicate
- Additional options  
**Usage**: Create a copy of an existing database  
**Example**: "Duplicate database 123 as 'Development Copy'"

### `optimize_database`
**Description**: Optimizare performanță bază de date  
**Parameters**: 
- `database_id` (required): Database ID
- Optimization options  
**Usage**: Get optimization recommendations for better performance  
**Example**: "Optimize database 123 for better performance"

### `database_monitoring`
**Description**: Monitorizare metrici în timp real  
**Parameters**: 
- `database_id` (required): Database ID
- Monitoring options  
**Usage**: Monitor database metrics and performance  
**Example**: "Monitor the performance of database 123"

### `database_migration`
**Description**: Migrare date între baze de date  
**Parameters**: 
- `source_database_id` (required): Source database ID
- `target_database_id` (required): Target database ID
- Migration options  
**Usage**: Plan or execute data migration between databases  
**Example**: "Migrate data from database 123 to database 456"

### `database_security_audit`
**Description**: Audit securitate și conformitate  
**Parameters**: 
- `database_id` (required): Database ID
- Audit options  
**Usage**: Perform security audit and compliance check  
**Example**: "Audit the security of database 123"

---

## 📦 Bulk Data Operations

### `bulk_data_operations`
**Description**: Operații în bloc pentru volume mari de date  
**Parameters**: 
- `operation_type` (required): Type of bulk operation (bulk_insert, bulk_update, bulk_delete)
- `table_id` (required): Table ID
- Additional operation-specific data  
**Usage**: Perform bulk operations on large datasets  
**Example**: "Perform bulk insert of 1000 records into table 456"

---

## 🔍 Advanced Query Builder

### `advanced_query_builder`
**Description**: Constructor de interogări complexe cu filtre și agregări  
**Parameters**: 
- `database_id` (required): Database ID
- `query_config` (required): Query configuration object
- Additional query options  
**Usage**: Build and execute complex queries with joins, filters, and aggregations  
**Example**: "Query database 123 for all customers with orders in the last month"

---

## 📈 Content Analytics & Viral Management

### `analyze_content_performance`
**Description**: Analiză performanță conținut pentru marketing viral  
**Parameters**: 
- `table_id` (required): Table ID containing content
- Analysis options  
**Usage**: Analyze content performance metrics for viral marketing  
**Example**: "Analyze the performance of content in table 456"

### `track_viral_trends`
**Description**: Urmărire tendințe virale și metrici engagement  
**Parameters**: 
- `table_id` (required): Table ID
- `period` (optional): Tracking period  
**Usage**: Track viral trends and engagement metrics  
**Example**: "Track viral trends for content in table 456 over the last week"

### `generate_content_insights`
**Description**: Generare insights și recomandări pentru conținut  
**Parameters**: 
- `table_id` (required): Table ID
- Insight options  
**Usage**: Generate actionable insights for content strategy  
**Example**: "Generate insights for my content strategy from table 456"

### `export_analytics_report`
**Description**: Export rapoarte analytics în diverse formate  
**Parameters**: 
- `table_id` (required): Table ID
- `report_type` (optional): Type of report
- `format` (optional): Export format  
**Usage**: Export comprehensive analytics reports  
**Example**: "Export analytics report for table 456 as JSON"

---

## 🚀 How to Use These Functions with Claude Desktop

### Prerequisites
1. **Baserow Instance**: Running Baserow server (local or hosted)
2. **API Token**: Valid Baserow API token
3. **MCP Server**: This MCP server running and configured
4. **Claude Desktop**: With MCP configuration pointing to this server

### Example Usage Scenarios

#### Content Management
```
"Create a new database for my social media content, then create tables for posts, analytics, and viral trends"
```

#### Data Analysis
```
"Analyze the structure of my customer database and provide optimization recommendations"
```

#### Performance Monitoring
```
"Check the health of my Baserow instance and monitor the performance of database 123"
```

#### Bulk Operations
```
"Perform a bulk update on all inactive customers in table 456 to mark them as archived"
```

#### Analytics & Insights
```
"Analyze the content performance in my posts table and generate insights for improving viral reach"
```

### Configuration Tips

1. **Environment Variables**: Ensure `.env` file has correct Baserow URL and API token
2. **MCP Configuration**: Add this server to Claude Desktop's MCP config
3. **Network Access**: Ensure Claude Desktop can reach your Baserow instance
4. **API Permissions**: Verify API token has necessary permissions for all operations

### Error Handling

All functions include comprehensive error handling and will return descriptive error messages if:
- API token is invalid or expired
- Network connection fails
- Baserow server is unreachable
- Invalid parameters are provided
- Permission errors occur

### Performance Notes

- Functions are optimized for real-time interaction with Claude
- Large operations may take time to complete
- Pagination is used for large datasets
- Analytics functions may require multiple API calls

---

## 📞 Support & Troubleshooting

If you encounter issues:

1. **Check Health**: Use `health_check` and `test_api_connection` first
2. **Verify Configuration**: Ensure `.env` file is properly configured
3. **API Token**: Verify your Baserow API token is valid and has correct permissions
4. **Network**: Ensure Baserow server is accessible from Claude Desktop
5. **Logs**: Check MCP server logs for detailed error information

For additional support, refer to:
- `TROUBLESHOOTING.md` for common issues
- Baserow API documentation for endpoint details
- MCP protocol documentation for integration details

---

*Last Updated: Current implementation includes all basic and advanced functions with comprehensive error handling and Romanian descriptions for optimal Claude integration.*

# API Documentation - Baserow Viral Content Management

This document provides comprehensive API documentation for the Baserow viral content management system.

## Base Configuration

- **Base URL**: `https://baserow.infant-viral.com/api`
- **Authentication**: Token-based (`Authorization: Token YOUR_TOKEN`)
- **Content-Type**: `application/json`
- **Rate Limits**: 1000 requests/hour per token

## Authentication

### API Token Types

1. **N8N Workflows Token** - Full read/write access
2. **Analytics Token** - Read-only access  
3. **Claude MCP Token** - Full access including schema modifications

### Usage
```bash
curl -H "Authorization: Token YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     https://baserow.infant-viral.com/api/
```

## Database Structure

### Database ID: 1 (Viral Content Management)

Tables overview:
- Table 1: Content_Ideas
- Table 2: Video_Production  
- Table 3: Publishing_Schedule
- Table 4: Performance_Analytics
- Table 5: Content_Calendar

## Content_Ideas API (Table 1)

### List Content Ideas
```bash
GET /api/database/rows/table/1/
```

**Query Parameters:**
- `size`: Number of results (default: 100, max: 200)
- `page`: Page number
- `search`: Search in title and notes
- `order_by`: Field to order by (prefix with `-` for descending)
- `filter__field__contains`: Filter by field content

**Example:**
```bash
curl -H "Authorization: Token YOUR_TOKEN" \
  "https://baserow.infant-viral.com/api/database/rows/table/1/?size=50&order_by=-created_date&filter__status__equal=approved"
```

**Response:**
```json
{
  "count": 25,
  "next": "https://baserow.infant-viral.com/api/database/rows/table/1/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "title": "Toddler Sleep Regression Solutions",
      "hook": "POV: Your 2-year-old suddenly hates bedtime...",
      "content_type": "educational",
      "target_age": "1-2",
      "viral_score": 8,
      "status": "approved",
      "created_date": "2023-12-15",
      "notes": "Focus on gentle techniques"
    }
  ]
}
```

### Create Content Idea
```bash
POST /api/database/rows/table/1/
```

**Payload:**
```json
{
  "title": "Gentle Discipline for Toddlers",
  "hook": "Instead of time-outs, try this gentle approach...",
  "content_type": "gentle_parenting", 
  "target_age": "2-3",
  "viral_score": 7,
  "status": "idea",
  "notes": "Based on Montessori principles"
}
```

### Update Content Idea
```bash
PATCH /api/database/rows/table/1/{id}/
```

### Delete Content Idea
```bash
DELETE /api/database/rows/table/1/{id}/
```

## Video_Production API (Table 2)

### List Video Productions
```bash
GET /api/database/rows/table/2/
```

**Filters:**
- `filter__production_status__equal`: Filter by status
- `filter__content_idea__equal`: Filter by linked content idea ID

### Create Video Production
```bash
POST /api/database/rows/table/2/
```

**Payload:**
```json
{
  "content_idea": [1],
  "script_english": "Today we're talking about toddler sleep...",
  "veo3_prompt": "A calm nursery scene with soft lighting...",
  "video_segments": 4,
  "voice_over_text": "Bedtime struggles are common...",
  "production_status": "scripting",
  "duration_seconds": 32
}
```

## Publishing_Schedule API (Table 3)

### List Scheduled Publications
```bash
GET /api/database/rows/table/3/
```

**Useful Filters:**
- `filter__scheduled_date__date_equal`: Filter by specific date
- `filter__published__equal`: Filter by published status
- `filter__platform__contains`: Filter by platform

### Schedule Publication
```bash
POST /api/database/rows/table/3/
```

**Payload:**
```json
{
  "video": [1],
  "platform": ["TikTok", "Instagram"],
  "scheduled_date": "2023-12-20",
  "scheduled_time": "18:00",
  "title_variations": "{\"TikTok\": \"Sleep hack every parent needs!\", \"Instagram\": \"Gentle bedtime routine that works\"}",
  "hashtags": "#toddlersleep #gentleparenting #parentingtips #sleeptraining",
  "published": false
}
```

## Performance_Analytics API (Table 4)

### Get Analytics Data
```bash
GET /api/database/rows/table/4/
```

**Advanced Filtering:**
- `filter__views__gte`: Views greater than or equal
- `filter__checked_date__date_gte`: Date range filtering
- `filter__platform__equal`: Specific platform

**Example - Top Performing Videos:**
```bash
curl -H "Authorization: Token YOUR_TOKEN" \
  "https://baserow.infant-viral.com/api/database/rows/table/4/?order_by=-views&size=10"
```

### Add Performance Data
```bash
POST /api/database/rows/table/4/
```

**Payload:**
```json
{
  "video": [1],
  "platform": "TikTok",
  "views": 125000,
  "likes": 8500,
  "comments": 234,
  "shares": 1200,
  "watch_time_avg": 28,
  "revenue": 45.50,
  "checked_date": "2023-12-15"
}
```

## Content_Calendar API (Table 5)

### Get Weekly Calendar
```bash
GET /api/database/rows/table/5/
```

**Filter by Date Range:**
```bash
curl -H "Authorization: Token YOUR_TOKEN" \
  "https://baserow.infant-viral.com/api/database/rows/table/5/?filter__week_start__date_gte=2023-12-11&filter__week_start__date_lte=2023-12-17"
```

## Advanced Queries

### Bulk Operations

#### Bulk Create
```bash
POST /api/database/rows/table/{table_id}/batch/
```

**Payload:**
```json
{
  "items": [
    {
      "title": "First idea",
      "content_type": "educational"
    },
    {
      "title": "Second idea", 
      "content_type": "humor"
    }
  ]
}
```

#### Bulk Update
```bash
PATCH /api/database/rows/table/{table_id}/batch/
```

#### Bulk Delete
```bash
DELETE /api/database/rows/table/{table_id}/batch/
```

**Payload:**
```json
{
  "items": [1, 2, 3, 4, 5]
}
```

### Complex Filtering

#### Multiple Conditions
```bash
# Ideas that are approved AND have viral score > 7
GET /api/database/rows/table/1/?filter__status__equal=approved&filter__viral_score__gte=7
```

#### Date Range Queries
```bash
# Content created in last 30 days
GET /api/database/rows/table/1/?filter__created_date__date_gte=2023-11-15
```

#### Text Search
```bash
# Search in multiple fields
GET /api/database/rows/table/1/?search=sleep toddler
```

## MCP Server API

### Base URL
`https://baserow.infant-viral.com/mcp`

### Health Check
```bash
GET /mcp/health
```

### Natural Language Queries
```bash
POST /mcp/query
```

**Payload:**
```json
{
  "query": "Show me all approved content ideas with viral score above 8",
  "context": "content_ideas",
  "format": "structured"
}
```

### Schema Operations
```bash
POST /mcp/schema/modify
```

**Add Field Example:**
```json
{
  "table": "content_ideas",
  "operation": "add_field",
  "field": {
    "name": "competitor_analysis",
    "type": "long_text"
  }
}
```

## Webhooks

### Configure Webhooks
```bash
POST /api/database/webhooks/table/{table_id}/
```

**Payload:**
```json
{
  "url": "https://your-n8n-instance.com/webhook/baserow",
  "include_all_events": false,
  "events": ["row.created", "row.updated"],
  "headers": {
    "Authorization": "Bearer your-webhook-token"
  }
}
```

### Webhook Event Types
- `row.created`
- `row.updated` 
- `row.deleted`
- `table.created`
- `table.updated`

### Webhook Payload Example
```json
{
  "table_id": 1,
  "event_type": "row.created",
  "row_id": 123,
  "row": {
    "id": 123,
    "title": "New content idea",
    "status": "idea"
  },
  "timestamp": "2023-12-15T10:30:00Z"
}
```

## Export/Import

### Export Table Data
```bash
GET /api/database/export/table/{table_id}/
```

**Query Parameters:**
- `format`: csv, json, xml
- `csv_column_separator`: Default comma
- `csv_first_row_header`: true/false

### Import Data
```bash
POST /api/database/import/table/{table_id}/
```

**Form Data:**
```bash
curl -X POST \
  -H "Authorization: Token YOUR_TOKEN" \
  -F "file=@content_ideas.csv" \
  -F "data={\"csv_column_separator\":\",\",\"first_row_header\":true}" \
  https://baserow.infant-viral.com/api/database/import/table/1/
```

## Error Handling

### HTTP Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `429` - Rate Limited
- `500` - Server Error

### Error Response Format
```json
{
  "error": "ERROR_CODE",
  "detail": "Human readable error message",
  "field_errors": {
    "field_name": ["Field specific error"]
  }
}
```

## Rate Limiting

### Limits by Token Type
- **N8N Token**: 1000 requests/hour
- **Analytics Token**: 500 requests/hour  
- **Claude MCP Token**: 500 requests/hour

### Rate Limit Headers
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## Best Practices

### Pagination
Always use pagination for large datasets:
```bash
GET /api/database/rows/table/1/?size=50&page=1
```

### Efficient Filtering
Use specific filters instead of fetching all data:
```bash
# Good
GET /api/database/rows/table/1/?filter__status__equal=published

# Avoid
GET /api/database/rows/table/1/ # then filter client-side
```

### Bulk Operations
Use batch endpoints for multiple operations:
```bash
# Good
POST /api/database/rows/table/1/batch/

# Avoid multiple single requests
POST /api/database/rows/table/1/
POST /api/database/rows/table/1/
```

### Error Handling
Always handle rate limits and errors gracefully:
```javascript
try {
  const response = await fetch(url, options);
  if (response.status === 429) {
    // Wait and retry
    await new Promise(resolve => setTimeout(resolve, 60000));
    return retry();
  }
  return response.json();
} catch (error) {
  console.error('API Error:', error);
}
```

## Example Workflows

### Complete Content Workflow
1. **Create Content Idea**
   ```bash
   POST /api/database/rows/table/1/
   ```

2. **Approve and Start Production**
   ```bash
   PATCH /api/database/rows/table/1/{id}/
   # Update status to "approved"
   
   POST /api/database/rows/table/2/
   # Create video production record
   ```

3. **Schedule Publishing**
   ```bash
   POST /api/database/rows/table/3/
   # Create publishing schedule
   ```

4. **Track Performance**
   ```bash
   POST /api/database/rows/table/4/
   # Add analytics data
   ```

### Analytics Dashboard Query
```bash
# Get this week's performance summary
curl -H "Authorization: Token YOUR_TOKEN" \
  "https://baserow.infant-viral.com/api/database/rows/table/4/?filter__checked_date__date_gte=2023-12-11&filter__checked_date__date_lte=2023-12-17"
```

### Content Calendar Population
```bash
# Get next week's scheduled content
curl -H "Authorization: Token YOUR_TOKEN" \
  "https://baserow.infant-viral.com/api/database/rows/table/3/?filter__scheduled_date__date_gte=2023-12-18&filter__scheduled_date__date_lte=2023-12-24&filter__published__equal=false"
```

---

For additional support or custom integrations, refer to the official Baserow API documentation or contact the system administrator.

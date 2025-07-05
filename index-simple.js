#!/usr/bin/env node

/**
 * Simplified Baserow MCP Server for Debugging
 * Basic version to test Claude Desktop integration
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { 
  CallToolRequestSchema, 
  ListToolsRequestSchema
} from "@modelcontextprotocol/sdk/types.js";
import axios from 'axios';
import * as dotenv from 'dotenv';

dotenv.config();

class SimpleBaserowMCPServer {
  constructor() {
    this.server = new Server(
      {
        name: "baserow-simple",
        version: "1.0.0",
      },
      {
        capabilities: {
          tools: {},
        }
      }
    );
    this.baserowUrl = process.env.BASEROW_URL || 'http://localhost:8010';
    this.apiToken = process.env.BASEROW_API_TOKEN;
    this.setupHandlers();
  }

  // HTTP Client pentru API calls
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

  // Metoda pentru API calls
  async makeApiCall(method, endpoint, data = null) {
    try {
      const client = this.getHttpClient();
      const config = {
        method: method,
        url: endpoint
      };
      
      if (data && (method === 'POST' || method === 'PATCH' || method === 'PUT')) {
        config.data = data;
      }
      
      const response = await client(config);
      return response.data;
    } catch (error) {
      console.error(`API Call Error [${method} ${endpoint}]:`, error.message);
      throw new Error(`API Error: ${error.message}`);
    }
  }

  setupHandlers() {
    // List Tools Handler
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: "health_check",
            description: "Verifică starea serverului Baserow",
            inputSchema: { 
              type: "object", 
              properties: {}, 
              required: [] 
            }
          },
          {
            name: "test_connection",
            description: "Testează conexiunea cu API-ul Baserow",
            inputSchema: { 
              type: "object", 
              properties: {}, 
              required: [] 
            }
          },
          {
            name: "list_workspaces",
            description: "Listează workspace-urile disponibile",
            inputSchema: { 
              type: "object", 
              properties: {}, 
              required: [] 
            }
          }
        ]
      };
    });

    // Call Tool Handler
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;
      
      try {
        switch (name) {
          case "health_check":
            return await this.healthCheck();
          case "test_connection":
            return await this.testConnection();
          case "list_workspaces":
            return await this.listWorkspaces();
          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            { 
              type: "text", 
              text: `Error executing ${name}: ${error.message}` 
            }
          ],
          isError: true
        };
      }
    });
  }

  // Simple health check
  async healthCheck() {
    try {
      const response = await axios.get(this.baserowUrl, { timeout: 5000 });
      return {
        content: [
          { 
            type: "text", 
            text: `✅ Baserow server is reachable at ${this.baserowUrl}\nStatus: ${response.status}` 
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          { 
            type: "text", 
            text: `❌ Cannot reach Baserow server: ${error.message}` 
          }
        ],
        isError: true
      };
    }
  }

  // Test API connection
  async testConnection() {
    try {
      if (!this.apiToken) {
        throw new Error('No API token configured');
      }
      
      // Try a simple API call
      const client = this.getHttpClient();
      const response = await client.get('/workspaces/');
      
      return {
        content: [
          { 
            type: "text", 
            text: `✅ API connection successful!\nToken: ${this.apiToken.substring(0, 10)}...\nWorkspaces found: ${response.data.length || 0}` 
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          { 
            type: "text", 
            text: `❌ API connection failed: ${error.message}` 
          }
        ],
        isError: true
      };
    }
  }

  // List workspaces
  async listWorkspaces() {
    try {
      const workspaces = await this.makeApiCall('GET', '/workspaces/');
      
      if (!workspaces || workspaces.length === 0) {
        return {
          content: [
            { 
              type: "text", 
              text: "📁 No workspaces found or different API structure." 
            }
          ]
        };
      }
      
      return {
        content: [
          { 
            type: "text", 
            text: `📁 Workspaces (${workspaces.length}):\n${workspaces.map(ws => 
              `• ${ws.name || ws.id} (ID: ${ws.id})`
            ).join('\n')}` 
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          { 
            type: "text", 
            text: `❌ Failed to list workspaces: ${error.message}` 
          }
        ],
        isError: true
      };
    }
  }

  async start() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error("Simple Baserow MCP Server running on stdio");
  }
}

const server = new SimpleBaserowMCPServer();
server.start().catch(console.error);

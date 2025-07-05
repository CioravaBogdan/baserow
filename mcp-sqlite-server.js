#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ErrorCode,
  ListToolsRequestSchema,
  McpError,
} from '@modelcontextprotocol/sdk/types.js';
import Database from 'better-sqlite3';
import path from 'path';
import fs from 'fs';

const DB_PATH = path.join(process.cwd(), 'dragulai_project.db');

class SQLiteMCPServer {
  constructor() {
    this.server = new Server(
      {
        name: 'dragulai-sqlite-server',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupToolHandlers();
  }

  initializeDatabase() {
    const db = new Database(DB_PATH);
    
    // Create schema if database doesn't exist
    if (!fs.existsSync(DB_PATH) || db.prepare("SELECT name FROM sqlite_master WHERE type='table'").all().length === 0) {
      console.error('Initializing DraculAI project database...');
      
      // Create tables
      db.exec(`
        CREATE TABLE IF NOT EXISTS tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'on_hold')),
          priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
          category TEXT,
          assigned_to TEXT,
          due_date TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          completed_at DATETIME,
          estimated_hours REAL,
          actual_hours REAL,
          tags TEXT,
          dependencies TEXT,
          progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100)
        );

        CREATE TABLE IF NOT EXISTS milestones (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          target_date TEXT,
          status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'delayed')),
          completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS task_milestone_relations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER,
          milestone_id INTEGER,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
          FOREIGN KEY (milestone_id) REFERENCES milestones (id) ON DELETE CASCADE,
          UNIQUE(task_id, milestone_id)
        );

        CREATE TABLE IF NOT EXISTS notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT,
          category TEXT,
          tags TEXT,
          task_id INTEGER,
          milestone_id INTEGER,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
          FOREIGN KEY (milestone_id) REFERENCES milestones (id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS time_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER,
          description TEXT,
          hours REAL NOT NULL,
          log_date TEXT NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
        );

        -- Insert initial data
        INSERT OR IGNORE INTO milestones (name, description, target_date, status) VALUES
        ('Project Setup', 'Initial project configuration and environment setup', '2024-01-15', 'completed'),
        ('Core Development', 'Main application development phase', '2024-03-01', 'active'),
        ('Testing & QA', 'Comprehensive testing and quality assurance', '2024-04-15', 'active'),
        ('Deployment', 'Production deployment and launch', '2024-05-01', 'active');        INSERT OR IGNORE INTO tasks (title, description, status, priority, category) 
        SELECT 'Setup Development Environment', 'Configure local development environment with all necessary tools', 'completed', 'high', 'Setup'
        WHERE NOT EXISTS (SELECT 1 FROM tasks WHERE title = 'Setup Development Environment');
        
        -- Link initial task to milestone
        INSERT OR IGNORE INTO task_milestone_relations (task_id, milestone_id)
        SELECT t.id, 1
        FROM tasks t 
        WHERE t.title = 'Setup Development Environment' AND NOT EXISTS (
          SELECT 1 FROM task_milestone_relations WHERE task_id = t.id AND milestone_id = 1
        );
      `);
    }
    
    db.close();
    console.error('Database initialized successfully');
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'create_task',
            description: 'Create a new task in the DraculAI project',
            inputSchema: {
              type: 'object',
              properties: {
                title: { type: 'string', description: 'Task title' },
                description: { type: 'string', description: 'Task description' },
                priority: { type: 'string', enum: ['low', 'medium', 'high', 'urgent'], default: 'medium' },
                category: { type: 'string', description: 'Task category' },
                due_date: { type: 'string', description: 'Due date (YYYY-MM-DD)' },
                estimated_hours: { type: 'number', description: 'Estimated hours' },
                milestone_id: { type: 'number', description: 'Associated milestone ID' }
              },
              required: ['title']
            }
          },
          {
            name: 'list_tasks',
            description: 'List tasks with optional filtering',
            inputSchema: {
              type: 'object',
              properties: {
                status: { type: 'string', enum: ['pending', 'in_progress', 'completed', 'on_hold'] },
                priority: { type: 'string', enum: ['low', 'medium', 'high', 'urgent'] },
                category: { type: 'string' },
                milestone_id: { type: 'number' }
              }
            }
          },
          {
            name: 'update_task',
            description: 'Update an existing task',
            inputSchema: {
              type: 'object',
              properties: {
                id: { type: 'number', description: 'Task ID' },
                title: { type: 'string' },
                description: { type: 'string' },
                status: { type: 'string', enum: ['pending', 'in_progress', 'completed', 'on_hold'] },
                priority: { type: 'string', enum: ['low', 'medium', 'high', 'urgent'] },
                progress: { type: 'number', minimum: 0, maximum: 100 },
                actual_hours: { type: 'number' }
              },
              required: ['id']
            }
          },
          {
            name: 'create_milestone',
            description: 'Create a new milestone',
            inputSchema: {
              type: 'object',
              properties: {
                name: { type: 'string', description: 'Milestone name' },
                description: { type: 'string', description: 'Milestone description' },
                target_date: { type: 'string', description: 'Target date (YYYY-MM-DD)' }
              },
              required: ['name']
            }
          },
          {
            name: 'list_milestones',
            description: 'List all milestones',
            inputSchema: {
              type: 'object',
              properties: {
                status: { type: 'string', enum: ['active', 'completed', 'delayed'] }
              }
            }
          },
          {
            name: 'add_note',
            description: 'Add a note to a task or milestone',
            inputSchema: {
              type: 'object',
              properties: {
                title: { type: 'string', description: 'Note title' },
                content: { type: 'string', description: 'Note content' },
                task_id: { type: 'number', description: 'Associated task ID' },
                milestone_id: { type: 'number', description: 'Associated milestone ID' },
                category: { type: 'string', description: 'Note category' }
              },
              required: ['title', 'content']
            }
          },
          {
            name: 'log_time',
            description: 'Log time spent on a task',
            inputSchema: {
              type: 'object',
              properties: {
                task_id: { type: 'number', description: 'Task ID' },
                description: { type: 'string', description: 'Work description' },
                hours: { type: 'number', description: 'Hours spent' },
                log_date: { type: 'string', description: 'Date (YYYY-MM-DD)' }
              },
              required: ['task_id', 'hours', 'log_date']
            }
          },
          {
            name: 'get_project_status',
            description: 'Get overall project status and metrics',
            inputSchema: {
              type: 'object',
              properties: {}
            }
          }
        ]
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        const db = new Database(DB_PATH);
        let result;

        switch (name) {
          case 'create_task':
            result = this.createTask(db, args);
            break;
          case 'list_tasks':
            result = this.listTasks(db, args);
            break;
          case 'update_task':
            result = this.updateTask(db, args);
            break;
          case 'create_milestone':
            result = this.createMilestone(db, args);
            break;
          case 'list_milestones':
            result = this.listMilestones(db, args);
            break;
          case 'add_note':
            result = this.addNote(db, args);
            break;
          case 'log_time':
            result = this.logTime(db, args);
            break;
          case 'get_project_status':
            result = this.getProjectStatus(db);
            break;
          default:
            throw new McpError(ErrorCode.MethodNotFound, `Unknown tool: ${name}`);
        }

        db.close();
        return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
      } catch (error) {
        throw new McpError(ErrorCode.InternalError, `Tool execution failed: ${error.message}`);
      }
    });
  }

  createTask(db, args) {
    const stmt = db.prepare(`
      INSERT INTO tasks (title, description, priority, category, due_date, estimated_hours)
      VALUES (?, ?, ?, ?, ?, ?)
    `);
    
    const result = stmt.run(
      args.title,
      args.description || null,
      args.priority || 'medium',
      args.category || null,
      args.due_date || null,
      args.estimated_hours || null
    );

    // Link to milestone if provided
    if (args.milestone_id) {
      const linkStmt = db.prepare(`
        INSERT INTO task_milestone_relations (task_id, milestone_id)
        VALUES (?, ?)
      `);
      linkStmt.run(result.lastInsertRowid, args.milestone_id);
    }

    return { success: true, taskId: result.lastInsertRowid, message: 'Task created successfully' };
  }

  listTasks(db, args = {}) {
    let query = `
      SELECT t.*, m.name as milestone_name 
      FROM tasks t
      LEFT JOIN task_milestone_relations tmr ON t.id = tmr.task_id
      LEFT JOIN milestones m ON tmr.milestone_id = m.id
      WHERE 1=1
    `;
    const params = [];

    if (args.status) {
      query += ' AND t.status = ?';
      params.push(args.status);
    }
    if (args.priority) {
      query += ' AND t.priority = ?';
      params.push(args.priority);
    }
    if (args.category) {
      query += ' AND t.category = ?';
      params.push(args.category);
    }
    if (args.milestone_id) {
      query += ' AND tmr.milestone_id = ?';
      params.push(args.milestone_id);
    }

    query += ' ORDER BY t.created_at DESC';

    const stmt = db.prepare(query);
    const tasks = stmt.all(...params);

    return { tasks };
  }

  updateTask(db, args) {
    const updateFields = [];
    const params = [];

    const allowedFields = ['title', 'description', 'status', 'priority', 'progress', 'actual_hours'];
    
    allowedFields.forEach(field => {
      if (args[field] !== undefined) {
        updateFields.push(`${field} = ?`);
        params.push(args[field]);
      }
    });

    if (updateFields.length === 0) {
      return { success: false, message: 'No fields to update' };
    }

    updateFields.push('updated_at = CURRENT_TIMESTAMP');
    
    if (args.status === 'completed') {
      updateFields.push('completed_at = CURRENT_TIMESTAMP');
    }

    params.push(args.id);

    const query = `UPDATE tasks SET ${updateFields.join(', ')} WHERE id = ?`;
    const stmt = db.prepare(query);
    const result = stmt.run(...params);

    return { 
      success: result.changes > 0, 
      message: result.changes > 0 ? 'Task updated successfully' : 'Task not found' 
    };
  }

  createMilestone(db, args) {
    const stmt = db.prepare(`
      INSERT INTO milestones (name, description, target_date)
      VALUES (?, ?, ?)
    `);
    
    const result = stmt.run(
      args.name,
      args.description || null,
      args.target_date || null
    );

    return { success: true, milestoneId: result.lastInsertRowid, message: 'Milestone created successfully' };
  }

  listMilestones(db, args = {}) {
    let query = 'SELECT * FROM milestones WHERE 1=1';
    const params = [];

    if (args.status) {
      query += ' AND status = ?';
      params.push(args.status);
    }

    query += ' ORDER BY target_date ASC';

    const stmt = db.prepare(query);
    const milestones = stmt.all(...params);

    // Get task counts for each milestone
    const taskCountStmt = db.prepare(`
      SELECT 
        m.id,
        COUNT(t.id) as total_tasks,
        COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as completed_tasks
      FROM milestones m
      LEFT JOIN task_milestone_relations tmr ON m.id = tmr.milestone_id
      LEFT JOIN tasks t ON tmr.task_id = t.id
      WHERE m.id = ?
      GROUP BY m.id
    `);

    milestones.forEach(milestone => {
      const counts = taskCountStmt.get(milestone.id) || { total_tasks: 0, completed_tasks: 0 };
      milestone.task_counts = counts;
    });

    return { milestones };
  }

  addNote(db, args) {
    const stmt = db.prepare(`
      INSERT INTO notes (title, content, category, task_id, milestone_id)
      VALUES (?, ?, ?, ?, ?)
    `);
    
    const result = stmt.run(
      args.title,
      args.content,
      args.category || null,
      args.task_id || null,
      args.milestone_id || null
    );

    return { success: true, noteId: result.lastInsertRowid, message: 'Note added successfully' };
  }

  logTime(db, args) {
    const stmt = db.prepare(`
      INSERT INTO time_logs (task_id, description, hours, log_date)
      VALUES (?, ?, ?, ?)
    `);
    
    const result = stmt.run(
      args.task_id,
      args.description || null,
      args.hours,
      args.log_date
    );

    // Update task actual hours
    const updateStmt = db.prepare(`
      UPDATE tasks 
      SET actual_hours = COALESCE(actual_hours, 0) + ?
      WHERE id = ?
    `);
    updateStmt.run(args.hours, args.task_id);

    return { success: true, logId: result.lastInsertRowid, message: 'Time logged successfully' };
  }

  getProjectStatus(db) {
    // Get task statistics
    const taskStats = db.prepare(`
      SELECT 
        status,
        COUNT(*) as count
      FROM tasks
      GROUP BY status
    `).all();

    // Get milestone progress
    const milestoneProgress = db.prepare(`
      SELECT 
        m.name,
        m.status,
        m.target_date,
        COUNT(t.id) as total_tasks,
        COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as completed_tasks,
        ROUND(
          CASE 
            WHEN COUNT(t.id) > 0 THEN 
              (COUNT(CASE WHEN t.status = 'completed' THEN 1 END) * 100.0 / COUNT(t.id))
            ELSE 0 
          END, 2
        ) as completion_percentage
      FROM milestones m
      LEFT JOIN task_milestone_relations tmr ON m.id = tmr.milestone_id
      LEFT JOIN tasks t ON tmr.task_id = t.id
      GROUP BY m.id, m.name, m.status, m.target_date
      ORDER BY m.target_date ASC
    `).all();

    // Get recent activity
    const recentTasks = db.prepare(`
      SELECT title, status, updated_at
      FROM tasks
      ORDER BY updated_at DESC
      LIMIT 5
    `).all();

    // Get time tracking summary
    const timeStats = db.prepare(`
      SELECT 
        SUM(hours) as total_hours,
        COUNT(DISTINCT task_id) as tasks_with_time,
        COUNT(*) as total_entries
      FROM time_logs
    `).get();

    return {
      task_statistics: taskStats,
      milestone_progress: milestoneProgress,
      recent_activity: recentTasks,
      time_tracking: timeStats,
      generated_at: new Date().toISOString()
    };
  }

  async run() {
    // Initialize database first
    this.initializeDatabase();

    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('DraculAI SQLite MCP Server running on stdio');
  }
}

const server = new SQLiteMCPServer();
server.run().catch(console.error);

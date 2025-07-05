-- PostgreSQL initialization script for Baserow
-- This script sets up additional database optimizations and extensions

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pg_buffercache";

-- Create additional indexes for better performance on large datasets
-- (These will be applied after Baserow creates its tables)

-- Optimize PostgreSQL settings for Baserow workload
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET track_activity_query_size = 2048;
ALTER SYSTEM SET track_io_timing = on;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET effective_io_concurrency = 200;
ALTER SYSTEM SET random_page_cost = 1.1;

-- Performance monitoring view
CREATE OR REPLACE VIEW performance_stats AS
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation,
    most_common_vals
FROM pg_stats 
WHERE schemaname = 'public'
ORDER BY tablename, attname;

-- Create a function to analyze query performance
CREATE OR REPLACE FUNCTION analyze_performance()
RETURNS TABLE(
    query text,
    calls bigint,
    total_time double precision,
    avg_time double precision
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pg_stat_statements.query,
        pg_stat_statements.calls,
        pg_stat_statements.total_exec_time,
        pg_stat_statements.mean_exec_time
    FROM pg_stat_statements
    ORDER BY pg_stat_statements.total_exec_time DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql;

-- Log successful initialization
DO $$
BEGIN
    RAISE NOTICE 'Baserow PostgreSQL initialization completed successfully';
END $$;

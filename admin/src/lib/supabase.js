import { createClient } from '@supabase/supabase-js';

// Supabase configuration
const supabaseUrl = 'https://anzsbqqippijhemwxkqh.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuenNicXFpcHBpamhlbXd4a3FoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyMDM1MTQsImV4cCI6MjA3Njc3OTUxNH0.6l1Bt9_5_5ohFeH8IN6mP9jU0pFUToHMmV1NwQEeP-Q';

// Create Supabase client
const supabase = createClient(supabaseUrl, supabaseKey);

export default supabase;
import { createClient } from '@supabase/supabase-js';

export function createServerSupabaseClient() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://dleibonvtotzjrpeevll.supabase.co';
  const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRsZWlib252dG90empycGVldmxsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg2OTM3NDYsImV4cCI6MjEwNDI2OTc0Nn0.kHWGayxeao7kHqKl3QWSMCyJc-EHp5crG8ZP1lvPEkU';

  return createClient(supabaseUrl, supabaseKey);
}

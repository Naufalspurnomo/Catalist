-- ROLLBACK SCRIPT: Hapus semua changes dari supabase-profiles-schema.sql
-- Run script ini di Supabase SQL Editor untuk rollback migration yang error

-- PERINGATAN: Script ini TIDAK akan menghapus tabel profiles yang sudah ada
-- Hanya menghapus policies, triggers, dan views yang baru ditambahkan

-- 1. Drop view
DROP VIEW IF EXISTS user_statistics;

-- 2. Drop RLS policies yang baru ditambahkan
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Service role can manage profiles" ON profiles;

-- 3. Drop triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;

-- 4. Drop functions
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 5. Revoke permissions yang baru ditambahkan
REVOKE ALL ON profiles FROM authenticated;
REVOKE ALL ON profiles FROM service_role;

-- CATATAN: Tabel profiles TIDAK dihapus karena mungkin sudah ada data penting
-- Jika Anda yakin ingin menghapus tabel profiles (HATI-HATI):
-- DROP TABLE IF EXISTS profiles CASCADE;

-- Setelah rollback, jalankan script FIX yang baru (supabase-profiles-fix.sql)

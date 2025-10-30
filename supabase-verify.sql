-- ============================================================================
-- SUPABASE VERIFICATION SCRIPT
-- ============================================================================
-- Jalankan script ini setelah recovery untuk memastikan semuanya berfungsi
-- ============================================================================

-- 1. Cek struktur tabel profiles
SELECT
    'Columns in profiles table:' as info;

SELECT
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 2. Cek RLS policies di profiles
SELECT
    '---' as separator,
    'RLS Policies on profiles table:' as info;

SELECT
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'profiles';

-- 3. Cek triggers
SELECT
    '---' as separator,
    'Triggers on profiles table:' as info;

SELECT
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'profiles';

-- 4. Cek data di profiles
SELECT
    '---' as separator,
    'User count by role and status:' as info;

SELECT
    role,
    is_active,
    COUNT(*) as user_count
FROM profiles
GROUP BY role, is_active
ORDER BY role, is_active;

-- 5. Cek user statistics view
SELECT
    '---' as separator,
    'User statistics:' as info;

SELECT * FROM user_statistics;

-- 6. Cek admin users
SELECT
    '---' as separator,
    'Admin users:' as info;

SELECT
    id,
    email,
    display_name,
    role,
    is_active,
    created_at
FROM profiles
WHERE role = 'admin'
ORDER BY created_at;

-- 7. Cek products table
SELECT
    '---' as separator,
    'Products count:' as info;

SELECT COUNT(*) as total_products FROM products;

-- 8. Cek RLS policies di products
SELECT
    '---' as separator,
    'RLS Policies on products table:' as info;

SELECT
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'products';

-- 9. Cek orders table
SELECT
    '---' as separator,
    'Orders count:' as info;

SELECT COUNT(*) as total_orders FROM orders;

-- 10. Summary
SELECT
    '---' as separator,
    'SUMMARY - All tables and policies:' as info;

SELECT
    schemaname,
    tablename,
    COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY tablename;

-- ============================================================================
-- SET ADMIN USER SCRIPT
-- ============================================================================
-- Gunakan script ini untuk set user sebagai admin
-- GANTI 'your-email@example.com' dengan email Anda yang sebenarnya
-- ============================================================================

-- Option 1: Set admin by email
UPDATE profiles
SET
    role = 'admin',
    is_active = true
WHERE email = 'your-email@example.com';  -- GANTI INI!

-- Verify the change
SELECT
    id,
    email,
    display_name,
    role,
    is_active,
    created_at
FROM profiles
WHERE email = 'your-email@example.com';  -- GANTI INI!

-- ============================================================================
-- Option 2: Set admin by user ID (jika tahu ID-nya)
-- ============================================================================

-- UPDATE profiles
-- SET
--     role = 'admin',
--     is_active = true
-- WHERE id = 'your-user-id-here';

-- ============================================================================
-- Option 3: Set multiple admins sekaligus
-- ============================================================================

-- UPDATE profiles
-- SET
--     role = 'admin',
--     is_active = true
-- WHERE email IN (
--     'admin1@example.com',
--     'admin2@example.com',
--     'admin3@example.com'
-- );

-- ============================================================================
-- Verify all admin users
-- ============================================================================

SELECT
    'All admin users:' as info;

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

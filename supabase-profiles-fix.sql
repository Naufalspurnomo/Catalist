-- FIX SCRIPT: Perbaikan untuk profiles table yang sudah exist
-- Script ini hanya MENAMBAH column is_active dan RLS policies tanpa drop table

-- LANGKAH 1: Tambah column is_active jika belum ada
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'profiles' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE profiles ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
END $$;

-- LANGKAH 2: Tambah column role jika belum ada
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'profiles' AND column_name = 'role'
    ) THEN
        ALTER TABLE profiles ADD COLUMN role VARCHAR(20) DEFAULT 'customer'
            CHECK (role IN ('admin', 'customer'));
    END IF;
END $$;

-- LANGKAH 3: Update existing users yang belum punya is_active atau role
UPDATE profiles
SET is_active = COALESCE(is_active, true),
    role = COALESCE(role, 'customer')
WHERE is_active IS NULL OR role IS NULL;

-- LANGKAH 4: Buat index jika belum ada
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

-- LANGKAH 5: Enable RLS jika belum enabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- LANGKAH 6: Drop existing policies (untuk avoid duplicate)
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Service role can manage profiles" ON profiles;

-- LANGKAH 7: Buat RLS policies baru
-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT
    USING (auth.uid() = id);

-- Users can update their own profile (kecuali role dan is_active)
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (
        auth.uid() = id
        AND role = (SELECT role FROM profiles WHERE id = auth.uid())
        AND is_active = (SELECT is_active FROM profiles WHERE id = auth.uid())
    );

-- Admin can view all profiles
CREATE POLICY "Admins can view all profiles" ON profiles
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = 'admin'
            AND is_active = true
        )
    );

-- Admin can update all profiles (including role and is_active)
CREATE POLICY "Admins can update all profiles" ON profiles
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = 'admin'
            AND is_active = true
        )
    );

-- Admin can insert new profiles
CREATE POLICY "Admins can insert profiles" ON profiles
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = 'admin'
            AND is_active = true
        )
    );

-- Service role can do anything (for triggers and backend)
CREATE POLICY "Service role can manage profiles" ON profiles
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- LANGKAH 8: Grant permissions
GRANT SELECT, UPDATE ON profiles TO authenticated;
GRANT INSERT ON profiles TO authenticated;
GRANT ALL ON profiles TO service_role;

-- LANGKAH 9: Buat view untuk statistics (optional)
CREATE OR REPLACE VIEW user_statistics AS
SELECT
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE role = 'admin') as total_admins,
    COUNT(*) FILTER (WHERE role = 'customer') as total_customers,
    COUNT(*) FILTER (WHERE is_active = true) as active_users,
    COUNT(*) FILTER (WHERE is_active = false) as inactive_users,
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') as new_users_last_30_days
FROM profiles;

GRANT SELECT ON user_statistics TO authenticated;

-- LANGKAH 10: Buat auto-update trigger untuk updated_at jika belum ada
CREATE OR REPLACE FUNCTION update_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION update_profiles_updated_at();

-- SELESAI! Sekarang jalankan query ini untuk verify:
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'profiles';

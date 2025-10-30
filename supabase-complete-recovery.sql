-- ============================================================================
-- SUPABASE COMPLETE RECOVERY SCRIPT
-- ============================================================================
-- Script ini akan memperbaiki semua masalah SQL/Supabase yang rusak
-- Aman dijalankan multiple kali (idempotent)
-- ============================================================================

-- ============================================================================
-- STEP 1: CLEANUP - Hapus semua policies dan triggers yang bermasalah
-- ============================================================================

-- Drop semua RLS policies yang mungkin conflict
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Service role can manage profiles" ON profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON profiles;

-- Drop triggers yang mungkin bermasalah
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;

-- Drop functions yang mungkin bermasalah
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_profiles_updated_at() CASCADE;

-- Drop view jika ada
DROP VIEW IF EXISTS user_statistics;

-- ============================================================================
-- STEP 2: PRODUCTS TABLE - Pastikan tabel products exist
-- ============================================================================

CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR NOT NULL,
    description TEXT,
    price INTEGER NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    image_url VARCHAR,
    category VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index untuk products
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at);

-- ============================================================================
-- STEP 3: PROFILES TABLE - Fix existing table structure
-- ============================================================================

-- Tambah column is_active jika belum ada
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'is_active'
    ) THEN
        ALTER TABLE profiles ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
END $$;

-- Tambah column role jika belum ada
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'role'
    ) THEN
        ALTER TABLE profiles ADD COLUMN role VARCHAR(20) DEFAULT 'customer'
            CHECK (role IN ('admin', 'customer'));
    END IF;
END $$;

-- Tambah column created_at jika belum ada
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'created_at'
    ) THEN
        ALTER TABLE profiles ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Tambah column updated_at jika belum ada
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE profiles ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Update existing data untuk set default values
UPDATE profiles
SET
    is_active = COALESCE(is_active, true),
    role = COALESCE(role, 'customer'),
    created_at = COALESCE(created_at, NOW()),
    updated_at = COALESCE(updated_at, NOW())
WHERE is_active IS NULL OR role IS NULL OR created_at IS NULL OR updated_at IS NULL;

-- ============================================================================
-- STEP 4: INDEXES - Buat semua index yang diperlukan
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

-- ============================================================================
-- STEP 5: FUNCTIONS - Buat ulang semua functions yang diperlukan
-- ============================================================================

-- Function untuk auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function untuk handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name, role, is_active)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
        true
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- STEP 6: TRIGGERS - Buat ulang semua triggers
-- ============================================================================

-- Trigger untuk auto-update updated_at di profiles
CREATE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger untuk auto-create profile on user signup
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

-- Trigger untuk orders
DROP TRIGGER IF EXISTS update_orders_updated_at ON orders;
CREATE TRIGGER update_orders_updated_at
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger untuk payment_history
DROP TRIGGER IF EXISTS update_payment_history_updated_at ON payment_history;
CREATE TRIGGER update_payment_history_updated_at
BEFORE UPDATE ON payment_history
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger untuk shipping_history
DROP TRIGGER IF EXISTS update_shipping_history_updated_at ON shipping_history;
CREATE TRIGGER update_shipping_history_updated_at
BEFORE UPDATE ON shipping_history
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- STEP 7: ROW LEVEL SECURITY - Enable RLS pada semua tabel
-- ============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Enable RLS pada tabel lain jika belum
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipping_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 8: RLS POLICIES - Profiles Table
-- ============================================================================

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

-- Admins can view all profiles
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

-- Admins can update all profiles (including role and is_active)
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

-- Admins can insert new profiles
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

-- Service role can do anything (for backend operations)
CREATE POLICY "Service role can manage profiles" ON profiles
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- STEP 9: RLS POLICIES - Products Table
-- ============================================================================

-- Drop existing policies first
DROP POLICY IF EXISTS "Anyone can view products" ON products;
DROP POLICY IF EXISTS "Admins can insert products" ON products;
DROP POLICY IF EXISTS "Admins can update products" ON products;
DROP POLICY IF EXISTS "Admins can delete products" ON products;
DROP POLICY IF EXISTS "Service role can manage products" ON products;

-- Everyone can view products
CREATE POLICY "Anyone can view products" ON products
    FOR SELECT
    USING (true);

-- Admins can insert products
CREATE POLICY "Admins can insert products" ON products
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = 'admin'
            AND is_active = true
        )
    );

-- Admins can update products
CREATE POLICY "Admins can update products" ON products
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = 'admin'
            AND is_active = true
        )
    );

-- Admins can delete products
CREATE POLICY "Admins can delete products" ON products
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = 'admin'
            AND is_active = true
        )
    );

-- Service role can manage products
CREATE POLICY "Service role can manage products" ON products
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- STEP 10: VIEWS - User Statistics
-- ============================================================================

CREATE OR REPLACE VIEW user_statistics AS
SELECT
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE role = 'admin') as total_admins,
    COUNT(*) FILTER (WHERE role = 'customer') as total_customers,
    COUNT(*) FILTER (WHERE is_active = true) as active_users,
    COUNT(*) FILTER (WHERE is_active = false) as inactive_users,
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') as new_users_last_30_days
FROM profiles;

-- ============================================================================
-- STEP 11: PERMISSIONS - Grant necessary permissions
-- ============================================================================

-- Profiles permissions
GRANT SELECT, UPDATE ON profiles TO authenticated;
GRANT INSERT ON profiles TO authenticated;
GRANT ALL ON profiles TO service_role;

-- Products permissions
GRANT SELECT ON products TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON products TO authenticated;
GRANT ALL ON products TO service_role;

-- Orders permissions
GRANT SELECT, INSERT, UPDATE ON orders TO anon, authenticated;
GRANT SELECT, INSERT ON order_items TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON payment_history TO anon, authenticated;
GRANT SELECT ON shipping_history TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON cart TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON cart_items TO anon, authenticated;

-- View permissions
GRANT SELECT ON user_statistics TO authenticated;

-- Sequence permissions
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- ============================================================================
-- STEP 12: VERIFICATION - Check if everything is setup correctly
-- ============================================================================

-- This will show all columns in profiles table
DO $$
DECLARE
    result_count INTEGER;
BEGIN
    -- Check if profiles table has all required columns
    SELECT COUNT(*) INTO result_count
    FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'profiles'
    AND column_name IN ('id', 'email', 'display_name', 'role', 'is_active', 'created_at', 'updated_at');

    IF result_count < 7 THEN
        RAISE NOTICE 'WARNING: profiles table missing some required columns';
    ELSE
        RAISE NOTICE 'SUCCESS: profiles table has all required columns';
    END IF;

    -- Check if RLS policies exist
    SELECT COUNT(*) INTO result_count
    FROM pg_policies
    WHERE tablename = 'profiles';

    IF result_count < 6 THEN
        RAISE NOTICE 'WARNING: profiles table missing some RLS policies';
    ELSE
        RAISE NOTICE 'SUCCESS: profiles table has all RLS policies';
    END IF;
END $$;

-- ============================================================================
-- SELESAI!
-- ============================================================================
-- Sekarang jalankan query ini untuk verify setup:
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'profiles';
-- SELECT * FROM pg_policies WHERE tablename = 'profiles';
-- SELECT * FROM user_statistics;

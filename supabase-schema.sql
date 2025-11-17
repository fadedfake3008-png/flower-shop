-- =====================================================
-- FLOWER SHOP CATALOG - SUPABASE SCHEMA
-- Run these commands in Supabase SQL Editor
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE: flower_types
-- =====================================================
CREATE TABLE flower_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    color TEXT DEFAULT '#f5f5f5',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default flower types
INSERT INTO flower_types (name, color) VALUES
    ('Hồng môn', '#ffebee'),
    ('Lan', '#e8f5e9'),
    ('Tùng', '#fff3e0'),
    ('Mimosa', '#fff9c4'),
    ('Lá trang trí', '#e0f2f1'),
    ('Khác', '#f5f5f5');

-- =====================================================
-- TABLE: unit_types
-- =====================================================
CREATE TABLE unit_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default unit types
INSERT INTO unit_types (name) VALUES
    ('1 bó'),
    ('1 cành'),
    ('1 kg'),
    ('1 chậu'),
    ('1 bình'),
    ('1 lọ'),
    ('1 cây'),
    ('1 giỏ'),
    ('1 set'),
    ('1 đôi');

-- =====================================================
-- TABLE: flowers (main table)
-- =====================================================
CREATE TABLE flowers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    price INTEGER NOT NULL CHECK (price > 0),
    type TEXT NOT NULL DEFAULT 'Khác',
    unit TEXT NOT NULL DEFAULT '1 bó',
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better search performance
CREATE INDEX idx_flowers_name ON flowers(name);
CREATE INDEX idx_flowers_type ON flowers(type);
CREATE INDEX idx_flowers_created_at ON flowers(created_at DESC);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) - Optional
-- Enable if you want user authentication
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE flowers ENABLE ROW LEVEL SECURITY;
ALTER TABLE flower_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE unit_types ENABLE ROW LEVEL SECURITY;

-- Public read access (everyone can view)
CREATE POLICY "Public flowers read" ON flowers
    FOR SELECT USING (true);

CREATE POLICY "Public flower_types read" ON flower_types
    FOR SELECT USING (true);

CREATE POLICY "Public unit_types read" ON unit_types
    FOR SELECT USING (true);

-- Authenticated users can do everything
-- (Remove these if you want admin-only access)
CREATE POLICY "Authenticated flowers all" ON flowers
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated flower_types all" ON flower_types
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated unit_types all" ON unit_types
    FOR ALL USING (auth.role() = 'authenticated');

-- =====================================================
-- STORAGE BUCKET for images
-- Run this in Supabase Dashboard > Storage
-- =====================================================

-- Create bucket (do this in Supabase UI or via API)
-- Bucket name: flower-images
-- Public: Yes
-- File size limit: 5MB
-- Allowed MIME types: image/jpeg, image/png, image/webp

-- Storage policy for public read
CREATE POLICY "Public flower images read"
ON storage.objects FOR SELECT
USING (bucket_id = 'flower-images');

-- Authenticated users can upload/update/delete
CREATE POLICY "Authenticated flower images write"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'flower-images' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated flower images update"
ON storage.objects FOR UPDATE
USING (bucket_id = 'flower-images' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated flower images delete"
ON storage.objects FOR DELETE
USING (bucket_id = 'flower-images' AND auth.role() = 'authenticated');

-- =====================================================
-- TRIGGERS: Auto-update timestamp
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_flowers_updated_at
    BEFORE UPDATE ON flowers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCTIONS: Helpful utility functions
-- =====================================================

-- Get flowers count by type
CREATE OR REPLACE FUNCTION get_flowers_by_type_count()
RETURNS TABLE(type TEXT, count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT f.type, COUNT(*)::BIGINT
    FROM flowers f
    GROUP BY f.type
    ORDER BY COUNT(*) DESC;
END;
$$ LANGUAGE plpgsql;

-- Search flowers (full-text search)
CREATE OR REPLACE FUNCTION search_flowers(search_term TEXT)
RETURNS SETOF flowers AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM flowers
    WHERE name ILIKE '%' || search_term || '%'
       OR type ILIKE '%' || search_term || '%'
    ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SAMPLE DATA (Optional - for testing)
-- =====================================================

INSERT INTO flowers (name, price, type, unit) VALUES
    ('Hồng Ecuador Red', 850000, 'Hồng môn', '1 bó'),
    ('Lan Hồ Điệp Trắng', 1200000, 'Lan', '1 chậu'),
    ('Tùng Tuế Premium', 350000, 'Tùng', '1 cành'),
    ('Mimosa Vàng Pháp', 450000, 'Mimosa', '1 bó'),
    ('Lá Phi Yến Xanh', 180000, 'Lá trang trí', '1 kg');

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check all tables
SELECT 'flowers' as table_name, COUNT(*) as count FROM flowers
UNION ALL
SELECT 'flower_types', COUNT(*) FROM flower_types
UNION ALL
SELECT 'unit_types', COUNT(*) FROM unit_types;
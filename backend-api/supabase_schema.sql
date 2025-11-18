-- =====================================================
-- Supabase Schema for StyleFinder Bulk Processing
-- =====================================================

-- Table: clothing_items
-- Stores individual analyzed clothing items
CREATE TABLE IF NOT EXISTS clothing_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    original_image_url TEXT,
    extracted_image_url TEXT,
    type VARCHAR(100),
    color VARCHAR(100),
    pattern VARCHAR(100),
    style VARCHAR(100),
    confidence FLOAT,
    season TEXT[],  -- Array of seasons
    pairs_well_with TEXT[],  -- Array of compatible items
    occasion TEXT[],  -- Array of occasions
    material VARCHAR(100),
    care_instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: processing_jobs
-- Tracks bulk image processing jobs
CREATE TABLE IF NOT EXISTS processing_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',  -- pending, processing, completed, failed
    total_images INTEGER NOT NULL,
    processed_images INTEGER DEFAULT 0,
    failed_images INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT
);

-- Table: job_images
-- Tracks individual images within a processing job
CREATE TABLE IF NOT EXISTS job_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID REFERENCES processing_jobs(id) ON DELETE CASCADE,
    user_id VARCHAR(255) NOT NULL,
    image_url TEXT NOT NULL,  -- Tigris URL
    status VARCHAR(50) NOT NULL DEFAULT 'pending',  -- pending, processing, completed, failed
    item_id UUID REFERENCES clothing_items(id) ON DELETE SET NULL,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_clothing_items_user_id ON clothing_items(user_id);
CREATE INDEX IF NOT EXISTS idx_clothing_items_created_at ON clothing_items(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_processing_jobs_user_id ON processing_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_processing_jobs_status ON processing_jobs(status);
CREATE INDEX IF NOT EXISTS idx_job_images_job_id ON job_images(job_id);
CREATE INDEX IF NOT EXISTS idx_job_images_status ON job_images(status);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_clothing_items_updated_at ON clothing_items;
CREATE TRIGGER update_clothing_items_updated_at
    BEFORE UPDATE ON clothing_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_processing_jobs_updated_at ON processing_jobs;
CREATE TRIGGER update_processing_jobs_updated_at
    BEFORE UPDATE ON processing_jobs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_job_images_updated_at ON job_images;
CREATE TRIGGER update_job_images_updated_at
    BEFORE UPDATE ON job_images
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) - Enable if needed
-- ALTER TABLE clothing_items ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE processing_jobs ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE job_images ENABLE ROW LEVEL SECURITY;

-- Sample RLS policies (uncomment and modify as needed)
-- CREATE POLICY "Users can view their own items" ON clothing_items
--     FOR SELECT USING (auth.uid()::text = user_id);
--
-- CREATE POLICY "Users can insert their own items" ON clothing_items
--     FOR INSERT WITH CHECK (auth.uid()::text = user_id);

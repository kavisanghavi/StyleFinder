-- ============================================
-- Supabase Table Creation for ClosetAI
-- ============================================
-- Run this in your Supabase SQL Editor:
-- Dashboard → SQL Editor → New Query → Paste & Run

CREATE TABLE IF NOT EXISTS public.clothing_items (
    -- Primary Key
    id TEXT PRIMARY KEY,

    -- User Association
    user_id TEXT NOT NULL,

    -- Image URLs (Tigris presigned URLs)
    original_image_url TEXT,
    extracted_image_url TEXT,

    -- Claude Analysis Results
    type TEXT NOT NULL,
    color TEXT NOT NULL,
    pattern TEXT NOT NULL,
    style TEXT NOT NULL,
    confidence FLOAT NOT NULL,

    -- JSON Arrays
    season JSONB NOT NULL DEFAULT '[]'::jsonb,
    pairs_well_with JSONB NOT NULL DEFAULT '[]'::jsonb,
    occasion JSONB,

    -- Optional Metadata
    material TEXT,
    care_instructions TEXT,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    last_worn_at TIMESTAMP WITH TIME ZONE,

    -- Usage Tracking
    worn_count INTEGER DEFAULT 0,
    favorite BOOLEAN DEFAULT FALSE
);

-- Create index on user_id for fast queries
CREATE INDEX IF NOT EXISTS idx_clothing_items_user_id ON public.clothing_items(user_id);

-- Create index on created_at for sorting
CREATE INDEX IF NOT EXISTS idx_clothing_items_created_at ON public.clothing_items(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.clothing_items ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all operations (you can restrict this later)
CREATE POLICY "Allow all access to clothing_items"
ON public.clothing_items
FOR ALL
USING (true)
WITH CHECK (true);

-- Grant permissions
GRANT ALL ON public.clothing_items TO anon;
GRANT ALL ON public.clothing_items TO authenticated;

SELECT 'Table created successfully!' as status;

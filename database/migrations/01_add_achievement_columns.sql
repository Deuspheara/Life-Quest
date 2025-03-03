-- Add missing columns to the achievements table

-- Add badge_color column if it doesn't exist
DO $$
BEGIN
  ALTER TABLE achievements ADD COLUMN badge_color TEXT;
EXCEPTION
  WHEN duplicate_column THEN
    -- Column already exists, do nothing
    NULL;
END
$$;

-- Add points column if it doesn't exist
DO $$
BEGIN
  ALTER TABLE achievements ADD COLUMN points INTEGER NOT NULL DEFAULT 10;
EXCEPTION
  WHEN duplicate_column THEN
    -- Column already exists, do nothing
    NULL;
END
$$;

-- Add criteria column if it doesn't exist
DO $$
BEGIN
  ALTER TABLE achievements ADD COLUMN criteria JSONB;
EXCEPTION
  WHEN duplicate_column THEN
    -- Column already exists, do nothing
    NULL;
END
$$;

-- Add category column if it doesn't exist
DO $$
BEGIN
  ALTER TABLE achievements ADD COLUMN category TEXT NOT NULL DEFAULT 'quest';
EXCEPTION
  WHEN duplicate_column THEN
    -- Column already exists, do nothing
    NULL;
END
$$;

-- Update existing achievements to have default categories if they don't have one
UPDATE achievements SET category = 'quest' WHERE category IS NULL;

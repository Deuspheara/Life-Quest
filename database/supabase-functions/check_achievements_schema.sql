-- Function to check and update the achievements table schema

CREATE OR REPLACE FUNCTION check_achievements_schema()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if badge_color column exists and add it if it doesn't
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'achievements' AND column_name = 'badge_color'
  ) THEN
    ALTER TABLE achievements ADD COLUMN badge_color TEXT;
  END IF;
  
  -- Check if points column exists and add it if it doesn't
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'achievements' AND column_name = 'points'
  ) THEN
    ALTER TABLE achievements ADD COLUMN points INTEGER NOT NULL DEFAULT 10;
  END IF;
  
  -- Check if criteria column exists and add it if it doesn't
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'achievements' AND column_name = 'criteria'
  ) THEN
    ALTER TABLE achievements ADD COLUMN criteria JSONB;
  END IF;
  
  -- Check if category column exists and add it if it doesn't
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'achievements' AND column_name = 'category'
  ) THEN
    ALTER TABLE achievements ADD COLUMN category TEXT NOT NULL DEFAULT 'quest';
    -- Update existing achievements to have a category
    UPDATE achievements SET category = 'quest' WHERE category IS NULL;
  END IF;
END;
$$;

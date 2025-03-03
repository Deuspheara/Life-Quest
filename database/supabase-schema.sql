-- Create the profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  level INTEGER NOT NULL DEFAULT 1,
  experience INTEGER NOT NULL DEFAULT 0,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security (doesn't error if already enabled)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can delete their own profile" ON profiles;

-- Create policies for the profiles table
CREATE POLICY "Users can view their own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete their own profile" ON profiles
  FOR DELETE USING (auth.uid() = id);

-- Create the quests table if it doesn't exist
CREATE TABLE IF NOT EXISTS quests (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  difficulty TEXT NOT NULL,
  experience_points INTEGER NOT NULL,
  status TEXT NOT NULL,
  steps TEXT[] NOT NULL,
  completed_steps INTEGER[] NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  due_date TIMESTAMPTZ NOT NULL
);

-- Enable Row Level Security (doesn't error if already enabled)
ALTER TABLE quests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own quests" ON quests;
DROP POLICY IF EXISTS "Users can insert their own quests" ON quests;
DROP POLICY IF EXISTS "Users can update their own quests" ON quests;
DROP POLICY IF EXISTS "Users can delete their own quests" ON quests;

-- Create policies for the quests table
CREATE POLICY "Users can view their own quests" ON quests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own quests" ON quests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own quests" ON quests
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own quests" ON quests
  FOR DELETE USING (auth.uid() = user_id);

-- Create the enhanced achievements table if it doesn't exist
CREATE TABLE IF NOT EXISTS achievements (
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  icon_path TEXT NOT NULL,
  required_level INTEGER NOT NULL,
  is_secret BOOLEAN NOT NULL DEFAULT FALSE,
  points INTEGER NOT NULL DEFAULT 10,
  badge_color TEXT,
  criteria JSONB
);

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

-- Create the user_achievements table if it doesn't exist
CREATE TABLE IF NOT EXISTS user_achievements (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  achievement_id UUID REFERENCES achievements(id) NOT NULL,
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_achievement UNIQUE (user_id, achievement_id)
);

-- Drop existing indexes if they exist to avoid conflicts
DROP INDEX IF EXISTS achievements_category_idx;
DROP INDEX IF EXISTS achievements_required_level_idx;
DROP INDEX IF EXISTS user_achievements_user_id_idx;

-- Add performance indexes for achievements
CREATE INDEX achievements_category_idx ON achievements (category);
CREATE INDEX achievements_required_level_idx ON achievements (required_level);
CREATE INDEX user_achievements_user_id_idx ON user_achievements (user_id);

-- Enable Row Level Security (doesn't error if already enabled)
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own achievements" ON user_achievements;
DROP POLICY IF EXISTS "Users can insert their own achievements" ON user_achievements;
DROP POLICY IF EXISTS "Users can delete their own achievements" ON user_achievements;

-- Create policies for the user_achievements table
CREATE POLICY "Users can view their own achievements" ON user_achievements
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own achievements" ON user_achievements
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own achievements" ON user_achievements
  FOR DELETE USING (auth.uid() = user_id);

-- Create or replace the function to update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop the trigger if it exists, then create it
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create or replace the function to handle achievement unlocks
CREATE OR REPLACE FUNCTION handle_achievement_unlock()
RETURNS TRIGGER AS $$
BEGIN
  -- This function could be extended to add notifications to a notifications table
  -- or trigger other achievement-related events
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop the trigger if it exists, then create it
DROP TRIGGER IF EXISTS on_achievement_unlock ON user_achievements;
CREATE TRIGGER on_achievement_unlock
AFTER INSERT ON user_achievements
FOR EACH ROW
EXECUTE FUNCTION handle_achievement_unlock();

-----------------------
-- STORAGE SETUP
-----------------------

-- Create avatars bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- First, list all existing policies
-- SELECT policyname 
-- FROM pg_policies 
-- WHERE tablename = 'objects' AND schemaname = 'storage';

-- Then drop all existing policies related to avatars
DROP POLICY IF EXISTS "Give users authenticated access to folder 1oj01fe_0" ON storage.objects;
DROP POLICY IF EXISTS "Public access to avatars" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload their avatars" ON storage.objects;
DROP POLICY IF EXISTS "avatars_bucket_read_policy" ON storage.objects;
DROP POLICY IF EXISTS "avatars_bucket_insert_policy" ON storage.objects;
DROP POLICY IF EXISTS "avatars_bucket_update_policy" ON storage.objects;
DROP POLICY IF EXISTS "avatars_bucket_delete_policy" ON storage.objects;

-- Create new policies with unique names
-- SELECT (Read) policy
CREATE POLICY "avatars_bucket_read_policy" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'avatars');

-- INSERT policy
CREATE POLICY "avatars_bucket_insert_policy" 
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1]::uuid = auth.uid()
);

-- UPDATE policy
CREATE POLICY "avatars_bucket_update_policy" 
ON storage.objects FOR UPDATE 
TO authenticated 
USING (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1]::uuid = auth.uid()
);

-- DELETE policy
CREATE POLICY "avatars_bucket_delete_policy" 
ON storage.objects FOR DELETE 
TO authenticated 
USING (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1]::uuid = auth.uid()
);
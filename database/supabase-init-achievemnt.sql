-- Add new columns to the achievements table
ALTER TABLE achievements 
ADD COLUMN experience_reward INTEGER NOT NULL DEFAULT 50,
ADD COLUMN criteria TEXT,
ADD COLUMN category TEXT DEFAULT 'general',
ADD COLUMN color INTEGER;

-- Add progress tracking to user_achievements
ALTER TABLE user_achievements
ADD COLUMN progress REAL DEFAULT 0.0;

-- Create some sample achievements
INSERT INTO achievements (id, title, description, icon_path, required_level, is_secret, experience_reward, criteria, category, color)
VALUES
-- Level Achievements
('level_5', 'Rising Star', 'Reach level 5', 'assets/images/achievements/level_5.png', 5, false, 100, '', 'level', -16711936),
('level_10', 'Quest Apprentice', 'Reach level 10', 'assets/images/achievements/level_10.png', 10, false, 200, '', 'level', -16711936),
('level_25', 'Quest Master', 'Reach level 25', 'assets/images/achievements/level_25.png', 25, false, 500, '', 'level', -16711936),
('level_50', 'Quest Legend', 'Reach level 50', 'assets/images/achievements/level_50.png', 50, false, 1000, '', 'level', -16711936),

-- Quest Count Achievements
('quest_1', 'First Steps', 'Complete your first quest', 'assets/images/achievements/first_quest.png', 1, false, 50, 'total_quests: 1', 'quest', -16776961),
('quest_5', 'Getting Started', 'Complete 5 quests', 'assets/images/achievements/quest_5.png', 1, false, 100, 'total_quests: 5', 'quest', -16776961),
('quest_25', 'Quest Enthusiast', 'Complete 25 quests', 'assets/images/achievements/quest_25.png', 1, false, 250, 'total_quests: 25', 'quest', -16776961),
('quest_100', 'Quest Aficionado', 'Complete 100 quests', 'assets/images/achievements/quest_100.png', 1, false, 500, 'total_quests: 100', 'quest', -16776961),

-- Difficulty-based Achievements
('easy_10', 'Easy Rider', 'Complete 10 easy quests', 'assets/images/achievements/easy_10.png', 1, false, 100, 'easy_quests: 10', 'quest', -16744448),
('medium_10', 'Moderately Impressive', 'Complete 10 medium quests', 'assets/images/achievements/medium_10.png', 5, false, 200, 'medium_quests: 10', 'quest', -16744448),
('hard_10', 'Hardcore Quester', 'Complete 10 hard quests', 'assets/images/achievements/hard_10.png', 10, false, 300, 'hard_quests: 10', 'quest', -16744448),
('epic_5', 'Epic Adventurer', 'Complete 5 epic quests', 'assets/images/achievements/epic_5.png', 15, false, 500, 'epic_quests: 5', 'quest', -16744448),

-- Secret Achievements
('secret_1', 'Hidden Potential', 'You discovered a hidden achievement!', 'assets/images/achievements/secret_1.png', 1, true, 200, '', 'secret', -65536),
('secret_2', 'Mystery Master', 'You love to solve mysteries!', 'assets/images/achievements/secret_2.png', 5, true, 300, '', 'secret', -65536);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_achievements_category ON achievements(category);
CREATE INDEX IF NOT EXISTS idx_achievements_required_level ON achievements(required_level);
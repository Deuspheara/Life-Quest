-- Insert basic achievements
INSERT INTO achievements (id, title, description, icon_path, required_level, is_secret)
VALUES 
('first_quest', 'First Steps', 'Complete your first quest', 'assets/images/achievements/first_quest.png', 1, false),
('level_5', 'Apprentice', 'Reach level 5', 'assets/images/achievements/level_5.png', 5, false),
('level_10', 'Adept', 'Reach level 10', 'assets/images/achievements/level_10.png', 10, false),
('level_25', 'Master', 'Reach level 25', 'assets/images/achievements/level_25.png', 25, false),
('quest_master', 'Quest Master', 'Complete 10 quests', 'assets/images/achievements/quest_master.png', 1, false),
('streak_warrior', 'Streak Warrior', 'Complete quests for 7 days in a row', 'assets/images/achievements/streak.png', 1, false),
('epic_challenge', 'Epic Challenge', 'Complete an epic difficulty quest', 'assets/images/achievements/epic_quest.png', 10, true),
('balanced_life', 'Balanced Life', 'Complete quests in every category', 'assets/images/achievements/balanced.png', 5, false),
('early_bird', 'Early Bird', 'Complete a quest before 8 AM', 'assets/images/achievements/early_bird.png', 1, true),
('night_owl', 'Night Owl', 'Complete a quest after 10 PM', 'assets/images/achievements/night_owl.png', 1, true);

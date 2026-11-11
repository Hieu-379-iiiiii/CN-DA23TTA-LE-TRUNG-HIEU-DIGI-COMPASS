CREATE TYPE role_enum AS ENUM ('admin', 'user');
CREATE TYPE progress_status_enum AS ENUM ('not_started', 'in_progress', 'completed');
CREATE TYPE step_type_enum AS ENUM ('post', 'test', 'series');

-- USERS
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role role_enum NOT NULL DEFAULT 'user',
    major VARCHAR(100),
    year_of_study INT,
    
    -- 5 DigComp Scores
    score_info_data INT NOT NULL DEFAULT 0,
    score_com_collab INT NOT NULL DEFAULT 0,
    score_content_creation INT NOT NULL DEFAULT 0,
    score_safety INT NOT NULL DEFAULT 0,
    score_problem_solving INT NOT NULL DEFAULT 0,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- SKILLS
CREATE TABLE skills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    icon_url VARCHAR(255),
    parent_id UUID REFERENCES skills(id) ON DELETE CASCADE
);

-- TAGS
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) UNIQUE NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL
);

-- POSTS + SERIES
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    content TEXT NOT NULL,
    video_url VARCHAR(255), 
    author_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE post_tags (
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, tag_id)
);

CREATE TABLE series (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Connect bla bla bla
CREATE TABLE series_posts (
    series_id UUID REFERENCES series(id) ON DELETE CASCADE,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    step_number INT NOT NULL,
    PRIMARY KEY (series_id, post_id),
    UNIQUE (series_id, step_number)
);

-- TESTS + QUESTIONS
CREATE TABLE tests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    passing_score INT DEFAULT 70,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_id UUID NOT NULL REFERENCES tests(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL
);

CREATE TABLE options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL DEFAULT FALSE
);

-- COURSES + STEPS
CREATE TABLE courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE course_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    step_number INT NOT NULL,
    step_type step_type_enum NOT NULL,
    post_id UUID REFERENCES posts(id) ON DELETE SET NULL,
    test_id UUID REFERENCES tests(id) ON DELETE SET NULL,
    series_id UUID REFERENCES series(id) ON DELETE SET NULL,
    UNIQUE (course_id, step_number)
);

-- SKILL TREE!!!! TREE!!!! THEY'RE SPEAKING VIETNAMESE!!! AHHHHHHHHHHHHHHHHHHHH
CREATE TABLE skill_trees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT
);

CREATE TABLE skill_tree_nodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    skill_tree_id UUID NOT NULL REFERENCES skill_trees(id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
    parent_node_id UUID REFERENCES skill_tree_nodes(id) ON DELETE CASCADE,
    
    target_course_id UUID REFERENCES courses(id) ON DELETE SET NULL,
    target_series_id UUID REFERENCES series(id) ON DELETE SET NULL,
    target_post_id UUID REFERENCES posts(id) ON DELETE SET NULL
);

-- UI CARDS... BASICALLY ADS, NO IDEA IF I WILL USE, BUT MADE JUST IN CASE :3
CREATE TABLE cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    image_url TEXT,
    target_lesson_id UUID REFERENCES posts(id) ON DELETE SET NULL,
    target_test_id UUID REFERENCES tests(id) ON DELETE SET NULL
);

-- Tracks progress for each step in a course
CREATE TABLE user_step_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    course_step_id UUID NOT NULL REFERENCES course_steps(id) ON DELETE CASCADE,
    status progress_status_enum NOT NULL DEFAULT 'not_started',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, course_step_id)
);

-- Tracks overall course progress (calculated percentage)
CREATE TABLE user_course_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    completion_percentage INT NOT NULL DEFAULT 0, -- 0 to 100%
    status progress_status_enum NOT NULL DEFAULT 'not_started',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, course_id)
);

CREATE INDEX idx_course_steps_course ON course_steps(course_id);
CREATE INDEX idx_series_posts_series ON series_posts(series_id);
CREATE INDEX idx_skill_tree_nodes_tree ON skill_tree_nodes(skill_tree_id);
CREATE INDEX idx_user_step_progress_user ON user_step_progress(user_id);
CREATE INDEX idx_user_course_progress_user ON user_course_progress(user_id);
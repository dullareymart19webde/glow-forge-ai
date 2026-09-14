-- Supabase PostgreSQL Initialization Script for GlowForge AI

-- 1. Create Users Table (extends Supabase Auth)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for users
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own profile." ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile." ON users FOR UPDATE USING (auth.uid() = id);

-- Trigger to automatically create a user profile when a new auth user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'full_name');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 2. Create Chat Sessions Table
CREATE TABLE chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    session_title TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own chat sessions." ON chat_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own chat sessions." ON chat_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own chat sessions." ON chat_sessions FOR DELETE USING (auth.uid() = user_id);

-- 3. Create Chat Messages Table
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE NOT NULL,
    sender_role TEXT NOT NULL CHECK (sender_role IN ('user', 'ai')),
    message_content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
-- Users can read messages if they own the session
CREATE POLICY "Users can view messages of their sessions." ON chat_messages FOR SELECT USING (
    EXISTS (SELECT 1 FROM chat_sessions WHERE id = chat_messages.session_id AND user_id = auth.uid())
);
CREATE POLICY "Users can insert messages into their sessions." ON chat_messages FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM chat_sessions WHERE id = chat_messages.session_id AND user_id = auth.uid())
);

-- 4. Create Saved Resumes Table
CREATE TABLE saved_resumes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    resume_title TEXT NOT NULL,
    resume_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE saved_resumes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own resumes." ON saved_resumes FOR ALL USING (auth.uid() = user_id);

-- Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_saved_resumes_modtime
BEFORE UPDATE ON saved_resumes
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

-- 5. Create Photo Enhancements Table
CREATE TABLE photo_enhancements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    original_image_url TEXT NOT NULL,
    enhanced_image_url TEXT,
    enhancement_type TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE photo_enhancements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own photo enhancements." ON photo_enhancements FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own photo enhancements." ON photo_enhancements FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Storage bucket definition (Needs to be done manually or via Supabase UI typically, but here's the concept)
-- bucket_name: 'glowforge_photos'

-- ==============================================================================
-- ALGEBRIX SUPABASE BACKEND SCHEMA & RLS POLICIES
-- Execute this script in the Supabase Dashboard -> SQL Editor
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Step 1: Create public.profiles table
-- ------------------------------------------------------------------------------
-- Links directly to Supabase Auth (auth.users) via 1:1 foreign key.
-- Stores gamification stats (XP, level, streak, badges) and learning progress.

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    avatar_url TEXT,
    xp INTEGER NOT NULL DEFAULT 0,
    level INTEGER NOT NULL DEFAULT 1,
    level_title TEXT NOT NULL DEFAULT 'Math Beginner',
    streak INTEGER NOT NULL DEFAULT 0,
    badges TEXT[] NOT NULL DEFAULT '{}',
    completed_lesson_ids TEXT[] NOT NULL DEFAULT '{}',
    last_active TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Comment on table and key columns
COMMENT ON TABLE public.profiles IS 'Stores learner profile data, progress, and gamification state for Algebrix.';
COMMENT ON COLUMN public.profiles.id IS 'References auth.users.id 1:1';

-- ------------------------------------------------------------------------------
-- Step 2: Enable Row Level Security (RLS)
-- ------------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- Step 3: Define RLS Policies for public.profiles
-- ------------------------------------------------------------------------------

-- Allow users to read their own profile
CREATE POLICY "Users can view own profile" 
ON public.profiles 
FOR SELECT 
USING (auth.uid() = id);

-- Allow authenticated users to view profiles (for leaderboards/social features)
CREATE POLICY "Authenticated users can view all profiles"
ON public.profiles
FOR SELECT
TO authenticated
USING (true);

-- Allow users to insert their own profile matching auth.uid()
CREATE POLICY "Users can insert own profile" 
ON public.profiles 
FOR INSERT 
WITH CHECK (auth.uid() = id);

-- Allow users to update only their own profile
CREATE POLICY "Users can update own profile" 
ON public.profiles 
FOR UPDATE 
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- ------------------------------------------------------------------------------
-- Step 4: Create Automatic Profile Creation Trigger on User Signup
-- ------------------------------------------------------------------------------
-- Automatically executes when a new row is created in auth.users (via Email or Google OAuth).

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (
        id, 
        name, 
        avatar_url, 
        xp, 
        level, 
        level_title, 
        streak, 
        badges, 
        completed_lesson_ids, 
        last_active, 
        created_at, 
        updated_at
    )
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'full_name',
            NEW.raw_user_meta_data->>'name',
            SPLIT_PART(NEW.email, '@', 1),
            'Learner'
        ),
        NEW.raw_user_meta_data->>'avatar_url',
        0,
        1,
        'Math Beginner',
        0,
        '{}',
        '{}',
        NOW(),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        avatar_url = COALESCE(public.profiles.avatar_url, EXCLUDED.avatar_url),
        updated_at = NOW();

    RETURN NEW;
END;
$$;

-- Bind trigger to auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW 
    EXECUTE FUNCTION public.handle_new_user();

-- ------------------------------------------------------------------------------
-- Step 5: Updated At Auto-Maintenance Trigger
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

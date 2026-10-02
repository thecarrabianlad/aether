-- =============================================================
-- AETHER — User Profiles
-- Run this in the Supabase SQL Editor (or via supabase db push)
-- =============================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null default 'User',
  role text not null default 'Student',
  avatar_url text,
  is_premium boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------------------
-- ROW LEVEL SECURITY
-- Users can only see and modify their own profile.
-- ----------------------------------------
alter table public.profiles enable row level security;

create policy "Users manage own profile"
  on public.profiles for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ----------------------------------------
-- updated_at trigger (reuses set_updated_at from 001)
-- ----------------------------------------
create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

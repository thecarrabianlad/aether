-- =============================================================
-- AETHER — Habits Schema
-- Creates habits and habit_logs tables with reminder columns.
-- Run in Supabase SQL Editor or via supabase db push
-- =============================================================

-- ----------------------------------------
-- HABITS
-- ----------------------------------------
create table if not exists public.habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  category text not null default 'study', -- 'study' | 'health' | 'mind'
  icon text not null default 'menu_book_outlined',
  color text not null default '#E8443F',
  longest_streak int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  reminder_time text,   -- 'HH:mm' nullable
  reminder_days text    -- comma-separated ISO weekdays '1,3,5' nullable
);

-- ----------------------------------------
-- HABIT LOGS
-- ----------------------------------------
create table if not exists public.habit_logs (
  id uuid primary key default gen_random_uuid(),
  habit_id uuid not null references public.habits (id) on delete cascade,
  date date not null,
  is_completed boolean not null default false,

  -- Ensure only one log entry per habit per day
  unique(habit_id, date)
);

-- ----------------------------------------
-- INDEXES
-- ----------------------------------------
create index if not exists idx_habits_user on public.habits (user_id);
create index if not exists idx_habit_logs_habit on public.habit_logs (habit_id);

-- ----------------------------------------
-- ROW LEVEL SECURITY
-- ----------------------------------------
alter table public.habits enable row level security;
alter table public.habit_logs enable row level security;

create policy "Users manage own habits"
  on public.habits for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- habit_logs inherit access through the habits FK:
-- users can only insert/update/delete logs whose habit belongs to them.
create policy "Users manage own habit logs"
  on public.habit_logs for all
  using (
    exists (
      select 1 from public.habits
      where habits.id = habit_logs.habit_id
        and habits.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.habits
      where habits.id = habit_logs.habit_id
        and habits.user_id = auth.uid()
    )
  );

-- ----------------------------------------
-- updated_at trigger (set_updated_at already created in 001)
-- ----------------------------------------
create trigger habits_updated_at before update on public.habits
  for each row execute function public.set_updated_at();

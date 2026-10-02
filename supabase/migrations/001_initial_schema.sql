-- =============================================================
-- AETHER — Initial Academics Schema
-- Run this in the Supabase SQL Editor (or via supabase db push)
-- =============================================================

-- ----------------------------------------
-- COURSES
-- ----------------------------------------
create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  code text,
  professor text,
  color text not null default '#8B5CF6', -- hex accent color
  icon text,                              -- icon identifier
  semester text,
  location text,
  credits int,
  schedule_days text[],                   -- e.g. {'Mon','Wed','Fri'}
  schedule_start time,
  schedule_end time,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------------------
-- LECTURES
-- ----------------------------------------
create table if not exists public.lectures (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  chapter text,
  tag text,                               -- e.g. 'Upcoming'
  scheduled_at timestamptz,
  duration_minutes int default 90,
  is_completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------------------
-- ASSIGNMENTS
-- ----------------------------------------
create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  description text,
  due_date timestamptz,
  is_completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------------------
-- INDEXES
-- ----------------------------------------
create index if not exists idx_courses_user on public.courses (user_id);
create index if not exists idx_lectures_course on public.lectures (course_id);
create index if not exists idx_lectures_user on public.lectures (user_id);
create index if not exists idx_assignments_course on public.assignments (course_id);
create index if not exists idx_assignments_user on public.assignments (user_id);

-- ----------------------------------------
-- ROW LEVEL SECURITY
-- Users can only see and modify their own rows.
-- ----------------------------------------
alter table public.courses enable row level security;
alter table public.lectures enable row level security;
alter table public.assignments enable row level security;

create policy "Users manage own courses"
  on public.courses for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own lectures"
  on public.lectures for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own assignments"
  on public.assignments for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ----------------------------------------
-- updated_at trigger
-- ----------------------------------------
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger courses_updated_at before update on public.courses
  for each row execute function public.set_updated_at();
create trigger lectures_updated_at before update on public.lectures
  for each row execute function public.set_updated_at();
create trigger assignments_updated_at before update on public.assignments
  for each row execute function public.set_updated_at();

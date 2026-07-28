-- =============================================================
-- AETHER — Quick Access Schema (003)
-- Notes, Past Papers, Pomodoro, Flashcards
-- =============================================================

-- ----------------------------------------
-- NOTES
-- ----------------------------------------
create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  course_id uuid references public.courses (id) on delete cascade,
  title text not null,
  content text not null default '',
  tags text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------------------
-- PAST PAPERS
-- ----------------------------------------
create table if not exists public.past_papers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  course_id uuid references public.courses (id) on delete cascade,
  title text not null,
  year text,
  exam_type text,
  file_url text,
  file_name text,
  tags text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------------------
-- POMODORO SESSIONS
-- ----------------------------------------
create table if not exists public.pomodoro_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  task_id uuid, -- Optional reference to a task (no FK to keep it flexible)
  started_at timestamptz not null,
  ended_at timestamptz,
  planned_minutes int not null,
  actual_minutes int,
  completed boolean not null default false
);

-- ----------------------------------------
-- FLASHCARD DECKS
-- ----------------------------------------
create table if not exists public.flashcard_decks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  course_id uuid references public.courses (id) on delete cascade,
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------------------
-- FLASHCARDS
-- ----------------------------------------
create table if not exists public.flashcards (
  id uuid primary key default gen_random_uuid(),
  deck_id uuid not null references public.flashcard_decks (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  front text not null,
  back text not null,
  position int not null default 0,
  interval_days int not null default 1,
  ease_factor int not null default 250,
  repetitions int not null default 0,
  next_review_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------------------
-- INDEXES
-- ----------------------------------------
create index if not exists idx_notes_user on public.notes (user_id);
create index if not exists idx_notes_course on public.notes (course_id);
create index if not exists idx_past_papers_user on public.past_papers (user_id);
create index if not exists idx_past_papers_course on public.past_papers (course_id);
create index if not exists idx_pomodoro_sessions_user on public.pomodoro_sessions (user_id);
create index if not exists idx_flashcard_decks_user on public.flashcard_decks (user_id);
create index if not exists idx_flashcards_deck on public.flashcards (deck_id);
create index if not exists idx_flashcards_next_review on public.flashcards (next_review_at);

-- ----------------------------------------
-- ROW LEVEL SECURITY
-- ----------------------------------------
alter table public.notes enable row level security;
alter table public.past_papers enable row level security;
alter table public.pomodoro_sessions enable row level security;
alter table public.flashcard_decks enable row level security;
alter table public.flashcards enable row level security;

create policy "Users manage own notes" on public.notes for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own past papers" on public.past_papers for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own pomodoro sessions" on public.pomodoro_sessions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own flashcard decks" on public.flashcard_decks for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own flashcards" on public.flashcards for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ----------------------------------------
-- TRIGGERS
-- ----------------------------------------
create trigger notes_updated_at before update on public.notes for each row execute function public.set_updated_at();
create trigger past_papers_updated_at before update on public.past_papers for each row execute function public.set_updated_at();
create trigger flashcard_decks_updated_at before update on public.flashcard_decks for each row execute function public.set_updated_at();
create trigger flashcards_updated_at before update on public.flashcards for each row execute function public.set_updated_at();

-- ----------------------------------------
-- STORAGE BUCKET
-- ----------------------------------------
insert into storage.buckets (id, name, public) values ('past-papers', 'past-papers', false);

create policy "Users can upload own past papers"
  on storage.objects for insert
  with check (bucket_id = 'past-papers' and auth.uid() = owner);

create policy "Users can view own past papers"
  on storage.objects for select
  using (bucket_id = 'past-papers' and auth.uid() = owner);

create policy "Users can delete own past papers"
  on storage.objects for delete
  using (bucket_id = 'past-papers' and auth.uid() = owner);

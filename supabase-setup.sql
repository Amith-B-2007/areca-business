-- ═══════════════════════════════════════════════════════════
--  Areca Farm Tracker — database setup
--  Paste this whole file into Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════

-- ── Tables ────────────────────────────────────────────────
-- Text ids (not uuid) so records already saved on the phone
-- keep their existing ids when they sync up for the first time.

create table if not exists public.lands (
  id          text primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  name        text default '',
  position    int  default 0,
  deleted     boolean default false,
  updated_at  timestamptz default now()
);

create table if not exists public.harvests (
  id           text primary key,
  user_id      uuid not null references auth.users(id) on delete cascade,
  number       int,
  harvest_date date not null,
  rate         numeric default 0,
  price        numeric default 0,
  entries      jsonb   default '[]'::jsonb,
  total_fresh  numeric default 0,
  total_dried  numeric default 0,
  total_value  numeric default 0,
  deleted      boolean default false,
  updated_at   timestamptz default now()
);

create table if not exists public.expenses (
  id           text primary key,
  user_id      uuid not null references auth.users(id) on delete cascade,
  expense_date date not null,
  category     text,
  land_id      text,
  land_name    text default '',
  amount       numeric default 0,
  note         text    default '',
  deleted      boolean default false,
  updated_at   timestamptz default now()
);

-- one row per user: the drying rate and price he last used
create table if not exists public.settings (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  rate        text default '',
  price       text default '',
  updated_at  timestamptz default now()
);

-- ── Row Level Security ────────────────────────────────────
-- This is what makes the public anon key safe: every query is
-- restricted to the signed-in user's own rows.

alter table public.lands    enable row level security;
alter table public.harvests enable row level security;
alter table public.expenses enable row level security;
alter table public.settings enable row level security;

drop policy if exists "own lands"    on public.lands;
drop policy if exists "own harvests" on public.harvests;
drop policy if exists "own expenses" on public.expenses;
drop policy if exists "own settings" on public.settings;

create policy "own lands" on public.lands
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own harvests" on public.harvests
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own expenses" on public.expenses
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own settings" on public.settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── Indexes ───────────────────────────────────────────────
create index if not exists lands_user_idx    on public.lands(user_id);
create index if not exists harvests_user_idx on public.harvests(user_id, harvest_date desc);
create index if not exists expenses_user_idx on public.expenses(user_id, expense_date desc);

-- Done. Every table is protected: a signed-in user can only
-- ever read or write rows where user_id matches their own id.

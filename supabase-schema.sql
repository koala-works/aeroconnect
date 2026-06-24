-- ============================================================
-- AeroConnect — Supabase database setup
-- Paste this whole file into Supabase → SQL Editor → Run.
-- Safe to re-run (uses IF NOT EXISTS / OR REPLACE where possible).
-- ============================================================

-- ---------- PROFILES (one row per user: owner or pilot) ----------
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  role          text not null check (role in ('owner','pilot')),
  full_name     text not null,
  home_airport  text not null,
  ratings       text[] not null default '{}',   -- pilots only
  range_nm      int,                              -- pilots only
  available_from date,                            -- pilots only
  available_to   date,                            -- pilots only
  cert_level    text,                             -- pilots only
  created_at    timestamptz not null default now()
);

-- ---------- REQUESTS (an owner needs a pilot for a trip) ----------
create table if not exists public.requests (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references public.profiles(id) on delete cascade,
  aircraft    text not null,
  airport     text not null,
  trip_date   date not null,
  trip_name   text,
  notes       text,
  status      text not null default 'open',
  created_at  timestamptz not null default now()
);

-- ---------- CONNECTIONS (owner reaches out to a pilot for a request) ----------
create table if not exists public.connections (
  id          uuid primary key default gen_random_uuid(),
  request_id  uuid references public.requests(id) on delete cascade,
  owner_id    uuid not null references public.profiles(id) on delete cascade,
  pilot_id    uuid not null references public.profiles(id) on delete cascade,
  status      text not null default 'pending' check (status in ('pending','accepted','declined')),
  created_at  timestamptz not null default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- Class-app rules: any signed-in user can read the directory of
-- profiles & open requests; you can only write your own rows.
-- ============================================================
alter table public.profiles    enable row level security;
alter table public.requests    enable row level security;
alter table public.connections enable row level security;

-- profiles
drop policy if exists "read profiles" on public.profiles;
create policy "read profiles" on public.profiles
  for select to authenticated using (true);

drop policy if exists "insert own profile" on public.profiles;
create policy "insert own profile" on public.profiles
  for insert to authenticated with check (auth.uid() = id);

drop policy if exists "update own profile" on public.profiles;
create policy "update own profile" on public.profiles
  for update to authenticated using (auth.uid() = id);

-- requests
drop policy if exists "read requests" on public.requests;
create policy "read requests" on public.requests
  for select to authenticated using (true);

drop policy if exists "insert own requests" on public.requests;
create policy "insert own requests" on public.requests
  for insert to authenticated with check (auth.uid() = owner_id);

drop policy if exists "update own requests" on public.requests;
create policy "update own requests" on public.requests
  for update to authenticated using (auth.uid() = owner_id);

-- connections (only the owner or the pilot involved can see/update)
drop policy if exists "read own connections" on public.connections;
create policy "read own connections" on public.connections
  for select to authenticated using (auth.uid() = owner_id or auth.uid() = pilot_id);

drop policy if exists "owner inserts connections" on public.connections;
create policy "owner inserts connections" on public.connections
  for insert to authenticated with check (auth.uid() = owner_id);

drop policy if exists "involved updates connections" on public.connections;
create policy "involved updates connections" on public.connections
  for update to authenticated using (auth.uid() = owner_id or auth.uid() = pilot_id);

-- ============================================================
-- REALTIME — let all laptops receive live changes
-- ============================================================
alter publication supabase_realtime add table public.profiles;
alter publication supabase_realtime add table public.requests;
alter publication supabase_realtime add table public.connections;

-- Done. Next: turn OFF "Confirm email" in Authentication → Providers → Email,
-- then paste your Project URL + anon key into AeroConnect.html.

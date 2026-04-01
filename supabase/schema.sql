-- Run this in your Supabase SQL editor to set up the database

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  username text unique not null,
  created_at timestamptz default now()
);

create table if not exists game_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  started_at timestamptz default now(),
  ended_at timestamptz,
  rules_snapshot jsonb not null default '{}',
  hands_played int not null default 0,
  correct_decisions int not null default 0,
  incorrect_decisions int not null default 0
);

create table if not exists hand_records (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references game_sessions(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  timestamp timestamptz default now(),
  spot_number int not null default 0,
  player_cards jsonb not null default '[]',
  dealer_upcard jsonb,
  dealer_final_hand jsonb not null default '[]',
  hand_type text not null,
  player_total int not null,
  actions_taken jsonb not null default '[]',
  outcome text not null,
  was_split boolean not null default false,
  was_doubled boolean not null default false,
  was_surrendered boolean not null default false
);

-- Indexes
create index if not exists idx_sessions_user on game_sessions(user_id);
create index if not exists idx_hands_user on hand_records(user_id);
create index if not exists idx_hands_session on hand_records(session_id);

-- Row Level Security (open read/write via anon key — username is the only gating)
alter table users enable row level security;
alter table game_sessions enable row level security;
alter table hand_records enable row level security;

create policy "public read/write users" on users for all using (true) with check (true);
create policy "public read/write sessions" on game_sessions for all using (true) with check (true);
create policy "public read/write hands" on hand_records for all using (true) with check (true);

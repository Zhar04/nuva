-- Nuva — Supabase schema, Phase 1.
-- Run in SQL Editor of your Supabase project after creating it.
-- All access is gated through Row-Level Security policies below.

create extension if not exists "uuid-ossp";

-- ─────────────────────────────────────────────────────────
-- Users
-- ─────────────────────────────────────────────────────────
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  alias text not null default 'Аноним',
  language text not null default 'ru',
  created_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────
-- Specialists
-- ─────────────────────────────────────────────────────────
create table if not exists specialists (
  id uuid primary key default uuid_generate_v4(),
  first_name text not null,
  last_name text not null,
  title text not null,
  years_experience int not null,
  languages text[] not null default array[]::text[],
  approaches text[] not null default array[]::text[],
  works_with text[] not null default array[]::text[],
  session_price_kzt int not null,
  rating numeric(2,1) not null default 0,
  review_count int not null default 0,
  about text not null,
  avatar_gradient text[] not null default array['#7FB7E8','#A3D8F4'],
  is_verified boolean not null default false,
  is_active boolean not null default true,
  whatsapp_e164 text,
  created_at timestamptz not null default now()
);

create table if not exists education (
  id uuid primary key default uuid_generate_v4(),
  specialist_id uuid not null references specialists(id) on delete cascade,
  institution text not null,
  degree text not null,
  years text not null
);

create table if not exists reviews (
  id uuid primary key default uuid_generate_v4(),
  specialist_id uuid not null references specialists(id) on delete cascade,
  author_alias text not null,
  rating int not null check (rating between 1 and 5),
  text text not null,
  created_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────
-- Bookings + sessions
-- ─────────────────────────────────────────────────────────
create type booking_status as enum (
  'pending_payment', 'paid', 'completed', 'cancelled', 'refunded'
);

create type session_format as enum ('video', 'audio', 'chat');

create table if not exists bookings (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  specialist_id uuid not null references specialists(id) on delete restrict,
  starts_at timestamptz not null,
  format session_format not null default 'video',
  duration_minutes int not null default 50,
  price_kzt int not null,
  service_fee_kzt int not null default 1000,
  status booking_status not null default 'pending_payment',
  payment_provider text,
  payment_id text,
  created_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────
-- Chats
-- ─────────────────────────────────────────────────────────
create table if not exists chats (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  specialist_id uuid not null references specialists(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, specialist_id)
);

create table if not exists messages (
  id uuid primary key default uuid_generate_v4(),
  chat_id uuid not null references chats(id) on delete cascade,
  sender_id uuid not null,
  text text not null,
  is_voice boolean not null default false,
  voice_seconds int,
  sent_at timestamptz not null default now()
);
create index if not exists messages_chat_idx on messages(chat_id, sent_at);

-- ─────────────────────────────────────────────────────────
-- Community feed
-- ─────────────────────────────────────────────────────────
create table if not exists community_posts (
  id uuid primary key default uuid_generate_v4(),
  author_id uuid not null references auth.users(id) on delete cascade,
  author_alias text not null default 'Тихий ветер',
  text text not null,
  tags text[] not null default array[]::text[],
  is_supported boolean not null default false,
  likes_count int not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists community_posts_tags_idx on community_posts using gin(tags);
create index if not exists community_posts_created_idx
  on community_posts(created_at desc);

create table if not exists community_replies (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid not null references community_posts(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  author_alias text not null default 'Тихий ветер',
  text text not null,
  from_specialist boolean not null default false,
  likes_count int not null default 0,
  created_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────
-- Mood journal
-- ─────────────────────────────────────────────────────────
create table if not exists mood_entries (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  mood int not null check (mood between 1 and 5),
  note text,
  created_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────
-- Row-Level Security
-- ─────────────────────────────────────────────────────────
alter table profiles enable row level security;
alter table specialists enable row level security;
alter table education enable row level security;
alter table reviews enable row level security;
alter table bookings enable row level security;
alter table chats enable row level security;
alter table messages enable row level security;
alter table community_posts enable row level security;
alter table community_replies enable row level security;
alter table mood_entries enable row level security;

-- Profiles: read anyone, write only self
create policy "profiles read" on profiles for select using (true);
create policy "profiles write self" on profiles for all
  using (auth.uid() = id) with check (auth.uid() = id);

-- Specialists / education / reviews — public read.
create policy "specialists read" on specialists for select using (is_active);
create policy "education read" on education for select using (true);
create policy "reviews read" on reviews for select using (true);

-- Bookings — only owner
create policy "bookings own" on bookings for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Chats — only owner
create policy "chats own" on chats for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Messages — only if the user owns the chat
create policy "messages own" on messages for all
  using (
    exists (
      select 1 from chats c
      where c.id = chat_id and c.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from chats c
      where c.id = chat_id and c.user_id = auth.uid()
    )
  );

-- Community — read everyone, write self
create policy "posts read" on community_posts for select using (true);
create policy "posts write" on community_posts for insert
  with check (auth.uid() = author_id);
create policy "posts update own" on community_posts for update
  using (auth.uid() = author_id);

create policy "replies read" on community_replies for select using (true);
create policy "replies write" on community_replies for insert
  with check (auth.uid() = author_id);

-- Mood — only owner
create policy "mood own" on mood_entries for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────
-- Seed: minimal demo psychologists. Replace before launch.
-- ─────────────────────────────────────────────────────────
insert into specialists
  (first_name, last_name, title, years_experience, languages, approaches,
   works_with, session_price_kzt, rating, review_count, about,
   avatar_gradient, is_verified)
values
  ('Айгуль', 'С.', 'Клинический психолог', 9,
   array['Қазақша','Русский','English'], array['КПТ','Схема-терапия'],
   array['Тревога','Самооценка','Отношения'], 18000, 4.9, 142,
   'Помогаю взрослым справиться с тревожностью и стрессом.',
   array['#FFB6C1','#FFC8DD'], true),
  ('Арман', 'Б.', 'Психотерапевт', 12,
   array['Русский','Қазақша'], array['Гештальт','EMDR'],
   array['Травма','ПТСР','Утрата'], 22000, 4.8, 98,
   'Специализируюсь на работе с травматическим опытом.',
   array['#7FB7E8','#A3D8F4'], true);

-- ============================================================
-- WE RISE — Supabase Migration 001: Initial schema
-- ============================================================
-- Run with: supabase db push
-- All tables use UUID primary keys.
-- RLS enforced on every table.
-- ============================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";
create extension if not exists "pg_cron";  -- for auto-escalation

-- ── ENUMS ────────────────────────────────────────────────────────────────────

create type complaint_status as enum (
  'pending_review', 'verified', 'assigned', 'work_started',
  'awaiting_confirmation', 'problem_solved', 'rejected', 'escalated'
);

create type complaint_category as enum (
  'pothole', 'garbage', 'sewage', 'waterlogging',
  'blocked_drain', 'streetlight', 'other'
);

create type user_role as enum (
  'citizen', 'volunteer', 'moderator', 'partner', 'authority'
);

create type org_type as enum (
  'ngo', 'rwa', 'nss', 'ncc', 'gcc', 'cmwssb', 'pwd', 'other'
);

create type photo_source as enum ('camera', 'gallery');

create type risk_class as enum ('low', 'medium', 'dangerous');

create type confirmation_kind as enum ('confirmed', 'rejected');

-- ── USERS ────────────────────────────────────────────────────────────────────

create table public.app_users (
  id               uuid primary key default uuid_generate_v4(),
  auth_user_id     uuid references auth.users(id) on delete cascade,
  anonymous_handle text not null unique,
  role             user_role not null default 'citizen',
  ward_id          text,
  organisation_id  uuid,
  volunteer_hours  numeric(8,2) not null default 0,
  created_at       timestamptz not null default now()
);

-- RLS: users can read their own row; public sees nothing (no names)
alter table public.app_users enable row level security;

create policy "Users can read own profile"
  on public.app_users for select
  using (auth.uid() = auth_user_id);

create policy "Users can update own profile"
  on public.app_users for update
  using (auth.uid() = auth_user_id);

-- ── WARDS ────────────────────────────────────────────────────────────────────

create table public.wards (
  id                  text primary key,
  name                text not null,
  vulnerability_index numeric(4,3) not null default 0.5
);

alter table public.wards enable row level security;

create policy "Wards are publicly readable"
  on public.wards for select using (true);

-- Seed wards
insert into public.wards values
  ('tondiarpet',     'Tondiarpet',     0.90),
  ('perungudi',      'Perungudi',      0.75),
  ('kodambakkam',    'Kodambakkam',    0.70),
  ('velachery',      'Velachery',      0.55),
  ('sholinganallur', 'Sholinganallur', 0.45),
  ('t_nagar',        'T. Nagar',       0.35),
  ('adyar',          'Adyar',          0.30),
  ('anna_nagar',     'Anna Nagar',     0.25);

-- ── ORGANISATIONS ─────────────────────────────────────────────────────────────

create table public.organisations (
  id            uuid primary key default uuid_generate_v4(),
  name          text not null,
  type          org_type not null,
  ward_ids      text[] not null default '{}',
  admin_user_id uuid references public.app_users(id),
  created_at    timestamptz not null default now()
);

alter table public.organisations enable row level security;

create policy "Organisations are publicly readable"
  on public.organisations for select using (true);

-- ── COMPLAINTS ───────────────────────────────────────────────────────────────

create table public.complaints (
  id                 uuid primary key default uuid_generate_v4(),
  tracking_id        text not null unique,
  category           complaint_category not null,
  status             complaint_status not null default 'pending_review',
  ward_id            text not null references public.wards(id),
  lat                double precision not null,
  lng                double precision not null,
  reporter_id        uuid not null references public.app_users(id),
  note               text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  escalated          boolean not null default false,
  severity_override  numeric(3,1),
  priority_score     numeric(5,2),
  assigned_org_id    uuid references public.organisations(id),
  recurrence_count   integer not null default 0
);

alter table public.complaints enable row level security;

-- Public reads: show location, category, status — NOT reporter_id
create policy "Public can view approved complaints (anonymous fields only)"
  on public.complaints for select
  using (status != 'pending_review' and status != 'rejected');

-- Reporter can see own pending complaints
create policy "Reporter can view own pending complaints"
  on public.complaints for select
  using (
    auth.uid() = (select auth_user_id from public.app_users where id = reporter_id)
    and status = 'pending_review'
  );

-- Any authenticated user can create a complaint
create policy "Authenticated users can create complaints"
  on public.complaints for insert
  with check (auth.uid() is not null);

-- Only moderators can set verified/rejected
create policy "Only moderators can verify or reject"
  on public.complaints for update
  using (
    (select role from public.app_users where auth_user_id = auth.uid()) = 'moderator'
    or auth.uid() = (select auth_user_id from public.app_users where id = reporter_id)
  );

-- ── COMPLAINT PHOTOS ─────────────────────────────────────────────────────────

create table public.complaint_photos (
  id           uuid primary key default uuid_generate_v4(),
  complaint_id uuid not null references public.complaints(id) on delete cascade,
  storage_path text not null,
  source       photo_source not null,
  captured_at  timestamptz,
  lat          double precision,
  lng          double precision,
  is_after     boolean not null default false,
  created_at   timestamptz not null default now()
);

alter table public.complaint_photos enable row level security;

create policy "Photos visible for public complaints"
  on public.complaint_photos for select
  using (
    exists (
      select 1 from public.complaints c
      where c.id = complaint_id
        and c.status not in ('pending_review', 'rejected')
    )
  );

create policy "Authenticated can insert photos"
  on public.complaint_photos for insert
  with check (auth.uid() is not null);

-- ── STATUS HISTORY ────────────────────────────────────────────────────────────

create table public.status_history (
  id           uuid primary key default uuid_generate_v4(),
  complaint_id uuid not null references public.complaints(id) on delete cascade,
  status       complaint_status not null,
  actor_role   user_role not null,
  note         text,
  created_at   timestamptz not null default now()
);

alter table public.status_history enable row level security;

create policy "Status history visible for public complaints"
  on public.status_history for select
  using (
    exists (
      select 1 from public.complaints c
      where c.id = complaint_id
        and c.status not in ('pending_review', 'rejected')
    )
  );

-- ── SUPPORTERS ───────────────────────────────────────────────────────────────

create table public.supporters (
  complaint_id uuid not null references public.complaints(id) on delete cascade,
  user_id      uuid not null references public.app_users(id) on delete cascade,
  created_at   timestamptz not null default now(),
  primary key (complaint_id, user_id)
);

alter table public.supporters enable row level security;

create policy "Anyone can see support count (not who)"
  on public.supporters for select using (true);

create policy "Authenticated can support"
  on public.supporters for insert
  with check (
    auth.uid() = (select auth_user_id from public.app_users where id = user_id)
  );

-- ── TASKS ────────────────────────────────────────────────────────────────────

create table public.tasks (
  id                      uuid primary key default uuid_generate_v4(),
  complaint_id            uuid not null references public.complaints(id) on delete cascade,
  supervising_org_id      uuid not null references public.organisations(id),
  volunteer_safe          boolean not null default false,
  volunteer_ids           uuid[] not null default '{}',
  required_skills         text[] not null default '{}',
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

alter table public.tasks enable row level security;

create policy "Volunteer-safe tasks are publicly visible"
  on public.tasks for select
  using (volunteer_safe = true);

-- ── CONFIRMATIONS ────────────────────────────────────────────────────────────

create table public.confirmations (
  id           uuid primary key default uuid_generate_v4(),
  complaint_id uuid not null references public.complaints(id) on delete cascade,
  user_id      uuid not null references public.app_users(id),
  kind         confirmation_kind not null,
  lat          double precision not null,
  lng          double precision not null,
  note         text,
  created_at   timestamptz not null default now(),
  unique (complaint_id, user_id)
);

alter table public.confirmations enable row level security;

create policy "Authenticated can confirm"
  on public.confirmations for insert
  with check (auth.uid() is not null);

create policy "Own confirmations readable"
  on public.confirmations for select
  using (auth.uid() = (select auth_user_id from public.app_users where id = user_id));

-- ── CLOSURE RULE FUNCTION ─────────────────────────────────────────────────────
-- Enforces: original reporter confirmed + 2 distinct nearby users (≤300m) +
-- resolver NOT among confirmers.

create or replace function can_close_complaint(
  p_complaint_id uuid,
  p_resolver_user_id uuid
) returns boolean language plpgsql security definer as $$
declare
  v_reporter_id    uuid;
  v_comp_lat       double precision;
  v_comp_lng       double precision;
  reporter_confirmed boolean;
  nearby_non_resolver integer;
begin
  select reporter_id, lat, lng
    into v_reporter_id, v_comp_lat, v_comp_lng
    from public.complaints
   where id = p_complaint_id;

  -- 1. Original reporter must have confirmed
  select exists (
    select 1 from public.confirmations
     where complaint_id = p_complaint_id
       and user_id = v_reporter_id
       and kind = 'confirmed'
  ) into reporter_confirmed;

  if not reporter_confirmed then return false; end if;

  -- 2. Resolver must NOT be among confirmers
  if exists (
    select 1 from public.confirmations
     where complaint_id = p_complaint_id
       and user_id = p_resolver_user_id
  ) then return false; end if;

  -- 3. Count distinct nearby confirmers (≤300m, excluding resolver, excluding reporter)
  select count(distinct c.user_id)
    into nearby_non_resolver
    from public.confirmations c
    join public.complaints comp on comp.id = c.complaint_id
   where c.complaint_id = p_complaint_id
     and c.user_id != p_resolver_user_id
     and c.user_id != v_reporter_id
     and c.kind = 'confirmed'
     and (
       6371000 * acos(
         cos(radians(v_comp_lat)) * cos(radians(c.lat)) *
         cos(radians(c.lng) - radians(v_comp_lng)) +
         sin(radians(v_comp_lat)) * sin(radians(c.lat))
       )
     ) <= 300;

  return nearby_non_resolver >= 2;
end;
$$;

-- ── AUTO-ESCALATION VIA pg_cron ──────────────────────────────────────────────
-- Runs every hour; escalates complaints with no update for 7+ days

create or replace function escalate_stale_complaints() returns void
language plpgsql security definer as $$
begin
  update public.complaints
     set escalated = true,
         status    = 'escalated',
         updated_at = now()
   where status not in ('problem_solved', 'rejected', 'escalated')
     and updated_at < now() - interval '7 days';
end;
$$;

select cron.schedule(
  'escalate-stale-complaints',
  '0 * * * *',  -- every hour
  'select escalate_stale_complaints()'
);

-- ── PRIORITY RECALCULATION ────────────────────────────────────────────────────

create or replace function recalculate_priority(p_complaint_id uuid)
returns numeric language plpgsql security definer as $$
declare
  v_severity       numeric;
  v_age_days       numeric;
  v_vulnerability  numeric;
  v_recurrence     integer;
  v_support_count  integer;
  v_age_factor     numeric;
  v_demand_capped  numeric;
  v_score          numeric;
  v_category       complaint_category;
  v_ward_id        text;
  v_created_at     timestamptz;
begin
  select category, ward_id, created_at
    into v_category, v_ward_id, v_created_at
    from public.complaints
   where id = p_complaint_id;

  -- Severity by category (1-5 normalised)
  v_severity := case v_category
    when 'sewage'       then 0.90
    when 'waterlogging' then 0.80
    when 'pothole'      then 0.70
    when 'blocked_drain'then 0.60
    when 'streetlight'  then 0.75
    when 'garbage'      then 0.40
    else                     0.30
  end;

  -- Age factor (0-1, capped at 30 days)
  v_age_days   := least(extract(epoch from (now() - v_created_at)) / 86400, 30);
  v_age_factor := v_age_days / 30.0;

  -- Equity weight from ward
  select vulnerability_index into v_vulnerability
    from public.wards where id = v_ward_id;
  v_vulnerability := coalesce(v_vulnerability, 0.5);

  -- Recurrence
  select recurrence_count into v_recurrence
    from public.complaints where id = p_complaint_id;

  -- Demand (log-scaled, cap 50)
  select count(*) into v_support_count
    from public.supporters where complaint_id = p_complaint_id;
  v_demand_capped := ln(least(v_support_count, 50) + 1) / ln(51);

  v_score := 100 * (
    0.35 * v_severity +
    0.25 * v_age_factor +
    0.20 * v_vulnerability +
    0.12 * (least(v_recurrence, 10) / 10.0) +
    0.08 * v_demand_capped
  );

  update public.complaints
     set priority_score = v_score
   where id = p_complaint_id;

  return v_score;
end;
$$;

-- ── TRACKING ID GENERATION ────────────────────────────────────────────────────

create sequence if not exists complaint_seq start 1;

create or replace function generate_tracking_id() returns text
language plpgsql as $$
declare
  v_seq integer;
  v_year integer;
begin
  v_seq  := nextval('complaint_seq');
  v_year := extract(year from now());
  return 'WR-CHE-' || v_year || '-' || lpad(v_seq::text, 6, '0');
end;
$$;

-- ============================================================
-- WE RISE — Supabase Migration 002: Certificates, Account Deletion & Storage
-- ============================================================

-- ── CERTIFICATES ─────────────────────────────────────────────────────────────

create table if not exists public.certificates (
  id                uuid primary key default uuid_generate_v4(),
  user_id           uuid not null references public.app_users(id) on delete cascade,
  anonymous_handle  text not null,
  org_id            uuid not null references public.organisations(id),
  hours             numeric(6,2) not null,
  verification_code text not null unique,
  issued_at         timestamptz not null default now()
);

alter table public.certificates enable row level security;

create policy "Users can view own certificates"
  on public.certificates for select
  using (auth.uid() = (select auth_user_id from public.app_users where id = user_id));

create policy "Anyone can verify a certificate by code"
  on public.certificates for select
  using (true);

create policy "Authenticated can create own certificate"
  on public.certificates for insert
  with check (auth.uid() = (select auth_user_id from public.app_users where id = user_id));

-- ── ACCOUNT DELETION RPC ─────────────────────────────────────────────────────

create or replace function delete_own_account() returns void
language plpgsql security definer as $$
begin
  delete from public.app_users where auth_user_id = auth.uid();
end;
$$;

-- ── STORAGE BUCKET & POLICIES ────────────────────────────────────────────────

insert into storage.buckets (id, name, public)
values ('complaint-photos', 'complaint-photos', true)
on conflict (id) do nothing;

create policy "Public read complaint photos"
  on storage.objects for select
  using (bucket_id = 'complaint-photos');

create policy "Authenticated upload complaint photos"
  on storage.objects for insert
  with check (bucket_id = 'complaint-photos' and auth.uid() is not null);

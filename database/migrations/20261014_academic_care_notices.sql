create table if not exists public.academic_care_notices (
 id uuid primary key default gen_random_uuid(),
 title text not null check (length(trim(title)) between 3 and 200),
 body text not null check (length(trim(body)) between 1 and 10000),
 notice_type text not null default 'normal' check (notice_type in ('normal','urgent')),
 link_url text,
 publish_at timestamptz,
 expires_at timestamptz,
 status text not null default 'draft' check (status in ('draft','published')),
 created_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint academic_care_notices_valid_dates check (expires_at is null or publish_at is null or expires_at > publish_at),
 constraint academic_care_notices_valid_link check (link_url is null or link_url ~* '^https?://')
);
alter table public.academic_care_notices enable row level security;
drop policy if exists academic_care_notices_admin_all on public.academic_care_notices;
create policy academic_care_notices_admin_all on public.academic_care_notices for all to authenticated using (public.academic_care_is_admin()) with check (public.academic_care_is_admin());
drop policy if exists academic_care_notices_public_read on public.academic_care_notices;
create policy academic_care_notices_public_read on public.academic_care_notices for select to anon, authenticated using (status='published' and (publish_at is null or publish_at <= now()) and (expires_at is null or expires_at > now()));
create index if not exists academic_care_notices_public_schedule_idx on public.academic_care_notices(status,publish_at,expires_at);

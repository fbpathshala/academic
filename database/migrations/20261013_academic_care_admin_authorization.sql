create table if not exists public.academic_care_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin' check (role in ('admin', 'editor')),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.academic_care_admins enable row level security;
revoke all on public.academic_care_admins from anon, authenticated;
create or replace function public.academic_care_is_admin()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists (select 1 from public.academic_care_admins a where a.user_id=(select auth.uid()) and a.is_active=true); $$;
revoke all on function public.academic_care_is_admin() from public;
grant execute on function public.academic_care_is_admin() to authenticated;
drop policy if exists academic_care_admins_select_self on public.academic_care_admins;
create policy academic_care_admins_select_self on public.academic_care_admins for select to authenticated using (user_id=(select auth.uid()));
drop policy if exists academic_care_exams_admin_all on public.academic_care_exams;
create policy academic_care_exams_admin_all on public.academic_care_exams for all to authenticated using (public.academic_care_is_admin()) with check (public.academic_care_is_admin());
drop policy if exists academic_care_materials_admin_all on public.academic_care_materials;
create policy academic_care_materials_admin_all on public.academic_care_materials for all to authenticated using (public.academic_care_is_admin()) with check (public.academic_care_is_admin());
drop policy if exists academic_care_submissions_admin_select on public.academic_care_submissions;
create policy academic_care_submissions_admin_select on public.academic_care_submissions for select to authenticated using (public.academic_care_is_admin());
drop policy if exists academic_care_submissions_admin_update on public.academic_care_submissions;
create policy academic_care_submissions_admin_update on public.academic_care_submissions for update to authenticated using (public.academic_care_is_admin()) with check (public.academic_care_is_admin());
grant select, insert, update, delete on public.academic_care_exams to authenticated;
grant select, insert, update, delete on public.academic_care_materials to authenticated;
grant select, update on public.academic_care_submissions to authenticated;

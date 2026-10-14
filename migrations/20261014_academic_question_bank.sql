-- Additive migration: standalone Academic Care question bank.
-- Existing exam-linked academic_care_questions and student records are untouched.
create table if not exists public.academic_care_question_bank (
  id uuid primary key default gen_random_uuid(),
  category_id bigint not null references public.academic_care_categories(id) on delete restrict,
  folder_id bigint not null references public.academic_care_folders(id) on delete restrict,
  set_id bigint not null references public.academic_care_sets(id) on delete restrict,
  question_text text not null,
  question_type text not null default 'mcq' check (question_type in ('mcq','cq')),
  options jsonb not null default '[]'::jsonb,
  correct_option text,
  accepted_answers jsonb not null default '[]'::jsonb,
  marks numeric not null default 1 check (marks >= 0),
  subject text,
  sort_order integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists academic_care_question_bank_category_idx
  on public.academic_care_question_bank(category_id);
create index if not exists academic_care_question_bank_folder_idx
  on public.academic_care_question_bank(folder_id);
create index if not exists academic_care_question_bank_set_idx
  on public.academic_care_question_bank(set_id);

alter table public.academic_care_question_bank enable row level security;

drop policy if exists academic_care_question_bank_admin_all
  on public.academic_care_question_bank;
create policy academic_care_question_bank_admin_all
  on public.academic_care_question_bank
  for all to authenticated
  using (public.academic_care_is_admin())
  with check (public.academic_care_is_admin());

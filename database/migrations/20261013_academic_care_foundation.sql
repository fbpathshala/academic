-- Academic Care foundation schema
-- Applied to Supabase project without modifying existing MCQ Exam tables.
-- Keep RLS enabled and do not add public write policies until authenticated
-- admin flows and safe student submission endpoints are implemented.

create table if not exists public.academic_care_exams (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(trim(title)) between 1 and 200),
  exam_type text not null check (exam_type in ('MCQ', 'CQ', 'MCQ_CQ')),
  duration_minutes integer not null default 30 check (duration_minutes between 1 and 600),
  status text not null default 'draft' check (status in ('draft', 'scheduled', 'published', 'closed', 'archived')),
  description text,
  public_token uuid not null default gen_random_uuid() unique,
  settings jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.academic_care_materials (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(trim(title)) between 1 and 200),
  material_type text not null check (material_type in ('PDF', 'NOTE', 'IMAGE', 'OTHER')),
  subject text,
  description text,
  storage_path text,
  external_url text,
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint academic_care_material_location_check
    check (storage_path is not null or external_url is not null or status = 'draft')
);

create table if not exists public.academic_care_submissions (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.academic_care_exams(id) on delete restrict,
  student_name text not null check (length(trim(student_name)) between 1 and 200),
  student_contact text,
  answer_text text,
  answer_file_path text,
  mcq_answers jsonb not null default '{}'::jsonb,
  score numeric,
  total_marks numeric,
  grading_status text not null default 'pending' check (grading_status in ('pending', 'auto_graded', 'manual_review', 'graded')),
  submitted_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint academic_care_submission_content_check
    check (answer_text is not null or answer_file_path is not null or mcq_answers <> '{}'::jsonb)
);

create index if not exists academic_care_exams_status_created_idx
  on public.academic_care_exams (status, created_at desc);
create index if not exists academic_care_materials_status_created_idx
  on public.academic_care_materials (status, created_at desc);
create index if not exists academic_care_submissions_exam_submitted_idx
  on public.academic_care_submissions (exam_id, submitted_at desc);

alter table public.academic_care_exams enable row level security;
alter table public.academic_care_materials enable row level security;
alter table public.academic_care_submissions enable row level security;

revoke all on public.academic_care_exams from anon, authenticated;
revoke all on public.academic_care_materials from anon, authenticated;
revoke all on public.academic_care_submissions from anon, authenticated;

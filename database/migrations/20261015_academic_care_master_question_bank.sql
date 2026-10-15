-- Standalone master question bank for the Question Creation section.
-- Additive only: existing exam questions, answer keys, and submissions remain untouched.
create table if not exists public.academic_care_question_bank_items (
  id uuid primary key default gen_random_uuid(),
  question_text text not null check (length(trim(question_text)) between 1 and 20000),
  question_type text not null check (question_type in ('mcq','cq')),
  options jsonb not null default '[]'::jsonb,
  marks numeric not null default 1 check (marks >= 0),
  sort_order integer not null default 0,
  category_id bigint references public.academic_care_categories(id) on delete restrict,
  folder_id bigint references public.academic_care_folders(id) on delete restrict,
  set_id bigint references public.academic_care_sets(id) on delete restrict,
  subject text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint academic_care_bank_item_mcq_options_check
    check (question_type <> 'mcq' or jsonb_typeof(options) = 'array' and jsonb_array_length(options) = 4),
  constraint academic_care_bank_item_cq_options_check
    check (question_type <> 'cq' or options = '[]'::jsonb)
);
create table if not exists public.academic_care_question_bank_answer_keys (
  question_id uuid primary key references public.academic_care_question_bank_items(id) on delete cascade,
  correct_option text not null check (correct_option in ('a','b','c','d')),
  updated_at timestamptz not null default now()
);
create index if not exists academic_care_question_bank_items_filter_idx
  on public.academic_care_question_bank_items (question_type, category_id, folder_id, set_id, subject);
create index if not exists academic_care_question_bank_items_created_idx
  on public.academic_care_question_bank_items (created_at desc);
alter table public.academic_care_question_bank_items enable row level security;
alter table public.academic_care_question_bank_answer_keys enable row level security;
revoke all on public.academic_care_question_bank_items from anon, authenticated;
revoke all on public.academic_care_question_bank_answer_keys from anon, authenticated;
grant select, insert, update, delete on public.academic_care_question_bank_items to authenticated;
grant select, insert, update, delete on public.academic_care_question_bank_answer_keys to authenticated;
drop policy if exists academic_care_question_bank_items_admin_all on public.academic_care_question_bank_items;
create policy academic_care_question_bank_items_admin_all
  on public.academic_care_question_bank_items for all to authenticated
  using (public.academic_care_is_admin()) with check (public.academic_care_is_admin());
drop policy if exists academic_care_question_bank_answer_keys_admin_all on public.academic_care_question_bank_answer_keys;
create policy academic_care_question_bank_answer_keys_admin_all
  on public.academic_care_question_bank_answer_keys for all to authenticated
  using (public.academic_care_is_admin()) with check (public.academic_care_is_admin());

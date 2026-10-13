create table if not exists public.academic_care_questions (
 id uuid primary key default gen_random_uuid(), exam_id uuid not null references public.academic_care_exams(id) on delete cascade,
 question_text text not null, question_type text not null default 'mcq' check(question_type in ('mcq','cq')),
 options jsonb not null default '[]'::jsonb, marks numeric not null default 1 check(marks>=0),
 sort_order integer not null default 0, created_at timestamptz not null default now()
);
create table if not exists public.academic_care_answer_keys (
 question_id uuid primary key references public.academic_care_questions(id) on delete cascade,
 correct_option text, accepted_answers jsonb not null default '[]'::jsonb, updated_at timestamptz not null default now()
);
create index if not exists academic_care_questions_exam_sort_idx on public.academic_care_questions(exam_id,sort_order);
alter table public.academic_care_questions enable row level security;
alter table public.academic_care_answer_keys enable row level security;
revoke all on public.academic_care_questions from anon,authenticated;
revoke all on public.academic_care_answer_keys from anon,authenticated;
grant select on public.academic_care_questions to anon,authenticated;
grant select,insert,update,delete on public.academic_care_questions to authenticated;
grant select,insert,update,delete on public.academic_care_answer_keys to authenticated;
drop policy if exists academic_care_questions_public_read on public.academic_care_questions;
create policy academic_care_questions_public_read on public.academic_care_questions for select to anon,authenticated using (exists(select 1 from public.academic_care_exams e where e.id=academic_care_questions.exam_id and e.status='published'));
drop policy if exists academic_care_questions_admin_all on public.academic_care_questions;
create policy academic_care_questions_admin_all on public.academic_care_questions for all to authenticated using(public.academic_care_is_admin()) with check(public.academic_care_is_admin());
drop policy if exists academic_care_answer_keys_admin_all on public.academic_care_answer_keys;
create policy academic_care_answer_keys_admin_all on public.academic_care_answer_keys for all to authenticated using(public.academic_care_is_admin()) with check(public.academic_care_is_admin());
drop policy if exists academic_care_exams_public_read on public.academic_care_exams;
create policy academic_care_exams_public_read on public.academic_care_exams for select to anon,authenticated using(status='published');
drop policy if exists academic_care_materials_public_read on public.academic_care_materials;
create policy academic_care_materials_public_read on public.academic_care_materials for select to anon,authenticated using(status='published');
grant select on public.academic_care_exams to anon,authenticated;
grant select on public.academic_care_materials to anon,authenticated;
create or replace function public.academic_care_submit_exam(p_public_token uuid,p_student_name text,p_student_contact text default null,p_answer_text text default null,p_mcq_answers jsonb default '{}'::jsonb,p_answer_file_path text default null)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_exam public.academic_care_exams%rowtype; v_submission_id uuid; v_score numeric:=0; v_total numeric:=0; v_has_mcq boolean:=false; v_item record; v_answer text;
begin
 if p_student_name is null or length(trim(p_student_name))<2 or length(trim(p_student_name))>160 then raise exception 'Please enter a valid student name'; end if;
 if coalesce(length(p_student_contact),0)>200 or coalesce(length(p_answer_text),0)>50000 then raise exception 'Submitted data is too long'; end if;
 if p_mcq_answers is null or jsonb_typeof(p_mcq_answers)<>'object' then raise exception 'MCQ answers must be an object'; end if;
 select * into v_exam from public.academic_care_exams where public_token=p_public_token and status='published';
 if not found then raise exception 'Exam not found or not published'; end if;
 if v_exam.exam_type in ('CQ','MCQ + CQ') and nullif(trim(coalesce(p_answer_text,'')),'') is null and nullif(trim(coalesce(p_answer_file_path,'')),'') is null then raise exception 'Please provide your written answer or answer-sheet photo'; end if;
 for v_item in select q.id,q.marks,k.correct_option from public.academic_care_questions q left join public.academic_care_answer_keys k on k.question_id=q.id where q.exam_id=v_exam.id and q.question_type='mcq'
 loop v_has_mcq:=true;v_total:=v_total+v_item.marks;v_answer:=p_mcq_answers->>v_item.id::text;if v_item.correct_option is not null and v_answer=v_item.correct_option then v_score:=v_score+v_item.marks;end if;end loop;
 if (select count(*) from jsonb_object_keys(p_mcq_answers))>(select count(*) from public.academic_care_questions q where q.exam_id=v_exam.id and q.question_type='mcq') then raise exception 'Submitted answers contain unknown question IDs'; end if;
 insert into public.academic_care_submissions(exam_id,student_name,student_contact,answer_text,answer_file_path,mcq_answers,score,total_marks,grading_status)
 values(v_exam.id,trim(p_student_name),nullif(trim(coalesce(p_student_contact,'')),''),nullif(trim(coalesce(p_answer_text,'')),''),nullif(trim(coalesce(p_answer_file_path,'')),''),p_mcq_answers,case when v_has_mcq then v_score else null end,case when v_has_mcq then v_total else null end,case when v_has_mcq then 'auto_graded' else 'pending' end)
 returning id into v_submission_id;
 return jsonb_build_object('submission_id',v_submission_id,'grading_status',case when v_has_mcq then 'auto_graded' else 'pending' end,'score',case when v_has_mcq then v_score else null end,'total_marks',case when v_has_mcq then v_total else null end,'message','Submission received');
end; $$;
revoke all on function public.academic_care_submit_exam(uuid,text,text,text,jsonb,text) from public;
grant execute on function public.academic_care_submit_exam(uuid,text,text,text,jsonb,text) to anon,authenticated;
revoke all on public.academic_care_submissions from anon,authenticated;
grant select,update on public.academic_care_submissions to authenticated;

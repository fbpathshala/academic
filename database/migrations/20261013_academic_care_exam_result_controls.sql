-- Replace the submission RPC with per-exam result controls.
create or replace function public.academic_care_submit_exam(
 p_public_token uuid,p_student_name text,p_student_contact text default null,p_answer_text text default null,p_mcq_answers jsonb default '{}'::jsonb,p_answer_file_path text default null
) returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_exam public.academic_care_exams%rowtype;v_submission_id uuid;v_score numeric:=0;v_total numeric:=0;v_has_mcq boolean:=false;v_item record;v_answer text;v_show_results boolean:=false;v_show_position boolean:=false;v_position bigint;
begin
 if p_student_name is null or length(trim(p_student_name))<2 or length(trim(p_student_name))>160 then raise exception 'Please enter a valid student name';end if;
 if coalesce(length(p_student_contact),0)>200 or coalesce(length(p_answer_text),0)>50000 then raise exception 'Submitted data is too long';end if;
 if p_mcq_answers is null or jsonb_typeof(p_mcq_answers)<>'object' then raise exception 'MCQ answers must be an object';end if;
 select * into v_exam from public.academic_care_exams where public_token=p_public_token and status='published';
 if not found then raise exception 'Exam not found or not published';end if;
 v_show_results:=coalesce((v_exam.settings->>'show_results')::boolean,false);
 v_show_position:=coalesce((v_exam.settings->>'show_position')::boolean,false);
 if v_exam.exam_type in ('CQ','MCQ + CQ') and nullif(trim(coalesce(p_answer_text,'')),'') is null and nullif(trim(coalesce(p_answer_file_path,'')),'') is null then raise exception 'Please provide your written answer or answer-sheet photo';end if;
 for v_item in select q.id,q.marks,k.correct_option from public.academic_care_questions q left join public.academic_care_answer_keys k on k.question_id=q.id where q.exam_id=v_exam.id and q.question_type='mcq'
 loop v_has_mcq:=true;v_total:=v_total+v_item.marks;v_answer:=p_mcq_answers->>v_item.id::text;if v_item.correct_option is not null and v_answer=v_item.correct_option then v_score:=v_score+v_item.marks;end if;end loop;
 if (select count(*) from jsonb_object_keys(p_mcq_answers))>(select count(*) from public.academic_care_questions q where q.exam_id=v_exam.id and q.question_type='mcq') then raise exception 'Submitted answers contain unknown question IDs';end if;
 insert into public.academic_care_submissions(exam_id,student_name,student_contact,answer_text,answer_file_path,mcq_answers,score,total_marks,grading_status)
 values(v_exam.id,trim(p_student_name),nullif(trim(coalesce(p_student_contact,'')),''),nullif(trim(coalesce(p_answer_text,'')),''),nullif(trim(coalesce(p_answer_file_path,'')),''),p_mcq_answers,case when v_has_mcq then v_score else null end,case when v_has_mcq then v_total else null end,case when v_has_mcq then 'auto_graded' else 'pending' end)
 returning id into v_submission_id;
 if v_show_results and v_has_mcq and v_show_position then select count(*)+1 into v_position from public.academic_care_submissions where exam_id=v_exam.id and score>v_score;end if;
 if v_show_results and v_has_mcq then return jsonb_build_object('submission_id',v_submission_id,'grading_status','auto_graded','score',v_score,'total_marks',v_total,'position',case when v_show_position then v_position else null end,'thank_you_message',coalesce(v_exam.settings->>'thank_you_message','আপনার উত্তর জমা দেওয়ার জন্য ধন্যবাদ।'),'facebook_group_url',coalesce(v_exam.settings->>'facebook_group_url',''),'message','Submission received');end if;
 return jsonb_build_object('submission_id',v_submission_id,'grading_status',case when v_has_mcq then 'auto_graded' else 'pending' end,'thank_you_message',coalesce(v_exam.settings->>'thank_you_message','আপনার উত্তর জমা দেওয়ার জন্য ধন্যবাদ।'),'facebook_group_url',coalesce(v_exam.settings->>'facebook_group_url',''),'message','Submission received');
end;$$;
revoke all on function public.academic_care_submit_exam(uuid,text,text,text,jsonb,text) from public;
grant execute on function public.academic_care_submit_exam(uuid,text,text,text,jsonb,text) to anon,authenticated;

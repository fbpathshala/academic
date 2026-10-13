-- Allow answer-sheet uploads for all supported CQ-capable Academic Care exam types.
-- The canonical combined exam_type value is MCQ_CQ; keep the legacy label compatible too.
drop policy if exists academic_care_answer_files_upload on storage.objects;
create policy academic_care_answer_files_upload on storage.objects
for insert to anon, authenticated
with check (
  bucket_id = 'academic-care-answers'
  and exists (
    select 1
    from public.academic_care_exams e
    where e.public_token::text = (storage.foldername(name))[1]
      and e.status = 'published'
      and e.exam_type in ('CQ', 'MCQ_CQ', 'MCQ + CQ')
  )
);

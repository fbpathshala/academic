-- Align Academic Care master question bank with Job Care display fields.
-- Additive and safe: exam questions, answer keys and submissions are untouched.
alter table public.academic_care_question_bank_items
  add column if not exists explanation text;

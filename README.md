# Academic Care

Academic Care is a focused learning platform for:
- MCQ exams with a timer and automatic grading
- CQ/written exams with typed answers or answer-sheet photo uploads
- Public study materials such as PDFs, images, and notes
- A separate administrator dashboard for exams, questions, and materials

## Pages

- Public landing page: `index.html`
- Student experience: `student.html`
- Admin dashboard: `admin.html`

## Backend

The project uses Supabase project `ydvbnalhcnfqpxkkmywr` with separate `academic_care_*` tables. Legacy MCQ Exam tables are not used by this project.

- Admin authentication uses Supabase Auth plus the server-side `academic_care_is_admin()` check.
- Published exams/materials can be read publicly; drafts remain private.
- Answer keys are stored separately from question text.
- Student submissions are written through `academic_care_submit_exam()`; submissions are not directly readable by anonymous visitors.
- Study-material files are in the public `academic-care-materials` bucket.
- Answer-sheet images are stored in the private `academic-care-answers` bucket; only authorized admins can read them.
- The frontend contains only the Supabase publishable key. Never put a service-role key or database password in browser code.

## Important setup still required

1. The existing project's `super_admin` account has been copied into `public.academic_care_admins`; sign in to the admin dashboard with that account's existing Supabase Auth email and password.
2. The repository now includes a GitHub Pages deployment workflow. Enable GitHub Pages with GitHub Actions as the source in repository Settings, then verify the published URL.
3. Test a full published exam on mobile, including timer expiry, MCQ grading, typed CQ, photo upload, and private-result handling.
4. Confirm the required result visibility and thank-you text per exam before production use.

## Current implementation limits

- The admin dashboard can create exams, add MCQ/CQ questions, save answer keys, upload material files, change each exam’s result visibility, position display, thank-you message, and Facebook group link, review private submissions, open private answer-sheet images with temporary signed links, and save manual CQ marks. It uses the database, not temporary browser arrays.
- The student page lists published exams/materials, starts a timed exam, submits MCQ answers and CQ text/photo, and shows a submission receipt.
- Position display is currently based on available numeric scores; CQ answers remain pending until an administrator records their marks. The full flow still needs an end-to-end live test.
- A hosting URL and first-admin account still need owner-side configuration. Do not describe the project as fully production-tested until the end-to-end checks are complete.

# Academic Care

Academic Care is a focused academic platform for students, combining:

- MCQ exams with a timer and automatic grading
- CQ/written exams with both typed answers and answer-sheet photo uploads
- Study materials such as PDFs, images, and notes
- A simple administration dashboard for managing exams and materials

## Access and privacy

Published exams and study materials should be publicly accessible to students. Administrative controls and student submissions, identity details, and private result data must be protected by server-side authorization. Do not place service-role keys, database passwords, or other secrets in frontend files.

## Current status

The initial `index.html` is only a public landing-page scaffold. Exam delivery, answer submissions, results, file storage, authentication/authorization, and admin workflows are not implemented yet.

## Planned implementation

1. Choose and configure a secure backend/database and file storage.
2. Build the admin workflow for creating and publishing MCQ and CQ exams and study materials.
3. Implement student exam flows, including typed CQ answers and photo uploads.
4. Implement grading/results with per-exam settings.
5. Test privacy, mobile usability, and the complete student flow before public launch.

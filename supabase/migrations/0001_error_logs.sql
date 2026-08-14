-- Client-side error log.
--
-- Users see a plain-language message; the technical detail that used to be
-- shown to them (exception type, message, stack) lands here instead.
--
-- Run in the Supabase SQL editor, or via `supabase db push` once the CLI is
-- linked to the project.

create table if not exists public.error_logs (
  id            uuid primary key default gen_random_uuid(),
  created_at    timestamptz not null default now(),

  -- Null for failures that happen before sign-in, which is most of the
  -- onboarding flow. Kept if the account is later deleted so the log stays
  -- diagnostically useful without pointing at a person.
  user_id       uuid references auth.users(id) on delete set null,

  area          text not null,   -- e.g. 'onboarding.auth'
  action        text not null,   -- e.g. 'sign_in_google'
  error_type    text,            -- runtime type of the exception
  message       text,            -- technical message
  stack_trace   text,
  context       jsonb,           -- extra non-identifying detail
  app_version   text,
  platform      text
);

create index if not exists error_logs_created_at_idx
  on public.error_logs (created_at desc);

create index if not exists error_logs_area_idx
  on public.error_logs (area, created_at desc);

alter table public.error_logs enable row level security;

-- The Data API does not expose a new table to the client roles automatically.
grant insert on public.error_logs to anon, authenticated;

-- Insert only, and deliberately no select/update/delete policy: the app must
-- be able to report a failure, including one that happened before the user
-- signed in, but no client may ever read the log back. Read it from the
-- dashboard or with the service role.
drop policy if exists "clients may append error logs" on public.error_logs;
create policy "clients may append error logs"
  on public.error_logs
  for insert
  to anon, authenticated
  with check (true);

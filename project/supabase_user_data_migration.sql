-- ============================================================
-- Migration: Create user_data table
-- Run this in your Supabase project's SQL Editor
-- Dashboard → SQL Editor → New query → paste & run
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_data (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  streak          integer NOT NULL DEFAULT 0,
  duration        double precision NOT NULL DEFAULT 0,
  date            date,
  date_n_duration jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- One row per user (the app upserts by user_id)
CREATE UNIQUE INDEX IF NOT EXISTS user_data_user_id_idx ON public.user_data (user_id);

-- Auto-update updated_at on every row change
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_user_data_updated_at ON public.user_data;
CREATE TRIGGER set_user_data_updated_at
  BEFORE UPDATE ON public.user_data
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── Row Level Security ──────────────────────────────────────
ALTER TABLE public.user_data ENABLE ROW LEVEL SECURITY;

-- Users can only read/write their own row
CREATE POLICY "user_data: select own"
  ON public.user_data FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "user_data: insert own"
  ON public.user_data FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_data: update own"
  ON public.user_data FOR UPDATE
  USING (auth.uid() = user_id);

-- Migration: link staff rows to Supabase auth users
-- Adds auth_user_id to staff table so the session-based auth user can be
-- matched to a staff record. password_hash is retained but no longer used
-- for sign-in (Supabase Auth handles credentials).

alter table staff
  add column if not exists auth_user_id uuid
    unique
    references auth.users(id)
    on delete set null;

create index if not exists staff_auth_user_id_idx on staff (auth_user_id);

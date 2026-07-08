-- Link client rows to Supabase auth users (optional client accounts).
-- Mirrors 0002_auth.sql's staff.auth_user_id. Guests remain identified by
-- phone alone (clients.phone, unique) with no auth_user_id set.

alter table clients
  add column if not exists auth_user_id uuid
    unique
    references auth.users(id)
    on delete set null;

create index if not exists clients_auth_user_id_idx on clients (auth_user_id);

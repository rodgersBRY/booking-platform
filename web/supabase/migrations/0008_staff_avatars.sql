-- Staff profile photos.
--
-- Public bucket: photos are shown to clients in the booking staff picker, so
-- no signed-URL machinery is needed. All writes go through the server-side
-- admin client (POST /api/staff/[id]/avatar), matching the rest of the app's
-- "RLS everywhere disabled, enforcement in app code" pattern — no storage
-- policies needed since public reads don't require one and the admin client
-- bypasses storage RLS the same way it bypasses table RLS.

alter table staff
  add column if not exists avatar_url text;

insert into storage.buckets (id, name, public)
values ('staff-avatars', 'staff-avatars', true)
on conflict (id) do nothing;

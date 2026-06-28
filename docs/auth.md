# Authentication & Role-Based Access

**Fade & Sharp · Barbershop Platform**

---

## Auth model

The app uses **Supabase Auth** (email + password) for identity, combined with a custom `staff` table for roles. There is no separate user profile table — every person who can sign in is a row in `staff`.

### staff ↔ auth.users linking

Migration `0002_auth.sql` adds `auth_user_id uuid` to the `staff` table. This column references `auth.users(id)` (Supabase's built-in auth user table). The link is optional (`null` by default) and is set manually when provisioning a staff member.

```
auth.users.id  ──►  staff.auth_user_id
```

- One Supabase Auth user maps to exactly one staff row (the column has a `UNIQUE` constraint).
- If the auth user is deleted, `auth_user_id` is set to `null` (ON DELETE SET NULL) — the staff row is preserved.
- `password_hash` on `staff` is retained from the original schema but is no longer used for sign-in.

---

## Role → home route map

| Role           | Home route   | Access                          |
| -------------- | ------------ | ------------------------------- |
| `owner`        | `/dashboard` | Full access                     |
| `receptionist` | `/console`   | Console + dashboard denied      |
| `barber`       | `/me`        | Own schedule only                |

Implemented in `src/lib/auth.ts → roleHome(role)`.

---

## Route protection

### Proxy layer (`src/proxy.ts`)

Every request passes through `proxy.ts` (Next.js 16's replacement for `middleware.ts`). It:

1. Creates a Supabase SSR client and calls `supabase.auth.getUser()` — this refreshes the session cookie if needed.
2. If the user is **not authenticated** and the path is **not public**, redirects to `/login`.

Public paths: `/login`, `/auth/callback`.

The proxy performs only an **optimistic check** (session cookie present + valid). Role enforcement happens server-side in the page itself.

### Page-level enforcement (`src/lib/auth.ts`)

Pages call one of these helpers:

```ts
requireStaff()               // any authenticated staff
requireRole('owner')         // owner only
requireRole('owner', 'receptionist')  // owner or receptionist
```

- If no session → `redirect('/login')`
- If wrong role → `redirect(roleHome(staff.role))` (their own home)

The staff lookup uses the **admin client** (service-role key) to bypass RLS, since the `staff` table has no RLS policies for the anon key.

---

## Session refresh

`proxy.ts` uses `@supabase/ssr`'s `createServerClient` with the request/response cookie adapter. The `setAll` callback re-creates the `NextResponse` so refreshed auth cookies are forwarded to the browser on every request.

---

## Login flow

1. User visits any protected route → proxy redirects to `/login`.
2. `/login/page.tsx` renders `LoginForm` (client component).
3. Form submits to the `signIn` Server Action (`/login/actions.ts`).
4. On success: looks up the staff row by `auth_user_id`, then redirects to `roleHome(staff.role)`.
5. On failure: returns an error string rendered inline. No toast library needed.

Sign-out is a Server Action (`signOut`) that calls `supabase.auth.signOut()` then redirects to `/login`. It is invoked from a `<form action={signOut}>` on each stub page.

---

## Creating the first owner user

You need to:
1. Create a Supabase Auth user.
2. Create (or update) a `staff` row and link it.

### Step 1 — Create the auth user

In the **Supabase dashboard → Authentication → Users**, click "Invite user" or "Add user" and set the email and password.

Copy the UUID shown in the user list (e.g. `a1b2c3d4-...`). This is the `auth.users.id`.

Alternatively, via SQL:

```sql
-- This uses the auth schema helper. Only works in the Supabase SQL editor.
select auth.uid(); -- just to verify you're connected
```

Or via the Supabase Management API / CLI:

```bash
supabase auth admin create-user \
  --email owner@example.com \
  --password 'change-me-now'
```

### Step 2 — Create the staff row and link it

Run this in the **Supabase SQL Editor** (use the service-role key or the SQL editor, which bypasses RLS):

```sql
-- Replace the values below.
insert into staff (name, role, email, auth_user_id, status)
values (
  'Your Name',
  'owner',
  'owner@example.com',
  'a1b2c3d4-0000-0000-0000-000000000000',  -- ← paste the auth user UUID here
  'active'
);
```

If a staff row already exists (e.g. from a seed), update it instead:

```sql
update staff
set auth_user_id = 'a1b2c3d4-0000-0000-0000-000000000000'
where email = 'owner@example.com';
```

### Step 3 — Verify

Sign in at `/login` with the credentials you set in Step 1. You should land on `/dashboard`.

---

## Key files

| File | Purpose |
|------|---------|
| `src/proxy.ts` | Session refresh + unauthenticated redirect (Next.js 16 proxy) |
| `src/lib/auth.ts` | `getCurrentStaff`, `requireStaff`, `requireRole`, `roleHome` |
| `src/app/login/page.tsx` | Login page (server, redirects if already signed in) |
| `src/app/login/LoginForm.tsx` | Login form (client component, `useActionState`) |
| `src/app/login/actions.ts` | `signIn` and `signOut` Server Actions |
| `src/app/auth/callback/route.ts` | OAuth / magic-link code exchange handler |
| `web/supabase/migrations/0002_auth.sql` | Adds `auth_user_id` column to `staff` |

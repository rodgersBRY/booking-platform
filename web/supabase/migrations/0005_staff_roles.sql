-- Add beautician and masseuse as bookable staff roles, alongside barber.
--
-- Kept to only these two statements: Postgres cannot use a newly-added enum
-- value in the same transaction that added it, and Supabase runs each
-- migration file as its own transaction.

alter type staff_role add value if not exists 'beautician';
alter type staff_role add value if not exists 'masseuse';

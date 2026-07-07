-- Reset public application data while keeping the database schema intact.
--
-- After running this, start the app once with OWNER_EMAIL and OWNER_PASSWORD set.
-- Runtime bootstrap will recreate/link the owner staff row and seed services
-- from src/lib/init/services.json. Add barbers and receptionists from the owner dashboard.

begin;

truncate table
  public.message_log,
  public.loyalty_transactions,
  public.visits,
  public.queue_entries,
  public.bookings,
  public.barber_time_off,
  public.barber_availability,
  public.clients,
  public.services,
  public.staff
restart identity cascade;

commit;

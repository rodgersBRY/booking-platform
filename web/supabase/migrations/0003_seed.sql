-- Seed migration: sample data for development / demo.
-- Safe to run once; uses a DO block.

DO $$
DECLARE
  tunde_id uuid := gen_random_uuid();
  james_id uuid := gen_random_uuid();
  mary_id  uuid := gen_random_uuid();
BEGIN

  -- 3 barbers
  INSERT INTO staff (id, name, role, status) VALUES
    (tunde_id, 'Tunde', 'barber', 'active'),
    (james_id, 'James', 'barber', 'active'),
    (mary_id,  'Mary',  'barber', 'active');

  -- 6 services: columns are (name, duration_minutes, price, active)
  INSERT INTO services (name, duration_minutes, price, active) VALUES
    ('Haircuts & Styling',        45,  1000.00, true),
    ('Beard Grooming',            20,  400.00, true),
    ('Shaving Services',          30,  500.00, true),
    ('Facials & Skincare',        30,  700.00, true),
    ('Hair & Scalp Treatments',   45, 1000.00, true),
    ('Premium Grooming Packages', 90, 2500.00, true);

  -- barber_availability: weekdays Mon-Fri (1-5) 09:00-19:00, weekends Sat(6)/Sun(0) 13:00-21:00
  INSERT INTO barber_availability (barber_id, weekday, start_time, end_time)
  SELECT b.id, d.weekday, d.start_time::time, d.end_time::time
  FROM (VALUES (tunde_id), (james_id), (mary_id)) AS b(id)
  CROSS JOIN (
    VALUES
      (1, '09:00', '19:00'),
      (2, '09:00', '19:00'),
      (3, '09:00', '19:00'),
      (4, '09:00', '19:00'),
      (5, '09:00', '19:00'),
      (6, '13:00', '21:00'),
      (0, '13:00', '21:00')
  ) AS d(weekday, start_time, end_time);

  -- 3 sample clients, each with a preferred barber (subselect by name so it works
  -- regardless of generated UUIDs).
  INSERT INTO clients (name, phone, acquisition_source, preferred_barber_id) VALUES
    ('Josphat Mwirigi', '+254700000001', 'referral',  (SELECT id FROM staff WHERE name = 'James' AND role = 'barber')),
    ('Aisha Mohamed',   '+254700000002', 'walkin',    (SELECT id FROM staff WHERE name = 'Mary'  AND role = 'barber')),
    ('Kevin Otieno',    '+254700000003', 'whatsapp',  (SELECT id FROM staff WHERE name = 'Tunde' AND role = 'barber'));

END $$;

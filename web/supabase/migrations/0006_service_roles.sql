-- Service ↔ staff-role eligibility (many-to-many): which staff role(s) can
-- perform a given service. Enforced in app code (createBooking, availability,
-- public booking API) — see src/lib/booking/createBooking.ts.

create table service_roles (
  service_id uuid not null references services(id) on delete cascade,
  role       staff_role not null,
  primary key (service_id, role)
);
create index idx_service_roles_role on service_roles (role);

alter table service_roles enable row level security;
-- No policies, matching every other table: service-role key only.

-- ── Backfill from services.category ──────────────────────────────────────────
-- Mirrored in TS as CATEGORY_ROLE_MAP (src/lib/services/roleMapping.ts) — keep
-- both in sync if the category list ever changes.
--   haircuts, beards, hair_dyes, hair_relaxing, hair_treatments -> barber
--   nail_care, facials, waxing                                  -> beautician
--   massage, body_treatments                                    -> masseuse
--   spa_packages                                                -> masseuse + beautician (bundle)
--   unknown/null category                                       -> barber (preserves today's
--     de facto "anyone can do it" behavior so nothing goes silently unbookable)

insert into service_roles (service_id, role)
select id, 'barber'::staff_role from services
where category in ('haircuts', 'beards', 'hair_dyes', 'hair_relaxing', 'hair_treatments')
   or category is null
   or category not in (
     'haircuts', 'beards', 'hair_dyes', 'hair_relaxing', 'hair_treatments',
     'nail_care', 'facials', 'waxing', 'massage', 'body_treatments', 'spa_packages'
   );

insert into service_roles (service_id, role)
select id, 'beautician'::staff_role from services
where category in ('nail_care', 'facials', 'waxing', 'spa_packages');

insert into service_roles (service_id, role)
select id, 'masseuse'::staff_role from services
where category in ('massage', 'body_treatments', 'spa_packages');

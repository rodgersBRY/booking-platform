import type { ClientSearchResult } from "./clients/searchClients";

// Compile-time pin only — see staffDay.test.ts / staffAuth.test.ts for why
// this repo pins JSON shapes at the type level instead of executing tests.
// Pins GET /api/v1/staff/clients/search?q= (and, via the same
// ClientSearchResult shape, the cookie-authed /api/clients/search it shares
// searchClients() with).

type StaffClientSearchResponse = { clients: ClientSearchResult[] };

const withPreferredStaff: StaffClientSearchResponse = {
  clients: [
    {
      id: "client-1",
      name: "Brian Mwangi",
      phone: "0700000000",
      preferredStaffId: "staff-1",
      preferredStaffName: "James Otieno",
      totalVisits: 14,
      lastVisitAt: "2026-07-10T09:00:00.000Z",
      isRegular: true,
    },
  ],
};

const empty: StaffClientSearchResponse = { clients: [] };

void withPreferredStaff;
void empty;
